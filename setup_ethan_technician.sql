-- Setup Script: Make Ethan Estino a Technician
-- Email: fixittechnician@gmail.com

-- Step 1: Find Ethan's user ID from auth.users
-- Run this first to get the user ID
SELECT id, email, created_at
FROM auth.users
WHERE email = 'fixittechnician@gmail.com';

-- Step 2: After you get the ID from above, replace 'USER_ID_HERE' below and run this
-- This will create or update the user in public.users table with technician role
INSERT INTO public.users (
  id,
  email,
  full_name,
  role,
  verified,
  created_at
)
VALUES (
  'USER_ID_HERE'::uuid,  -- Replace with actual UUID from Step 1
  'fixittechnician@gmail.com',
  'Ethan Estino',
  'technician',
  true,
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET 
  role = 'technician',
  full_name = 'Ethan Estino',
  verified = true,
  updated_at = NOW();

-- Step 3: Verify the technician was created
SELECT id, email, full_name, role, verified
FROM public.users
WHERE email = 'fixittechnician@gmail.com';

-- Step 4 (OPTIONAL): Create a default service for Ethan
-- Replace 'USER_ID_HERE' with the same UUID from Step 1
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
  'USER_ID_HERE'::uuid,  -- Replace with actual UUID
  'General Repair',
  'Professional device repair service by Ethan Estino',
  'Repair',
  60,
  true,
  NOW()
)
ON CONFLICT DO NOTHING;

-- Step 5: Verify service was created
SELECT id, service_name, technician_id, is_active
FROM public.services
WHERE technician_id = 'USER_ID_HERE'::uuid;  -- Replace with actual UUID

-- DONE! Ethan is now a technician ✅
