-- Fix RLS policies for technician_profiles table
-- Allows admins to create/update technician profiles during verification approval

-- ==============================================================================
-- Enable RLS on technician_profiles table
-- ==============================================================================
ALTER TABLE technician_profiles ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- Drop existing policies
-- ==============================================================================
DROP POLICY IF EXISTS "Technicians can view their own profile" ON technician_profiles;
DROP POLICY IF EXISTS "Technicians can update their own profile" ON technician_profiles;
DROP POLICY IF EXISTS "Admins can view all technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Admins can insert technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Admins can update technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Public can view verified technician profiles" ON technician_profiles;

-- ==============================================================================
-- Create new RLS policies
-- ==============================================================================

-- 1. Technicians can view their own profile
CREATE POLICY "Technicians can view their own profile"
ON technician_profiles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 2. Technicians can update their own profile
CREATE POLICY "Technicians can update their own profile"
ON technician_profiles
FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- 3. Admins can view all technician profiles
CREATE POLICY "Admins can view all technician profiles"
ON technician_profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- 4. Admins can INSERT technician profiles (for verification approval)
CREATE POLICY "Admins can insert technician profiles"
ON technician_profiles
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- 5. Admins can UPDATE technician profiles
CREATE POLICY "Admins can update technician profiles"
ON technician_profiles
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- 6. Public can view verified technician profiles (for customer browsing)
CREATE POLICY "Public can view verified technician profiles"
ON technician_profiles
FOR SELECT
TO anon, authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = technician_profiles.user_id 
    AND users.verified = true
  )
);

-- ==============================================================================
-- Verify policies are active
-- ==============================================================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'technician_profiles'
ORDER BY policyname;

-- ==============================================================================
SELECT 'RLS policies for technician_profiles fixed successfully!' as status;
-- ==============================================================================
