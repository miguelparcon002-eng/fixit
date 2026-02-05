# Part 1: Migrate to TRUE Local Storage (Hive on Device)

## Overview
Currently, `StorageService` stores data in Supabase's `local_storage` table. To use **true device-local storage**, we'll use Hive (already in `pubspec.yaml`).

## When to Use Device-Local Storage

**✅ Good Use Cases:**
- User preferences (theme, language)
- Cache for offline access
- Draft/unsaved work
- Session tokens (with encryption)
- Recently viewed items
- UI state (selected tab, filters)

**❌ Bad Use Cases:**
- Primary data storage (bookings, addresses)
- Data that needs sync across devices
- Data that needs backup
- Sensitive user data without encryption

---

## Implementation Guide

### Step 1: Create True Local Storage Service

Create `lib/services/device_storage_service.dart`:

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

/// Service for TRUE local device storage using Hive
/// This data stays on device and doesn't sync to Supabase
class DeviceStorageService {
  static const String _boxName = 'fixit_local_data';
  static Box? _box;

  /// Initialize Hive storage
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    print('DeviceStorageService: Initialized with ${_box!.length} keys');
  }

  /// Get the box instance
  static Box get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('DeviceStorageService not initialized. Call init() first.');
    }
    return _box!;
  }

  // ===== GENERIC METHODS =====

  /// Save string data
  static Future<void> saveString(String key, String value) async {
    await box.put(key, value);
    print('DeviceStorage: Saved string to "$key"');
  }

  /// Load string data
  static String? loadString(String key) {
    final value = box.get(key) as String?;
    print('DeviceStorage: Loaded string from "$key": ${value != null ? "found" : "not found"}');
    return value;
  }

  /// Save JSON-serializable data
  static Future<void> saveJson(String key, Map<String, dynamic> json) async {
    final jsonString = jsonEncode(json);
    await box.put(key, jsonString);
    print('DeviceStorage: Saved JSON to "$key"');
  }

  /// Load JSON data
  static Map<String, dynamic>? loadJson(String key) {
    final jsonString = box.get(key) as String?;
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('DeviceStorage: Error parsing JSON from "$key": $e');
      return null;
    }
  }

  /// Save list of JSON objects
  static Future<void> saveJsonList(String key, List<Map<String, dynamic>> list) async {
    final jsonString = jsonEncode(list);
    await box.put(key, jsonString);
    print('DeviceStorage: Saved JSON list to "$key" (${list.length} items)');
  }

  /// Load list of JSON objects
  static List<Map<String, dynamic>>? loadJsonList(String key) {
    final jsonString = box.get(key) as String?;
    if (jsonString == null) return null;
    
    try {
      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('DeviceStorage: Error parsing JSON list from "$key": $e');
      return null;
    }
  }

  /// Save boolean
  static Future<void> saveBool(String key, bool value) async {
    await box.put(key, value);
  }

  /// Load boolean
  static bool? loadBool(String key) {
    return box.get(key) as bool?;
  }

  /// Save integer
  static Future<void> saveInt(String key, int value) async {
    await box.put(key, value);
  }

  /// Load integer
  static int? loadInt(String key) {
    return box.get(key) as int?;
  }

  /// Save double
  static Future<void> saveDouble(String key, double value) async {
    await box.put(key, value);
  }

  /// Load double
  static double? loadDouble(String key) {
    return box.get(key) as double?;
  }

  /// Delete data
  static Future<void> delete(String key) async {
    await box.delete(key);
    print('DeviceStorage: Deleted "$key"');
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return box.containsKey(key);
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await box.clear();
    print('DeviceStorage: Cleared all data');
  }

  /// Get all keys
  static List<String> getAllKeys() {
    return box.keys.cast<String>().toList();
  }

  // ===== USER-SPECIFIC METHODS =====

  static String? _currentUserId;

  /// Set current user context
  static void setCurrentUser(String? userId) {
    _currentUserId = userId;
    print('DeviceStorage: User context set to ${userId ?? "none"}');
  }

  /// Get user-specific key
  static String _getUserKey(String baseKey) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return baseKey; // Global key if no user
    }
    return '${_currentUserId}_$baseKey';
  }

  /// Save user-specific data
  static Future<void> saveUserData(String key, String value) async {
    await saveString(_getUserKey(key), value);
  }

  /// Load user-specific data
  static String? loadUserData(String key) {
    return loadString(_getUserKey(key));
  }

  /// Delete user-specific data
  static Future<void> deleteUserData(String key) async {
    await delete(_getUserKey(key));
  }

  /// Clear all data for current user
  static Future<void> clearCurrentUserData() async {
    if (_currentUserId == null) return;

    final keysToDelete = box.keys
        .cast<String>()
        .where((key) => key.startsWith('${_currentUserId}_'))
        .toList();

    for (final key in keysToDelete) {
      await box.delete(key);
    }
    print('DeviceStorage: Cleared ${keysToDelete.length} keys for user $_currentUserId');
  }

  // ===== SPECIFIC USE CASES =====

  /// Save user preferences
  static Future<void> savePreferences(Map<String, dynamic> prefs) async {
    await saveJson('app_preferences', prefs);
  }

  /// Load user preferences
  static Map<String, dynamic>? loadPreferences() {
    return loadJson('app_preferences');
  }

  /// Save cached profile data for offline access
  static Future<void> saveCachedProfile(String userId, Map<String, dynamic> profile) async {
    await saveJson('cached_profile_$userId', profile);
  }

  /// Load cached profile
  static Map<String, dynamic>? loadCachedProfile(String userId) {
    return loadJson('cached_profile_$userId');
  }

  /// Save draft booking (unsaved work)
  static Future<void> saveDraftBooking(Map<String, dynamic> draft) async {
    await saveJson('draft_booking', draft);
  }

  /// Load draft booking
  static Map<String, dynamic>? loadDraftBooking() {
    return loadJson('draft_booking');
  }

  /// Clear draft booking
  static Future<void> clearDraftBooking() async {
    await delete('draft_booking');
  }

  /// Save recently viewed items
  static Future<void> saveRecentlyViewed(List<String> itemIds) async {
    await saveString('recently_viewed', jsonEncode(itemIds));
  }

  /// Load recently viewed items
  static List<String> loadRecentlyViewed() {
    final jsonString = loadString('recently_viewed');
    if (jsonString == null) return [];
    
    try {
      return List<String>.from(jsonDecode(jsonString));
    } catch (e) {
      return [];
    }
  }

  /// Save onboarding completion status
  static Future<void> setOnboardingComplete(bool complete) async {
    await saveBool('onboarding_complete', complete);
  }

  /// Check if onboarding is complete
  static bool isOnboardingComplete() {
    return loadBool('onboarding_complete') ?? false;
  }

  /// Save last sync timestamp
  static Future<void> saveLastSyncTime(DateTime time) async {
    await saveString('last_sync', time.toIso8601String());
  }

  /// Get last sync timestamp
  static DateTime? getLastSyncTime() {
    final timeString = loadString('last_sync');
    if (timeString == null) return null;
    
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }
}
```

---

### Step 2: Update main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize device-local storage (Hive)
  await DeviceStorageService.init();
  print('=== Device Storage initialized ===');

  // Initialize Supabase cloud storage
  await StorageService.init();
  print('=== Cloud Storage initialized ===');

  await SupabaseConfig.initialize();

  // ... rest of main
}
```

