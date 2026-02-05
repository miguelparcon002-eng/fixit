# Storage Architecture Recommendations & Trade-offs

## Executive Summary

Your FIXIT app has **critical architecture issues** where core business data (bookings, addresses, vouchers) is stored in a key-value `local_storage` table instead of proper relational tables. This document provides actionable recommendations.

---

## 🎯 Recommended Architecture

### Three-Tier Storage Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    FIXIT Storage Layers                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Layer 1: DEVICE LOCAL (Hive)                               │
│  ├─ User Preferences (theme, language)                      │
│  ├─ Draft Data (unsaved bookings)                           │
│  ├─ Cache (offline access)                                  │
│  ├─ Recently Viewed                                         │
│  └─ Onboarding Status                                       │
│                                                               │
│  Layer 2: SUPABASE RELATIONAL TABLES (Primary)              │
│  ├─ bookings (with RLS, realtime)                           │
│  ├─ addresses (with foreign keys)                           │
│  ├─ vouchers + redemptions                                  │
│  ├─ users (with reward_points column)                       │
│  ├─ reward_transactions (audit log)                         │
│  └─ All other core data                                     │
│                                                               │
│  Layer 3: SUPABASE STORAGE (Files)                          │
│  ├─ Profile Pictures                                        │
│  ├─ Verification Documents                                  │
│  ├─ Invoices (PDFs)                                         │
│  └─ Chat Images                                             │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚨 Critical Actions (Do These First)

### 1. Migrate Bookings IMMEDIATELY

**Why Critical:**
- Your app can't scale beyond demo with bookings in JSON
- No data integrity or foreign key constraints
- Can't use Supabase features (realtime, complex queries, RLS)
- Risk of data corruption

**Action:**
```bash
# Run this SQL file
supabase_migrate_bookings_from_storage.sql
```

**Impact:**
- ✅ Enable real-time booking updates
- ✅ Proper queries and reporting
- ✅ Data integrity with foreign keys
- ✅ Admin dashboard actually works

**Effort:** Low (table already exists, just migrate data)
**Time:** 1-2 hours

---

### 2. Fix Specialties Redundancy

**Why Critical:**
- You're storing the same data in two places
- Data can get out of sync
- `technician_profiles` table already has `specialties TEXT[]` column!

**Action:**
```dart
// DELETE from profile_service.dart:
await StorageService.saveData('specialties', data);

// USE existing column:
await SupabaseConfig.client
    .from('technician_profiles')
    .update({'specialties': specialtiesList})
    .eq('user_id', userId);
```

**Impact:**
- ✅ Eliminate data duplication
- ✅ Use proper database schema
- ✅ Reduce confusion

**Effort:** Very Low
**Time:** 30 minutes

---

### 3. Create Addresses Table

**Why Important:**
- Can't do location-based queries (find technicians near address)
- No proper address management
- Missing relational benefits

**Action:**
```bash
# Run this SQL file
supabase_create_addresses_table.sql
```

**Impact:**
- ✅ Proper address management
- ✅ Location-based queries
- ✅ Better UX (save multiple addresses)

**Effort:** Medium
**Time:** 2-3 hours

---

## 📊 Migration Priority Matrix

| Data Type | Current Location | Recommended | Priority | Effort | Impact |
|-----------|-----------------|-------------|----------|--------|--------|
| **Bookings** | `local_storage` (JSON) | `bookings` table | 🔴 **CRITICAL** | Low | High |
| **Specialties** | `local_storage` (duplicate) | `technician_profiles.specialties` | 🔴 **CRITICAL** | Very Low | Medium |
| **Addresses** | `local_storage` (JSON) | `addresses` table | 🟠 **HIGH** | Medium | High |
| **Vouchers** | `local_storage` (JSON) | `vouchers` + `redemptions` tables | 🟠 **HIGH** | High | Medium |
| **Reward Points** | `local_storage` (number) | `users.reward_points` + transactions | 🟡 **MEDIUM** | Medium | Medium |
| **Profile Cache** | `local_storage` (Supabase) | Device storage (Hive) | 🟢 **LOW** | Low | Low |
| **Preferences** | Not implemented | Device storage (Hive) | 🟢 **LOW** | Low | Medium |
| **Profile Setup Status** | `local_storage` | `users` table column OR Hive | 🟢 **LOW** | Very Low | Low |

---

## 💡 Decision Framework: Where to Store Data?

### Use Device Storage (Hive) When:

✅ **User Preferences**
- Theme, language, notification settings
- Personal, device-specific
- No need to sync across devices

✅ **Temporary/Draft Data**
- Unsaved form data
- In-progress booking creation
- Prevents data loss on app crash

✅ **Cache for Offline**
- Read-only copy of profile
- Recently viewed services
- Improves offline experience

✅ **UI State**
- Selected tab, expanded sections
- Filter preferences
- Map zoom level

✅ **Non-Critical Flags**
- Onboarding completed
- Feature tour shown
- Tips dismissed

