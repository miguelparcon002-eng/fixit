-- ============================================
-- FIX VOUCHER SYSTEM - ENSURE ALL TABLES ARE READY
-- ============================================
-- This migration ensures the voucher system works correctly
-- Run this in your Supabase SQL Editor

-- ============================================
-- 1. ENSURE user_redeemed_vouchers TABLE EXISTS
-- ============================================
CREATE TABLE IF NOT EXISTS user_redeemed_vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    voucher_id VARCHAR(50) NOT NULL,
    voucher_title VARCHAR(100) NOT NULL,
    voucher_description TEXT,
    points_cost INTEGER NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL,
    discount_type VARCHAR(20) NOT NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE,
    booking_id UUID,
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_redeemed_vouchers_user_id') THEN
        CREATE INDEX idx_user_redeemed_vouchers_user_id ON user_redeemed_vouchers(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_redeemed_vouchers_used') THEN
        CREATE INDEX idx_user_redeemed_vouchers_used ON user_redeemed_vouchers(user_id, is_used);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_redeemed_vouchers_booking') THEN
        CREATE INDEX idx_user_redeemed_vouchers_booking ON user_redeemed_vouchers(booking_id);
    END IF;
END $$;

-- Enable RLS
ALTER TABLE user_redeemed_vouchers ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view their own redeemed vouchers" ON user_redeemed_vouchers;
DROP POLICY IF EXISTS "Users can insert their own redeemed vouchers" ON user_redeemed_vouchers;
DROP POLICY IF EXISTS "Users can update their own redeemed vouchers" ON user_redeemed_vouchers;

-- Create RLS policies
CREATE POLICY "Users can view their own redeemed vouchers"
    ON user_redeemed_vouchers FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own redeemed vouchers"
    ON user_redeemed_vouchers FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own redeemed vouchers"
    ON user_redeemed_vouchers FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- 2. ADD FOREIGN KEY TO BOOKINGS TABLE (IF NEEDED)
-- ============================================
-- First, check if bookings table exists and add foreign key reference
DO $$
BEGIN
    -- Add foreign key constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'user_redeemed_vouchers_booking_id_fkey'
        AND table_name = 'user_redeemed_vouchers'
    ) THEN
        -- Only add if bookings table exists
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bookings') THEN
            ALTER TABLE user_redeemed_vouchers
            ADD CONSTRAINT user_redeemed_vouchers_booking_id_fkey
            FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL;
        END IF;
    END IF;
END $$;

-- ============================================
-- 3. ENSURE BOOKINGS TABLE HAS NECESSARY FIELDS
-- ============================================
-- Make sure diagnostic_notes exists in bookings table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bookings') THEN
        -- Check and add diagnostic_notes if missing
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'bookings' AND column_name = 'diagnostic_notes'
        ) THEN
            ALTER TABLE bookings ADD COLUMN diagnostic_notes TEXT;
        END IF;

        -- Check and add final_cost if missing
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'bookings' AND column_name = 'final_cost'
        ) THEN
            ALTER TABLE bookings ADD COLUMN final_cost DECIMAL(10, 2);
        END IF;

        -- Check and add estimated_cost if missing
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'bookings' AND column_name = 'estimated_cost'
        ) THEN
            ALTER TABLE bookings ADD COLUMN estimated_cost DECIMAL(10, 2);
        END IF;
    END IF;
END $$;

-- ============================================
-- 4. VERIFY USER ADDRESSES TABLE EXISTS
-- ============================================
CREATE TABLE IF NOT EXISTS user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_addresses_user_id') THEN
        CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_user_addresses_default') THEN
        CREATE INDEX idx_user_addresses_default ON user_addresses(user_id, is_default) WHERE is_default = true;
    END IF;
END $$;

-- Enable RLS
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view their own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can insert their own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can update their own addresses" ON user_addresses;
DROP POLICY IF EXISTS "Users can delete their own addresses" ON user_addresses;

-- Create RLS policies
CREATE POLICY "Users can view their own addresses"
    ON user_addresses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addresses"
    ON user_addresses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses"
    ON user_addresses FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses"
    ON user_addresses FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        UPDATE user_addresses
        SET is_default = false
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS trigger_ensure_single_default_address ON user_addresses;
CREATE TRIGGER trigger_ensure_single_default_address
    BEFORE INSERT OR UPDATE ON user_addresses
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_address();

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to verify everything is set up correctly

-- Check user_redeemed_vouchers table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_redeemed_vouchers'
ORDER BY ordinal_position;

-- Check bookings table has necessary columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'bookings' AND column_name IN ('diagnostic_notes', 'final_cost', 'estimated_cost')
ORDER BY ordinal_position;

-- Check RLS policies
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE tablename IN ('user_redeemed_vouchers', 'user_addresses')
ORDER BY tablename, policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Voucher system tables and policies have been created/updated successfully!';
END $$;
