# Setup Instructions: Adding Technician and Service

## Error: "insert or update on table bookings violates foreign key constraint"

This error occurs when there are no **technicians** or **services** in your database. Here's how to fix it:

---

## Solution 1: Add a Technician User via Supabase Dashboard

### Step 1: Create a Technician User

1. Go to your **Supabase Dashboard**
2. Navigate to **Authentication** → **Users**
3. Click **Add user** (or **Invite user**)
4. Enter:
   - **Email**: technician@example.com
   - **Password**: Choose a strong password
   - **Confirm email**: ✅ (check this)
5. Click **Create user**
6. **Copy the User ID** (UUID) - you'll need this

### Step 2: Update User Role in Database

1. Go to **Table Editor** → **users** table
2. Find the user you just created
3. Click **Edit** on that row
4. Set these fields:
   - **role**: `technician`
   - **full_name**: `John Doe` (or any name)
   - **verified**: `true` ✅
5. Click **Save**

### Step 3: Create a Service (Optional - App will auto-create)

The app will automatically create a "General Repair" service when you make your first booking. But if you want to create it manually:

1. Go to **Table Editor** → **services** table
2. Click **Insert** → **Insert row**
3. Fill in:
   - **technician_id**: (paste the technician user ID from Step 1)
   - **service_name**: `General Repair`
   - **description**: `General device repair service`
   - **category**: `Repair`
   - **estimated_duration**: `60`
   - **is_active**: `true` ✅
4. Click **Save**

---

## Solution 2: Add Technician via SQL (Faster)

Run this SQL in **Supabase SQL Editor**:

```sql
-- Step 1: Create a technician user in auth.users (replace with your email/password)
-- You need to do this through the Supabase dashboard first, then get the user ID

-- Step 2: Update the user role in public.users
-- Replace 'YOUR_USER_ID_HERE' with the actual UUID from auth.users
INSERT INTO public.users (id, email, full_name, role, verified, created_at)
VALUES (
  'YOUR_USER_ID_HERE'::uuid,  -- Replace with actual user ID
  'technician@example.com',
  'John Doe',
  'technician',
  true,
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET role = 'technician',
    verified = true;

-- Step 3: Create a default service (OPTIONAL - app will auto-create)
INSERT INTO public.services (
  technician_id,
  service_name,
  description,
  category,
  estimated_duration,
  is_active,
  created_at
)
VALUES (
  'YOUR_USER_ID_HERE'::uuid,  -- Same user ID as above
  'General Repair',
  'General device repair service',
  'Repair',
  60,
  true,
  NOW()
);
```

---

## Solution 3: Sign Up as Technician in the App

1. **Run the app**
2. Go to **Sign Up**
3. Select **Technician** role
4. Complete registration
5. The app should automatically create the user with `role='technician'`

---

## Verification

After adding a technician, verify by running this SQL:

```sql
-- Check if technician exists
SELECT id, email, full_name, role, verified
FROM public.users
WHERE role = 'technician';

-- Check if services exist
SELECT id, service_name, technician_id, is_active
FROM public.services;
```

You should see at least one technician user. Services can be auto-created by the app.

---

## Now Try Creating a Booking Again!

After completing these steps:
1. **Restart your app** (if needed)
2. Try creating a booking again
3. The app will now find the technician and create/use the service

---

## Troubleshooting

### Still getting error?

**Check your RLS policies:**
```sql
-- Make sure users table is accessible
SELECT * FROM public.users WHERE role = 'technician' LIMIT 1;

-- Make sure services table is accessible
SELECT * FROM public.services LIMIT 1;
```

If you get permission errors, run:
```sql
-- Enable RLS but allow read access
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to services"
ON public.services FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow technicians to manage their services"
ON public.services FOR ALL
TO authenticated
USING (technician_id = auth.uid());
```

---

## Quick Test Script

Copy your technician user ID and run this to verify setup:

```sql
-- Replace with your actual technician ID
DO $$
DECLARE
  tech_id uuid := 'YOUR_TECHNICIAN_ID_HERE'::uuid;
  service_id uuid;
BEGIN
  -- Check technician exists
  IF EXISTS (SELECT 1 FROM public.users WHERE id = tech_id AND role = 'technician') THEN
    RAISE NOTICE 'Technician found: %', tech_id;
  ELSE
    RAISE EXCEPTION 'Technician not found!';
  END IF;
  
  -- Check or create service
  SELECT id INTO service_id FROM public.services WHERE technician_id = tech_id LIMIT 1;
  
  IF service_id IS NULL THEN
    INSERT INTO public.services (technician_id, service_name, description, category, estimated_duration, is_active)
    VALUES (tech_id, 'General Repair', 'General device repair service', 'Repair', 60, true)
    RETURNING id INTO service_id;
    RAISE NOTICE 'Service created: %', service_id;
  ELSE
    RAISE NOTICE 'Service found: %', service_id;
  END IF;
END $$;
```

---

**After setup, you should be able to create bookings successfully!** ✅
