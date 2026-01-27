-- FIXIT - Fix Admin and Technician Accounts
-- Run this in your Supabase SQL Editor

-- First, let's see what accounts exist in auth.users
SELECT 'Auth users:' as info;
SELECT id, email, raw_user_meta_data
FROM auth.users
ORDER BY created_at DESC;

-- See what's in the users table
SELECT 'Users table:' as info;
SELECT id, email, full_name, role, verified
FROM users
ORDER BY created_at DESC;

-- Fix the admin account - Update role to 'admin'
UPDATE users
SET role = 'admin', verified = true
WHERE email = 'fixitadmin@gmail.com';

-- Fix the technician account - Update role to 'technician'
UPDATE users
SET role = 'technician', verified = true
WHERE email = 'fixittechnician@gmail.com';

-- Also update the auth.users metadata to store the correct role
-- This ensures future logins will have the correct role in metadata
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin", "full_name": "FixIT Admin"}'::jsonb
WHERE email = 'fixitadmin@gmail.com';

UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{"role": "technician", "full_name": "FixIT Technician"}'::jsonb
WHERE email = 'fixittechnician@gmail.com';

-- Verify the changes
SELECT 'After fix - Users table:' as info;
SELECT id, email, full_name, role, verified
FROM users
WHERE email IN ('fixitadmin@gmail.com', 'fixittechnician@gmail.com');

SELECT 'After fix - Auth users metadata:' as info;
SELECT email, raw_user_meta_data->>'role' as role, raw_user_meta_data->>'full_name' as full_name
FROM auth.users
WHERE email IN ('fixitadmin@gmail.com', 'fixittechnician@gmail.com');

-- If the accounts don't exist in the users table yet, insert them
-- First check if they exist in auth.users but not in users table
INSERT INTO users (id, email, full_name, role, verified, created_at)
SELECT
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', 'FixIT Admin'),
    'admin',
    true,
    NOW()
FROM auth.users au
WHERE au.email = 'fixitadmin@gmail.com'
AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = au.id)
ON CONFLICT (id) DO UPDATE SET role = 'admin', verified = true;

INSERT INTO users (id, email, full_name, role, verified, created_at)
SELECT
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', 'FixIT Technician'),
    'technician',
    true,
    NOW()
FROM auth.users au
WHERE au.email = 'fixittechnician@gmail.com'
AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = au.id)
ON CONFLICT (id) DO UPDATE SET role = 'technician', verified = true;

-- Final verification
SELECT 'Final state - All users:' as info;
SELECT id, email, full_name, role, verified, created_at
FROM users
ORDER BY
    CASE role
        WHEN 'admin' THEN 1
        WHEN 'technician' THEN 2
        ELSE 3
    END,
    created_at DESC;
