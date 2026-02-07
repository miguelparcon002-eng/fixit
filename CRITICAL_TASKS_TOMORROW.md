# Critical Tasks for Your Application

This is your guide for tomorrow. Tasks are organized by priority.

## 🔴 CRITICAL - Must Do First (Security & Data Integrity)

### 1. Verify All Data is Saving to Supabase (Not Local Storage)
**Why Critical:** Local storage data is lost when users clear cache or switch devices.

**What to Check:**
- [ ] Bookings save to `bookings` table (not Hive/localStorage)
- [ ] User profiles save to `users` table
- [ ] Addresses save to `user_addresses` table
- [ ] Vouchers save to `user_redeemed_vouchers` table
- [ ] Reviews/ratings save to `bookings` table

**How to Test:**
1. Create a booking as customer
2. Go to Supabase → Table Editor → `bookings`
3. Verify the booking appears immediately
4. Repeat for profiles, addresses, vouchers, reviews

**Files to Check:**
- [lib/services/booking_service.dart](lib/services/booking_service.dart)
- [lib/services/storage_service.dart](lib/services/storage_service.dart)
- [lib/providers/booking_provider.dart](lib/providers/booking_provider.dart)

---

### 2. Configure Row Level Security (RLS) Policies
**Why Critical:** Without RLS, users can see/edit other users' data.

**Tables Needing RLS:**
- [ ] `bookings` - Users should only see their own bookings
- [ ] `user_redeemed_vouchers` - Users should only see their own vouchers
- [ ] `user_addresses` - Users should only see their own addresses
- [ ] `technician_profiles` - Technicians can only edit their own profile
- [ ] `reviews` - Users can only create reviews for their own bookings
- [ ] `messages` - Users can only see their own chats
- [ ] `notifications` - Users can only see their own notifications

**Example RLS Policy for Bookings:**
```sql
-- Enable RLS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Customers can see their own bookings
CREATE POLICY "Customers can view own bookings"
ON bookings FOR SELECT
USING (auth.uid() = customer_id);

-- Technicians can see bookings assigned to them
CREATE POLICY "Technicians can view assigned bookings"
ON bookings FOR SELECT
USING (auth.uid() = technician_id);

-- Customers can insert bookings
CREATE POLICY "Customers can create bookings"
ON bookings FOR INSERT
WITH CHECK (auth.uid() = customer_id);

-- Technicians can update their bookings
CREATE POLICY "Technicians can update assigned bookings"
ON bookings FOR UPDATE
USING (auth.uid() = technician_id);
```

**Action:** Create RLS policies for ALL tables with user data.

---

### 3. Verify Voucher System End-to-End
**Why Critical:** This is a core feature you just fixed.

**Test Checklist:**
- [ ] **All voucher types work** (not just FIRST20)
  - Test: WELCOME10, SAVE15, LOYALTY25, etc.
- [ ] **Vouchers disappear after use**
  - Redeem voucher → Use in booking → Check it's gone from available list
- [ ] **is_used flag updates correctly**
  - Check `user_redeemed_vouchers` table after booking
- [ ] **Discount applies correctly**
  - Percentage: 20% off ₱5000 = ₱4000
  - Fixed: ₱100 off ₱5000 = ₱4900
- [ ] **Discount maintains when technician adjusts price**
  - Original: ₱5000 - 20% = ₱4000
  - Add ₱1000: ₱6000 - 20% = ₱4800
- [ ] **Cannot use same voucher twice**
- [ ] **Voucher codes are case-insensitive** (FIRST20 = first20)

**How to Test:**
1. Log in as customer
2. Go to Rewards → Redeem voucher
3. Create booking and apply voucher
4. Verify discount applies
5. Log in as technician
6. Edit booking, add ₱1000
7. Verify discount recalculates
8. Log back as customer
9. Check voucher is marked as used

**SQL to Create Test Vouchers:**
```sql
-- Create various voucher types for testing
INSERT INTO user_redeemed_vouchers (user_id, voucher_id, voucher_title, voucher_description, points_cost, discount_amount, discount_type, is_used)
VALUES
  (auth.uid(), 'WELCOME10', '10% Welcome Discount', 'New customer welcome offer', 100, 10, 'percentage', false),
  (auth.uid(), 'SAVE15', '15% Off', 'Save 15% on your next repair', 150, 15, 'percentage', false),
  (auth.uid(), 'FIXED100', '₱100 Off', 'Get ₱100 off any service', 200, 100, 'fixed', false);
```

---

## 🟠 HIGH PRIORITY - Do Soon (Core Features)

### 4. Real-Time Data Synchronization
**Why Important:** Users expect instant updates when booking status changes.

**What to Verify:**
- [ ] When technician accepts booking, customer sees update instantly
- [ ] When technician marks complete, customer notified immediately
- [ ] Booking status changes reflect in both customer and technician apps
- [ ] Chat messages appear in real-time

**Files to Check:**
- [lib/providers/booking_provider.dart](lib/providers/booking_provider.dart) - Uses `StreamProvider`
- [lib/services/booking_service.dart](lib/services/booking_service.dart) - `watchCustomerBookings()`, `watchTechnicianBookings()`

**How to Test:**
1. Open app on two devices/browsers
2. Log in as customer on one, technician on other
3. Create booking as customer
4. Accept booking as technician
5. Verify customer sees "Accepted" status instantly (no refresh needed)

---

### 5. Earnings & Statistics System
**Why Important:** Technicians and admin need accurate financial data.

**What to Verify:**
- [ ] Technician earnings calculate from completed bookings in Supabase
- [ ] Today's earnings show correct amount
- [ ] Weekly/monthly earnings accurate
- [ ] Total jobs count matches database
- [ ] Average rating calculates correctly
- [ ] Admin dashboard shows correct app-wide statistics

