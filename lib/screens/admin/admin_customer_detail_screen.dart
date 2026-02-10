import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../core/widgets/app_logo.dart';

class AdminCustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const AdminCustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState
    extends ConsumerState<AdminCustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(customerByIdProvider(widget.customerId));
    final bookingHistoryAsync = ref.watch(
      customerBookingHistoryProvider(widget.customerId),
    );

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Row(
            children: [
              const AppLogo(size: 30, showText: false, assetPath: 'assets/images/logo_square.png'),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Customer Details',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              titleSpacing: 16,
              title: const AppLogo(
                size: 28,
                showText: false,
                textColor: Colors.white,
                assetPath: 'assets/images/logo_square.png',
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.deepBlue,
                        AppTheme.deepBlue.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          // Avatar with status
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    customer.profileImageUrl != null
                                    ? NetworkImage(customer.profileImageUrl!)
                                    : null,
                                child: customer.profileImageUrl == null
                                    ? Text(
                                        customer.name.isNotEmpty
                                            ? customer.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.deepBlue,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: customer.isCurrentlyActive
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                customer,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              customer.activityStatus,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(customer),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleMenuAction(value, customer),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Suspend Customer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Activate Customer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.deepBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.deepBlue,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Bookings'),
                    Tab(text: 'Contact'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Overview Tab
            _buildOverviewTab(customer),
            // Bookings Tab
            _buildBookingsTab(bookingHistoryAsync),
            // Contact Tab
            _buildContactTab(customer),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CustomerModel customer) {
    if (customer.status == CustomerStatus.suspended) return Colors.red;
    if (customer.isCurrentlyActive) return Colors.green;
    return Colors.grey;
  }

  void _handleMenuAction(String action, CustomerModel customer) {
    if (action == 'suspend') {
      _showSuspendDialog(customer);
    } else if (action == 'activate') {
      ref
          .read(customersProvider.notifier)
          .updateCustomerStatus(customer.id, CustomerStatus.active);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer activated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSuspendDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Suspend Customer'),
        content: Text(
          'Are you sure you want to suspend ${customer.name}? They will not be able to use the app until reactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(customersProvider.notifier)
                  .updateCustomerStatus(customer.id, CustomerStatus.suspended);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Customer suspended'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(CustomerModel customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today,
                  label: 'Total Bookings',
                  value: '${customer.totalBookings}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: '${customer.completedBookings}',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.cancel,
                  label: 'Cancelled',
                  value: '${customer.cancelledBookings}',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money,
                  label: 'Total Spent',
                  value: '\$${customer.totalSpent.toStringAsFixed(2)}',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Account Info
          _SectionCard(
            title: 'Account Information',
            children: [
              _InfoRow(
                icon: Icons.person,
                label: 'Customer ID',
                value: customer.id,
              ),
              _InfoRow(
                icon: Icons.calendar_month,
                label: 'Member Since',
                value: DateFormat('MMMM d, yyyy').format(customer.createdAt),
              ),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Last Active',
                value: customer.lastActiveAt != null
                    ? DateFormat(
                        'MMM d, yyyy h:mm a',
                      ).format(customer.lastActiveAt!)
                    : 'Never',
              ),
              _InfoRow(
                icon: Icons.verified_user,
                label: 'Account Status',
                value: customer.status.name.toUpperCase(),
                valueColor: customer.status == CustomerStatus.suspended
                    ? Colors.red
                    : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab(
    AsyncValue<List<CustomerBookingHistory>> bookingHistoryAsync,
  ) {
    return bookingHistoryAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No booking history',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This customer has not made any bookings yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingHistoryCard(booking: booking);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Error loading bookings: $error')),
    );
  }

  Widget _buildContactTab(CustomerModel customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: 'Contact Information',
            children: [
              _ContactRow(
                icon: Icons.email,
                label: 'Email',
                value: customer.email,
                onTap: () {
                  // Could launch email
                },
              ),
              if (customer.phone != null)
                _ContactRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: customer.phone!,
                  onTap: () {
                    // Could launch phone
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (customer.addresses.isNotEmpty)
            _SectionCard(
              title: 'Saved Addresses',
              children: customer.addresses
                  .map(
                    (address) => _ContactRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: address,
                    ),
                  )
                  .toList(),
            ),
          if (customer.addresses.isEmpty)
            _SectionCard(
              title: 'Saved Addresses',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No saved addresses',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.deepBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppTheme.deepBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final CustomerBookingHistory booking;

  const _BookingHistoryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                booking.technicianName,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy - h:mm a').format(booking.bookingDate),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                '\$${booking.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
