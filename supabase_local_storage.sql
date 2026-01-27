-- Create a simple key-value storage table for demo bookings
-- This allows the app to persist data across sessions without authentication

CREATE TABLE IF NOT EXISTS local_storage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_local_storage_key ON local_storage(key);

-- Enable Row Level Security
ALTER TABLE local_storage ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read/write (for demo mode - adjust for production)
CREATE POLICY "Allow public read access" ON local_storage
    FOR SELECT USING (true);

CREATE POLICY "Allow public insert access" ON local_storage
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public update access" ON local_storage
    FOR UPDATE USING (true);

CREATE POLICY "Allow public delete access" ON local_storage
    FOR DELETE USING (true);

-- Trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_local_storage_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_local_storage_timestamp
    BEFORE UPDATE ON local_storage
    FOR EACH ROW
    EXECUTE FUNCTION update_local_storage_updated_at();
