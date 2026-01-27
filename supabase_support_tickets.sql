-- =====================================================
-- SUPABASE SCHEMA FOR SUPPORT TICKETS SYSTEM
-- Run this in your Supabase SQL Editor
-- =====================================================

-- 1. Create support_tickets table
CREATE TABLE IF NOT EXISTS support_tickets (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    customer_phone TEXT,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('booking_issue', 'payment_issue', 'technician_complaint', 'app_bug', 'other')),
    priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    booking_id TEXT,
    technician_id TEXT,
    assigned_admin_id TEXT,
    attachments TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- 2. Create ticket_messages table for conversation threads
CREATE TABLE IF NOT EXISTS ticket_messages (
    id TEXT PRIMARY KEY,
    ticket_id TEXT NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL CHECK (sender_role IN ('customer', 'admin')),
    message TEXT NOT NULL,
    attachments TEXT[] DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_support_tickets_customer_id ON support_tickets(customer_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_priority ON support_tickets(priority);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category ON support_tickets(category);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket_id ON ticket_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_messages_created_at ON ticket_messages(created_at);

-- 4. Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_support_ticket_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS trigger_update_support_ticket_updated_at ON support_tickets;
CREATE TRIGGER trigger_update_support_ticket_updated_at
    BEFORE UPDATE ON support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_support_ticket_updated_at();

-- 6. Enable Row Level Security (RLS)
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies for support_tickets (Simple policies for all authenticated users)

-- Allow all authenticated users to read tickets
CREATE POLICY "Allow read tickets"
    ON support_tickets FOR SELECT
    TO authenticated
    USING (true);

-- Allow all authenticated users to insert tickets
CREATE POLICY "Allow insert tickets"
    ON support_tickets FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow all authenticated users to update tickets
CREATE POLICY "Allow update tickets"
    ON support_tickets FOR UPDATE
    TO authenticated
    USING (true);

-- Allow all authenticated users to delete tickets
CREATE POLICY "Allow delete tickets"
    ON support_tickets FOR DELETE
    TO authenticated
    USING (true);

-- 8. RLS Policies for ticket_messages

-- Allow all authenticated users to read messages
CREATE POLICY "Allow read messages"
    ON ticket_messages FOR SELECT
    TO authenticated
    USING (true);

-- Allow all authenticated users to insert messages
CREATE POLICY "Allow insert messages"
    ON ticket_messages FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow all authenticated users to update messages
CREATE POLICY "Allow update messages"
    ON ticket_messages FOR UPDATE
    TO authenticated
    USING (true);

-- Allow all authenticated users to delete messages
CREATE POLICY "Allow delete messages"
    ON ticket_messages FOR DELETE
    TO authenticated
    USING (true);

-- =====================================================
-- REALTIME SUBSCRIPTION (Optional)
-- =====================================================

-- Enable realtime for support_tickets table (uncomment if needed)
-- ALTER PUBLICATION supabase_realtime ADD TABLE support_tickets;

-- Enable realtime for ticket_messages table (uncomment if needed)
-- ALTER PUBLICATION supabase_realtime ADD TABLE ticket_messages;