**Files to Check:**
- [lib/providers/earnings_provider.dart](lib/providers/earnings_provider.dart)
- [lib/services/earnings_service.dart](lib/services/earnings_service.dart)

**SQL to Verify:**
```sql
-- Check technician earnings
SELECT
  t.id,
  t.full_name,
  COUNT(b.id) as total_jobs,
  SUM(b.final_cost) as total_earnings,
  AVG(b.rating) as average_rating
FROM users t
LEFT JOIN bookings b ON b.technician_id = t.id
WHERE t.role = 'technician'
  AND b.status = 'completed'
GROUP BY t.id, t.full_name;
```

---

### 6. Profile & Address Management
**Why Important:** Users need to save delivery addresses and profile info.

**What to Verify:**
- [ ] User can add multiple addresses
- [ ] Addresses save to `user_addresses` table in Supabase
- [ ] Can set default address
- [ ] Address auto-selects on booking creation
- [ ] Profile images upload to Supabase Storage
- [ ] Profile changes sync across devices

**Tables:**
- `user_addresses` - Stores addresses with lat/long
- `users` - Main profile data
- Supabase Storage bucket for profile images

**How to Test:**
1. Go to Profile → Addresses → Add New
2. Add address, set as default
3. Check Supabase `user_addresses` table
4. Create booking and verify address pre-fills

---

### 7. Notification System
**Why Important:** Users need alerts for booking updates.

**What to Verify:**
- [ ] Notifications save to `notifications` table
- [ ] Customer gets notified when technician accepts
- [ ] Technician gets notified of new bookings
- [ ] Notifications marked as read correctly
- [ ] Real-time notifications appear without refresh

**Files to Check:**
- [lib/providers/notifications_provider.dart](lib/providers/notifications_provider.dart) (if exists)
- Check for Supabase real-time subscription

---

## 🟡 MEDIUM PRIORITY - Important but Not Urgent

### 8. Review & Rating System
**What to Verify:**
- [ ] Customers can rate completed bookings
- [ ] Ratings save to `bookings` table
- [ ] Technician average rating updates in `technician_profiles`
- [ ] Reviews display on technician profile

### 9. Payment Status Tracking
**What to Verify:**
- [ ] Payment status updates in database
- [ ] Payment methods recorded correctly
- [ ] Admin can see payment history

### 10. Admin Dashboard
**What to Verify:**
- [ ] All statistics load from Supabase
- [ ] Verification requests show pending techs
- [ ] Can approve/reject technician verification
- [ ] Support tickets display correctly

### 11. Chat/Messaging System
**What to Verify:**
- [ ] Messages save to `messages` table
- [ ] Real-time message delivery works
- [ ] Unread count updates correctly
- [ ] Image messages upload to Supabase Storage

---

## 🟢 LOW PRIORITY - Nice to Have

### 12. Offline Support
**What to Do:**
- Implement queue for operations when offline
- Sync data when connection restored
- Show offline indicator in UI

### 13. Data Backup
**What to Do:**
- Add export function for user data
- Implement automatic backups
- Create restore functionality

### 14. Error Handling
**What to Do:**
- Handle Supabase connection failures gracefully
- Retry failed operations
- Show user-friendly error messages

---

## 📋 Quick Action Checklist for Tomorrow Morning

Start with these in order:

1. ✅ **Remove debug print statements** from production code
   - Search for `print('🔍` and `print('💾` and remove them

2. ✅ **Test all voucher types work**
   - Create test vouchers with SQL above
   - Test percentage and fixed discounts

3. ✅ **Verify bookings save to Supabase**
   - Create booking, check database immediately

4. ✅ **Set up RLS policies**
   - Start with `bookings` table
   - Then `user_redeemed_vouchers`
   - Then other user tables

5. ✅ **Test real-time sync**
   - Open two devices/browsers
   - Create and accept booking
   - Verify instant updates

---

## 🔧 Useful SQL Queries for Testing

### Check All User Data
```sql
-- See all bookings for a user
SELECT * FROM bookings
WHERE customer_id = 'USER-ID-HERE'
OR technician_id = 'USER-ID-HERE'
ORDER BY created_at DESC;

-- See all redeemed vouchers
SELECT * FROM user_redeemed_vouchers
WHERE user_id = 'USER-ID-HERE'
ORDER BY redeemed_at DESC;

-- See technician stats
SELECT * FROM app_technician_stats
WHERE technician_id = 'USER-ID-HERE';
```

### Verify Data Integrity
```sql
-- Check for bookings without customer/technician
SELECT * FROM bookings
WHERE customer_id IS NULL OR technician_id IS NULL;

-- Check for unused vouchers
SELECT COUNT(*) FROM user_redeemed_vouchers
WHERE is_used = false;

-- Check for bookings with invalid status
SELECT * FROM bookings
WHERE status NOT IN ('requested', 'accepted', 'in_progress', 'completed', 'cancelled');
```

---

## 📞 Need Help? Debug Steps

If something doesn't work:

1. **Check Console Logs**
   - Look for errors (red text)
   - Check debug output (🔍, 💾, ✅ emojis)

2. **Check Supabase Logs**
   - Go to Supabase Dashboard → Logs
   - Look for failed queries or auth errors

3. **Verify Database**
   - Use SQL queries above to check data
   - Verify RLS policies aren't blocking access

4. **Test Incrementally**
   - Test one feature at a time
   - Verify each step before moving on

---

Good luck tomorrow! Start with the Critical tasks first, then work your way down.
