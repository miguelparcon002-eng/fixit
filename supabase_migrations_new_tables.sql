-- ============================================
-- SUPABASE MIGRATIONS FOR LOCAL STORAGE DATA
-- ============================================
-- This file creates tables for data currently stored in local storage
-- Run this in your Supabase SQL Editor

-- ============================================
-- 1. USER ADDRESSES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL, -- e.g., "Home", "Work", "Mom's Place"
    address TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX idx_user_addresses_default ON user_addresses(user_id, is_default) WHERE is_default = true;

-- Enable Row Level Security
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_addresses
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
-- 2. USER REDEEMED VOUCHERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_redeemed_vouchers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    voucher_id VARCHAR(50) NOT NULL, -- e.g., "v1", "v2", "v3"
    voucher_title VARCHAR(100) NOT NULL,
    voucher_description TEXT,
    points_cost INTEGER NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL,
    discount_type VARCHAR(20) NOT NULL, -- 'fixed' or 'percentage'
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE, -- When the voucher was actually used in a booking
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL, -- Optional: link to booking where used
    is_used BOOLEAN DEFAULT false,
    expires_at TIMESTAMP WITH TIME ZONE, -- Optional: expiration date
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_user_redeemed_vouchers_user_id ON user_redeemed_vouchers(user_id);
CREATE INDEX idx_user_redeemed_vouchers_used ON user_redeemed_vouchers(user_id, is_used);
CREATE INDEX idx_user_redeemed_vouchers_booking ON user_redeemed_vouchers(booking_id);

-- Enable Row Level Security
ALTER TABLE user_redeemed_vouchers ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_redeemed_vouchers
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
-- 3. TECHNICIAN SPECIALTIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS technician_specialties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technician_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    specialty_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index and unique constraint
CREATE INDEX idx_technician_specialties_technician_id ON technician_specialties(technician_id);
CREATE UNIQUE INDEX idx_technician_specialties_unique ON technician_specialties(technician_id, specialty_name);

-- Enable Row Level Security
ALTER TABLE technician_specialties ENABLE ROW LEVEL SECURITY;

-- RLS Policies for technician_specialties
CREATE POLICY "Anyone can view technician specialties"
    ON technician_specialties FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Technicians can manage their own specialties"
    ON technician_specialties FOR ALL
    USING (auth.uid() = technician_id);

-- ============================================
-- 4. ADD COLUMNS TO EXISTING TABLES
-- ============================================

-- Add profile_setup_complete to users table (if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'profile_setup_complete'
    ) THEN
        ALTER TABLE users ADD COLUMN profile_setup_complete BOOLEAN DEFAULT false;
    END IF;
END $$;

-- Add profile_image_url to users table (if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'profile_image_url'
    ) THEN
        ALTER TABLE users ADD COLUMN profile_image_url TEXT;
    END IF;
END $$;

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        -- Set all other addresses for this user to not default
        UPDATE user_addresses
        SET is_default = false
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for default address
DROP TRIGGER IF EXISTS trigger_ensure_single_default_address ON user_addresses;
CREATE TRIGGER trigger_ensure_single_default_address
    BEFORE INSERT OR UPDATE ON user_addresses
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_address();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_addresses updated_at
DROP TRIGGER IF EXISTS trigger_user_addresses_updated_at ON user_addresses;
CREATE TRIGGER trigger_user_addresses_updated_at
    BEFORE UPDATE ON user_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. GRANT PERMISSIONS
-- ============================================

-- Grant necessary permissions
GRANT ALL ON user_addresses TO authenticated;
GRANT ALL ON user_redeemed_vouchers TO authenticated;
GRANT ALL ON technician_specialties TO authenticated;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
-- After running this migration:
-- 1. Update Flutter code to use these new tables
-- 2. Migrate existing local storage data to Supabase
-- 3. Remove old local storage code
-- ============================================
