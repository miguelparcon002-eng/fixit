import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../models/admin_customer_user.dart';
import '../../models/admin_technician_list_item.dart';
import '../../providers/admin_customers_provider.dart';
import '../../providers/admin_technicians_provider.dart';
import 'widgets/admin_customer_details_sheet.dart';
import 'widgets/admin_notifications_dialog.dart';
import 'widgets/admin_technician_details_sheet.dart';
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}
class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customerSearchController =
      TextEditingController();
  String _customerSearchQuery = '';
  String _customerFilter = 'all';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(
              size: 30,
              showText: false,
              assetPath: 'assets/images/logo_square.png',
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Users',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminCustomersProvider);
              ref.invalidate(adminTechniciansProvider);
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AdminNotificationsDialog(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: Colors.grey.shade200),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.deepBlue,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                indicatorColor: AppTheme.deepBlue,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Customers'),
                  Tab(text: 'Technicians'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CustomersTab(
            searchController: _customerSearchController,
            searchQuery: _customerSearchQuery,
            selectedFilter: _customerFilter,
            onSearchChanged: (v) => setState(() => _customerSearchQuery = v),
            onFilterChanged: (v) => setState(() => _customerFilter = v),
          ),
          const _TechniciansTab(),
        ],
      ),
    );
  }
}
class _CustomersTab extends ConsumerWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  const _CustomersTab({
    required this.searchController,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(adminCustomersProvider);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search & filters',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.deepBlue),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: selectedFilter == 'all',
                      onSelected: () => onFilterChanged('all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Active',
                      isSelected: selectedFilter == 'active',
                      onSelected: () => onFilterChanged('active'),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactive',
                      isSelected: selectedFilter == 'inactive',
                      onSelected: () => onFilterChanged('inactive'),
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Suspended',
                      isSelected: selectedFilter == 'suspended',
                      onSelected: () => onFilterChanged('suspended'),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        customersAsync.when(
          data: (customers) {
            final activeCount =
                customers.where((c) => c.isActive && !c.isSuspended).length;
            final suspendedCount = customers.where((c) => c.isSuspended).length;
            final total = customers.length;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatBadge(label: 'Total', value: '$total', color: Colors.blue),
                  const SizedBox(width: 10),
                  _StatBadge(
                      label: 'Active', value: '$activeCount', color: Colors.green),
                  const SizedBox(width: 10),
                  _StatBadge(
                      label: 'Inactive',
                      value: '${total - activeCount - suspendedCount}',
                      color: Colors.grey),
                  const SizedBox(width: 10),
                  _StatBadge(
                      label: 'Suspended',
                      value: '$suspendedCount',
                      color: Colors.red),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: customersAsync.when(
            data: (customers) {
              var filtered = customers;
              if (searchQuery.isNotEmpty) {
                final q = searchQuery.toLowerCase();
                filtered = filtered
                    .where((c) =>
                        c.fullName.toLowerCase().contains(q) ||
                        c.email.toLowerCase().contains(q) ||
                        (c.phone?.contains(q) ?? false))
                    .toList();
              }
              if (selectedFilter == 'active') {
                filtered = filtered
                    .where((c) => c.isActive && !c.isSuspended)
                    .toList();
              } else if (selectedFilter == 'inactive') {
                filtered = filtered
                    .where((c) => !c.isActive && !c.isSuspended)
                    .toList();
              } else if (selectedFilter == 'suspended') {
                filtered = filtered.where((c) => c.isSuspended).toList();
              }
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        searchQuery.isNotEmpty || selectedFilter != 'all'
                            ? 'No customers found'
                            : 'No customers yet',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final c = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CustomerCard(
                      customer: c,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (_) => AdminCustomerDetailsSheet(customer: c),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text('Error loading customers',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(adminCustomersProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
enum _TechSort { experience, createdAt, jobsDone }
enum _TechVerifiedFilter { all, verified, unverified, suspended }
class _TechniciansTab extends ConsumerStatefulWidget {
  const _TechniciansTab();
  @override
  ConsumerState<_TechniciansTab> createState() => _TechniciansTabState();
}
class _TechniciansTabState extends ConsumerState<_TechniciansTab> {
  _TechSort _sort = _TechSort.jobsDone;
  _TechVerifiedFilter _verifiedFilter = _TechVerifiedFilter.all;
  String get _verifiedFilterLabel {
    switch (_verifiedFilter) {
      case _TechVerifiedFilter.all:
        return 'All';
      case _TechVerifiedFilter.verified:
        return 'Verified';
      case _TechVerifiedFilter.unverified:
        return 'Unverified';
      case _TechVerifiedFilter.suspended:
        return 'Suspended';
    }
  }
  String get _sortLabel {
    switch (_sort) {
      case _TechSort.experience:
        return 'Experience';
      case _TechSort.createdAt:
        return 'Account created';
      case _TechSort.jobsDone:
        return 'Bookings done';
    }
  }
  List<AdminTechnicianListItem> _applyFilter(
      List<AdminTechnicianListItem> items) {
    switch (_verifiedFilter) {
      case _TechVerifiedFilter.all:
        return items;
      case _TechVerifiedFilter.verified:
        return items.where((t) => t.verified).toList();
      case _TechVerifiedFilter.unverified:
        return items.where((t) => !t.verified).toList();
      case _TechVerifiedFilter.suspended:
        return items.where((t) => t.isSuspended).toList();
    }
  }
  int _compare(AdminTechnicianListItem a, AdminTechnicianListItem b) {
    if (a.isSuspended != b.isSuspended) return a.isSuspended ? 1 : -1;
    int desc(num x, num y) => y.compareTo(x);
    switch (_sort) {
      case _TechSort.experience:
        return desc(a.profile?.yearsExperience ?? 0,
            b.profile?.yearsExperience ?? 0);
      case _TechSort.createdAt:
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      case _TechSort.jobsDone:
        return desc(a.completedBookings, b.completedBookings);
    }
  }
  void _pickVerifiedFilter() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TechFilterOption(
                label: 'All',
                isSelected: _verifiedFilter == _TechVerifiedFilter.all,
                onTap: () {
                  setState(() => _verifiedFilter = _TechVerifiedFilter.all);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _TechFilterOption(
                label: 'Verified',
                isSelected: _verifiedFilter == _TechVerifiedFilter.verified,
                onTap: () {
                  setState(
                      () => _verifiedFilter = _TechVerifiedFilter.verified);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _TechFilterOption(
                label: 'Unverified',
                isSelected: _verifiedFilter == _TechVerifiedFilter.unverified,
                onTap: () {
                  setState(
                      () => _verifiedFilter = _TechVerifiedFilter.unverified);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _TechFilterOption(
                label: 'Suspended',
                isSelected: _verifiedFilter == _TechVerifiedFilter.suspended,
                onTap: () {
                  setState(
                      () => _verifiedFilter = _TechVerifiedFilter.suspended);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _pickSort() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TechFilterOption(
                label: 'Bookings done',
                isSelected: _sort == _TechSort.jobsDone,
                onTap: () {
                  setState(() => _sort = _TechSort.jobsDone);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _TechFilterOption(
                label: 'Experience',
                isSelected: _sort == _TechSort.experience,
                onTap: () {
                  setState(() => _sort = _TechSort.experience);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _TechFilterOption(
                label: 'Account created',
                isSelected: _sort == _TechSort.createdAt,
                onTap: () {
                  setState(() => _sort = _TechSort.createdAt);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final techsAsync = ref.watch(adminTechniciansProvider);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickVerifiedFilter,
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text(_verifiedFilterLabel,
                    style: const TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.deepBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _pickSort,
                icon: const Icon(Icons.sort, size: 18),
                label: Text(_sortLabel,
                    style: const TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.deepBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: techsAsync.when(
            data: (items) {
              final filtered = _applyFilter(items);
              final sorted = [...filtered]..sort(_compare);
              if (sorted.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.engineering_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'No technicians found',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = sorted[index];
                  return _TechnicianCard(
                    technician: t,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (_) =>
                          AdminTechnicianDetailsSheet(technician: t),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading technicians: $e',
                    style: TextStyle(color: Colors.grey.shade700),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? Colors.blue) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
class _TechFilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TechFilterOption(
      {required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.deepBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.deepBlue
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.deepBlue : Colors.black)),
            if (isSelected)
              const Icon(Icons.check_box,
                  color: AppTheme.deepBlue, size: 20)
            else
              Icon(Icons.check_box_outline_blank,
                  color: Colors.grey.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
class _CustomerCard extends StatelessWidget {
  final AdminCustomerUser customer;
  final VoidCallback onTap;
  const _CustomerCard({required this.customer, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: customer.profilePicture != null
                      ? NetworkImage(customer.profilePicture!)
                      : null,
                  child: customer.profilePicture == null
                      ? Text(
                          customer.fullName.isNotEmpty
                              ? customer.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700]))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: customer.isSuspended
                          ? Colors.red
                          : (customer.isActive ? Colors.green : Colors.grey),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.fullName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (customer.isSuspended)
                        _StatusBadge(label: 'Suspended', color: Colors.red)
                      else if (!customer.isActive)
                        _StatusBadge(label: 'Inactive', color: Colors.grey)
                      else
                        _StatusBadge(label: 'Active', color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(customer.email,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(customer.phone ?? 'No phone',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 12,
                          color: customer.isActive
                              ? Colors.green
                              : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          customer.isActive
                              ? 'Active (≤7d)'
                              : 'Inactive (>7d)',
                          style: TextStyle(
                              fontSize: 11,
                              color: customer.isActive
                                  ? Colors.green
                                  : Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w800)),
    );
  }
}
class _TechnicianCard extends StatelessWidget {
  final AdminTechnicianListItem technician;
  final VoidCallback onTap;
  const _TechnicianCard({required this.technician, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = technician.profile;
    final specialties = profile?.specialties ?? const <String>[];
    final rating = profile?.rating ?? 0.0;
    final jobs = technician.completedBookings;
    final exp = profile?.yearsExperience ?? 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: (technician.profilePicture != null &&
                          technician.profilePicture!.isNotEmpty)
                      ? NetworkImage(technician.profilePicture!)
                      : null,
                  child: (technician.profilePicture == null ||
                          technician.profilePicture!.isEmpty)
                      ? const Icon(Icons.engineering)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              technician.fullName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimaryColor),
                            ),
                          ),
                          if (technician.isSuspended)
                            _StatusBadge(
                                label: 'Suspended', color: Colors.red)
                          else if (technician.verified)
                            _StatusBadge(
                                label: 'Verified',
                                color: AppTheme.successColor),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(technician.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniStat(
                    icon: Icons.star,
                    value: rating.toStringAsFixed(1),
                    color: Colors.pink),
                _MiniStat(
                    icon: Icons.work,
                    value: '$jobs jobs',
                    color: AppTheme.lightBlue),
                _MiniStat(
                    icon: Icons.trending_up,
                    value: '${exp}y exp',
                    color: AppTheme.accentPurple),
              ],
            ),
            if (specialties.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specialties.take(4).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.primaryCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: AppTheme.primaryCyan
                              .withValues(alpha: 0.25)),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor)),
                  );
                }).toList(),
              ),
            ],
            if ((technician.city ?? technician.address) != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        technician.city ?? technician.address ?? '',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.icon, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      ),
    );
  }
}