# Part 2: Migrate to Proper Supabase Tables

## Overview
Move data from `local_storage` key-value table to proper relational tables with:
- Foreign keys and constraints
- Proper indexing
- Row Level Security (RLS)
- Real-time capabilities
- Query optimization

---

## Migration Plan

### Priority 1: CRITICAL - Bookings (Already Have Table!)

**Current Problem:**
- Bookings stored in `local_storage` with key `global_bookings`
- You already have a proper `bookings` table in schema!
- Just need to migrate the data

**Migration SQL:**

```sql
-- File: supabase_migrate_bookings_from_storage.sql

-- Step 1: Backup current bookings table (safety)
CREATE TABLE bookings_backup AS SELECT * FROM bookings;

-- Step 2: Extract bookings from local_storage
-- This assumes your bookings are stored as JSON array in local_storage
DO $$
DECLARE
    bookings_json TEXT;
    booking_record JSONB;
BEGIN
    -- Get the JSON string from local_storage
    SELECT value INTO bookings_json 
    FROM local_storage 
    WHERE key = 'global_bookings';
    
    -- Exit if no data found
    IF bookings_json IS NULL THEN
        RAISE NOTICE 'No global_bookings found in local_storage';
        RETURN;
    END IF;
    
    -- Loop through each booking in the JSON array
    FOR booking_record IN SELECT * FROM jsonb_array_elements(bookings_json::jsonb)
    LOOP
        -- Insert into bookings table
        INSERT INTO bookings (
            id,
            customer_id,
            technician_id,
            service_id,
            status,
            scheduled_date,
            customer_address,
            customer_latitude,
            customer_longitude,
            diagnostic_notes,
            parts_list,
            estimated_cost,
            final_cost,
            payment_method,
            payment_status,
            cancellation_reason,
            rating,
            review,
            invoice_url,
            created_at,
            accepted_at,
            completed_at,
            cancelled_at,
            updated_at
        )
        VALUES (
            (booking_record->>'id')::UUID,
            (booking_record->>'customer_id')::UUID,
            (booking_record->>'technician_id')::UUID,
            (booking_record->>'service_id')::UUID,
            booking_record->>'status',
            (booking_record->>'scheduled_date')::TIMESTAMP WITH TIME ZONE,
            booking_record->>'customer_address',
            (booking_record->>'customer_latitude')::DOUBLE PRECISION,
            (booking_record->>'customer_longitude')::DOUBLE PRECISION,
            booking_record->>'diagnostic_notes',
            ARRAY(SELECT jsonb_array_elements_text(booking_record->'parts_list')),
            (booking_record->>'estimated_cost')::NUMERIC,
            (booking_record->>'final_cost')::NUMERIC,
            booking_record->>'payment_method',
            booking_record->>'payment_status',
            booking_record->>'cancellation_reason',
            (booking_record->>'rating')::INTEGER,
            booking_record->>'review',
            booking_record->>'invoice_url',
            (booking_record->>'created_at')::TIMESTAMP WITH TIME ZONE,
            (booking_record->>'accepted_at')::TIMESTAMP WITH TIME ZONE,
            (booking_record->>'completed_at')::TIMESTAMP WITH TIME ZONE,
            (booking_record->>'cancelled_at')::TIMESTAMP WITH TIME ZONE,
            (booking_record->>'updated_at')::TIMESTAMP WITH TIME ZONE
        )
        ON CONFLICT (id) DO UPDATE SET
            status = EXCLUDED.status,
            updated_at = EXCLUDED.updated_at;
    END LOOP;
    
    RAISE NOTICE 'Migration complete';
END $$;

-- Step 3: Archive the old data (don't delete yet, for safety)
UPDATE local_storage 
SET key = 'global_bookings_archived_' || NOW()::TEXT
WHERE key = 'global_bookings';

-- Step 4: Verify migration
SELECT 
    'Bookings in table' as source,
    COUNT(*) as count,
    MIN(created_at) as oldest,
    MAX(created_at) as newest
FROM bookings
UNION ALL
SELECT 
    'Archived bookings' as source,
    jsonb_array_length(value::jsonb) as count,
    NULL as oldest,
    NULL as newest
FROM local_storage 
WHERE key LIKE 'global_bookings_archived_%';
```

**Update Dart Code:**

