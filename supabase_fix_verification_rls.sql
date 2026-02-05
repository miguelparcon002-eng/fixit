-- Fix RLS policies for verification_requests table
-- This allows technicians to insert verification requests

-- ==============================================================================
-- Enable RLS on verification_requests table
-- ==============================================================================
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- Drop existing policies (if any)
-- ==============================================================================
DROP POLICY IF EXISTS "Technicians can insert verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Technicians can view their own verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Admins can view all verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Admins can update verification requests" ON verification_requests;

-- ==============================================================================
-- Create new RLS policies
-- ==============================================================================

-- 1. Technicians can INSERT their own verification requests
CREATE POLICY "Technicians can insert verification requests"
ON verification_requests
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid() 
  AND 
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'technician'
  )
);

-- 2. Technicians can SELECT (view) their own verification requests
CREATE POLICY "Technicians can view their own verification requests"
ON verification_requests
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- 3. Admins can SELECT (view) all verification requests
CREATE POLICY "Admins can view all verification requests"
ON verification_requests
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- 4. Admins can UPDATE verification requests (approve/reject)
CREATE POLICY "Admins can update verification requests"
ON verification_requests
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'admin'
  )
);

-- 5. Technicians can UPDATE their own verification requests (for resubmission)
CREATE POLICY "Technicians can update their own verification requests"
ON verification_requests
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
  AND
  status IN ('rejected', 'resubmit')
);

-- ==============================================================================
-- Fix storage bucket policies for document uploads
-- ==============================================================================

-- Allow authenticated users to upload to documents bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies
DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all documents" ON storage.objects;

-- Create storage policies
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  )
);

CREATE POLICY "Users can update their own documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
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
    qual
FROM pg_policies
WHERE tablename = 'verification_requests';

-- ==============================================================================
-- Test queries (run these to verify)
-- ==============================================================================
-- Check if verification_requests table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'verification_requests';

-- Check RLS is enabled
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE relname = 'verification_requests';

-- ==============================================================================
SELECT 'RLS policies fixed successfully!' as status;
-- ==============================================================================
