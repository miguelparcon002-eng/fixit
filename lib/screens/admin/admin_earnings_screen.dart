import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_earnings_provider.dart';

class AdminEarningsScreen extends ConsumerStatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  ConsumerState<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends ConsumerState<AdminEarningsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(adminEarningsOverviewProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        title: const Text(
          'Earnings Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminEarningsOverviewProvider);
              ref.invalidate(allTechniciansEarningsProvider);
              ref.invalidate(allCustomersSpendingProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              Container(height: 1, color: Colors.grey.shade200),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.deepBlue,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                indicatorColor: AppTheme.deepBlue,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Technicians'),
                  Tab(text: 'Customers'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TechniciansEarningsTab(overviewAsync: overviewAsync),
          _CustomersSpendingTab(overviewAsync: overviewAsync),
        ],
      ),
    );
  }
}

class _PlatformMetric extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _PlatformMetric({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _TechniciansEarningsTab extends ConsumerWidget {
  final AsyncValue<dynamic> overviewAsync;

  const _TechniciansEarningsTab({required this.overviewAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techniciansAsync = ref.watch(allTechniciansEarningsProvider);

    return techniciansAsync.when(
      data: (technicians) {
        if (technicians.isEmpty) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.engineering_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No technicians found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allTechniciansEarningsProvider);
            ref.invalidate(adminEarningsOverviewProvider);
            await ref.read(allTechniciansEarningsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tech = technicians[index];
                      return _TechnicianEarningsCard(technician: tech);
                    },
                    childCount: technicians.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (e, _) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading technicians:\n$e',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allTechniciansEarningsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianEarningsCard extends StatelessWidget {
  final dynamic technician;

  const _TechnicianEarningsCard({required this.technician});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/admin-technician-earnings/${technician.technicianId}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: technician.profileImageUrl != null
                          ? NetworkImage(technician.profileImageUrl!)
                          : null,
                      child: technician.profileImageUrl == null
                          ? Text(
                              technician.technicianName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician.technicianName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (technician.averageRating != null) ...[
                                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  technician.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${technician.totalCompletedJobs} jobs',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Earnings:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₱${technician.totalEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Today',
                        value: '₱${technician.todayEarnings.toStringAsFixed(0)}',
                        jobs: technician.todayCompletedJobs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Week',
                        value: '₱${technician.weekEarnings.toStringAsFixed(0)}',
                        jobs: technician.weekCompletedJobs,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Month',
                        value: '₱${technician.monthEarnings.toStringAsFixed(0)}',
                        jobs: technician.monthCompletedJobs,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final int jobs;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.jobs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$jobs job${jobs != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomersSpendingTab extends ConsumerWidget {
  final AsyncValue<dynamic> overviewAsync;

  const _CustomersSpendingTab({required this.overviewAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersSpendingProvider);

    return customersAsync.when(
      data: (customers) {
        if (customers.isEmpty) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No customers found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allCustomersSpendingProvider);
            ref.invalidate(adminEarningsOverviewProvider);
            await ref.read(allCustomersSpendingProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final customer = customers[index];
                      return _CustomerSpendingCard(customer: customer);
                    },
                    childCount: customers.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
      error: (e, _) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PlatformOverviewCard(overviewAsync: overviewAsync)),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading customers:\n$e',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(allCustomersSpendingProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSpendingCard extends StatelessWidget {
  final dynamic customer;

  const _CustomerSpendingCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.deepBlue.withOpacity(0.1),
                child: Text(
                  customer.customerName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer.totalBookings} bookings • ${customer.completedBookings} completed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.deepBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.deepBlue.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments,
                  color: AppTheme.deepBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Total Spent:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '₱${customer.totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CustomerMiniStat(
                  label: 'Today',
                  value: '₱${customer.todaySpent.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMiniStat(
                  label: 'Week',
                  value: '₱${customer.weekSpent.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CustomerMiniStat(
                  label: 'Month',
                  value: '₱${customer.monthSpent.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _CustomerMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformOverviewCard extends StatelessWidget {
  final AsyncValue<dynamic> overviewAsync;

  const _PlatformOverviewCard({required this.overviewAsync});

  @override
  Widget build(BuildContext context) {
    return overviewAsync.when(
      data: (overview) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.deepBlue,
              AppTheme.lightBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Platform Earnings',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.deepBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Total Revenue',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₱${overview.totalEarnings.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${overview.totalCompletedBookings} completed bookings',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _PlatformMetric(
                      label: 'Today',
                      value: '₱${overview.todayEarnings.toStringAsFixed(0)}',
                      subtitle: '${overview.todayCompletedBookings} jobs',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  Expanded(
                    child: _PlatformMetric(
                      label: 'This Week',
                      value: '₱${overview.weekEarnings.toStringAsFixed(0)}',
                      subtitle: '${overview.weekCompletedBookings} jobs',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.25),
                  ),
                  Expanded(
                    child: _PlatformMetric(
                      label: 'This Month',
                      value: '₱${overview.monthEarnings.toStringAsFixed(0)}',
                      subtitle: '${overview.monthCompletedBookings} jobs',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text('Error loading overview: $e'),
      ),
    );
  }
}
