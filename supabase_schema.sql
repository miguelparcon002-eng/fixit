-- FIXIT Database Schema for Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('customer', 'technician', 'admin')),
    verified BOOLEAN DEFAULT FALSE,
    contact_number TEXT,
    address TEXT,
    profile_picture TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    city TEXT,
    neighborhood TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Technician Profiles table
CREATE TABLE technician_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    specialties TEXT[] NOT NULL,
    years_experience INTEGER DEFAULT 0,
    bio TEXT,
    shop_name TEXT,
    certifications TEXT[],
    tools TEXT[],
    hourly_rate NUMERIC(10, 2),
    diagnostic_fee NUMERIC(10, 2),
    warranty_policy TEXT,
    turnaround_time INTEGER,
    service_radius NUMERIC(10, 2),
    is_available BOOLEAN DEFAULT TRUE,
    rating NUMERIC(3, 2) DEFAULT 0.0,
    total_jobs INTEGER DEFAULT 0,
    acceptance_rate INTEGER DEFAULT 0,
    average_response_time INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Services table
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID REFERENCES users(id) ON DELETE CASCADE,
    service_name TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    base_price NUMERIC(10, 2),
    price_range_min NUMERIC(10, 2),
    price_range_max NUMERIC(10, 2),
    estimated_duration INTEGER NOT NULL,
    images TEXT[],
    parts_availability TEXT DEFAULT 'in_stock',
    warranty_terms TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Bookings table
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES users(id) ON DELETE CASCADE,
    service_id UUID REFERENCES services(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('requested', 'accepted', 'scheduled', 'en_route', 'in_progress', 'completed', 'cancelled', 'refunded')),
    scheduled_date TIMESTAMP WITH TIME ZONE,
    customer_address TEXT,
    customer_latitude DOUBLE PRECISION,
    customer_longitude DOUBLE PRECISION,
    diagnostic_notes TEXT,
    parts_list TEXT[],
    estimated_cost NUMERIC(10, 2),
    final_cost NUMERIC(10, 2),
    payment_method TEXT,
    payment_status TEXT,
    cancellation_reason TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    invoice_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Chats table
CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES users(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count_customer INTEGER DEFAULT 0,
    unread_count_technician INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verification Requests table
CREATE TABLE verification_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    documents TEXT[] NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'resubmit')),
    admin_notes TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Reviews table
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    icon TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity Logs table
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    details JSONB,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reports/Disputes table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for better performance
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_verified ON users(verified);
CREATE INDEX idx_users_location ON users(latitude, longitude);
CREATE INDEX idx_services_technician ON services(technician_id);
CREATE INDEX idx_services_category ON services(category);
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_bookings_technician ON bookings(technician_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_chats_customer ON chats(customer_id);
CREATE INDEX idx_chats_technician ON chats(technician_id);
CREATE INDEX idx_messages_chat ON messages(chat_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_reviews_technician ON reviews(technician_id);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE technician_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can insert their own profile on signup" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can view their own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Anyone can view verified technicians" ON users FOR SELECT USING (role = 'technician' AND verified = TRUE);

-- Helper function to check admin role (bypasses RLS to prevent infinite recursion)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin policies using the helper function
CREATE POLICY "Admins can view all users" ON users FOR SELECT USING (is_admin());
CREATE POLICY "Admins can update any user" ON users FOR UPDATE USING (is_admin());

-- Technician Profiles policies
CREATE POLICY "Technicians can manage their profile" ON technician_profiles FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Anyone can view verified technician profiles" ON technician_profiles FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = user_id AND verified = TRUE)
);

-- Services policies
CREATE POLICY "Technicians can manage their services" ON services FOR ALL USING (technician_id = auth.uid());
CREATE POLICY "Anyone can view active services" ON services FOR SELECT USING (is_active = TRUE);

-- Bookings policies
CREATE POLICY "Customers can view their bookings" ON bookings FOR SELECT USING (customer_id = auth.uid());
CREATE POLICY "Technicians can view their bookings" ON bookings FOR SELECT USING (technician_id = auth.uid());
CREATE POLICY "Customers can create bookings" ON bookings FOR INSERT WITH CHECK (customer_id = auth.uid());
CREATE POLICY "Customers can update their bookings" ON bookings FOR UPDATE USING (customer_id = auth.uid());
CREATE POLICY "Technicians can update their bookings" ON bookings FOR UPDATE USING (technician_id = auth.uid());

-- Chats policies
CREATE POLICY "Users can view their chats" ON chats FOR SELECT USING (
    customer_id = auth.uid() OR technician_id = auth.uid()
);
CREATE POLICY "Users can create chats" ON chats FOR INSERT WITH CHECK (
    customer_id = auth.uid() OR technician_id = auth.uid()
);

-- Messages policies
CREATE POLICY "Chat participants can view messages" ON messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM chats
        WHERE chats.id = messages.chat_id
        AND (chats.customer_id = auth.uid() OR chats.technician_id = auth.uid())
    )
);
CREATE POLICY "Chat participants can send messages" ON messages FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM chats
        WHERE chats.id = messages.chat_id
        AND (chats.customer_id = auth.uid() OR chats.technician_id = auth.uid())
    ) AND sender_id = auth.uid()
);

