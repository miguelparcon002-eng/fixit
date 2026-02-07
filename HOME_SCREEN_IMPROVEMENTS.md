# Customer Home Screen Improvements - Implementation Guide

## Summary of Changes Required

All changes are for: `lib/screens/home/home_screen.dart`

---

## ✅ CHANGE #1: Make Entire Screen Scrollable (Including Upper Part)

**Current Problem:** Header is in a Scaffold appBar or fixed container
**Solution:** Replace Scaffold with CustomScrollView and SliverAppBar/SliverToBoxAdapter

### Find (around line 200-320):
```dart
return Scaffold(
  backgroundColor: AppTheme.primaryCyan,
  body: SafeArea(
    child: Column(
      children: [
        // Header section
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(...),
        ),
        // Main content
        Expanded(
          child: SingleChildScrollView(...),
        ),
      ],
    ),
  ),
);
```

### Replace with:
```dart
return Scaffold(
  backgroundColor: AppTheme.primaryCyan,
  body: CustomScrollView(
    slivers: [
      // Header - Now scrollable
      SliverToBoxAdapter(
        child: Container(
          color: AppTheme.primaryCyan,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            children: [
              // Logo and Notification (keep existing code)
              // Tagline (keep existing code)
              // Search Bar (keep existing code)
            ],
          ),
        ),
      ),

      // Main Content - Now in sliver list
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // All your content here
          ]),
        ),
      ),
    ],
  ),
);
```

---

## ✅ CHANGE #2: Add Navigation to Active Orders Card

**Current Code** (around line 339-388):
```dart
_buildStatCard(
  icon: Icons.shopping_bag,
  count: activeOrdersCount,
  label: 'Active Orders',
  color: AppTheme.lightBlue,
),
```

**Add `onTap`:**
```dart
_buildStatCard(
  icon: Icons.shopping_bag,
  count: activeOrdersCount,
  label: 'Active Orders',
  color: AppTheme.lightBlue,
  onTap: () => context.push('/bookings'), // ADD THIS LINE
),
```

**Update `_buildStatCard` method** (around line 1051):
```dart
Widget _buildStatCard({
  required IconData icon,
  required String count,
  required String label,
  required Color color,
  VoidCallback? onTap, // ADD THIS PARAMETER
}) {
  return GestureDetector( // WRAP WITH GestureDetector
    onTap: onTap, // ADD THIS
    child: Container(
      // ... rest of existing code
    ),
  );
}
```

---

## ✅ CHANGE #3: Add Navigation to Saved Addresses Card

**Current Code** (around line 390-439):
```dart
_buildStatCard(
  icon: Icons.location_on,
  count: savedAddressCount,
  label: 'Saved Addresses',
  color: AppTheme.successColor,
),
```

**Add navigation:**
```dart
_buildStatCard(
  icon: Icons.location_on,
  count: savedAddressCount,
  label: 'Saved Addresses',
  color: AppTheme.successColor,
  onTap: () => Navigator.push( // ADD THESE LINES
    context,
    MaterialPageRoute(builder: (_) => const AddressesScreen()),
  ),
),
```

**Add import at top:**
```dart
import '../profile/addresses_screen.dart'; // ADD THIS
```

---

## ✅ CHANGE #4: Remove "More Service" Card

**Find the 4th service card** (around line 556-569):
```dart
_buildCategoryCard(
  icon: Icons.more_horiz,
  iconColor: const Color(0xFF66BB6A),
  title: 'More Service',
  subtitle: 'Available /Accessible',
  onTap: () { ... },
),
```

**DELETE IT COMPLETELY** - Keep only 3 cards:
1. Emergency Repair
2. Same Day
3. A Week (or rename to "Scheduled")

**Update the Row** (line 504):
```dart
// OLD: 4 cards in 2x2 grid
Row(
  children: [
    Expanded(flex: 1, child: _buildCategoryCard(...)), // Emergency
    const SizedBox(width: 12),
    Expanded(flex: 1, child: _buildCategoryCard(...)), // Same Day
  ],
),
const SizedBox(height: 12),
Row(
  children: [
    Expanded(flex: 1, child: _buildCategoryCard(...)), // A Week
    const SizedBox(width: 12),
    Expanded(flex: 1, child: _buildCategoryCard(...)), // More Service - REMOVE THIS
  ],
),

// NEW: 3 cards in single row
Row(
  children: [
    Expanded(
      child: _buildCategoryCard(...), // Emergency
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildCategoryCard(...), // Same Day
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildCategoryCard(...), // Scheduled
    ),
  ],
),
```

---

## ✅ CHANGE #5: Make Featured Shops Clickable with Details

**Find `_FeaturedShopCard`** (around line 1121-1379):

