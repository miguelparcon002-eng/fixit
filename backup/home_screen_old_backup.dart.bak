import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/voucher_provider.dart';
import '../../models/booking_model.dart';
import '../../services/voucher_service.dart' show Voucher;
import '../booking/widgets/booking_dialog.dart';
import '../services/services_list_screen.dart';
import '../profile/rewards_screen.dart';
import 'profile_setup_dialog.dart';

// Provider to track if promo has been claimed
final promoClaimedProvider = StateProvider<bool>((ref) => false);

// Provider to track if setup dialog has been shown this session
final setupDialogShownProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check for profile setup after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileSetup();
      // Reward points are automatically calculated from Supabase bookings
    });
  }

  // Reward points are now automatically calculated from Supabase bookings
  // No need to manually sync

  Future<void> _checkProfileSetup() async {
    // Don't show dialog if already shown this session
    if (ref.read(setupDialogShownProvider)) return;

    final voucherService = ref.read(voucherServiceProvider);
    final isSetupComplete = await voucherService.isProfileSetupComplete();

    if (!isSetupComplete && mounted) {
      // Mark as shown for this session
      ref.read(setupDialogShownProvider.notifier).state = true;

      // Show the profile setup dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProfileSetupDialog(
          onComplete: () {
            // Refresh vouchers after setup
            ref.invalidate(voucherNotifierProvider);
            ref.invalidate(validVouchersProvider);
          },
        ),
      );
    }
  }

  Widget _buildWelcomeVoucherCard(Voucher voucher) {
    final daysLeft = voucher.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Welcome Reward!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$daysLeft days left',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            voucher.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            voucher.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.confirmation_number,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Code: ${voucher.code}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedAddressCount = ref.watch(savedAddressCountProvider);
    final rewardPointsAsync = ref.watch(rewardPointsProvider);
    // Use proper Supabase bookings table
    final bookingsAsync = ref.watch(customerBookingsProvider);
    final validVouchersAsync = ref.watch(validVouchersProvider);

    // Count active orders (only In Progress)
    final activeOrdersCount = bookingsAsync.maybeWhen(
      data: (bookings) => bookings.where((booking) => booking.status == 'in_progress').length,
      orElse: () => 0,
    );

    // Check if there are valid vouchers to display
    final validVouchers = validVouchersAsync.valueOrNull ?? [];
    final hasWelcomeVoucher = validVouchers.any((v) => v.code == 'WELCOME20');

    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Cyan header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryCyan,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/images/logo_gears.png',
                              width: 50,
                              height: 50,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.build_circle,
                                  size: 50,
                                  color: Colors.black,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'FixIT',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, color: Colors.black, size: 28),
                            onPressed: () => context.push('/notifications'),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: const Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ask any question regarding to our business',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for help...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Cyan content section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryCyan,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Voucher Card - shows when user has earned the voucher
                        if (hasWelcomeVoucher) ...[
                          _buildWelcomeVoucherCard(validVouchers.firstWhere((v) => v.code == 'WELCOME20')),
                          const SizedBox(height: 24),
                        ],

                        // Stats Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        color: AppTheme.lightBlue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '$activeOrdersCount',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Active Orders',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: AppTheme.successColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '$savedAddressCount',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Saved Addresses',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RewardsScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.warningColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          color: AppTheme.warningColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${rewardPointsAsync.valueOrNull ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Reward Points',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Service Category Cards
                        Row(
                          children: [
                            Expanded(
                              child: _CategoryCard(
                                icon: Icons.bolt,
                                title: 'Emergency Repair',
                                subtitle: '24/7 Service',
                                color: const Color(0xFFFF6B6B),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const BookingDialog(isEmergency: true),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CategoryCard(
                                icon: Icons.access_time,
                                title: 'Same Day',
                                subtitle: 'Quick Fix',
                                color: const Color(0xFF4ECDC4),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const BookingDialog(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CategoryCard(
                                icon: Icons.calendar_today,
                                title: 'A Week',
                                subtitle: 'More time, Less hassle',
                                color: const Color(0xFF9B59B6),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const BookingDialog(isWeekBooking: true),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CategoryCard(
                                icon: Icons.more_horiz,
                                title: 'More Service',
                                subtitle: 'Available /Accessible',
                                color: const Color(0xFF66BB6A),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ServicesListScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Featured Shops
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Featured Shops',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'San Francisco',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Featured Shop Cards (Horizontal Scroll)
                        SizedBox(
                          height: 215,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              const _FeaturedShopCard(
                                shopName: 'TechFix Hub',
                                ownerName: 'Juan Dela Cruz',
                                rating: 4.8,
                                reviewCount: 156,
                                services: ['Laptops', 'Phones', 'Tablets'],
                                distance: '0.5 km',
                                isOpen: true,
                                openTime: '8 AM - 8 PM',
                                gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                isFeatured: true,
                              ),
                              const SizedBox(width: 16),
                              const _FeaturedShopCard(
                                shopName: 'Mobile Masters',
                                ownerName: 'Maria Santos',
                                rating: 4.6,
                                reviewCount: 98,
                                services: ['Phones', 'Accessories'],
                                distance: '1.2 km',
                                isOpen: true,
                                openTime: '9 AM - 7 PM',
                                gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                                isFeatured: false,
                              ),
                              const SizedBox(width: 16),
                              const _FeaturedShopCard(
                                shopName: 'Gadget Care Pro',
                                ownerName: 'Pedro Reyes',
                                rating: 4.9,
                                reviewCount: 203,
                                services: ['Laptops', 'Phones', 'Gaming'],
                                distance: '2.0 km',
                                isOpen: false,
                                openTime: 'Opens 9 AM',
                                gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                                isFeatured: true,
                              ),
                              const SizedBox(width: 16),
                              const _FeaturedShopCard(
                                shopName: 'QuickFix Station',
                                ownerName: 'Ana Gonzales',
                                rating: 4.5,
                                reviewCount: 67,
                                services: ['Phones', 'Tablets'],
                                distance: '2.8 km',
                                isOpen: true,
                                openTime: '10 AM - 6 PM',
                                gradientColors: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
                                isFeatured: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Actions
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.flash_on_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ModernQuickActionCard(
                                icon: Icons.build_circle_rounded,
                                label: 'Book Repair',
                                subtitle: 'Schedule now',
                                gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const BookingDialog(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModernQuickActionCard(
                                icon: Icons.track_changes_rounded,
                                label: 'Track Order',
                                subtitle: 'View status',
                                gradientColors: const [Color(0xFF11998e), Color(0xFF38ef7d)],
                                onTap: () => context.push('/bookings'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ModernQuickActionCard(
                                icon: Icons.support_agent_rounded,
                                label: 'Support',
                                subtitle: 'Get help',
                                gradientColors: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                                onTap: () => context.push('/help-support'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Tips & Tricks
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.deepBlue, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.deepBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.lightbulb,
                                  color: AppTheme.deepBlue,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pro Tip!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.deepBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Book repairs during weekdays for faster service and exclusive discounts!',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Recent Orders
                        const Text(
                          'Recent Orders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Recent Orders List
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 100,
                            maxHeight: 600,
                          ),
                          child: _buildRecentOrders(ref),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(WidgetRef ref) {
    // Use proper Supabase bookings table
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading bookings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
      data: (allBookings) => _buildRecentOrdersContent(allBookings),
    );
  }

  Widget _buildRecentOrdersContent(List<BookingModel> allBookings) {
    if (allBookings.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No orders yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show only the 3 most recent bookings
    final recentBookings = allBookings.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: recentBookings.map((booking) {
        Color statusColor;
        String displayStatus;
        switch (booking.status) {
          case 'requested':
          case 'accepted':
          case 'scheduled':
            statusColor = const Color(0xFFFF9800); // Orange
            displayStatus = 'Scheduled';
            break;
          case 'in_progress':
            statusColor = AppTheme.lightBlue;
            displayStatus = 'In Progress';
            break;
          case 'completed':
            statusColor = Colors.green;
            displayStatus = 'Completed';
            break;
          case 'cancelled':
            statusColor = Colors.red;
            displayStatus = 'Cancelled';
            break;
          default:
            statusColor = Colors.grey;
            displayStatus = booking.status;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 150,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              booking.id,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '📱',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayStatus,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Repair Service',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.scheduledDate != null 
                          ? '${booking.scheduledDate!.month}/${booking.scheduledDate!.day}/${booking.scheduledDate!.year}'
                          : 'TBD',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '₱${booking.finalCost?.toStringAsFixed(2) ?? booking.estimatedCost?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Category Card Widget
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Featured Shop Card Widget
class _FeaturedShopCard extends StatelessWidget {
  final String shopName;
  final String ownerName;
  final double rating;
  final int reviewCount;
  final List<String> services;
  final String distance;
  final bool isOpen;
  final String openTime;
  final List<Color> gradientColors;
  final bool isFeatured;

  const _FeaturedShopCard({
    required this.shopName,
    required this.ownerName,
    required this.rating,
    required this.reviewCount,
    required this.services,
    required this.distance,
    required this.isOpen,
    required this.openTime,
    required this.gradientColors,
    required this.isFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shop icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    // Status badge
                    Row(
                      children: [
                        if (isFeatured) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.white, size: 10),
                                SizedBox(width: 2),
                                Text(
                                  'Top',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? const Color(0xFF4CAF50)
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shopName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ownerName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content section
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating and reviews
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($reviewCount)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.location_on_outlined, color: Colors.grey.shade500, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      distance,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Services tags
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: services.map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: gradientColors[0].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: gradientColors[0].withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        service,
                        style: TextStyle(
                          color: gradientColors[0],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                // Operating hours
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.grey.shade500,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      openTime,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Quick Action Card Widget
class _ModernQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ModernQuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
