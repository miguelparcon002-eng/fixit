# Supabase Migration Guide
## Moving from Local Storage to Supabase

This guide explains the new Supabase tables created and the changes needed to migrate from local storage.

---

## 📋 New Tables Created

### 1. `user_addresses`
Stores customer delivery addresses.

**Columns:**
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users)
- `label` (VARCHAR) - e.g., "Home", "Work"
- `address` (TEXT) - Full address
- `latitude` (DECIMAL)
- `longitude` (DECIMAL)
- `is_default` (BOOLEAN) - Only one default per user
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Features:**
- Automatic trigger ensures only one default address per user
- RLS policies for user privacy
- Indexes for fast queries

**Replaces:** `address_provider.dart` local storage

---

### 2. `user_redeemed_vouchers`
Tracks vouchers redeemed by customers.

**Columns:**
- `id` (UUID, Primary Key)
- `user_id` (UUID, Foreign Key to auth.users)
- `voucher_id` (VARCHAR) - e.g., "v1", "v2"
- `voucher_title` (VARCHAR)
- `voucher_description` (TEXT)
- `points_cost` (INTEGER)
- `discount_amount` (DECIMAL)
- `discount_type` (VARCHAR) - 'fixed' or 'percentage'
- `redeemed_at` (TIMESTAMP)
- `used_at` (TIMESTAMP, nullable)
- `booking_id` (UUID, nullable, Foreign Key to bookings)
- `is_used` (BOOLEAN)
- `expires_at` (TIMESTAMP, nullable)
- `created_at` (TIMESTAMP)

**Features:**
- Track when voucher was redeemed vs used
- Link to booking where voucher was applied
- Optional expiration dates
- RLS policies for user privacy

**Replaces:** `rewards_provider.dart` redeemed vouchers local storage

---

### 3. `technician_specialties`
Stores technician expertise areas.

**Columns:**
- `id` (UUID, Primary Key)
- `technician_id` (UUID, Foreign Key to auth.users)
- `specialty_name` (VARCHAR)
- `created_at` (TIMESTAMP)

**Features:**
- Unique constraint on (technician_id, specialty_name)
- Public read access for searching technicians
- Technicians can only modify their own specialties

**Replaces:** `profile_service.dart` specialties local storage

---

## 🔧 Columns Added to Existing Tables

### `users` table
- `profile_setup_complete` (BOOLEAN, default: false)
- `profile_image_url` (TEXT, nullable)

**Purpose:** Track onboarding completion and profile images

---

## 🗂️ New Dart Models Created

### 1. `lib/models/user_address.dart`
```dart
class UserAddress {
  final String id;
  final String userId;
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 2. `lib/models/redeemed_voucher.dart`
```dart
class RedeemedVoucher {
  final String id;
  final String userId;
  final String voucherId;
  final String voucherTitle;
  final int pointsCost;
  final double discountAmount;
  final String discountType;
  final DateTime redeemedAt;
  final bool isUsed;
}
```

### 3. `lib/models/technician_specialty.dart`
```dart
class TechnicianSpecialty {
  final String id;
  final String technicianId;
  final String specialtyName;
  final DateTime createdAt;
}
```

---

## 🚀 Migration Steps

### Step 1: Run SQL Migration
1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `supabase_migrations_new_tables.sql`
3. Run the SQL script
4. Verify tables were created successfully

### Step 2: Update Flutter Dependencies
The models have been created. Now you need to:
1. Create services for each new table
2. Update providers to use Supabase instead of local storage
3. Migrate existing local data (optional)

---

## 📝 Files to Update

### High Priority (Must Update)

#### 1. **Address Provider**
**File:** `lib/providers/address_provider.dart`
**Current:** Uses `StorageService.loadAddresses()` / `saveAddresses()`
**Change to:** Use Supabase `user_addresses` table

#### 2. **Rewards Provider**
**File:** `lib/providers/rewards_provider.dart`
**Current:** `RedeemedVouchersNotifier` uses local storage
**Change to:** Use Supabase `user_redeemed_vouchers` table

#### 3. **Profile Service**
**File:** `lib/services/profile_service.dart`
**Current:** Stores specialties in local storage
**Change to:** Use Supabase `technician_specialties` table
**Also:** Update to use `users.profile_setup_complete` column

#### 4. **Voucher Service**
**File:** `lib/services/voucher_service.dart`
**Current:** Stores vouchers in local storage
**Change to:** Use Supabase `user_redeemed_vouchers` table

---

## ❌ Code to Remove (After Migration)

### 1. **LocalBooking System (LEGACY)**
**Files:**
- `lib/providers/booking_provider.dart` - Remove `LocalBookingNotifier`
- `lib/providers/booking_provider.dart` - Remove `localBookingsProvider`
- `lib/providers/booking_provider.dart` - Remove `customerFilteredBookingsProvider`

**Reason:** Duplicate of Supabase `bookings` table. Use `customerBookingsProvider` and `technicianBookingsProvider` instead.

### 2. **Local Storage Keys to Remove**
- `global_bookings` - Replaced by Supabase bookings table
- `redeemed_vouchers` - Replaced by `user_redeemed_vouchers` table
- `{userId}_addresses` - Replaced by `user_addresses` table
- `specialties` - Replaced by `technician_specialties` table
- `profile_setup_complete` - Now in `users` table
- `profile_image` - Now `profile_image_url` in `users` table

---

## 🔍 Testing Checklist

After migration, test:

### Addresses
- [ ] Customer can add new address
- [ ] Customer can set default address
- [ ] Customer can edit/delete address
- [ ] Address persists after logout/login
- [ ] Only user's own addresses are visible

### Redeemed Vouchers
- [ ] Customer can redeem voucher
- [ ] Points deducted correctly
- [ ] Voucher appears in redeemed list
- [ ] Voucher can be marked as used
- [ ] Redeemed vouchers persist after logout

### Technician Specialties
- [ ] Technician can add specialties
- [ ] Specialties visible in search
- [ ] Cannot add duplicate specialties
- [ ] Specialties persist after logout

### Profile Setup
- [ ] `profile_setup_complete` flag works
- [ ] Profile images save to `profile_image_url`
- [ ] Onboarding flow respects setup status

---

## 🎯 Benefits After Migration

1. **Data Persistence** - No data loss on app reinstall
2. **Better Security** - RLS policies protect user data
3. **Real-time Sync** - Changes reflect immediately across devices
4. **Analytics** - Can query data for insights
5. **Scalability** - Database handles growth better than local storage
6. **Backup** - Supabase handles backups automatically

---

## ⚠️ Important Notes

1. **RLS Security** - All tables have Row Level Security enabled
2. **User ID** - Always use `auth.uid()` for current user
3. **Indexes** - Tables have indexes for fast queries
4. **Cascading Deletes** - Deleting user deletes related data
5. **Timestamps** - Automatic `created_at` and `updated_at`

---

## 📞 Next Steps

1. ✅ SQL migration file created: `supabase_migrations_new_tables.sql`
2. ✅ Dart models created for new tables
3. ⏳ Run SQL in Supabase Dashboard
4. ⏳ Create services for new tables
5. ⏳ Update providers to use services
6. ⏳ Test thoroughly
7. ⏳ Remove old local storage code

---

## 🐛 Troubleshooting

**Issue:** RLS policies blocking access
**Solution:** Verify user is authenticated and `auth.uid()` matches user_id

**Issue:** Can't insert data
**Solution:** Check RLS INSERT policies and ensure user_id is set correctly

**Issue:** Old data not migrating
**Solution:** Write a one-time migration script to copy local storage → Supabase

---

Generated: $(date)
