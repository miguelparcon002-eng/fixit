-- Supabase SQL for Technician Stats Table
-- Run this in the Supabase SQL Editor

-- Create the technician stats table
CREATE TABLE IF NOT EXISTS app_technician_stats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    technician_id TEXT NOT NULL UNIQUE,
    average_rating DOUBLE PRECISION DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,
    completed_jobs INTEGER DEFAULT 0,
    total_earnings DOUBLE PRECISION DEFAULT 0.0,
    experience TEXT DEFAULT 'New',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_technician_stats_technician_id ON app_technician_stats(technician_id);

-- Enable Row Level Security (RLS)
ALTER TABLE app_technician_stats ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (adjust as needed for your security requirements)
CREATE POLICY "Allow all operations on technician stats" ON app_technician_stats
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Grant permissions
GRANT ALL ON app_technician_stats TO anon;
GRANT ALL ON app_technician_stats TO authenticated;