**Example:**
```dart
// Good: User's theme preference
await DeviceStorageService.savePreferences({'theme': 'dark'});

// Good: Draft booking
await DeviceStorageService.saveDraftBooking(draftData);
```

---

### Use Supabase Tables When:

✅ **Core Business Data**
- Bookings, services, users
- Must be authoritative source
- Needs backup and sync

✅ **Relational Data**
- Data with foreign keys
- Data that needs JOINs
- Data for queries/reports

✅ **Multi-User Data**
- Shared between users
- Needs access control (RLS)
- Admin needs to view/manage

✅ **Transactional Data**
- Needs ACID properties
- Audit trail required
- Financial data

✅ **Real-Time Data**
- Live updates (chat, bookings)
- Notifications
- Collaborative features

**Example:**
```dart
// Correct: Booking is core business data
await SupabaseConfig.client
    .from('bookings')
    .insert(bookingData);

// Correct: Address with foreign key
await SupabaseConfig.client
    .from('addresses')
    .insert({'user_id': userId, ...addressData});
```

---

### Use Supabase Storage (Buckets) When:

✅ **Files and Media**
- Images, PDFs, documents
- Large binary data
- Profile pictures, invoices

**Example:**
```dart
// Correct: Upload profile picture
await SupabaseConfig.client.storage
    .from('profiles')
    .upload('$userId/avatar.jpg', imageFile);
```

---

### ❌ NEVER Use `local_storage` Table For:

❌ Core business data (bookings, addresses)
❌ Data that needs foreign keys
❌ Data for analytics/reporting
❌ Data that needs real-time updates
❌ Data that needs complex queries

**The `local_storage` table should be REMOVED after migration!**

---

## 📈 Migration Roadmap

### Phase 1: Critical Fixes (Week 1)
**Goal:** Fix data architecture bugs

- [ ] Migrate bookings from `local_storage` to `bookings` table
- [ ] Update `BookingProvider` to use Supabase queries
- [ ] Enable realtime subscriptions for bookings
- [ ] Fix specialties duplication bug
- [ ] Test booking flow end-to-end
- [ ] Backup and archive old `local_storage` data

**Deliverable:** Bookings working in production schema

---

### Phase 2: Essential Tables (Week 2)
**Goal:** Add missing relational tables

- [ ] Create `addresses` table with RLS
- [ ] Migrate address data from `local_storage`
- [ ] Update `AddressProvider` to use table
- [ ] Create `vouchers` and `user_voucher_redemptions` tables
- [ ] Migrate voucher data
- [ ] Update `VoucherService` to use tables
- [ ] Add voucher validation function

**Deliverable:** Addresses and vouchers in proper tables

---

### Phase 3: Enhanced Features (Week 3)
**Goal:** Add reward system and caching

- [ ] Add `reward_points` column to `users` table
- [ ] Create `reward_transactions` audit table
- [ ] Migrate reward points from `local_storage`
- [ ] Add triggers for automatic point awards
- [ ] Create `DeviceStorageService` for Hive
- [ ] Move preferences to device storage
- [ ] Implement draft saving
- [ ] Add offline cache layer

**Deliverable:** Complete three-tier storage architecture

---

### Phase 4: Cleanup (Week 4)
**Goal:** Remove deprecated storage

- [ ] Verify all data migrated
- [ ] Update all providers to new storage
- [ ] Remove `local_storage` table usage from code
- [ ] Archive `local_storage` table
- [ ] Update documentation
- [ ] Performance testing
- [ ] Security audit (RLS policies)

**Deliverable:** Clean, production-ready architecture

---

## ⚖️ Trade-offs Analysis

### Device Storage (Hive)

**Pros:**
- ✅ Fast access (no network)
- ✅ Works offline
- ✅ Free (no Supabase storage cost)
- ✅ Low latency for UI updates
- ✅ Good for preferences

**Cons:**
- ❌ No backup (data loss on uninstall)
- ❌ Doesn't sync across devices
- ❌ Manual cache invalidation needed
- ❌ Limited to single device
- ❌ Risk of stale data

**Best For:** User preferences, drafts, cache

---

### Supabase Tables

**Pros:**
- ✅ Relational integrity (foreign keys)
- ✅ Complex queries and JOINs
- ✅ Real-time subscriptions
- ✅ Row Level Security (RLS)
- ✅ Automatic backups
- ✅ Syncs across devices
- ✅ Admin can manage data
- ✅ Audit trails

**Cons:**
- ❌ Requires network connection
- ❌ Slower than local storage
- ❌ Costs scale with usage
- ❌ Schema migrations needed

**Best For:** Core business data, multi-user data

---

### Key-Value Storage (local_storage table)

**Pros:**
- ✅ Flexible schema (JSON)
- ✅ Quick prototyping
- ✅ No migrations needed

