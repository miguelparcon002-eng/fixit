-- =====================================================
-- RATINGS SYSTEM FOR FIXIT APP
-- =====================================================
-- This SQL script sets up/updates the ratings tables for technicians
-- Run this in Supabase SQL Editor
--
-- IMPORTANT: Your existing app_technician_stats table uses TEXT for technician_id
-- This script is designed to work with that existing schema

-- =====================================================
-- 1. CHECK AND UPDATE APP_RATINGS TABLE
-- =====================================================

-- First, check if app_ratings table exists and add missing columns
-- NOTE: Using TEXT for technician_id to match existing app_technician_stats table
DO $$
BEGIN
    -- Add technician_id column if it doesn't exist (as TEXT to match app_technician_stats)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'app_ratings' AND column_name = 'technician_id'
    ) THEN
        ALTER TABLE app_ratings ADD COLUMN technician_id TEXT;
        RAISE NOTICE 'Added technician_id column to app_ratings';
    END IF;

    -- Add customer_id column if it doesn't exist (as TEXT for consistency)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'app_ratings' AND column_name = 'customer_id'
    ) THEN
        ALTER TABLE app_ratings ADD COLUMN customer_id TEXT;
        RAISE NOTICE 'Added customer_id column to app_ratings';
    END IF;

    -- Add booking_id column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'app_ratings' AND column_name = 'booking_id'
    ) THEN
        ALTER TABLE app_ratings ADD COLUMN booking_id TEXT;
        RAISE NOTICE 'Added booking_id column to app_ratings';
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'app_ratings' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE app_ratings ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to app_ratings';
    END IF;
END $$;

-- Add indexes (will skip if they already exist)
CREATE INDEX IF NOT EXISTS idx_app_ratings_technician ON app_ratings(technician);
CREATE INDEX IF NOT EXISTS idx_app_ratings_technician_id ON app_ratings(technician_id);
CREATE INDEX IF NOT EXISTS idx_app_ratings_customer_id ON app_ratings(customer_id);
CREATE INDEX IF NOT EXISTS idx_app_ratings_created_at ON app_ratings(created_at DESC);

-- Enable RLS (safe to run multiple times)
ALTER TABLE app_ratings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Anyone can read ratings" ON app_ratings;
DROP POLICY IF EXISTS "Authenticated users can insert ratings" ON app_ratings;
DROP POLICY IF EXISTS "Users can update own ratings" ON app_ratings;
DROP POLICY IF EXISTS "Users can delete own ratings" ON app_ratings;

-- Create policies for app_ratings
-- NOTE: customer_id is TEXT, so we cast auth.uid() to TEXT
CREATE POLICY "Anyone can read ratings" ON app_ratings
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert ratings" ON app_ratings
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own ratings" ON app_ratings
    FOR UPDATE USING (customer_id = auth.uid()::text);

CREATE POLICY "Users can delete own ratings" ON app_ratings
    FOR DELETE USING (customer_id = auth.uid()::text);


-- =====================================================
-- 2. APP_TECHNICIAN_STATS TABLE - Already exists with TEXT technician_id
-- =====================================================
-- Your existing table already has technician_id as TEXT, so we just ensure RLS is set up

-- Enable RLS
ALTER TABLE app_technician_stats ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
DROP POLICY IF EXISTS "Anyone can read technician stats" ON app_technician_stats;
DROP POLICY IF EXISTS "Technicians can update own stats" ON app_technician_stats;
DROP POLICY IF EXISTS "Authenticated can insert stats" ON app_technician_stats;

-- Create policies for app_technician_stats
-- NOTE: technician_id is TEXT, so we cast auth.uid() to TEXT
CREATE POLICY "Anyone can read technician stats" ON app_technician_stats
    FOR SELECT USING (true);

CREATE POLICY "Technicians can update own stats" ON app_technician_stats
    FOR UPDATE USING (technician_id = auth.uid()::text);

CREATE POLICY "Authenticated can insert stats" ON app_technician_stats
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);