-- Verification Requests policies
CREATE POLICY "Technicians can view their verification requests" ON verification_requests FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Technicians can submit verification requests" ON verification_requests FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Admins can view all verification requests" ON verification_requests FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Admins can update verification requests" ON verification_requests FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Reviews policies
CREATE POLICY "Anyone can view reviews" ON reviews FOR SELECT USING (TRUE);
CREATE POLICY "Customers can create reviews for their bookings" ON reviews FOR INSERT WITH CHECK (
    customer_id = auth.uid() AND
    EXISTS (SELECT 1 FROM bookings WHERE id = booking_id AND customer_id = auth.uid() AND status = 'completed')
);

-- Categories policies
CREATE POLICY "Anyone can view categories" ON categories FOR SELECT USING (TRUE);
CREATE POLICY "Admins can manage categories" ON categories FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Notifications policies
CREATE POLICY "Users can view their notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update their notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- Activity Logs policies
CREATE POLICY "Users can view their activity logs" ON activity_logs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Admins can view all activity logs" ON activity_logs FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Reports policies
CREATE POLICY "Users can view their reports" ON reports FOR SELECT USING (reporter_id = auth.uid());
CREATE POLICY "Users can create reports" ON reports FOR INSERT WITH CHECK (reporter_id = auth.uid());
CREATE POLICY "Admins can view and manage all reports" ON reports FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Storage buckets (Execute these in Supabase Dashboard Storage section)
-- Bucket: profiles (public)
-- Bucket: documents (private - technician verification docs)
-- Bucket: services (public - service images)
-- Bucket: chats (private - chat images)
-- Bucket: invoices (private - booking invoices)

-- Functions to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_technician_profiles_updated_at BEFORE UPDATE ON technician_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_services_updated_at BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chats_updated_at BEFORE UPDATE ON chats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update technician rating when new review is added
CREATE OR REPLACE FUNCTION update_technician_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE technician_profiles
    SET rating = (
        SELECT AVG(rating)::NUMERIC(3,2)
        FROM reviews
        WHERE technician_id = NEW.technician_id
    ),
    total_jobs = (
        SELECT COUNT(*)
        FROM bookings
        WHERE technician_id = NEW.technician_id AND status = 'completed'
    )
    WHERE user_id = NEW.technician_id;

    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_rating_on_review AFTER INSERT ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_technician_rating();

-- Insert default admin account (Change password after first login!)
-- Note: You need to create this user in Supabase Auth first, then insert the profile
-- The UUID below should match the auth.users UUID for admin@fixit.com

-- INSERT INTO users (id, email, full_name, role, verified, created_at)
-- VALUES (
--     '<ADMIN_AUTH_UUID>',
--     'admin@fixit.com',
--     'Admin',
--     'admin',
--     TRUE,
--     NOW()
-- );

-- Insert default service categories
INSERT INTO categories (name, description) VALUES
('Screen Repair', 'Mobile phone and laptop screen replacement and repair'),
('Battery Replacement', 'Battery replacement for mobile phones and laptops'),
('Water Damage', 'Water damage diagnostics and repair'),
('Software Issues', 'Operating system, software troubleshooting and fixes'),
('Data Recovery', 'Data recovery and backup services'),
('Hardware Upgrades', 'RAM, storage, and component upgrades'),
('Diagnostics', 'Complete device diagnostics and health check'),
('Accessories', 'Installation and setup of accessories and peripherals');
