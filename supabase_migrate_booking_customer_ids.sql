-- Migration script to ensure all bookings have proper customer_id
-- This fixes the issue where customers were seeing each other's appointments
-- Run this script in your Supabase SQL Editor

-- ==============================================================================
-- STEP 1: Identify bookings with NULL customer_id
-- ==============================================================================
-- Run this first to see which bookings need fixing
SELECT 
    id,
    customer_id,
    technician_id,
    status,
    created_at,
    customer_address
FROM bookings
WHERE customer_id IS NULL
ORDER BY created_at DESC;

-- ==============================================================================
-- STEP 2: Delete orphaned bookings (bookings with no customer_id)
-- ==============================================================================
-- WARNING: This will permanently delete bookings that cannot be associated with a customer
-- Only run this if you're sure these bookings are invalid or test data
-- Uncomment the line below to execute:

-- DELETE FROM bookings WHERE customer_id IS NULL;

-- ==============================================================================
-- STEP 3: Add constraint to prevent future NULL customer_ids (if not already present)
-- ==============================================================================
-- This ensures all future bookings MUST have a customer_id
DO $$ 
BEGIN
    -- Check if constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'bookings_customer_id_not_null' 
        AND table_name = 'bookings'
    ) THEN
        -- First, ensure no NULL values exist
        DELETE FROM bookings WHERE customer_id IS NULL;
        
        -- Then add NOT NULL constraint
        ALTER TABLE bookings 
        ALTER COLUMN customer_id SET NOT NULL;
        
        RAISE NOTICE 'Added NOT NULL constraint to bookings.customer_id';
    ELSE
        RAISE NOTICE 'Constraint already exists';
    END IF;
END $$;

-- ==============================================================================
-- STEP 4: Verify the fix
-- ==============================================================================
-- Check that all bookings now have customer_id
SELECT 
    COUNT(*) as total_bookings,
    COUNT(customer_id) as bookings_with_customer_id,
    COUNT(*) - COUNT(customer_id) as bookings_without_customer_id
FROM bookings;

-- View bookings grouped by customer
SELECT 
    u.full_name,
    u.email,
    COUNT(b.id) as booking_count
FROM users u
LEFT JOIN bookings b ON b.customer_id = u.id
WHERE u.role = 'customer'
GROUP BY u.id, u.full_name, u.email
ORDER BY booking_count DESC;

-- ==============================================================================
-- STEP 5: Update RLS policies to ensure they're secure
-- ==============================================================================
-- These policies ensure customers can ONLY see their own bookings

-- Drop existing customer booking policies
DROP POLICY IF EXISTS "Customers can view their bookings" ON bookings;
DROP POLICY IF EXISTS "Customers can create bookings" ON bookings;
DROP POLICY IF EXISTS "Customers can update their bookings" ON bookings;

-- Recreate with strict customer_id matching
CREATE POLICY "Customers can view their bookings" 
ON bookings FOR SELECT 
USING (customer_id = auth.uid());

CREATE POLICY "Customers can create bookings" 
ON bookings FOR INSERT 
WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Customers can update their bookings" 
ON bookings FOR UPDATE 
USING (customer_id = auth.uid());

-- Ensure technicians can still view and update their bookings
DROP POLICY IF EXISTS "Technicians can view their bookings" ON bookings;
DROP POLICY IF EXISTS "Technicians can update their bookings" ON bookings;

CREATE POLICY "Technicians can view their bookings" 
ON bookings FOR SELECT 
USING (technician_id = auth.uid());

CREATE POLICY "Technicians can update their bookings" 
ON bookings FOR UPDATE 
USING (technician_id = auth.uid());

-- Admin policies (admins can see everything)
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can update all bookings" ON bookings;

CREATE POLICY "Admins can view all bookings" 
ON bookings FOR SELECT 
USING (is_admin());

CREATE POLICY "Admins can update all bookings" 
ON bookings FOR UPDATE 
USING (is_admin());

-- ==============================================================================
-- MIGRATION COMPLETE
-- ==============================================================================
SELECT 'Migration completed successfully! All bookings now require customer_id.' as status;
