-- ============================================
-- User Feedback & Bug Reports Table
-- Run this in Supabase SQL Editor
-- ============================================

-- Create the user_feedback table
CREATE TABLE IF NOT EXISTS public.user_feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL DEFAULT 'Unknown',
  type TEXT NOT NULL CHECK (type IN ('feedback', 'bug_report')),
  message TEXT NOT NULL,
  rating INTEGER CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5)),
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'reviewed', 'resolved')),
  admin_note TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;

-- Policy: Authenticated users can insert their own feedback
CREATE POLICY "Users can submit feedback"
  ON public.user_feedback
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid()::text = user_id);

-- Policy: Authenticated users can view their own feedback
CREATE POLICY "Users can view their own feedback"
  ON public.user_feedback
  FOR SELECT
  TO authenticated
  USING (auth.uid()::text = user_id);

-- Policy: Admin can view all feedback
-- (Assumes admin role check - adjust if your admin detection is different)
CREATE POLICY "Admin can view all feedback"
  ON public.user_feedback
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id::text = auth.uid()::text AND role = 'admin'
    )
  );

-- Policy: Admin can update feedback (mark reviewed/resolved)
CREATE POLICY "Admin can update feedback"
  ON public.user_feedback
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id::text = auth.uid()::text AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id::text = auth.uid()::text AND role = 'admin'
    )
  );

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_feedback_type ON public.user_feedback(type);
CREATE INDEX IF NOT EXISTS idx_user_feedback_status ON public.user_feedback(status);
CREATE INDEX IF NOT EXISTS idx_user_feedback_created_at ON public.user_feedback(created_at DESC);
