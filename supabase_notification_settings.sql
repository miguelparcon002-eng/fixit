-- ============================================================
-- FIXIT APP - Notification Settings + Promotional Triggers
-- Run this in Supabase SQL Editor
-- ============================================================

-- -------------------------------------------------------
-- 1. user_notification_settings table
--    One row per user, upserted from the Flutter app.
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
  user_id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  push_notifications   BOOLEAN NOT NULL DEFAULT TRUE,
  email_notifications  BOOLEAN NOT NULL DEFAULT TRUE,
  sms_notifications    BOOLEAN NOT NULL DEFAULT FALSE,
  booking_updates      BOOLEAN NOT NULL DEFAULT TRUE,
  technician_messages  BOOLEAN NOT NULL DEFAULT TRUE,
  service_completed    BOOLEAN NOT NULL DEFAULT TRUE,
  payment_reminders    BOOLEAN NOT NULL DEFAULT TRUE,
  promotional          BOOLEAN NOT NULL DEFAULT TRUE,
  new_offers           BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Keep updated_at current automatically
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notification_settings_updated_at
  ON public.user_notification_settings;
CREATE TRIGGER trg_notification_settings_updated_at
  BEFORE UPDATE ON public.user_notification_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own notification settings"
  ON public.user_notification_settings;
CREATE POLICY "Users manage own notification settings"
  ON public.user_notification_settings
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- -------------------------------------------------------
-- 2. promotions table
--    Admins insert rows here to broadcast promotional
--    and new-offer notifications to all customers.
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.promotions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type        TEXT NOT NULL DEFAULT 'promotional',
  -- 'promotional' → maps to the "Promotional Notifications" toggle
  -- 'new_offer'   → maps to the "New Offers" toggle
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  data        JSONB,            -- optional extra payload (route, image_url, etc.)
  target_role TEXT DEFAULT NULL,
  -- NULL = all users, 'customer' = customers only, 'technician' = technicians only
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Only admins can insert/update/delete promotions
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage promotions" ON public.promotions;
CREATE POLICY "Admins manage promotions"
  ON public.promotions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Anyone authenticated can read promotions (the trigger does the actual fan-out)
DROP POLICY IF EXISTS "Authenticated users can read promotions" ON public.promotions;
CREATE POLICY "Authenticated users can read promotions"
  ON public.promotions FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- -------------------------------------------------------
-- 3. Trigger: fan-out promotional notifications
--    Fires on INSERT into promotions.
--    Sends a notification to every matching user whose
--    notification settings allow that type.
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_promotion_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_setting_col TEXT;
BEGIN
  -- Map promotion type to the settings column
  IF NEW.type = 'new_offer' THEN
    v_setting_col := 'new_offers';
  ELSE
    v_setting_col := 'promotional';
  END IF;

  -- Insert a notification for each eligible user
  -- A user is eligible when:
  --   a) their role matches the target_role (or target_role is NULL = all)
  --   b) their notification setting for this type is TRUE
  --      (or they have no settings row yet → defaults TRUE for promotional, FALSE for new_offers)
  INSERT INTO public.notifications (user_id, type, title, message, data)
  SELECT
    u.id,
    NEW.type,
    NEW.title,
    NEW.message,
    COALESCE(NEW.data, '{}'::jsonb)
  FROM public.users u
  LEFT JOIN public.user_notification_settings s ON s.user_id = u.id
  WHERE
    -- role filter
    (NEW.target_role IS NULL OR u.role = NEW.target_role)
    -- only active (non-admin) users
    AND u.role <> 'admin'
    -- respect the matching toggle (default TRUE for promotional, FALSE for new_offers)
    AND CASE
      WHEN v_setting_col = 'new_offers'   THEN COALESCE(s.new_offers,  FALSE)
      WHEN v_setting_col = 'promotional'  THEN COALESCE(s.promotional, TRUE)
      ELSE TRUE
    END = TRUE;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_promotion_notifications ON public.promotions;
CREATE TRIGGER trg_promotion_notifications
  AFTER INSERT ON public.promotions
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_promotion_notifications();


-- -------------------------------------------------------
-- 4. Also update the booking trigger so "service_completed"
--    uses the correct type so the Flutter `allows()` method
--    can filter it independently of booking_updates.
-- -------------------------------------------------------
-- Re-create handle_booking_notifications with 'service_completed' type
CREATE OR REPLACE FUNCTION public.handle_booking_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_customer_name  TEXT;
  v_tech_name      TEXT;
  v_booking_route  TEXT;
