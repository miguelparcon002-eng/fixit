# Home Screen Exact Code Changes

## STATUS: Ready to Apply

I've analyzed the current home_screen.dart file (1455 lines) and prepared exact changes.

---

## ✅ COMPLETED CHANGES

1. ✅ Added AddressesScreen import (line 14)
2. ✅ Fixed VoucherService usage in _checkProfileSetup (now uses userId parameter)

---

## 🔄 REMAINING CHANGES TO APPLY

### Change #3: Convert to CustomScrollView (Lines 211-343)

**Current Structure:**
```dart
return Scaffold(
  backgroundColor: AppTheme.primaryCyan,
  body: SafeArea(
    bottom: false,
    child: Column(
      children: [
        // Header Container (lines 218-321)
        Container(...),
        // Expanded with SingleChildScrollView (lines 323-847)
        Expanded(
          child: Container(
            child: SingleChildScrollView(...),
          ),
        ),
      ],
    ),
  ),
);
```

**New Structure:**
```dart
return Scaffold(
  backgroundColor: AppTheme.primaryCyan,
  body: CustomScrollView(
    slivers: [
      // Header - Now scrollable
      SliverToBoxAdapter(
        child: Container(...), // Same header code
      ),
      // Main Content - Now in sliver list
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // All content widgets here
          ]),
        ),
      ),
    ],
  ),
);
```

**Action:** This is a structural change - needs careful editing

---

### Change #4: Add onTap to Active Orders Card (Around line 343)

**Find:**
```dart
Expanded(
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shopping_bag,
            color: AppTheme.lightBlue,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          activeOrdersCount.toString(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const Text(
          'Active Orders',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    ),
  ),
),
```

**Wrap with GestureDetector:**
```dart
Expanded(
  child: GestureDetector(  // ADD THIS
    onTap: () => context.push('/bookings'),  // ADD THIS
    child: Container(
      // ... rest stays the same
    ),
  ),  // CLOSE GestureDetector
),
```

---

### Change #5: Add onTap to Saved Addresses Card (Around line 391)

**Find** the second stat card (Saved Addresses) and wrap similarly:
```dart
Expanded(
  child: GestureDetector(  // ADD THIS
    onTap: () => Navigator.push(  // ADD THIS
      context,
      MaterialPageRoute(builder: (_) => const AddressesScreen()),
    ),
    child: Container(
      // ... existing Saved Addresses card code
    ),
  ),
),
```

---

### Change #6: Remove "More Service" Card (Around line 556)

**Find** (should be 4 service cards in 2 rows):
```dart
// Service Categories
Row(
  children: [
    Expanded(flex: 1, child: _CategoryCard(...)), // Emergency
    const SizedBox(width: 12),
    Expanded(flex: 1, child: _CategoryCard(...)), // Same Day
  ],
),
const SizedBox(height: 12),
Row(
  children: [
    Expanded(flex: 1, child: _CategoryCard(...)), // A Week
    const SizedBox(width: 12),
    Expanded(flex: 1, child: _CategoryCard(...)), // More Service <- REMOVE
  ],
),
```

**Replace with** (3 cards in 1 row):
```dart
// Service Categories
Row(
  children: [
    Expanded(child: _CategoryCard(...)), // Emergency
    const SizedBox(width: 12),
    Expanded(child: _CategoryCard(...)), // Same Day
    const SizedBox(width: 12),
    Expanded(child: _CategoryCard(...)), // Scheduled
  ],
),
```

---

### Change #7: Make Featured Shops Clickable (Around line 574-701)

**Find** `_FeaturedShopCard` widget class (around line 1121) and wrap the return Container with GestureDetector:

```dart
class _FeaturedShopCard extends StatelessWidget {
  // ... constructor and properties

  @override
  Widget build(BuildContext context) {
    return GestureDetector(  // ADD THIS
      onTap: () {  // ADD THIS
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
                  // Shop name
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: serviceTags.map((s) => Chip(
                      label: Text(s),
                      backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
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
      },  // END onTap
      child: Container(  // EXISTING CARD CODE
        // ... all existing card UI code stays the same
      ),
    );  // END GestureDetector
  }
}
```

---

### Change #8: Replace Quick Actions (Lines 704-770)

**Find** the Quick Actions section with 3 cards:
- Book Repair
- Track Order
- Support

**Replace** with only Support card:

```dart
// Quick Actions Header
const Row(
  children: [
    Icon(Icons.flash_on, color: Colors.black, size: 20),
    SizedBox(width: 8),
    Text(
      'Need Help?',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  ],
),
const SizedBox(height: 16),
// ONLY Support Card
_ModernQuickActionCard(
  title: 'Customer Support',
  subtitle: 'Chat with our support team',
  icon: Icons.support_agent_rounded,
  gradientColors: const [Color(0xFFFF6B9D), Color(0xFFC73866)],
  onTap: () => context.push('/help-support'),
),
```

---

### Change #9: Simplify Recent Orders (Lines 884-1047)

**In `_buildRecentOrdersContent` method**, find the order card widget (around line 943) and replace with simpler version:

**Add helper method at top of `_buildRecentOrdersContent`:**
```dart
String getDeviceInfo(BookingModel booking) {
  if (booking.diagnosticNotes == null) return 'No details';

  final notes = booking.diagnosticNotes!;
  final deviceMatch = RegExp(r'Device: (.+)').firstMatch(notes);
  final modelMatch = RegExp(r'Model: (.+)').firstMatch(notes);

  if (deviceMatch != null && modelMatch != null) {
    final device = deviceMatch.group(1)?.trim() ?? '';
    final model = modelMatch.group(1)?.trim() ?? '';
    return '$device - $model';
  } else if (deviceMatch != null) {
    return deviceMatch.group(1)!.trim();
  }

  return 'No details';
}
```

**Replace order card widget:**
```dart
Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[200]!, width: 1),
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
      // Device info and short ID
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getDeviceInfo(booking),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '#${booking.id.substring(0, 8)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
      // Status badge and price
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
)
```

---

## Summary of Changes

| # | Change | Status | Complexity |
|---|--------|--------|------------|
| 1 | Add AddressesScreen import | ✅ Done | Easy |
| 2 | Fix VoucherService usage | ✅ Done | Easy |
| 3 | Convert to CustomScrollView | ⏳ TODO | Hard |
| 4 | Add Active Orders navigation | ⏳ TODO | Easy |
| 5 | Add Addresses navigation | ⏳ TODO | Easy |
| 6 | Remove More Service card | ⏳ TODO | Easy |
| 7 | Make shops clickable | ⏳ TODO | Medium |
| 8 | Replace quick actions | ⏳ TODO | Easy |
| 9 | Simplify recent orders | ⏳ TODO | Medium |

---

## Implementation Plan

Due to file size (1455 lines), I recommend:

1. **Apply easy changes first** (#4, #5, #6, #8) - Can use Edit tool
2. **Then medium changes** (#7, #9) - Need careful editing
3. **Finally the big change** (#3) - May need to rewrite build method

**Estimated Time:** 20-30 minutes total
