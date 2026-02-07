# Data Migration Needed - Critical Findings

## 🔴 CRITICAL: Data Stored Locally That Should Be in Supabase

### 1. **User Profiles** - DUAL STORAGE ISSUE
**Current Status:** Data saved BOTH in `local_storage` table AND `users` table

**Problem:**
- ProfileService loads from local storage FIRST, then falls back to Supabase
- This creates data inconsistency between devices
- Profile changes may not sync properly

**File:** `lib/services/profile_service.dart` (lines 28-43)

**Data Affected:**
- Email
- Phone number
- Location (address, city, neighborhood)
- Member since date
- Profile image path

**Solution:**
```dart
// CURRENT (WRONG):
Future<Profile?> getProfile() async {
  // Loads from StorageService.loadData('profile') first
  // Then falls back to Supabase users table
}

// CORRECT:
Future<Profile?> getProfile() async {
  // Load ONLY from Supabase users table
  final user = await authService.getCurrentUser();
  return user; // Users table has all profile data
}
```

**Action Required:**
1. Remove local storage fallback in ProfileService
2. Load profile data exclusively from `users` table
3. Remove `profile` and `profile_image` keys from StorageService

---

### 2. **Profile Setup Complete Flag** - UNNECESSARY LOCAL STORAGE
**Current Status:** Stored in `local_storage` table with key `{userId}_profile_setup_complete`

**Problem:**
- This boolean flag is stored locally instead of in the `users` table
- Doesn't sync across devices
- User has to complete setup on each device

**File:** `lib/services/voucher_service.dart` (lines 80-88)

**Solution:**
Add field to `users` table:
```sql
ALTER TABLE users
ADD COLUMN IF NOT EXISTS profile_setup_completed_at TIMESTAMP WITH TIME ZONE;

-- Or just use the existing profile_setup_complete boolean
-- It's already there but service doesn't use it!
```

**Update Service:**
```dart
// CURRENT (WRONG):
Future<bool> isProfileSetupComplete() async {
  return await StorageService.loadData('${userId}_profile_setup_complete') == 'true';
}

// CORRECT:
Future<bool> isProfileSetupComplete() async {
  final user = await authService.getCurrentUser();
  return user?.profileSetupComplete ?? false;
}
```

**Action Required:**
1. Use existing `profile_setup_complete` field in `users` table
2. Remove local storage for this flag
3. Update when user completes profile setup

---

### 3. **Vouchers** - LEGACY LOCAL FALLBACK
**Current Status:** VoucherService has local storage fallback for backward compatibility

**Problem:**
- Old voucher data may exist in `local_storage` table
- Service loads from local storage if Supabase fails
- Creates dual source of truth

**File:** `lib/services/voucher_service.dart` (lines 91-103)

**Data Affected:**
- User's redeemed vouchers list

**Solution:**
```dart
// CURRENT (WRONG):
Future<List<Voucher>> getVouchers() async {
  try {
    // Load from Supabase
  } catch (e) {
    // Falls back to local storage
    return await StorageService.loadData('vouchers');
  }
}

// CORRECT:
Future<List<Voucher>> getVouchers() async {
  // Load ONLY from user_redeemed_vouchers table
  final vouchers = await supabase
    .from('user_redeemed_vouchers')
    .select()
    .eq('user_id', userId)
    .eq('is_used', false);
  return vouchers;
}
```

**Action Required:**
1. Remove local storage fallback
2. Use `user_redeemed_vouchers` table exclusively
3. The table already exists and works correctly

---

## 🟡 OPTIONAL: Data Currently Stored Correctly

### ✅ Bookings
- **Table:** `bookings`
- **Status:** Correct (migration utility handles legacy data)
- **No action needed**

### ✅ Addresses
- **Table:** `user_addresses`
- **Status:** Fully migrated to Supabase
- **No action needed**

