-- ============================================================
-- FIXIT APP - Real-time Notification Triggers
-- Run this in Supabase SQL Editor
-- ============================================================

-- -------------------------------------------------------
-- 1. Make sure the notifications table exists with RLS
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL DEFAULT 'general',
  title       TEXT NOT NULL,
  message     TEXT NOT NULL,
  data        JSONB,
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast per-user queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id
  ON public.notifications(user_id, created_at DESC);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can only see their own notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update (mark read) their own notifications
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own notifications
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Service role can insert (used by triggers)
DROP POLICY IF EXISTS "Service role can insert notifications" ON public.notifications;
CREATE POLICY "Service role can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (TRUE);

-- Enable realtime on notifications table
-- REPLICA IDENTITY FULL is required for UPDATE/DELETE events to stream correctly
ALTER TABLE public.notifications REPLICA IDENTITY FULL;
-- NOTE: If you get "already member of publication" error, comment out the line below:
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- -------------------------------------------------------
-- 2. Helper function to insert a notification
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id  UUID,
  p_type     TEXT,
  p_title    TEXT,
  p_message  TEXT,
  p_data     JSONB DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.notifications(user_id, type, title, message, data)
  VALUES (p_user_id, p_type, p_title, p_message, p_data);
END;
$$;

-- -------------------------------------------------------
-- 3. Main trigger function on bookings table
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_booking_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_customer_name  TEXT;
  v_tech_name      TEXT;
  v_booking_route  TEXT;