Replace `lib/providers/booking_provider.dart`:

```dart
// OLD: Loading from local_storage
final bookingsData = await StorageService.loadGlobalBookings();

// NEW: Load from bookings table
final response = await SupabaseConfig.client
    .from('bookings')
    .select('''
        *,
        customer:customer_id(id, full_name, email, contact_number),
        technician:technician_id(id, full_name, email, contact_number),
        service:service_id(id, name, category, base_price)
    ''')
    .order('created_at', ascending: false);

final bookings = response.map((json) => BookingModel.fromJson(json)).toList();
```

**Enable Realtime:**

```dart
// Listen to booking changes in real-time
final subscription = SupabaseConfig.client
    .from('bookings')
    .stream(primaryKey: ['id'])
    .eq('customer_id', userId)
    .listen((data) {
      // Update UI automatically
      state = data.map((json) => BookingModel.fromJson(json)).toList();
    });
```

---

### Priority 2: HIGH - Addresses Table

**Create Table:**

```sql
-- File: supabase_create_addresses_table.sql

CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label TEXT, -- 'home', 'work', 'other'
    street_address TEXT NOT NULL,
    city TEXT,
    neighborhood TEXT,
    postal_code TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_addresses_user ON addresses(user_id);
CREATE INDEX idx_addresses_location ON addresses(latitude, longitude);
CREATE INDEX idx_addresses_default ON addresses(user_id, is_default) WHERE is_default = TRUE;

-- RLS Policies
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own addresses"
    ON addresses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own addresses"
    ON addresses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own addresses"
    ON addresses FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own addresses"
    ON addresses FOR DELETE
    USING (auth.uid() = user_id);

-- Trigger: Ensure only one default address per user
CREATE OR REPLACE FUNCTION enforce_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE addresses
        SET is_default = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_default
    AFTER INSERT OR UPDATE ON addresses
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION enforce_single_default_address();

-- Trigger: Update timestamp
CREATE OR REPLACE FUNCTION update_addresses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_addresses_timestamp
    BEFORE UPDATE ON addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_addresses_updated_at();
```

**Migrate Data:**

```sql
-- Migrate addresses from local_storage to addresses table
DO $$
DECLARE
    storage_record RECORD;
    addresses_json JSONB;
    address_record JSONB;
    user_id_extracted UUID;
BEGIN
    -- Loop through all address records in local_storage
    FOR storage_record IN 
        SELECT key, value 
        FROM local_storage 
        WHERE key LIKE '%_addresses'
    LOOP
        -- Extract user_id from key (format: "userid_addresses")
        user_id_extracted := SPLIT_PART(storage_record.key, '_', 1)::UUID;
        addresses_json := storage_record.value::JSONB;
        
        -- Insert each address
        FOR address_record IN SELECT * FROM jsonb_array_elements(addresses_json)
        LOOP
            INSERT INTO addresses (
                id,
                user_id,
                label,
                street_address,
                city,
                neighborhood,
                postal_code,
                latitude,
                longitude,
                is_default,
                created_at
            )
            VALUES (
                (address_record->>'id')::UUID,
                user_id_extracted,
                address_record->>'label',
                address_record->>'street',
                address_record->>'city',
                address_record->>'neighborhood',
                address_record->>'postalCode',
                (address_record->>'latitude')::DOUBLE PRECISION,
                (address_record->>'longitude')::DOUBLE PRECISION,
                (address_record->>'isDefault')::BOOLEAN,
                NOW()
            )
            ON CONFLICT (id) DO NOTHING;
        END LOOP;
        
        -- Archive old data
        UPDATE local_storage 
        SET key = key || '_archived_' || NOW()::TEXT
        WHERE key = storage_record.key;
    END LOOP;
END $$;
```

**Update Dart Code:**

```dart
// lib/services/address_service.dart
class AddressService {
  // Load addresses from Supabase
  Future<List<Address>> loadAddresses() async {
    final response = await SupabaseConfig.client
        .from('addresses')
        .select()
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    
    return response.map((json) => Address.fromJson(json)).toList();
  }

  // Add new address
  Future<Address> addAddress(Address address) async {
    final response = await SupabaseConfig.client
        .from('addresses')
        .insert(address.toJson())
        .select()
        .single();
    
    return Address.fromJson(response);
  }

  // Update address
  Future<void> updateAddress(Address address) async {
    await SupabaseConfig.client
        .from('addresses')
        .update(address.toJson())
        .eq('id', address.id);
  }

  // Delete address
  Future<void> deleteAddress(String id) async {
    await SupabaseConfig.client
        .from('addresses')
        .delete()
        .eq('id', id);
  }

  // Set default address
  Future<void> setDefaultAddress(String id) async {
    await SupabaseConfig.client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', id);
  }
}
```