---

### Step 3: Migration Strategy

**Data to move to device-local storage:**

#### 1. User Preferences (theme, language, etc.)
```dart
// Instead of Supabase
await DeviceStorageService.savePreferences({
  'theme': 'dark',
  'language': 'en',
  'notifications_enabled': true,
  'map_style': 'standard',
});

// Load
final prefs = DeviceStorageService.loadPreferences() ?? {};
final theme = prefs['theme'] ?? 'light';
```

#### 2. Draft Bookings (unsaved work)
```dart
// Save draft before user submits
await DeviceStorageService.saveDraftBooking({
  'service_id': serviceId,
  'scheduled_date': scheduledDate.toIso8601String(),
  'address': address,
  'notes': notes,
});

// Load when user returns
final draft = DeviceStorageService.loadDraftBooking();
if (draft != null) {
  // Pre-fill form with draft data
}

// Clear after successful submission
await DeviceStorageService.clearDraftBooking();
```

#### 3. Cached Data for Offline (read-only cache)
```dart
// Cache profile when online
await DeviceStorageService.saveCachedProfile(userId, profileData);

// Load when offline
final cachedProfile = DeviceStorageService.loadCachedProfile(userId);
if (cachedProfile != null) {
  // Use cached data
}
```

#### 4. Recently Viewed/Search History
```dart
// Add to recent
final recent = DeviceStorageService.loadRecentlyViewed();
recent.insert(0, serviceId);
if (recent.length > 10) recent.removeLast(); // Keep only 10
await DeviceStorageService.saveRecentlyViewed(recent);

// Display recent
final recentServices = DeviceStorageService.loadRecentlyViewed();
```

#### 5. Onboarding/First-time flags
```dart
// Check if user has seen onboarding
if (!DeviceStorageService.isOnboardingComplete()) {
  // Show onboarding screens
  await showOnboarding();
  await DeviceStorageService.setOnboardingComplete(true);
}
```

---

### Step 4: Update User Session Service