-- =====================================================
-- 3. FUNCTION: Calculate average rating for a technician
-- =====================================================
-- Using TEXT parameter to match the technician_id column type
CREATE OR REPLACE FUNCTION get_technician_average_rating(tech_id TEXT)
RETURNS TABLE(avg_rating DECIMAL, total_reviews BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(AVG(r.rating)::DECIMAL(3,2), 0.0) as avg_rating,
        COUNT(*) as total_reviews
    FROM app_ratings r
    WHERE r.technician_id = tech_id;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- 4. FUNCTION: Get technician stats by name (for existing data)
-- =====================================================
CREATE OR REPLACE FUNCTION get_technician_rating_by_name(tech_name TEXT)
RETURNS TABLE(avg_rating DECIMAL, total_reviews BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(AVG(r.rating)::DECIMAL(3,2), 0.0) as avg_rating,
        COUNT(*) as total_reviews
    FROM app_ratings r
    WHERE LOWER(r.technician) = LOWER(tech_name)
       OR LOWER(tech_name) LIKE '%' || LOWER(r.technician) || '%';
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- 5. FUNCTION: Get technician stats summary
-- =====================================================
-- Using TEXT parameter to match existing column types
CREATE OR REPLACE FUNCTION get_technician_stats(tech_id TEXT)
RETURNS TABLE(
    avg_rating DECIMAL,
    total_reviews BIGINT,
    completed_jobs BIGINT,
    total_earnings DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE((SELECT AVG(r.rating)::DECIMAL(3,2) FROM app_ratings r WHERE r.technician_id = tech_id), 0.0) as avg_rating,
        COALESCE((SELECT COUNT(*) FROM app_ratings r WHERE r.technician_id = tech_id), 0) as total_reviews,
        COALESCE((SELECT COUNT(*) FROM bookings b WHERE b.technician_id::text = tech_id AND b.status = 'completed'), 0) as completed_jobs,
        COALESCE((SELECT SUM(COALESCE(b.final_cost, b.estimated_cost, 0)) FROM bookings b WHERE b.technician_id::text = tech_id AND b.status = 'completed'), 0.0) as total_earnings;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- 6. TRIGGER: Auto-update technician stats on new rating
-- =====================================================
-- NOTE: technician_id is TEXT in both app_ratings and app_technician_stats
CREATE OR REPLACE FUNCTION update_technician_stats_on_rating()
RETURNS TRIGGER AS $$
DECLARE
    new_avg DOUBLE PRECISION;
    new_count INTEGER;
BEGIN
    -- Only proceed if technician_id is set
    IF NEW.technician_id IS NOT NULL AND NEW.technician_id != '' THEN
        -- Calculate new average rating
        SELECT
            COALESCE(AVG(rating)::DOUBLE PRECISION, 0.0),
            COUNT(*)::INTEGER
        INTO new_avg, new_count
        FROM app_ratings
        WHERE technician_id = NEW.technician_id;

        -- Upsert technician stats (technician_id is TEXT)
        INSERT INTO app_technician_stats (technician_id, average_rating, total_reviews, updated_at)
        VALUES (NEW.technician_id, new_avg, new_count, NOW())
        ON CONFLICT (technician_id)
        DO UPDATE SET
            average_rating = new_avg,
            total_reviews = new_count,
            updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (drop first to avoid duplicates)
DROP TRIGGER IF EXISTS trigger_update_stats_on_rating ON app_ratings;
CREATE TRIGGER trigger_update_stats_on_rating
    AFTER INSERT OR UPDATE ON app_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_technician_stats_on_rating();


-- =====================================================
-- 7. UPDATE EXISTING RATINGS WITH TECHNICIAN_ID
-- =====================================================
-- This updates existing ratings to link them with technician user IDs
-- based on matching the technician name
-- NOTE: technician_id is stored as TEXT (UUID cast to text)

DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    -- First, try exact match on full name (cast UUID to TEXT)
    UPDATE app_ratings r
    SET technician_id = u.id::text
    FROM auth.users u
    WHERE (r.technician_id IS NULL OR r.technician_id = '')
      AND LOWER(COALESCE(u.raw_user_meta_data->>'full_name', '')) = LOWER(r.technician)
      AND COALESCE(u.raw_user_meta_data->>'role', '') = 'technician';

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % ratings with exact name match', updated_count;

    -- Then, try partial match (technician name contains rating's technician field)
    UPDATE app_ratings r
    SET technician_id = u.id::text
    FROM auth.users u
    WHERE (r.technician_id IS NULL OR r.technician_id = '')
      AND LOWER(COALESCE(u.raw_user_meta_data->>'full_name', '')) LIKE '%' || LOWER(r.technician) || '%'
      AND COALESCE(u.raw_user_meta_data->>'role', '') = 'technician';

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % ratings with partial name match', updated_count;
END $$;


-- =====================================================
-- 8. VIEW: Technician Leaderboard
-- =====================================================
-- NOTE: app_technician_stats.technician_id is TEXT, so we cast auth.users.id to TEXT
DROP VIEW IF EXISTS technician_leaderboard;
CREATE VIEW technician_leaderboard AS
SELECT
    u.id::text as technician_id,
    COALESCE(u.raw_user_meta_data->>'full_name', 'Unknown') as technician_name,
    COALESCE(s.average_rating, 0.0) as average_rating,
    COALESCE(s.total_reviews, 0) as total_reviews,
    COALESCE(s.completed_jobs, 0) as completed_jobs,
    COALESCE(s.total_earnings, 0.0) as total_earnings,
    COALESCE(s.experience, 'New') as experience
FROM auth.users u
LEFT JOIN app_technician_stats s ON u.id::text = s.technician_id
WHERE COALESCE(u.raw_user_meta_data->>'role', '') = 'technician'
ORDER BY s.average_rating DESC NULLS LAST, s.completed_jobs DESC NULLS LAST;


-- =====================================================
-- 9. VERIFY THE SETUP
-- =====================================================
-- Check the app_ratings table structure
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'app_ratings'
ORDER BY ordinal_position;

-- Show current ratings count
SELECT COUNT(*) as total_ratings FROM app_ratings;

-- Show ratings with technician_id populated
SELECT COUNT(*) as ratings_with_tech_id FROM app_ratings WHERE technician_id IS NOT NULL AND technician_id != '';


-- =====================================================
-- DONE! Your ratings system is now set up.
-- =====================================================
--
-- Tables updated/created:
--   - app_ratings: Added technician_id, customer_id, booking_id columns (all TEXT)
--   - app_technician_stats: Using existing table with TEXT technician_id
--
-- Functions created:
--   - get_technician_average_rating(tech_id TEXT): Get avg rating by ID
--   - get_technician_rating_by_name(tech_name TEXT): Get avg rating by name
--   - get_technician_stats(tech_id TEXT): Get full stats summary
--
-- Triggers:
--   - Auto-updates technician stats when a new rating is added
--
-- To query a technician's rating from Flutter:
--   final response = await supabase
--       .from('app_ratings')
--       .select()
--       .eq('technician_id', technicianId);
--
-- Or use the function:
--   final response = await supabase
--       .rpc('get_technician_average_rating', params: {'tech_id': technicianId});
-- =====================================================
