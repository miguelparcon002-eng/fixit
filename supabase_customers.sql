-- =====================================================
-- FIXIT APP - CUSTOMERS MANAGEMENT SCHEMA
-- =====================================================
-- This SQL file creates the necessary tables and policies
-- for storing customer data in Supabase.
-- Run this in your Supabase SQL Editor.
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- CUSTOMERS TABLE
-- =====================================================
-- Stores all customer information including activity status

CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    profile_image_url TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE,
    total_bookings INTEGER NOT NULL DEFAULT 0,
    completed_bookings INTEGER NOT NULL DEFAULT 0,
    cancelled_bookings INTEGER NOT NULL DEFAULT 0,
    total_spent DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    addresses JSONB DEFAULT '[]'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_last_active ON customers(last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers(created_at DESC);

-- =====================================================
-- CUSTOMER BOOKING HISTORY TABLE
-- =====================================================
-- Stores booking history for each customer

CREATE TABLE IF NOT EXISTS customer_booking_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id TEXT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    booking_id TEXT NOT NULL,
    service_name TEXT NOT NULL,
    technician_name TEXT NOT NULL,
    booking_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_booking_history_customer ON customer_booking_history(customer_id);
CREATE INDEX IF NOT EXISTS idx_booking_history_date ON customer_booking_history(booking_date DESC);
CREATE INDEX IF NOT EXISTS idx_booking_history_status ON customer_booking_history(status);

-- =====================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION update_customers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS trigger_customers_updated_at ON customers;
CREATE TRIGGER trigger_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_updated_at();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on customers table
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Enable RLS on customer_booking_history table
ALTER TABLE customer_booking_history ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all customers (for admin)
CREATE POLICY "Allow read customers"
    ON customers FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow authenticated users to insert customers
CREATE POLICY "Allow insert customers"
    ON customers FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy: Allow authenticated users to update customers
CREATE POLICY "Allow update customers"
    ON customers FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Policy: Allow authenticated users to delete customers
CREATE POLICY "Allow delete customers"
    ON customers FOR DELETE
    TO authenticated
    USING (true);

-- Policy: Allow authenticated users to read booking history
CREATE POLICY "Allow read booking history"
    ON customer_booking_history FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow authenticated users to insert booking history
CREATE POLICY "Allow insert booking history"
    ON customer_booking_history FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Policy: Allow authenticated users to update booking history
CREATE POLICY "Allow update booking history"
    ON customer_booking_history FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Policy: Allow authenticated users to delete booking history
CREATE POLICY "Allow delete booking history"
    ON customer_booking_history FOR DELETE
    TO authenticated
    USING (true);

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to update customer stats after a booking is added
CREATE OR REPLACE FUNCTION update_customer_booking_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE customers
    SET
        total_bookings = total_bookings + 1,
        completed_bookings = CASE WHEN NEW.status = 'completed' THEN completed_bookings + 1 ELSE completed_bookings END,
        cancelled_bookings = CASE WHEN NEW.status = 'cancelled' THEN cancelled_bookings + 1 ELSE cancelled_bookings END,
        total_spent = CASE WHEN NEW.status = 'completed' THEN total_spent + NEW.amount ELSE total_spent END,
        last_active_at = NOW()
    WHERE id = NEW.customer_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update customer stats
DROP TRIGGER IF EXISTS trigger_update_customer_stats ON customer_booking_history;
CREATE TRIGGER trigger_update_customer_stats
    AFTER INSERT ON customer_booking_history
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_booking_stats();

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================
-- Uncomment and run if you want to add sample customers

/*
INSERT INTO customers (id, name, email, phone, status, created_at, last_active_at, total_bookings, completed_bookings, cancelled_bookings, total_spent, addresses)
VALUES
    ('cust_001', 'John Smith', 'john.smith@email.com', '+1234567890', 'active', NOW() - INTERVAL '30 days', NOW() - INTERVAL '1 day', 5, 4, 1, 450.00, '["123 Main St, City, State 12345"]'),
    ('cust_002', 'Maria Garcia', 'maria.garcia@email.com', '+1234567891', 'active', NOW() - INTERVAL '60 days', NOW() - INTERVAL '3 days', 8, 7, 1, 720.50, '["456 Oak Ave, Town, State 67890"]'),
    ('cust_003', 'David Lee', 'david.lee@email.com', '+1234567892', 'inactive', NOW() - INTERVAL '90 days', NOW() - INTERVAL '45 days', 2, 2, 0, 180.00, '[]'),
    ('cust_004', 'Sarah Johnson', 'sarah.j@email.com', '+1234567893', 'active', NOW() - INTERVAL '15 days', NOW(), 3, 2, 1, 290.00, '["789 Pine Rd, Village, State 11111", "321 Elm St, City, State 22222"]'),
    ('cust_005', 'Michael Brown', 'michael.b@email.com', NULL, 'suspended', NOW() - INTERVAL '120 days', NOW() - INTERVAL '100 days', 1, 0, 1, 0.00, '[]');

-- Sample booking history
INSERT INTO customer_booking_history (customer_id, booking_id, service_name, technician_name, booking_date, status, amount)
VALUES
    ('cust_001', 'BK001', 'Phone Screen Repair', 'Alex Tech', NOW() - INTERVAL '25 days', 'completed', 89.99),
    ('cust_001', 'BK002', 'Battery Replacement', 'Alex Tech', NOW() - INTERVAL '15 days', 'completed', 59.99),
    ('cust_001', 'BK003', 'Software Update', 'Jane Fix', NOW() - INTERVAL '5 days', 'completed', 39.99),
    ('cust_002', 'BK004', 'Laptop Repair', 'Bob Repair', NOW() - INTERVAL '10 days', 'completed', 149.99),
    ('cust_002', 'BK005', 'Data Recovery', 'Jane Fix', NOW() - INTERVAL '3 days', 'in_progress', 199.99);
*/

-- =====================================================
-- NOTES
-- =====================================================
--
-- The app also uses the local_storage table for JSON-based storage.
-- Make sure you have the local_storage table created:
--
-- CREATE TABLE IF NOT EXISTS local_storage (
--     key TEXT PRIMARY KEY,
--     value TEXT,
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );
--
-- The customer provider stores data in local_storage with key 'customers_data'
-- and booking history with keys 'booking_history_{customer_id}'
-- =====================================================