---

### Priority 3: HIGH - Vouchers System

**Create Tables:**

```sql
-- File: supabase_create_vouchers_tables.sql

-- Vouchers table (admin-managed)
CREATE TABLE vouchers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
    discount_value NUMERIC(10, 2) NOT NULL,
    min_order_amount NUMERIC(10, 2),
    max_discount_amount NUMERIC(10, 2),
    max_total_uses INTEGER, -- NULL = unlimited
    current_uses INTEGER DEFAULT 0,
    max_uses_per_user INTEGER DEFAULT 1,
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    voucher_type TEXT NOT NULL CHECK (voucher_type IN ('welcome', 'seasonal', 'loyalty', 'referral', 'custom')),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User voucher redemptions
CREATE TABLE user_voucher_redemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    voucher_id UUID NOT NULL REFERENCES vouchers(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    discount_applied NUMERIC(10, 2) NOT NULL,
    redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, voucher_id) -- One redemption per user per voucher (unless max_uses_per_user > 1)
);

-- Indexes
CREATE INDEX idx_vouchers_code ON vouchers(code);
CREATE INDEX idx_vouchers_active ON vouchers(is_active, expires_at);
CREATE INDEX idx_redemptions_user ON user_voucher_redemptions(user_id);
CREATE INDEX idx_redemptions_voucher ON user_voucher_redemptions(voucher_id);

-- RLS Policies
ALTER TABLE vouchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_voucher_redemptions ENABLE ROW LEVEL SECURITY;

-- Vouchers: Everyone can read active vouchers
CREATE POLICY "Anyone can view active vouchers"
    ON vouchers FOR SELECT
    USING (is_active = TRUE AND (expires_at IS NULL OR expires_at > NOW()));

-- Vouchers: Only admins can manage
CREATE POLICY "Admins can manage vouchers"
    ON vouchers FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Redemptions: Users see only their own
CREATE POLICY "Users view own redemptions"
    ON user_voucher_redemptions FOR SELECT
    USING (auth.uid() = user_id);

-- Redemptions: Users can redeem vouchers
CREATE POLICY "Users can redeem vouchers"
    ON user_voucher_redemptions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Function: Check if voucher is valid for user
CREATE OR REPLACE FUNCTION is_voucher_valid_for_user(
    p_voucher_id UUID,
    p_user_id UUID,
    p_order_amount NUMERIC
)
RETURNS TABLE (
    is_valid BOOLEAN,
    reason TEXT,
    discount_amount NUMERIC
) AS $$
DECLARE
    v_voucher RECORD;
    v_user_uses INTEGER;
    v_calculated_discount NUMERIC;
BEGIN
    -- Get voucher details
    SELECT * INTO v_voucher
    FROM vouchers
    WHERE id = p_voucher_id;
    
    -- Check if voucher exists
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Voucher not found'::TEXT, 0::NUMERIC;
        RETURN;
    END IF;
    
    -- Check if active
    IF NOT v_voucher.is_active THEN
        RETURN QUERY SELECT FALSE, 'Voucher is inactive'::TEXT, 0::NUMERIC;
        RETURN;
    END IF;
    
    -- Check expiration
    IF v_voucher.expires_at IS NOT NULL AND v_voucher.expires_at < NOW() THEN
        RETURN QUERY SELECT FALSE, 'Voucher has expired'::TEXT, 0::NUMERIC;
        RETURN;
    END IF;
    
    -- Check validity period
    IF v_voucher.valid_from > NOW() THEN
        RETURN QUERY SELECT FALSE, 'Voucher not yet valid'::TEXT, 0::NUMERIC;
        RETURN;
    END IF;
    
    -- Check max total uses
    IF v_voucher.max_total_uses IS NOT NULL 
       AND v_voucher.current_uses >= v_voucher.max_total_uses THEN
        RETURN QUERY SELECT FALSE, 'Voucher has reached maximum uses'::TEXT, 0::NUMERIC;
        RETURN;
    END IF;
    
    -- Check user usage limit
    SELECT COUNT(*) INTO v_user_uses
    FROM user_voucher_redemptions
    WHERE voucher_id = p_voucher_id AND user_id = p_user_id;
    
    IF v_user_uses >= v_voucher.max_uses_per_user THEN
        RETURN QUERY SELECT FALSE, 'You have already used this voucher'::TEXT, 0::NUMERIC;
        RETURN;
    END IF;
    
    -- Check minimum order amount
    IF v_voucher.min_order_amount IS NOT NULL 
       AND p_order_amount < v_voucher.min_order_amount THEN
        RETURN QUERY SELECT FALSE, 
            'Minimum order amount of ' || v_voucher.min_order_amount || ' required'::TEXT, 
            0::NUMERIC;
        RETURN;
    END IF;
    
    -- Calculate discount
    IF v_voucher.discount_type = 'percent' THEN
        v_calculated_discount := (p_order_amount * v_voucher.discount_value / 100);
        IF v_voucher.max_discount_amount IS NOT NULL THEN
            v_calculated_discount := LEAST(v_calculated_discount, v_voucher.max_discount_amount);
        END IF;
    ELSE -- fixed
        v_calculated_discount := v_voucher.discount_value;
    END IF;
    
    -- Discount cannot exceed order amount
    v_calculated_discount := LEAST(v_calculated_discount, p_order_amount);
    
    RETURN QUERY SELECT TRUE, 'Valid'::TEXT, v_calculated_discount;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Increment usage counter
CREATE OR REPLACE FUNCTION increment_voucher_usage()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE vouchers
    SET current_uses = current_uses + 1
    WHERE id = NEW.voucher_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_voucher_redemption
    AFTER INSERT ON user_voucher_redemptions
    FOR EACH ROW
    EXECUTE FUNCTION increment_voucher_usage();

-- Insert default welcome voucher
INSERT INTO vouchers (
    code,
    title,
    description,
    discount_type,
    discount_value,
    voucher_type,
    expires_at
) VALUES (
    'WELCOME20',
    '20% Off First Repair',
    'Welcome discount for new customers',
    'percent',
    20,
    'welcome',
    NOW() + INTERVAL '90 days'
);
```

