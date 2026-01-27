-- FIXIT - Setup Technician Account (Ethan Estino)
-- Run this in your Supabase SQL Editor

-- Update the fixittechnician@gmail.com account to have Ethan Estino's details
UPDATE users
SET
    full_name = 'Ethan Estino',
    address = 'San Francisco, Barangay 3',
    contact_number = '09123456789',
    verified = true,
    role = 'technician'
WHERE email = 'fixittechnician@gmail.com';

-- Also update the auth.users metadata
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{
    "full_name": "Ethan Estino",
    "role": "technician"
}'::jsonb
WHERE email = 'fixittechnician@gmail.com';

-- Verify the update
SELECT 'Updated technician account:' as info;
SELECT id, email, full_name, role, verified, address, contact_number
FROM users
WHERE email = 'fixittechnician@gmail.com';

-- Also verify admin account exists
SELECT 'Admin account:' as info;
SELECT id, email, full_name, role, verified
FROM users
WHERE email = 'fixitadmin@gmail.com';