**Cons:**
- ❌ No data integrity
- ❌ Can't query efficiently
- ❌ No foreign keys
- ❌ No indexing
- ❌ Poor scalability
- ❌ Manual serialization
- ❌ Risk of data corruption

**Best For:** Prototyping ONLY (not production!)

---

## 🎓 Best Practices

### 1. Single Source of Truth
```dart
// ❌ BAD: Data in multiple places
await StorageService.saveData('profile', profileJson); // Supabase
await DeviceStorageService.saveJson('profile', profile); // Device

// ✅ GOOD: One source of truth
final profile = await SupabaseConfig.client
    .from('users')
    .select()
    .eq('id', userId)
    .single(); // Supabase is source

// Cache locally for offline only
await DeviceStorageService.saveCachedProfile(userId, profile);
```

### 2. Cache Invalidation
```dart
// ✅ GOOD: Clear cache on logout
Future<void> onUserLogout() async {
  await DeviceStorageService.clearCurrentUserData();
  StorageService.setCurrentUser(null);
}

// ✅ GOOD: Refresh cache periodically
final lastSync = DeviceStorageService.getLastSyncTime();
if (lastSync == null || DateTime.now().difference(lastSync).inHours > 24) {
  await refreshCache();
}
```

### 3. Error Handling
```dart
// ✅ GOOD: Fallback to cache on network error
Future<User?> getProfile() async {
  try {
    // Try network first
    final profile = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    
    // Update cache
    await DeviceStorageService.saveCachedProfile(userId, profile);
    
    return User.fromJson(profile);
  } catch (e) {
    // Fallback to cached data
    print('Network error, using cache: $e');
    final cached = DeviceStorageService.loadCachedProfile(userId);
    return cached != null ? User.fromJson(cached) : null;
  }
}
```

### 4. Data Consistency
```dart
// ✅ GOOD: Use transactions for related data
await SupabaseConfig.client.rpc('redeem_voucher', params: {
  'booking_id': bookingId,
  'voucher_id': voucherId,
  'discount': discount,
});
// This function updates booking AND creates redemption record atomically
```

---

## 🔒 Security Considerations

### RLS Policies Must Match Storage Layer

**Device Storage:**
- No built-in security
- Anyone with device access can read
- Use encrypted box for sensitive data
- Never store passwords/tokens

**Supabase Tables:**
- Always enable RLS
- Test policies thoroughly
- Use `auth.uid()` for user isolation
- Admin access via role check

**Example RLS:**
```sql
-- Users can only see their own bookings
CREATE POLICY "Users view own bookings"
    ON bookings FOR SELECT
    USING (auth.uid() = customer_id OR auth.uid() = technician_id);

-- Admins can see all bookings
CREATE POLICY "Admins view all bookings"
    ON bookings FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

---

## 📦 What to Keep in `local_storage` (Temporarily)

During migration, you might keep these temporarily:

- Profile setup completion status (migrate to `users.profile_completed` column)
- Valid vouchers cache (until vouchers table is ready)

**But plan to remove `local_storage` table entirely!**

---

## 🎯 Success Metrics

After migration, you should have:

- ✅ Zero bookings in `local_storage` table
- ✅ All addresses in `addresses` table
- ✅ Vouchers manageable by admin
- ✅ Real-time booking updates working
- ✅ Device storage for preferences only
- ✅ < 100ms query time for bookings list
- ✅ Offline cache working for basic info
- ✅ No data duplication

---

## 🚀 Quick Start

**If you only do ONE thing:**

1. Run `supabase_migrate_bookings_from_storage.sql`
2. Update `BookingProvider` to query `bookings` table
3. Test the booking flow

This single change will fix your biggest architectural issue.

---

## 📚 Additional Resources

**Created Files:**
- `STORAGE_ARCHITECTURE_ANALYSIS.md` - Why current design is problematic
- `HIVE_LOCAL_STORAGE_MIGRATION.md` - How to implement device storage
- `SUPABASE_TABLE_MIGRATIONS.md` - SQL migrations for proper tables
- `STORAGE_RECOMMENDATIONS.md` - This file (recommendations)

**Next Steps:**
1. Review all files
2. Start with Phase 1 (Critical Fixes)
3. Test each migration thoroughly
4. Deploy incrementally

**Questions to Ask:**
- Do I need offline support? → Use device storage cache
- Does admin need to see this? → Use Supabase tables
- Is this user preference? → Use device storage
- Does this need to sync? → Use Supabase tables

---

## 💬 Decision Guide

```
Is this core business data?
├─ Yes → Supabase Table
└─ No
    ├─ Does it need to sync across devices?
    │   ├─ Yes → Supabase Table
    │   └─ No
    │       ├─ Is it a user preference?
    │       │   ├─ Yes → Device Storage (Hive)
    │       │   └─ No
    │       │       ├─ Is it a file/image?
    │       │       │   ├─ Yes → Supabase Storage (Bucket)
    │       │       │   └─ No → Device Storage (Hive)
```

---

**Good luck with your migration! 🚀**
