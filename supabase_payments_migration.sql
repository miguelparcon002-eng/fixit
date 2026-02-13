CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    reference_number TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    proof_image_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending_verification',
    payment_method TEXT DEFAULT 'gcash',
    admin_note TEXT,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can view their own payments"
    ON payments FOR SELECT
    USING (auth.uid()::text = customer_id);

CREATE POLICY "Customers can insert their own payments"
    ON payments FOR INSERT
    WITH CHECK (auth.uid()::text = customer_id);

CREATE POLICY "Admins can view all payments"
    ON payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users WHERE id::text = auth.uid()::text AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update payments"
    ON payments FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users WHERE id::text = auth.uid()::text AND role = 'admin'
        )
    );

GRANT ALL ON payments TO authenticated;

CREATE TABLE IF NOT EXISTS app_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    setting_key TEXT NOT NULL UNIQUE,
    setting_value JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read app_settings"
    ON app_settings FOR SELECT
    USING (true);

CREATE POLICY "Admins can manage app_settings"
    ON app_settings FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users WHERE id::text = auth.uid()::text AND role = 'admin'
        )
    );

GRANT ALL ON app_settings TO authenticated;

INSERT INTO storage.buckets (id, name, public)
VALUES ('payments', 'payments', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Authenticated users can upload payment files"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'payments' AND auth.role() = 'authenticated');

CREATE POLICY "Anyone can view payment files"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'payments');

CREATE POLICY "Admins can delete payment files"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'payments' AND
        EXISTS (
            SELECT 1 FROM users WHERE id::text = auth.uid()::text AND role = 'admin'
        )
    );