**Wrap the entire card with GestureDetector:**
```dart
Widget _buildFeaturedShopCard(...) {
  return GestureDetector( // ADD THIS
    onTap: () {
      // Show shop details dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop name with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Owner: $ownerName'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Rating and distance
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text('$rating'),
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, color: AppTheme.lightBlue, size: 20),
                    const SizedBox(width: 4),
                    Text(distance),
                  ],
                ),
                const SizedBox(height: 12),
                // Services
                const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: services.map((s) => Chip(
                    label: Text(s),
                    backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                // Hours
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'Open now' : 'Closed',
                      style: TextStyle(
                        color: isOpen ? AppTheme.successColor : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Book button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const BookingDialog(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Book Repair', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }, // END OF onTap
    child: Container( // EXISTING CARD CODE
      // ... all existing card code
    ),
  ); // END OF GestureDetector
}
```

---

## ✅ CHANGE #6: Replace Quick Actions (Keep Only Support)

**Find Quick Actions section** (lines 704-770):

**Replace with:**
```dart
// Quick Actions - ONLY SUPPORT
const Row(
  children: [
    Icon(Icons.flash_on, color: AppTheme.textPrimaryColor, size: 20),
    SizedBox(width: 8),
    Text(
      'Need Help?',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    ),
  ],
),
const SizedBox(height: 12),
_ModernQuickActionCard(
  title: 'Customer Support',
  subtitle: 'Chat with our support team',
  icon: Icons.support_agent_rounded,
  gradientColors: const [Color(0xFFFF6B9D), Color(0xFFC73866)],
  onTap: () => context.push('/help-support'),
),
```

**Remove:**
- "Book Repair" card
- "Track Order" card
- Keep only "Support" card

---

## ✅ CHANGE #7: Simplify Recent Orders Code

**Find `_buildRecentOrdersContent` method** (lines 884-1047):

**Replace the order card section** (lines 943-1044) with this simpler version:
```dart
return Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[200]!),
  ),
  child: Row(
    children: [
      // Icon with status color
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.build, color: statusColor, size: 20),
      ),
      const SizedBox(width: 12),
      // Details
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deviceInfo, // Device + Model
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#${booking.id.substring(0, 8)}', // SHORT ID
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
      // Status and price
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              booking.status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₱${(booking.finalCost ?? booking.estimatedCost ?? 0).toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    ],
  ),
);
```

---

## ✅ CHANGE #8: Extract Device Info from Diagnostic Notes

**Add this method** at the top of `_buildRecentOrdersContent`:
```dart
String getDeviceInfo(BookingModel booking) {
  if (booking.diagnosticNotes == null) return 'No details';

  final notes = booking.diagnosticNotes!;
  final deviceMatch = RegExp(r'Device: (.+)').firstMatch(notes);
  final modelMatch = RegExp(r'Model: (.+)').firstMatch(notes);

  if (deviceMatch != null && modelMatch != null) {
    return '${deviceMatch.group(1)} - ${modelMatch.group(1)}';
  } else if (deviceMatch != null) {
    return deviceMatch.group(1)!;
  }

  return 'No details';
}
```

**Then use it in the card:**
```dart
Text(
  getDeviceInfo(booking), // Instead of booking.serviceId or serviceName
  style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  ),
),
```

---

## 📝 Summary of All Changes

| # | Change | Lines | Status |
|---|--------|-------|--------|
| 1 | Make screen scrollable (CustomScrollView) | 200-320 | Critical |
| 2 | Add Active Orders navigation | 339-388 | Easy |
| 3 | Add Saved Addresses navigation | 390-439 | Easy |
| 4 | Remove "More Service" card | 556-569 | Easy |
| 5 | Make shops clickable with details | 1121-1379 | Medium |
| 6 | Replace quick actions (keep Support) | 704-770 | Easy |
| 7 | Simplify recent orders | 943-1044 | Medium |
| 8 | Show device + model in orders | Add method | Easy |

---

## Testing Checklist

After making changes:

- [ ] Screen scrolls smoothly (including header)
- [ ] Tapping "Active Orders" goes to `/bookings`
- [ ] Tapping "Saved Addresses" opens AddressesScreen
- [ ] Only 3 service cards show (Emergency, Same Day, Scheduled)
- [ ] Tapping a featured shop shows details dialog
- [ ] Only Support quick action shows
- [ ] Recent orders show device + model
- [ ] Order IDs are shortened (first 8 chars)
- [ ] No errors in console

---

## Quick Implementation Order

1. **Start with easy changes first:**
   - Add navigation to cards (#2, #3)
   - Remove More Service (#4)
   - Replace quick actions (#6)

2. **Then medium changes:**
   - Simplify recent orders (#7, #8)
   - Make shops clickable (#5)

3. **Finally the big change:**
   - Convert to CustomScrollView (#1)

This way you can test incrementally!

---

**Estimated Time:** 30-45 minutes for all changes

**File Backup:** Already created at `lib/screens/home/home_screen_old_backup.dart`
