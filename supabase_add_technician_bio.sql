ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bio text;

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

CREATE INDEX IF NOT EXISTS idx_technician_stats_technician_id ON app_technician_stats(technician_id);

ALTER TABLE app_technician_stats ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Allow all operations on technician stats" ON app_technician_stats
        FOR ALL USING (true) WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

GRANT ALL ON app_technician_stats TO anon;
GRANT ALL ON app_technician_stats TO authenticated;

CREATE TABLE IF NOT EXISTS technician_specialties (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    technician_id TEXT NOT NULL,
    specialty_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tech_specialties_tech_id ON technician_specialties(technician_id);

ALTER TABLE technician_specialties ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Allow all operations on technician specialties" ON technician_specialties
        FOR ALL USING (true) WITH CHECK (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

GRANT ALL ON technician_specialties TO anon;
GRANT ALL ON technician_specialties TO authenticated;