BEGIN
  SELECT COALESCE(full_name, 'Customer')   INTO v_customer_name
    FROM public.users WHERE id = NEW.customer_id;

  SELECT COALESCE(full_name, 'Technician') INTO v_tech_name
    FROM public.users WHERE id = NEW.technician_id;

  v_booking_route := '/booking/' || NEW.id;

  -- ── INSERT: New booking ──────────────────────────────
  IF TG_OP = 'INSERT' THEN
    PERFORM public.create_notification(
      NEW.technician_id,
      'job_request',
      'New Job Request',
      v_customer_name || ' requested a service. Tap to view details.',
      jsonb_build_object('booking_id', NEW.id, 'route', '/tech-jobs')
    );
    INSERT INTO public.notifications(user_id, type, title, message, data)
    SELECT id, 'booking_request', 'New Booking',
           v_customer_name || ' created a new booking.',
           jsonb_build_object('booking_id', NEW.id, 'route', '/admin-appointments')
    FROM public.users WHERE role = 'admin';
    RETURN NEW;
  END IF;

  -- ── UPDATE: Status changed ───────────────────────────
  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN

    IF NEW.status = 'accepted' THEN
      PERFORM public.create_notification(
        NEW.customer_id, 'job_accepted', 'Booking Accepted!',
        v_tech_name || ' accepted your service request. They will be on their way.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    ELSIF NEW.status = 'en_route' THEN
      PERFORM public.create_notification(
        NEW.customer_id, 'job_accepted', 'Technician On The Way',
        v_tech_name || ' is heading to your location now.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    ELSIF NEW.status = 'in_progress' THEN
      PERFORM public.create_notification(
        NEW.customer_id, 'job_accepted', 'Service Started',
        v_tech_name || ' has started working on your device.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    ELSIF NEW.status = 'completed' THEN
      -- Use 'service_completed' type so the toggle filters it separately
      PERFORM public.create_notification(
        NEW.customer_id, 'service_completed', 'Service Completed!',
        'Your service by ' || v_tech_name || ' is done. Please rate your experience.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );
      PERFORM public.create_notification(
        NEW.technician_id, 'payment', 'Job Completed',
        'You completed a job for ' || v_customer_name || '. Earnings will be updated shortly.',
        jsonb_build_object('booking_id', NEW.id, 'route', '/tech-jobs')
      );
      INSERT INTO public.notifications(user_id, type, title, message, data)
      SELECT id, 'payment', 'Booking Completed',
             v_tech_name || ' completed a job for ' || v_customer_name || '.',
             jsonb_build_object('booking_id', NEW.id, 'route', '/admin-appointments')
      FROM public.users WHERE role = 'admin';

    ELSIF NEW.status = 'cancelled' THEN
      PERFORM public.create_notification(
        NEW.customer_id, 'reminder', 'Booking Cancelled',
        'Your booking has been cancelled.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );
      PERFORM public.create_notification(
        NEW.technician_id, 'reminder', 'Job Cancelled',
        'A booking from ' || v_customer_name || ' was cancelled.',
        jsonb_build_object('booking_id', NEW.id, 'route', '/tech-jobs')
      );
      INSERT INTO public.notifications(user_id, type, title, message, data)
      SELECT id, 'reminder', 'Booking Cancelled',
             'Booking from ' || v_customer_name || ' was cancelled.',
             jsonb_build_object('booking_id', NEW.id, 'route', '/admin-appointments')
      FROM public.users WHERE role = 'admin';

    ELSIF NEW.status = 'scheduled' THEN
      PERFORM public.create_notification(
        NEW.customer_id, 'reminder', 'Appointment Scheduled',
        'Your appointment with ' || v_tech_name || ' is confirmed.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    END IF;
  END IF;

  -- ── UPDATE: Payment status ───────────────────────────
  IF TG_OP = 'UPDATE' AND OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
    IF NEW.payment_status = 'paid' THEN
      PERFORM public.create_notification(
        NEW.customer_id, 'payment', 'Payment Confirmed',
        'Your payment for the service has been received. Thank you!',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );
      PERFORM public.create_notification(
        NEW.technician_id, 'payment', 'Payment Received',
        v_customer_name || ' completed payment for your service.',
        jsonb_build_object('booking_id', NEW.id, 'route', '/tech-earnings')
      );
      INSERT INTO public.notifications(user_id, type, title, message, data)
      SELECT id, 'payment', 'Payment Received',
             v_customer_name || ' paid for booking.',
             jsonb_build_object('booking_id', NEW.id, 'route', '/admin-earnings')
      FROM public.users WHERE role = 'admin';
    END IF;
  END IF;

  -- ── UPDATE: Rating added ─────────────────────────────
  IF TG_OP = 'UPDATE' AND OLD.rating IS DISTINCT FROM NEW.rating AND NEW.rating IS NOT NULL THEN
    PERFORM public.create_notification(
      NEW.technician_id, 'rating', 'New Rating Received',
      v_customer_name || ' gave you a ' || NEW.rating || '-star rating.',
      jsonb_build_object('booking_id', NEW.id, 'route', '/tech-ratings')
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Re-attach (trigger name is the same so DROP IF EXISTS + CREATE is safe)
DROP TRIGGER IF EXISTS trg_booking_notifications ON public.bookings;
CREATE TRIGGER trg_booking_notifications
  AFTER INSERT OR UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_booking_notifications();
