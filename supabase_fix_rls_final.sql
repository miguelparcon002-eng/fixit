-- FIXIT - Final RLS Fix for User Authentication
-- Run this in your Supabase SQL Editor

-- Check current RLS status
SELECT 'RLS Status for users table:' as info;
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname = 'users';

-- List current policies on users table
SELECT 'Current policies on users table:' as info;
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'users';

-- Drop ALL existing policies on users table to start fresh
DROP POLICY IF EXISTS "Users can insert their own profile on signup" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Anyone can view verified technicians" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update any user" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Public can view verified technicians" ON users;
DROP POLICY IF EXISTS "Admins view all users" ON users;
DROP POLICY IF EXISTS "Admins update all users" ON users;
DROP POLICY IF EXISTS "Admins delete users" ON users;
DROP POLICY IF EXISTS "Enable read access for users" ON users;
DROP POLICY IF EXISTS "Enable insert for users" ON users;
DROP POLICY IF EXISTS "Enable update for users" ON users;

-- Create simple, working policies

-- 1. Users can SELECT their own profile (most important for login!)
CREATE POLICY "users_select_own"
ON users FOR SELECT
USING (auth.uid() = id);

-- 2. Users can INSERT their own profile during signup
CREATE POLICY "users_insert_own"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- 3. Users can UPDATE their own profile
CREATE POLICY "users_update_own"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Allow viewing verified technicians (for customer browsing)
CREATE POLICY "users_view_technicians"
ON users FOR SELECT
USING (role = 'technician' AND verified = true);

-- 5. Admins can do everything (using SECURITY DEFINER function to avoid recursion)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY "admins_select_all"
ON users FOR SELECT
USING (public.is_admin());

CREATE POLICY "admins_update_all"
ON users FOR UPDATE
USING (public.is_admin());

CREATE POLICY "admins_delete_all"
ON users FOR DELETE
USING (public.is_admin());

-- Verify the new policies
SELECT 'New policies on users table:' as info;
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'users';

-- Test: Show all users that the current session can see
SELECT 'Test - All visible users:' as info;
SELECT id, email, full_name, role, verified
FROM users
ORDER BY created_at DESC;