**Update Dart Code:**

```dart
// lib/services/voucher_service.dart
class VoucherService {
  // Get available vouchers for user
  Future<List<Voucher>> getAvailableVouchers() async {
    final response = await SupabaseConfig.client
        .from('vouchers')
        .select()
        .eq('is_active', true)
        .or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}')
        .order('created_at', ascending: false);
    
    return response.map((json) => Voucher.fromJson(json)).toList();
  }

  // Validate voucher for user
  Future<VoucherValidation> validateVoucher(
    String voucherCode,
    double orderAmount,
  ) async {
    final response = await SupabaseConfig.client
        .rpc('is_voucher_valid_for_user', params: {
          'p_voucher_id': voucherCode,
          'p_user_id': SupabaseConfig.client.auth.currentUser!.id,
          'p_order_amount': orderAmount,
        })
        .single();
    
    return VoucherValidation.fromJson(response);
  }

  // Redeem voucher
  Future<void> redeemVoucher(
    String voucherId,
    String bookingId,
    double discountApplied,
  ) async {
    await SupabaseConfig.client
        .from('user_voucher_redemptions')
        .insert({
          'voucher_id': voucherId,
          'booking_id': bookingId,
          'discount_applied': discountApplied,
        });
  }

  // Get user's redeemed vouchers
  Future<List<VoucherRedemption>> getUserRedemptions() async {
    final response = await SupabaseConfig.client
        .from('user_voucher_redemptions')
        .select('''
          *,
          voucher:voucher_id(*),
          booking:booking_id(*)
        ''')
        .order('redeemed_at', ascending: false);
    
    return response.map((json) => VoucherRedemption.fromJson(json)).toList();
  }
}
```

---

### Priority 4: MEDIUM - Reward Points

**Extend Customers Table:**

