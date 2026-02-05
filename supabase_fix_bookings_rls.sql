-- Fix RLS policies for bookings table
-- Ensures customers can view their own bookings and bookings are persisted in database

-- ==============================================================================
-- Enable RLS on bookings table
-- ==============================================================================
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- Drop existing policies
-- ==============================================================================
DROP POLICY IF EXISTS "Customers can view their bookings" ON bookings;
DROP POLICY IF EXISTS "Customers can create bookings" ON bookings;
DROP POLICY IF EXISTS "Customers can update their bookings" ON bookings;
DROP POLICY IF EXISTS "Technicians can view their bookings" ON bookings;
DROP POLICY IF EXISTS "Technicians can update their bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can update all bookings" ON bookings;

-- ==============================================================================
-- Create comprehensive RLS policies
-- ==============================================================================

-- 1. Customers can SELECT (view) their own bookings
CREATE POLICY "Customers can view their bookings"
ON bookings
FOR SELECT
USING (
  customer_id = auth.uid()
);

-- 2. Customers can INSERT (create) bookings
CREATE POLICY "Customers can create bookings"
ON bookings
FOR INSERT
WITH CHECK (
  customer_id = auth.uid()
);

-- 3. Customers can UPDATE their own bookings
CREATE POLICY "Customers can update their bookings"
ON bookings
FOR UPDATE
USING (
  customer_id = auth.uid()
);

-- 4. Technicians can SELECT (view) their assigned bookings
CREATE POLICY "Technicians can view their bookings"
ON bookings
FOR SELECT
USING (
  technician_id = auth.uid()
);

-- 5. Technicians can UPDATE their assigned bookings
CREATE POLICY "Technicians can update their bookings"
ON bookings
FOR UPDATE
USING (
  technician_id = auth.uid()
);

-- 6. Admins can SELECT (view) all bookings
CREATE POLICY "Admins can view all bookings"
ON bookings
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- 7. Admins can UPDATE all bookings
CREATE POLICY "Admins can update all bookings"
ON bookings
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
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
    cmd,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        ELSE cmd
    END as operation
FROM pg_policies
WHERE tablename = 'bookings'
ORDER BY policyname;

-- ==============================================================================
-- SUCCESS MESSAGE
-- ==============================================================================
SELECT '✅ RLS policies for bookings table have been fixed!' as status,
       '7 policies created' as policies,
       'Bookings are now persisted in database and customers can see their own bookings' as note;
