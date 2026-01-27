-- ============================================
-- FIXIT APP DATA STORAGE - Complete Schema
-- This creates tables for ALL app data persistence
-- ============================================

-- 1. RATINGS & REVIEWS STORAGE
-- Store customer ratings and reviews of technicians
CREATE TABLE IF NOT EXISTS app_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    device TEXT NOT NULL,
    service TEXT NOT NULL,
    date TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_ratings_technician ON app_ratings(technician);
CREATE INDEX IF NOT EXISTS idx_app_ratings_date ON app_ratings(date);

-- 2. EARNINGS STORAGE
-- Store technician earnings records
CREATE TABLE IF NOT EXISTS app_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_name TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    customer_name TEXT NOT NULL,
    service TEXT NOT NULL,
    job_id TEXT NOT NULL,
    date TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_earnings_technician ON app_earnings(technician_name);
CREATE INDEX IF NOT EXISTS idx_app_earnings_date ON app_earnings(date);
CREATE INDEX IF NOT EXISTS idx_app_earnings_job_id ON app_earnings(job_id);

-- 3. USER PROFILES STORAGE
-- Store user profile information (address, name, phone, picture, etc.)
CREATE TABLE IF NOT EXISTS app_user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT UNIQUE NOT NULL, -- For demo: email or unique identifier
    full_name TEXT NOT NULL,
    email TEXT,
    phone_number TEXT,
    profile_picture_url TEXT,
    address TEXT,
    city TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'Philippines',
    user_type TEXT CHECK (user_type IN ('customer', 'technician', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_user_profiles_user_id ON app_user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_app_user_profiles_email ON app_user_profiles(email);

-- 4. PROMO CODES STORAGE
-- Store active promo codes
CREATE TABLE IF NOT EXISTS app_promo_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_amount NUMERIC(10, 2) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    expiry_date TEXT,
    usage_count INTEGER DEFAULT 0,
    max_usage INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_promo_codes_code ON app_promo_codes(code);
CREATE INDEX IF NOT EXISTS idx_app_promo_codes_active ON app_promo_codes(is_active);

-- 5. APP SETTINGS STORAGE
-- Store app configuration and settings
CREATE TABLE IF NOT EXISTS app_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    setting_key TEXT NOT NULL,
    setting_value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, setting_key)
);

CREATE INDEX IF NOT EXISTS idx_app_settings_user_id ON app_settings(user_id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

ALTER TABLE app_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Allow public access for demo mode (adjust for production with auth)
CREATE POLICY "Allow public read ratings" ON app_ratings FOR SELECT USING (true);
CREATE POLICY "Allow public insert ratings" ON app_ratings FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update ratings" ON app_ratings FOR UPDATE USING (true);
CREATE POLICY "Allow public delete ratings" ON app_ratings FOR DELETE USING (true);

CREATE POLICY "Allow public read earnings" ON app_earnings FOR SELECT USING (true);
CREATE POLICY "Allow public insert earnings" ON app_earnings FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update earnings" ON app_earnings FOR UPDATE USING (true);
CREATE POLICY "Allow public delete earnings" ON app_earnings FOR DELETE USING (true);

CREATE POLICY "Allow public read profiles" ON app_user_profiles FOR SELECT USING (true);
CREATE POLICY "Allow public insert profiles" ON app_user_profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update profiles" ON app_user_profiles FOR UPDATE USING (true);
CREATE POLICY "Allow public delete profiles" ON app_user_profiles FOR DELETE USING (true);

CREATE POLICY "Allow public read promo codes" ON app_promo_codes FOR SELECT USING (true);
CREATE POLICY "Allow public insert promo codes" ON app_promo_codes FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update promo codes" ON app_promo_codes FOR UPDATE USING (true);
CREATE POLICY "Allow public delete promo codes" ON app_promo_codes FOR DELETE USING (true);

CREATE POLICY "Allow public read settings" ON app_settings FOR SELECT USING (true);
CREATE POLICY "Allow public insert settings" ON app_settings FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update settings" ON app_settings FOR UPDATE USING (true);
CREATE POLICY "Allow public delete settings" ON app_settings FOR DELETE USING (true);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

CREATE OR REPLACE FUNCTION update_app_data_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_app_ratings_timestamp
    BEFORE UPDATE ON app_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_app_data_updated_at();

CREATE TRIGGER update_app_earnings_timestamp
    BEFORE UPDATE ON app_earnings
    FOR EACH ROW
    EXECUTE FUNCTION update_app_data_updated_at();

CREATE TRIGGER update_app_user_profiles_timestamp
    BEFORE UPDATE ON app_user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_app_data_updated_at();

CREATE TRIGGER update_app_promo_codes_timestamp
    BEFORE UPDATE ON app_promo_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_app_data_updated_at();

CREATE TRIGGER update_app_settings_timestamp
    BEFORE UPDATE ON app_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_app_data_updated_at();

-- ============================================
-- SEED DATA (Optional - Sample Promo Codes)
-- ============================================

INSERT INTO app_promo_codes (code, discount_type, discount_amount, description, is_active, max_usage)
VALUES
    ('WELCOME10', 'percentage', 10, 'Welcome discount - 10% off', true, 100),
    ('SAVE500', 'fixed', 500, 'Save ₱500 on any repair', true, 50),
    ('FIRSTTIME', 'percentage', 15, 'First time customer - 15% off', true, NULL)
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'App data storage tables created successfully!';
    RAISE NOTICE 'Tables: app_ratings, app_earnings, app_user_profiles, app_promo_codes, app_settings';
END $$;
