-- Fix Row Level Security (RLS) for services table
-- This allows the app to create and read services

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow read access to services" ON public.services;
DROP POLICY IF EXISTS "Allow technicians to manage their services" ON public.services;
DROP POLICY IF EXISTS "Allow insert for authenticated users" ON public.services;
DROP POLICY IF EXISTS "Allow all operations on services" ON public.services;

-- Enable RLS on services table
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow everyone to read services (needed for booking)
CREATE POLICY "Allow read access to services"
ON public.services FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Allow technicians to insert their own services
CREATE POLICY "Allow technicians to insert services"
ON public.services FOR INSERT
TO authenticated
WITH CHECK (
  technician_id IN (
    SELECT id FROM public.users 
    WHERE id = auth.uid() 
    AND role = 'technician'
  )
);

-- Policy 3: Allow technicians to update their own services
CREATE POLICY "Allow technicians to update services"
ON public.services FOR UPDATE
TO authenticated
USING (technician_id = auth.uid())
WITH CHECK (technician_id = auth.uid());

-- Policy 4: Allow technicians to delete their own services
CREATE POLICY "Allow technicians to delete services"
ON public.services FOR DELETE
TO authenticated
USING (technician_id = auth.uid());

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'services';

-- Check if service already exists for Ethan
SELECT id, service_name, technician_id, is_active
FROM public.services
WHERE technician_id = '04a72f58-1e79-404b-87c8-3698bd57a5a8';
