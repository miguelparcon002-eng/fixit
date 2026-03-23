import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../models/job_request_model.dart';
import '../../providers/job_request_provider.dart';

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
    final requestsAsync = ref.watch(allJobRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Job Requests',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.deepBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.deepBlue,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Map'),
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'List'),
          ],
        ),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (requests) => TabBarView(
          controller: _tabController,
          children: [
            _MapView(requests: requests),
            _ListView(requests: requests),
          ],
        ),
      ),
    );
  }
}

// ── Map view ──────────────────────────────────────────────────────────────────

class _MapView extends StatelessWidget {
  final List<JobRequestModel> requests;
  const _MapView({required this.requests});

  Color _pinColor(String status) => switch (status) {
        'open'      => Colors.red,
        'accepted'  => const Color(0xFF0EA5E9),
        'completed' => const Color(0xFF059669),
        'cancelled' => Colors.grey,
        _           => Colors.purple,
      };

  @override
  Widget build(BuildContext context) {
    final center = requests.isNotEmpty
        ? LatLng(requests.first.latitude, requests.first.longitude)
        : const LatLng(14.5995, 120.9842); // Manila fallback

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
                        width: 44,
                        height: 52,
                        child: GestureDetector(
                          onTap: () => _showDetail(context, r),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _pinColor(r.status),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _pinColor(r.status)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.build,
                                    color: Colors.white, size: 16),
                              ),
                              Container(
                                width: 2,
                                height: 8,
                                color: _pinColor(r.status),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),

        // Legend
        Positioned(
          bottom: 16,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendDot(color: Colors.red,                  label: 'Open'),
                const SizedBox(height: 4),
                _LegendDot(color: const Color(0xFF0EA5E9),     label: 'Accepted'),
                const SizedBox(height: 4),
                _LegendDot(color: const Color(0xFF059669),     label: 'Completed'),
                const SizedBox(height: 4),
                _LegendDot(color: Colors.grey,                 label: 'Cancelled'),
              ],
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
      builder: (_) => _AdminJobSheet(request: r),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── List view ─────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<JobRequestModel> requests;
  const _ListView({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No job requests yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _AdminListCard(request: requests[i]),
    );
  }
}

class _AdminListCard extends ConsumerWidget {
  final JobRequestModel request;
  const _AdminListCard({required this.request});

  (Color, String) get _statusStyle => switch (request.status) {
        'open'      => (Colors.orange,           'Open'),
        'accepted'  => (const Color(0xFF0EA5E9), 'Accepted'),
        'completed' => (const Color(0xFF059669), 'Completed'),
        'cancelled' => (Colors.grey,             'Cancelled'),
        _           => (Colors.purple,           request.status),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, label) = _statusStyle;
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.deviceType,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(request.problemDescription,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Expanded(
                child: Text(request.address,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(fmt.format(request.createdAt.toLocal()),
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),

          // Admin actions
          if (request.status == 'open' || request.status == 'accepted') ...[
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _confirmCancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined,
                      size: 15, color: Colors.red),
                  label: const Text('Cancel',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request'),
        content: const Text('Cancel this job request?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(jobRequestServiceProvider).cancelRequest(request.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ── Admin job detail sheet ────────────────────────────────────────────────────

class _AdminJobSheet extends ConsumerWidget {
  final JobRequestModel request;
  const _AdminJobSheet({required this.request});

  (Color, String) get _statusStyle => switch (request.status) {
        'open'      => (Colors.orange,           'Open'),
        'accepted'  => (const Color(0xFF0EA5E9), 'Accepted'),
        'completed' => (const Color(0xFF059669), 'Completed'),
        'cancelled' => (Colors.grey,             'Cancelled'),
        _           => (Colors.purple,           request.status),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, label) = _statusStyle;
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                Expanded(
                  child: Text(request.deviceType,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(fmt.format(request.createdAt.toLocal()),
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 16),

            _SheetRow(
                icon: Icons.report_problem_outlined,
                label: 'Problem',
                value: request.problemDescription),
            const SizedBox(height: 10),
            _SheetRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: request.address),
            const SizedBox(height: 10),
            _SheetRow(
                icon: Icons.person_outline,
                label: 'Customer ID',
                value: '${request.customerId.substring(0, 12)}…'),
            if (request.technicianId != null) ...[
              const SizedBox(height: 10),
              _SheetRow(
                  icon: Icons.engineering_outlined,
                  label: 'Technician ID',
                  value: '${request.technicianId!.substring(0, 12)}…'),
            ],

            if (request.status == 'open' || request.status == 'accepted') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await ref
                          .read(jobRequestServiceProvider)
                          .cancelRequest(request.id);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed: $e'),
                          backgroundColor: Colors.red));
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Cancel Request',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SheetRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.deepBlue, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
        ),
      ],
    );
  }
}