### ✅ Redeemed Vouchers
- **Table:** `user_redeemed_vouchers`
- **Status:** Correct (providers use Supabase)
- **Note:** Service has unnecessary local fallback (see issue #3 above)

### ✅ Reward Points
- **Storage:** None (calculated from bookings)
- **Status:** Correct implementation
- **No action needed**

### ✅ Earnings
- **Table:** `app_earnings`
- **Status:** Fully migrated to Supabase
- **No action needed**

### ✅ Reviews/Ratings
- **Table:** `bookings` (rating and review fields)
- **Status:** Correct
- **No action needed**

---

## 📊 Summary Table

| Data Type | Current Storage | Should Be | Priority | Estimated Fix Time |
|-----------|----------------|-----------|----------|-------------------|
| User Profiles | `local_storage` + `users` | `users` only | 🔴 Critical | 30 mins |
| Profile Setup Flag | `local_storage` | `users.profile_setup_complete` | 🟡 Medium | 15 mins |
| Vouchers (fallback) | `local_storage` + Supabase | `user_redeemed_vouchers` only | 🟡 Medium | 15 mins |
| Bookings | ✅ `bookings` table | No change needed | ✅ Good | - |
| Addresses | ✅ `user_addresses` | No change needed | ✅ Good | - |
| Earnings | ✅ `app_earnings` | No change needed | ✅ Good | - |
| Reward Points | ✅ Calculated | No change needed | ✅ Good | - |

---

## 🛠️ Fix Implementation Guide

### Fix #1: Remove Profile Dual Storage

**Step 1: Update ProfileService**

File: `lib/services/profile_service.dart`

```dart
class ProfileService {
  final _supabase = SupabaseConfig.client;

  // Remove this method entirely
  // Future<void> saveProfile(Profile profile) async { ... }

  // Keep only this method (load from Supabase users table)
  Future<Profile?> getProfile(String userId) async {
    final response = await _supabase
      .from('users')
      .select()
      .eq('id', userId)
      .single();

    return Profile.fromJson(response);
  }

  // Update profile in users table
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _supabase
      .from('users')
      .update(data)
      .eq('id', userId);
  }
}
```

**Step 2: Update Profile Provider**

File: `lib/providers/profile_provider.dart` (if it exists)

```dart
final userProfileProvider = StreamProvider<Profile?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);

  // Stream from users table
  return SupabaseConfig.client
    .from('users')
    .stream(primaryKey: ['id'])
    .eq('id', user.id)
    .map((data) => data.isNotEmpty ? Profile.fromJson(data.first) : null);
});
```

---

### Fix #2: Use profile_setup_complete from Users Table

**Step 1: Update VoucherService**

File: `lib/services/voucher_service.dart`

```dart
// REMOVE this method:
Future<bool> isProfileSetupComplete() async {
  final data = await StorageService.loadData('${_currentUserId}_profile_setup_complete');
  return data == 'true';
}

Future<void> markProfileSetupComplete() async {
  await StorageService.saveData('${_currentUserId}_profile_setup_complete', 'true');
}

// REPLACE with:
Future<bool> isProfileSetupComplete(String userId) async {
  final response = await _supabase
    .from('users')
    .select('profile_setup_complete')
    .eq('id', userId)
    .single();

  return response['profile_setup_complete'] ?? false;
}

Future<void> markProfileSetupComplete(String userId) async {
  await _supabase
    .from('users')
    .update({'profile_setup_complete': true})
    .eq('id', userId);
}
```

**Step 2: Update Provider**

File: `lib/providers/voucher_provider.dart`

```dart
final profileSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return false;

  // Load from users table
  return user.profileSetupComplete ?? false;
});
```

---

### Fix #3: Remove Voucher Local Fallback

**File:** `lib/services/voucher_service.dart`

```dart
// REMOVE local storage fallback entirely
Future<List<Voucher>> getVouchers() async {
  // Remove try-catch with local storage fallback
  // Use ONLY user_redeemed_vouchers table

  final response = await _supabase
    .from('user_redeemed_vouchers')
    .select()
    .eq('user_id', userId)
    .eq('is_used', false)
    .order('redeemed_at', ascending: false);

  return (response as List)
    .map((e) => Voucher.fromJson(e))
    .toList();
}
```

---

## 🧪 Testing After Fixes

### Test Profile Migration
1. Log in on Device A
2. Update profile (name, phone, address)
3. Log in on Device B
4. Verify profile shows updated data
5. Update profile on Device B
6. Check Device A - should see changes

### Test Profile Setup Flag
1. Create new user account
2. Complete profile setup
3. Log out and log in again
4. Should not see setup wizard again
5. Log in on different device
6. Should not see setup wizard

### Test Vouchers
1. Redeem a voucher
2. Create booking with voucher
3. Verify voucher marked as used
4. Check it doesn't appear in available vouchers
5. Verify discount applied correctly

---

## 📋 Checklist

- [ ] Fix #1: Remove profile dual storage (30 mins)
- [ ] Fix #2: Use users.profile_setup_complete (15 mins)
- [ ] Fix #3: Remove voucher local fallback (15 mins)
- [ ] Test profile sync across devices
- [ ] Test profile setup flag persistence
- [ ] Test voucher redemption flow
- [ ] Remove unused storage keys from StorageService
- [ ] Update documentation

---

## 🎯 Expected Outcome

After these fixes:
- ✅ All user data stored in proper Supabase tables
- ✅ Data syncs across all devices
- ✅ Single source of truth (no dual storage)
- ✅ No data inconsistencies
- ✅ Proper real-time updates

**Total Estimated Time:** ~1 hour

**Impact:** High (eliminates data sync issues)
