import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../models/booking_model.dart';
import '../../models/job_request_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/job_request_provider.dart';
String _statusLabel(String status) => switch (status) {
      'open' || 'pending_customer_approval' => 'Requesting',
      'accepted' => 'Active',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => status,
    };
Color _statusColor(String status) => switch (status) {
      'open' || 'pending_customer_approval' => AppTheme.warningColor,
      'accepted' => AppTheme.lightBlue,
      'completed' => AppTheme.successColor,
      'cancelled' => AppTheme.textSecondaryColor,
      _ => Colors.purple,
    };
IconData _statusIcon(String status) => switch (status) {
      'open' || 'pending_customer_approval' => Icons.search_rounded,
      'accepted' => Icons.build_rounded,
      'completed' => Icons.check_circle_rounded,
      'cancelled' => Icons.cancel_rounded,
      _ => Icons.help_outline,
    };
String _bucket(String status) => switch (status) {
      'open' || 'pending_customer_approval' => 'requesting',
      'accepted' => 'active',
      'completed' => 'completed',
      'cancelled' => 'cancelled',
      _ => 'other',
    };
String _derivedBucket(JobRequestModel jr, List<BookingModel> bookings) {
  if (jr.status != 'accepted') return _bucket(jr.status);
  final relevant = bookings
      .where((b) => b.customerId == jr.customerId && b.technicianId == jr.technicianId)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  if (relevant.isEmpty) return 'active'; // booking not yet created — just accepted
  final latestStatus = relevant.first.status;
  const activeStatuses = {'accepted', 'scheduled', 'en_route', 'arrived', 'in_progress'};
  if (activeStatuses.contains(latestStatus)) return 'active';
  const doneStatuses = {'completed', 'paid', 'closed'};
  if (doneStatuses.contains(latestStatus)) return 'completed';
  return 'cancelled'; // cancelled / cancellation_pending
}
class AdminJobRequestsScreen extends ConsumerStatefulWidget {
  const AdminJobRequestsScreen({super.key});
  @override
  ConsumerState<AdminJobRequestsScreen> createState() =>
      _AdminJobRequestsScreenState();
}
class _AdminJobRequestsScreenState
    extends ConsumerState<AdminJobRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _filter; // null = all
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(
      () => ref.read(jobRequestServiceProvider).syncStaleStatuses(),
    );
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  List<JobRequestModel> _filtered(
      List<JobRequestModel> all, List<BookingModel> bookings) {
    if (_filter == null) return all;
    return all.where((r) => _derivedBucket(r, bookings) == _filter).toList();
  }
  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allJobRequestsProvider);
    final bookings = ref.watch(allPostProblemBookingsProvider).valueOrNull ?? [];
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const AppLogo(
              size: 30,
              showText: false,
              assetPath: 'assets/images/logo_square.png',
            ),
            const SizedBox(width: 10),
            const Text(
              'Job Requests Map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
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
                tabs: const [
                  Tab(icon: Icon(Icons.map_outlined), text: 'Map'),
                  Tab(icon: Icon(Icons.list_alt_outlined), text: 'List'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final stats = _Stats(
            requesting: all.where((r) => _derivedBucket(r, bookings) == 'requesting').length,
            active:     all.where((r) => _derivedBucket(r, bookings) == 'active').length,
            completed:  all.where((r) => _derivedBucket(r, bookings) == 'completed').length,
            cancelled:  all.where((r) => _derivedBucket(r, bookings) == 'cancelled').length,
          );
          final filtered = _filtered(all, bookings);
          return Column(
            children: [
              _StatsBar(stats: stats),
              _FilterRow(
                selected: _filter,
                stats: stats,
                onChanged: (v) => setState(() => _filter = v),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MapTab(requests: filtered),
                    _ListTab(requests: filtered),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
class _Stats {
  final int requesting, active, completed, cancelled;
  const _Stats(
      {required this.requesting,
      required this.active,
      required this.completed,
      required this.cancelled});
  int get total => requesting + active + completed + cancelled;
}
class _StatsBar extends StatelessWidget {
  final _Stats stats;
  const _StatsBar({required this.stats});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatPill(label: 'Total', value: stats.total, color: AppTheme.deepBlue),
          const SizedBox(width: 8),
          _StatPill(label: 'Requesting', value: stats.requesting, color: AppTheme.warningColor),
          const SizedBox(width: 8),
          _StatPill(label: 'Active', value: stats.active, color: AppTheme.lightBlue),
          const SizedBox(width: 8),
          _StatPill(label: 'Done', value: stats.completed, color: AppTheme.successColor),
        ],
      ),
    );
  }
}
class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
class _FilterRow extends StatelessWidget {
  final String? selected;
  final _Stats stats;
  final ValueChanged<String?> onChanged;
  const _FilterRow(
      {required this.selected, required this.stats, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
                label: 'All',
                count: stats.total,
                color: AppTheme.deepBlue,
                selected: selected == null,
                onTap: () => onChanged(null)),
            const SizedBox(width: 8),
            _Chip(
                label: 'Requesting',
                count: stats.requesting,
                color: AppTheme.warningColor,
                selected: selected == 'requesting',
                onTap: () => onChanged(selected == 'requesting' ? null : 'requesting')),
            const SizedBox(width: 8),
            _Chip(
                label: 'Active',
                count: stats.active,
                color: AppTheme.lightBlue,
                selected: selected == 'active',
                onTap: () => onChanged(selected == 'active' ? null : 'active')),
            const SizedBox(width: 8),
            _Chip(
                label: 'Completed',
                count: stats.completed,
                color: AppTheme.successColor,
                selected: selected == 'completed',
                onTap: () => onChanged(selected == 'completed' ? null : 'completed')),
            const SizedBox(width: 8),
            _Chip(
                label: 'Cancelled',
                count: stats.cancelled,
                color: AppTheme.textSecondaryColor,
                selected: selected == 'cancelled',
                onTap: () => onChanged(selected == 'cancelled' ? null : 'cancelled')),
          ],
        ),
      ),
    );
  }
}
class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.count,
      required this.color,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : color),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MapTab extends StatelessWidget {
  final List<JobRequestModel> requests;
  const _MapTab({required this.requests});
  @override
  Widget build(BuildContext context) {
    final center = requests.isNotEmpty
        ? LatLng(requests.first.latitude, requests.first.longitude)
        : const LatLng(8.5048, 125.9676);
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fixit.app',
            ),
            MarkerLayer(
              markers: requests
                  .map((r) => Marker(
                        point: LatLng(r.latitude, r.longitude),
                        width: 48,
                        height: 56,
                        child: GestureDetector(
                          onTap: () => _showDetail(context, r),
                          child: _MapPin(status: r.status),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        if (requests.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined,
                      color: Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Text('No requests to display',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 20,
          right: 14,
          child: _MapLegend(),
        ),
        if (requests.isNotEmpty)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tap a pin to view details',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
      ],
    );
  }
  void _showDetail(BuildContext context, JobRequestModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(request: r),
    );
  }
}
class _MapPin extends StatelessWidget {
  final String status;
  const _MapPin({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(
          width: 2.5,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}
class _MapLegend extends StatelessWidget {
  const _MapLegend();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Legend',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _LegendRow(color: AppTheme.warningColor,       icon: Icons.search_rounded,       label: 'Requesting'),
          const SizedBox(height: 5),
          _LegendRow(color: AppTheme.lightBlue,          icon: Icons.build_rounded,        label: 'Active'),
          const SizedBox(height: 5),
          _LegendRow(color: AppTheme.successColor,       icon: Icons.check_circle_rounded, label: 'Completed'),
          const SizedBox(height: 5),
          _LegendRow(color: AppTheme.textSecondaryColor, icon: Icons.cancel_rounded,       label: 'Cancelled'),
        ],
      ),
    );
  }
}
class _LegendRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _LegendRow({required this.color, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 11),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
class _ListTab extends StatelessWidget {
  final List<JobRequestModel> requests;
  const _ListTab({required this.requests});
  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No requests match this filter',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ListCard(request: requests[i]),
    );
  }
}
class _ListCard extends ConsumerWidget {
  final JobRequestModel request;
  const _ListCard({required this.request});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(request.status);
    final label = _statusLabel(request.status);
    final icon = _statusIcon(request.status);
    final fmt = DateFormat('MMM d, yyyy · h:mm a');
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DetailSheet(request: request),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.deviceType,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.problemDescription,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            request.address,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text(
                          fmt.format(request.createdAt.toLocal()),
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade300, size: 20),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
class _DetailSheet extends ConsumerWidget {
  final JobRequestModel request;
  const _DetailSheet({required this.request});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(request.status);
    final label = _statusLabel(request.status);
    final icon = _statusIcon(request.status);
    final fmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');
    final isActionable =
        request.status == 'open' || request.status == 'pending_customer_approval' || request.status == 'accepted';
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.deviceType,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time_outlined,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${fmt.format(request.createdAt.toLocal())}  ·  ${timeFmt.format(request.createdAt.toLocal())}',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 20),
            _SheetSection(
              title: 'Problem Description',
              icon: Icons.report_problem_outlined,
              color: Colors.orange.shade700,
              child: Text(
                request.problemDescription,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF374151), height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            _SheetSection(
              title: 'Location',
              icon: Icons.location_on_outlined,
              color: Colors.red.shade600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.address,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF374151))),
                  const SizedBox(height: 4),
                  Text(
                    '${request.latitude.toStringAsFixed(5)}, ${request.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SheetSection(
              title: 'People',
              icon: Icons.people_outline,
              color: AppTheme.deepBlue,
              child: Column(
                children: [
                  _PersonRow(
                    label: 'Customer',
                    icon: Icons.person_outline,
                    id: request.customerId,
                    color: AppTheme.deepBlue,
                  ),
                  if (request.technicianId != null) ...[
                    const SizedBox(height: 8),
                    _PersonRow(
                      label: request.status == 'pending_customer_approval'
                          ? 'Proposed Technician'
                          : 'Technician',
                      icon: Icons.engineering_outlined,
                      id: request.technicianId!,
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                  if (request.technicianId == null &&
                      (request.status == 'open' ||
                          request.status == 'pending_customer_approval')) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.engineering_outlined,
                              size: 15, color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 10),
                        Text('No technician assigned yet',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (request.status == 'pending_customer_approval') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Technician proposed — awaiting customer approval',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isActionable) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 18),
                  label: const Text('Cancel Request',
                      style: TextStyle(color: Colors.red, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request'),
        content: const Text(
            'Are you sure you want to cancel this job request? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    Navigator.pop(context);
    try {
      await ref.read(jobRequestServiceProvider).cancelRequest(request.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
class _SheetSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _SheetSection(
      {required this.title,
      required this.icon,
      required this.color,
      required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ],
    );
  }
}
class _PersonRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String id;
  final Color color;
  const _PersonRow(
      {required this.label,
      required this.icon,
      required this.id,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final shortId = id.length > 16 ? '${id.substring(0, 16)}…' : id;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
            Text(shortId,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }
}