```dart
class UserSessionService {
  final Ref _ref;

  UserSessionService(this._ref);

  Future<void> onUserLogin(String userId) async {
    print('UserSessionService: User logged in - $userId');

    // Set context for both storages
    StorageService.setCurrentUser(userId); // Cloud storage
    DeviceStorageService.setCurrentUser(userId); // Device storage

    await _reloadAllUserData();
  }

  Future<void> onUserLogout() async {
    print('UserSessionService: User logged out');

    // Clear cloud storage context
    StorageService.setCurrentUser(null);
    
    // Clear device storage context
    DeviceStorageService.setCurrentUser(null);
    
    // Optionally clear device cache (keep preferences)
    // await DeviceStorageService.clearCurrentUserData();

    _invalidateAllProviders();
  }

  Future<void> onUserSignup(String userId) async {
    print('UserSessionService: New user signed up - $userId');

    StorageService.setCurrentUser(userId);
    DeviceStorageService.setCurrentUser(userId);

    _invalidateAllProviders();
  }
}
```

---

## ⚠️ Important Considerations

### Security
```dart
// For sensitive data, use encrypted box
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Generate encryption key
final secureStorage = FlutterSecureStorage();
var encryptionKey = await secureStorage.read(key: 'hive_encryption_key');
if (encryptionKey == null) {
  final key = Hive.generateSecureKey();
  await secureStorage.write(
    key: 'hive_encryption_key',
    value: base64UrlEncode(key),
  );
}

// Open encrypted box
final key = base64Url.decode(encryptionKey!);
final encryptedBox = await Hive.openBox('secure_data', 
  encryptionCipher: HiveAesCipher(key)
);
```

### Data Persistence
- Device storage is **not backed up** automatically (unless user enables device backup)
- User uninstalling app = data loss
- Use for non-critical data only
- Critical data should be in Supabase

### Cross-Device Sync
- Device storage doesn't sync across devices
- User on multiple devices will have different local data
- For sync, use Supabase as source of truth

### Storage Limits
- Hive has no hard limit but consider:
  - **Mobile**: Keep under 10MB for performance
  - Don't store images/large files
  - Clean up old data regularly
  - Use for metadata, not binary data

### Performance
- Hive is fast for small to medium data
- For large lists, consider pagination
- Index frequently accessed data

---

## Migration Checklist

- [ ] Create `lib/services/device_storage_service.dart`
- [ ] Initialize `DeviceStorageService` in `main.dart`
- [ ] Move user preferences to device storage
- [ ] Implement draft booking save/restore
- [ ] Add offline cache layer for profiles
- [ ] Implement recently viewed tracking
- [ ] Add onboarding completion flag
- [ ] Update `UserSessionService` for dual storage
- [ ] Test on iOS and Android
- [ ] Test data persistence after app restart
- [ ] Test data isolation between users
- [ ] Test app uninstall/reinstall (data loss)
- [ ] Clean up old Supabase `local_storage` keys
- [ ] Document which data is local vs cloud

---

## Example: Complete Preferences System

Create `lib/services/preferences_service.dart`:

```dart
import 'device_storage_service.dart';

class PreferencesService {
  // Theme preferences
  static Future<void> setThemeMode(String mode) async {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    prefs['theme_mode'] = mode;
    await DeviceStorageService.savePreferences(prefs);
  }

  static String getThemeMode() {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    return prefs['theme_mode'] ?? 'system';
  }

  // Notification preferences
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    prefs['notifications_enabled'] = enabled;
    await DeviceStorageService.savePreferences(prefs);
  }

  static bool getNotificationsEnabled() {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    return prefs['notifications_enabled'] ?? true;
  }

  // Language preference
  static Future<void> setLanguage(String languageCode) async {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    prefs['language'] = languageCode;
    await DeviceStorageService.savePreferences(prefs);
  }

  static String getLanguage() {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    return prefs['language'] ?? 'en';
  }

  // Map style preference
  static Future<void> setMapStyle(String style) async {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    prefs['map_style'] = style;
    await DeviceStorageService.savePreferences(prefs);
  }

  static String getMapStyle() {
    final prefs = DeviceStorageService.loadPreferences() ?? {};
    return prefs['map_style'] ?? 'standard';
  }

  // Reset all preferences
  static Future<void> resetToDefaults() async {
    await DeviceStorageService.savePreferences({
      'theme_mode': 'system',
      'notifications_enabled': true,
      'language': 'en',
      'map_style': 'standard',
    });
  }
}
```

---

## Testing Device Storage

```dart
// Test file: test/device_storage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  setUp(() async {
    await Hive.initFlutter();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('Save and load string', () async {
    await DeviceStorageService.init();
    await DeviceStorageService.saveString('test_key', 'test_value');
    final value = DeviceStorageService.loadString('test_key');
    expect(value, 'test_value');
  });

  test('User context isolation', () async {
    await DeviceStorageService.init();
    
    DeviceStorageService.setCurrentUser('user1');
    await DeviceStorageService.saveUserData('key', 'value1');
    
    DeviceStorageService.setCurrentUser('user2');
    await DeviceStorageService.saveUserData('key', 'value2');
    
    DeviceStorageService.setCurrentUser('user1');
    expect(DeviceStorageService.loadUserData('key'), 'value1');
    
    DeviceStorageService.setCurrentUser('user2');
    expect(DeviceStorageService.loadUserData('key'), 'value2');
  });
}
```
