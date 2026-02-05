-- FINAL FIX for technician_profiles RLS policy
-- This allows admins to create technician profiles during verification approval
-- Based on your actual schema structure

-- ==============================================================================
-- Step 1: Drop all existing policies on technician_profiles
-- ==============================================================================
DROP POLICY IF EXISTS "Technicians can view their own profile" ON technician_profiles;
DROP POLICY IF EXISTS "Technicians can update their own profile" ON technician_profiles;
DROP POLICY IF EXISTS "Technicians can insert their own profile" ON technician_profiles;
DROP POLICY IF EXISTS "Admins can view all technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Admins can insert technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Admins can update technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Public can view verified technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Users can view technician profiles" ON technician_profiles;
DROP POLICY IF EXISTS "Users can update technician profiles" ON technician_profiles;

-- ==============================================================================
-- Step 2: Enable RLS (if not already enabled)
-- ==============================================================================
ALTER TABLE technician_profiles ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- Step 3: Create comprehensive RLS policies
-- ==============================================================================

-- Policy 1: Technicians can view their own profile
CREATE POLICY "Technicians can view their own profile"
ON technician_profiles
FOR SELECT
USING (
  user_id = auth.uid()
);

-- Policy 2: Technicians can update their own profile
CREATE POLICY "Technicians can update their own profile"
ON technician_profiles
FOR UPDATE
USING (
  user_id = auth.uid()
);

-- Policy 3: Technicians can insert their own profile (optional, for self-registration)
CREATE POLICY "Technicians can insert their own profile"
ON technician_profiles
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'technician'
  )
);

-- Policy 4: Admins can view ALL technician profiles
CREATE POLICY "Admins can view all technician profiles"
ON technician_profiles
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- Policy 5: Admins can INSERT technician profiles (CRITICAL FOR VERIFICATION APPROVAL)
CREATE POLICY "Admins can insert technician profiles"
ON technician_profiles
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- Policy 6: Admins can UPDATE technician profiles
CREATE POLICY "Admins can update technician profiles"
ON technician_profiles
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- Policy 7: Public/Customers can view verified technician profiles (for browsing)
CREATE POLICY "Public can view verified technician profiles"
ON technician_profiles
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = technician_profiles.user_id 
    AND users.verified = true
  )
);

-- ==============================================================================
-- Step 4: Verify policies are created
-- ==============================================================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        ELSE cmd
    END as operation
FROM pg_policies
WHERE tablename = 'technician_profiles'
ORDER BY policyname;

-- ==============================================================================
-- Step 5: Test admin can insert (run this after the policies are created)
-- ==============================================================================
-- Uncomment to test if you're logged in as admin:
-- INSERT INTO technician_profiles (
--     user_id, 
--     specialties, 
--     years_experience, 
--     bio,
--     is_available,
--     rating,
--     total_jobs
-- ) VALUES (
--     'YOUR_TEST_USER_ID'::uuid,
--     ARRAY['Test Specialty'],
--     5,
--     'Test bio',
--     true,
--     0.0,
--     0
-- );

-- ==============================================================================
-- SUCCESS MESSAGE
-- ==============================================================================
SELECT '✅ RLS policies for technician_profiles have been fixed!' as status,
       '7 policies created' as policies,
       'Admins can now create technician profiles during verification approval' as note;