BEGIN
  -- Fetch names for readable messages
  SELECT COALESCE(full_name, 'Customer')  INTO v_customer_name
    FROM public.users WHERE id = NEW.customer_id;

  SELECT COALESCE(full_name, 'Technician') INTO v_tech_name
    FROM public.users WHERE id = NEW.technician_id;

  v_booking_route := '/booking/' || NEW.id;

  -- ── INSERT: New booking created ──────────────────────────
  IF TG_OP = 'INSERT' THEN
    -- Notify the technician
    PERFORM public.create_notification(
      NEW.technician_id,
      'job_request',
      'New Job Request',
      v_customer_name || ' requested a service. Tap to view details.',
      jsonb_build_object('booking_id', NEW.id, 'route', '/tech-jobs')
    );

    -- Notify all admins
    INSERT INTO public.notifications(user_id, type, title, message, data)
    SELECT id,
           'booking_request',
           'New Booking',
           v_customer_name || ' created a new booking.',
           jsonb_build_object('booking_id', NEW.id, 'route', '/admin-appointments')
    FROM public.users
    WHERE role = 'admin';

    RETURN NEW;
  END IF;

  -- ── UPDATE: Status changed ───────────────────────────────
  IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN

    -- Technician accepted
    IF NEW.status = 'accepted' THEN
      PERFORM public.create_notification(
        NEW.customer_id,
        'job_accepted',
        'Booking Accepted!',
        v_tech_name || ' accepted your service request. They will be on their way.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    -- Technician on the way
    ELSIF NEW.status = 'en_route' THEN
      PERFORM public.create_notification(
        NEW.customer_id,
        'job_accepted',
        'Technician On The Way',
        v_tech_name || ' is heading to your location now.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    -- Service in progress
    ELSIF NEW.status = 'in_progress' THEN
      PERFORM public.create_notification(
        NEW.customer_id,
        'job_accepted',
        'Service Started',
        v_tech_name || ' has started working on your device.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    -- Service completed
    ELSIF NEW.status = 'completed' THEN
      -- Notify customer
      PERFORM public.create_notification(
        NEW.customer_id,
        'job_accepted',
        'Service Completed!',
        'Your service by ' || v_tech_name || ' is done. Please rate your experience.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );
      -- Notify technician
      PERFORM public.create_notification(
        NEW.technician_id,
        'payment',
        'Job Completed',
        'You completed a job for ' || v_customer_name || '. Earnings will be updated shortly.',
        jsonb_build_object('booking_id', NEW.id, 'route', '/tech-jobs')
      );
      -- Notify admins
      INSERT INTO public.notifications(user_id, type, title, message, data)
      SELECT id,
             'payment',
             'Booking Completed',
             v_tech_name || ' completed a job for ' || v_customer_name || '.',
             jsonb_build_object('booking_id', NEW.id, 'route', '/admin-appointments')
      FROM public.users WHERE role = 'admin';

    -- Cancelled
    ELSIF NEW.status = 'cancelled' THEN
      -- Notify customer
      PERFORM public.create_notification(
        NEW.customer_id,
        'reminder',
        'Booking Cancelled',
        'Your booking has been cancelled.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );
      -- Notify technician
      PERFORM public.create_notification(
        NEW.technician_id,
        'reminder',
        'Job Cancelled',
        'A booking from ' || v_customer_name || ' was cancelled.',
        jsonb_build_object('booking_id', NEW.id, 'route', '/tech-jobs')
      );
      -- Notify admins
      INSERT INTO public.notifications(user_id, type, title, message, data)
      SELECT id,
             'reminder',
             'Booking Cancelled',
             'Booking from ' || v_customer_name || ' was cancelled.',
             jsonb_build_object('booking_id', NEW.id, 'route', '/admin-appointments')
      FROM public.users WHERE role = 'admin';

    -- Scheduled
    ELSIF NEW.status = 'scheduled' THEN
      PERFORM public.create_notification(
        NEW.customer_id,
        'reminder',
        'Appointment Scheduled',
        'Your appointment with ' || v_tech_name || ' is confirmed.',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );

    END IF;
  END IF;

  -- ── UPDATE: Payment status changed ──────────────────────
  IF TG_OP = 'UPDATE' AND OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
    IF NEW.payment_status = 'paid' THEN
      -- Notify customer
      PERFORM public.create_notification(
        NEW.customer_id,
        'payment',
        'Payment Confirmed',
        'Your payment for the service has been received. Thank you!',
        jsonb_build_object('booking_id', NEW.id, 'route', v_booking_route)
      );
      -- Notify technician
      PERFORM public.create_notification(
        NEW.technician_id,
        'payment',
        'Payment Received',
        v_customer_name || ' completed payment for your service.',
        jsonb_build_object('booking_id', NEW.id, 'route', '/tech-earnings')
      );
      -- Notify admins
      INSERT INTO public.notifications(user_id, type, title, message, data)
      SELECT id,
             'payment',
             'Payment Received',
             v_customer_name || ' paid for booking.',
             jsonb_build_object('booking_id', NEW.id, 'route', '/admin-earnings')
      FROM public.users WHERE role = 'admin';
    END IF;
  END IF;

  -- ── UPDATE: Rating added ─────────────────────────────────
  IF TG_OP = 'UPDATE' AND OLD.rating IS DISTINCT FROM NEW.rating AND NEW.rating IS NOT NULL THEN
    PERFORM public.create_notification(
      NEW.technician_id,
      'rating',
      'New Rating Received',
      v_customer_name || ' gave you a ' || NEW.rating || '-star rating.',
      jsonb_build_object('booking_id', NEW.id, 'route', '/tech-ratings')
    );
  END IF;

  RETURN NEW;
END;
$$;

-- -------------------------------------------------------
-- 4. Attach trigger to bookings table
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS trg_booking_notifications ON public.bookings;
CREATE TRIGGER trg_booking_notifications
  AFTER INSERT OR UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_booking_notifications();

-- -------------------------------------------------------
-- 5. Trigger for technician verification status changes
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_verification_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.verified IS DISTINCT FROM NEW.verified THEN
    IF NEW.verified = TRUE THEN
      PERFORM public.create_notification(
        NEW.id,
        'verification_result',
        'Account Verified!',
        'Congratulations! Your technician account has been verified. You can now accept jobs.',
        jsonb_build_object('route', '/tech-home')
      );
    ELSE
      PERFORM public.create_notification(
        NEW.id,
        'verification_result',
        'Verification Revoked',
        'Your technician verification has been revoked. Please contact support.',
        jsonb_build_object('route', '/tech-help-support')
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_verification_notifications ON public.users;
CREATE TRIGGER trg_verification_notifications
  AFTER UPDATE OF verified ON public.users
  FOR EACH ROW
  WHEN (NEW.role = 'technician')
  EXECUTE FUNCTION public.handle_verification_notifications();

-- -------------------------------------------------------
-- 6. Trigger for chat messages (new message notification)
-- -------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_message_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_sender_name   TEXT;
  v_customer_id   UUID;
  v_tech_id       UUID;
  v_recipient_id  UUID;
BEGIN
  -- Get sender name
  SELECT COALESCE(full_name, 'Someone') INTO v_sender_name
    FROM public.users WHERE id = NEW.sender_id;

  -- Get the chat participants
  SELECT customer_id, technician_id
    INTO v_customer_id, v_tech_id
    FROM public.chats WHERE id = NEW.chat_id;

  -- Recipient is the other person in the chat
  IF NEW.sender_id = v_customer_id THEN
    v_recipient_id := v_tech_id;
  ELSE
    v_recipient_id := v_customer_id;
  END IF;

  PERFORM public.create_notification(
    v_recipient_id,
    'message',
    'New Message',
    v_sender_name || ': ' || LEFT(NEW.message, 80),
    jsonb_build_object('chat_id', NEW.chat_id, 'route', '/chat/' || NEW.chat_id)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_message_notifications ON public.messages;
CREATE TRIGGER trg_message_notifications
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_message_notifications();
