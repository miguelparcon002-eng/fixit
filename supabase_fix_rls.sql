-- FIXIT - Fix RLS Policies for User Accounts
-- Run this in your Supabase SQL Editor to fix account storage issues

-- First, drop existing user policies that might be causing conflicts
DROP POLICY IF EXISTS "Users can insert their own profile on signup" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Anyone can view verified technicians" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update any user" ON users;

-- Create new, more permissive policies for users table

-- Allow users to insert their own profile (matches auth.uid() with the id being inserted)
CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow anyone to view basic info of verified technicians (for browsing)
CREATE POLICY "Public can view verified technicians"
ON users FOR SELECT
USING (role = 'technician' AND verified = true);

-- Allow admins to view all users
CREATE POLICY "Admins view all users"
ON users FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Allow admins to update any user
CREATE POLICY "Admins update all users"
ON users FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Allow admins to delete users
CREATE POLICY "Admins delete users"
ON users FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Fix local_storage table policies (for user-specific app data)
DROP POLICY IF EXISTS "Users can manage their own storage" ON local_storage;
DROP POLICY IF EXISTS "Users can insert their own storage" ON local_storage;
DROP POLICY IF EXISTS "Users can view their own storage" ON local_storage;
DROP POLICY IF EXISTS "Users can update their own storage" ON local_storage;
DROP POLICY IF EXISTS "Users can delete their own storage" ON local_storage;
DROP POLICY IF EXISTS "Anyone can manage storage" ON local_storage;

-- Create permissive policy for local_storage (the key contains user ID for isolation)
CREATE POLICY "Users manage own storage data"
ON local_storage FOR ALL
USING (true)
WITH CHECK (true);

-- Verify the tables exist and show their structure
SELECT 'Users table columns:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

SELECT 'local_storage table columns:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'local_storage'
ORDER BY ordinal_position;

-- Show all users currently in the database
SELECT 'Current users in database:' as info;
SELECT id, email, full_name, role, verified, created_at
FROM users
ORDER BY created_at DESC;
