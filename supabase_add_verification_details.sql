-- Add technician information fields to verification_requests table
-- This allows admins to see all the information submitted by technicians

-- ==============================================================================
-- Add new columns to verification_requests table
-- ==============================================================================
ALTER TABLE verification_requests 
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS contact_number TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS years_experience INTEGER,
ADD COLUMN IF NOT EXISTS shop_name TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS specialties TEXT[];

-- ==============================================================================
-- Update existing verification requests to pull data from users table
-- ==============================================================================
UPDATE verification_requests vr
SET 
  full_name = u.full_name,
  contact_number = u.contact_number,
  address = u.address
FROM users u
WHERE vr.user_id = u.id
AND vr.full_name IS NULL;

-- ==============================================================================
-- Verify the changes
-- ==============================================================================
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'verification_requests'
ORDER BY ordinal_position;

-- ==============================================================================
SELECT 'Verification table updated successfully!' as status;
-- ==============================================================================