```sql
-- File: supabase_add_rewards_system.sql

-- Add reward points to customers table (if it exists)
-- Otherwise add to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS reward_points INTEGER DEFAULT 0;

-- Create reward transactions log
CREATE TABLE reward_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL, -- positive for earned, negative for spent
    points_balance INTEGER NOT NULL, -- snapshot of balance after transaction
    transaction_type TEXT NOT NULL CHECK (transaction_type IN (
        'booking_completed',
        'voucher_redeemed',
        'referral_bonus',
        'admin_adjustment',
        'points_expired'
    )),
    description TEXT,
    booking_id UUID REFERENCES bookings(id),
    voucher_id UUID REFERENCES vouchers(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_reward_transactions_user ON reward_transactions(user_id);
CREATE INDEX idx_reward_transactions_type ON reward_transactions(transaction_type);

-- RLS
ALTER TABLE reward_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own transactions"
    ON reward_transactions FOR SELECT
    USING (auth.uid() = user_id);

-- Function: Add reward points
CREATE OR REPLACE FUNCTION add_reward_points(
    p_user_id UUID,
    p_points INTEGER,
    p_type TEXT,
    p_description TEXT DEFAULT NULL,
    p_booking_id UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_new_balance INTEGER;
BEGIN
    -- Update user balance
    UPDATE users
    SET reward_points = reward_points + p_points
    WHERE id = p_user_id
    RETURNING reward_points INTO v_new_balance;
    
    -- Log transaction
    INSERT INTO reward_transactions (
        user_id,
        points_change,
        points_balance,
        transaction_type,
        description,
        booking_id
    ) VALUES (
        p_user_id,
        p_points,
        v_new_balance,
        p_type,
        p_description,
        p_booking_id
    );
    
    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Award points on booking completion
CREATE OR REPLACE FUNCTION award_points_on_booking_complete()
RETURNS TRIGGER AS $$
DECLARE
    v_points INTEGER;
BEGIN
    -- Only award points when status changes to 'completed'
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        -- Calculate points (e.g., 10% of final cost, rounded)
        v_points := ROUND((NEW.final_cost * 0.10))::INTEGER;
        
        -- Add points
        PERFORM add_reward_points(
            NEW.customer_id,
            v_points,
            'booking_completed',
            'Earned from booking #' || NEW.id,
            NEW.id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER award_booking_points
    AFTER UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION award_points_on_booking_complete();
```

**Update Dart Code:**

```dart
// lib/services/rewards_service.dart
class RewardsService {
  // Get user's reward points
  Future<int> getRewardPoints() async {
    final userId = SupabaseConfig.client.auth.currentUser!.id;
    final response = await SupabaseConfig.client
        .from('users')
        .select('reward_points')
        .eq('id', userId)
        .single();
    
    return response['reward_points'] ?? 0;
  }

  // Get transaction history
  Future<List<RewardTransaction>> getTransactionHistory() async {
    final response = await SupabaseConfig.client
        .from('reward_transactions')
        .select('''
          *,
          booking:booking_id(id, service_id)
        ''')
        .order('created_at', ascending: false)
        .limit(50);
    
    return response.map((json) => RewardTransaction.fromJson(json)).toList();
  }

  // Redeem points for voucher
  Future<void> redeemPointsForVoucher(int points, String voucherId) async {
    await SupabaseConfig.client.rpc('add_reward_points', params: {
      'p_user_id': SupabaseConfig.client.auth.currentUser!.id,
      'p_points': -points,
      'p_type': 'voucher_redeemed',
      'p_description': 'Redeemed for voucher',
      'p_voucher_id': voucherId,
    });
  }
}
```

---

## Summary of Migrations

| Data Type | From | To | Priority | Complexity |
|-----------|------|----|---------|-----------| 
| Bookings | `local_storage` | `bookings` table | 🔴 Critical | Low (table exists) |
| Addresses | `local_storage` | `addresses` table (new) | 🔴 High | Medium |
| Vouchers | `local_storage` | `vouchers` + redemptions tables (new) | 🟡 High | High |
| Reward Points | `local_storage` | `users.reward_points` + transactions | 🟡 Medium | Medium |
| Profile Cache | `local_storage` | Device storage (Hive) | 🟢 Low | Low |
| Specialties | `local_storage` | `technician_profiles.specialties` | 🔴 Bug Fix | Low (column exists!) |

