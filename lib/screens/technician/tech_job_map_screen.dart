import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/job_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_request_provider.dart';
import '../../services/notification_service.dart';
class TechJobMapScreen extends ConsumerStatefulWidget {
  const TechJobMapScreen({super.key});
  @override
  ConsumerState<TechJobMapScreen> createState() => _TechJobMapScreenState();
}
class _TechJobMapScreenState extends ConsumerState<TechJobMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _techLocation;
  bool _locating = true;
  @override
  void initState() {
    super.initState();
    _getTechLocation();
  }
  Future<void> _getTechLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _techLocation = LatLng(pos.latitude, pos.longitude);
          _locating = false;
        });
        _mapController.move(_techLocation!, 13);
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }
  double? _distanceTo(JobRequestModel r) {
    if (_techLocation == null) return null;
    final meters = Geolocator.distanceBetween(
      _techLocation!.latitude,
      _techLocation!.longitude,
      r.latitude,
      r.longitude,
    );
    return meters / 1000;
  }
  void _showJobSheet(BuildContext context, JobRequestModel request,
      {bool isPending = false}) {
    final dist = _distanceTo(request);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => isPending
          ? _WaitingSheet(request: request, distanceKm: dist)
          : _JobDetailSheet(
              request: request,
              distanceKm: dist,
              onAccepted: () => Navigator.pop(context),
            ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(openJobRequestsProvider);
    final techId = ref.watch(currentUserProvider).valueOrNull?.id;
    final proposalsAsync = techId != null
        ? ref.watch(techProposalsProvider(techId))
        : const AsyncData<List<JobRequestModel>>([]);
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
          'Nearby Job Requests',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_locating)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF4A5FE0)),
              tooltip: 'Go to my location',
              onPressed: () {
                if (_techLocation != null) {
                  _mapController.move(_techLocation!, 14);
                }
              },
            ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (requests) {
          final proposals = proposalsAsync.valueOrNull ?? [];
          final center = _techLocation ?? const LatLng(8.5048, 125.9676);
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fixit.app',
                  ),
                  MarkerLayer(
                    markers: [
                      if (_techLocation != null)
                        Marker(
                          point: _techLocation!,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.deepBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.deepBlue.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ...requests.map((r) => Marker(
                            point: LatLng(r.latitude, r.longitude),
                            width: 44,
                            height: 52,
                            child: GestureDetector(
                              onTap: () => _showJobSheet(context, r),
                              child: _buildPin(Colors.red.shade600),
                            ),
                          )),
                      ...proposals.map((r) => Marker(
                            point: LatLng(r.latitude, r.longitude),
                            width: 44,
                            height: 52,
                            child: GestureDetector(
                              onTap: () =>
                                  _showJobSheet(context, r, isPending: true),
                              child: _buildPin(Colors.amber.shade700),
                            ),
                          )),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBadge(
                      color: requests.isEmpty ? Colors.grey : Colors.red.shade600,
                      label:
                          '${requests.length} open ${requests.length == 1 ? 'request' : 'requests'}',
                    ),
                    if (proposals.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildBadge(
                        color: Colors.amber.shade700,
                        label:
                            '${proposals.length} awaiting customer approval',
                      ),
                    ],
                  ],
                ),
              ),
              if (requests.isEmpty && proposals.isEmpty)
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inbox_outlined,
                            color: Colors.grey.shade400, size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No open job requests in your area right now.',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF374151)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildPin(Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
          child: const Icon(Icons.build, color: Colors.white, size: 16),
        ),
        Container(width: 2, height: 8, color: color),
      ],
    );
  }
  Widget _buildBadge({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
class _WaitingSheet extends StatelessWidget {
  final JobRequestModel request;
  final double? distanceKm;
  const _WaitingSheet({required this.request, required this.distanceKm});
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy · h:mm a');
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.75,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waiting for Customer',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        Text(
                          'Your request is pending customer approval.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.devices,
                      color: Colors.amber.shade700, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.deviceType,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E)),
                      ),
                      Text(fmt.format(request.createdAt.toLocal()),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepBlue),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.report_problem_outlined,
              label: 'Problem',
              value: request.problemDescription,
            ),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: request.address,
            ),
          ],
        ),
      ),
    );
  }
}
class _JobDetailSheet extends ConsumerStatefulWidget {
  final JobRequestModel request;
  final double? distanceKm;
  final VoidCallback onAccepted;
  const _JobDetailSheet({
    required this.request,
    required this.distanceKm,
    required this.onAccepted,
  });
  @override
  ConsumerState<_JobDetailSheet> createState() => _JobDetailSheetState();
}
class _JobDetailSheetState extends ConsumerState<_JobDetailSheet> {
  bool _accepting = false;
  String? _customerName;
  @override
  void initState() {
    super.initState();
    _loadCustomerName();
  }
  Future<void> _loadCustomerName() async {
    try {
      final data = await SupabaseConfig.client
          .from('users')
          .select('full_name')
          .eq('id', widget.request.customerId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _customerName = data['full_name'] as String?);
      }
    } catch (_) {}
  }
  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Not logged in');
      await ref
          .read(jobRequestServiceProvider)
          .proposeRequest(widget.request.id, user.id);
      await NotificationService().sendNotification(
        userId: widget.request.customerId,
        type: 'tech_proposed',
        title: 'Technician Interested!',
        message: 'A technician is interested in your ${widget.request.deviceType} repair request. Tap to review.',
        data: {'route': '/my-requests'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! Waiting for customer confirmation.'),
          backgroundColor: Color(0xFF0EA5E9),
        ),
      );
      widget.onAccepted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }
  Future<void> _navigate() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.request.latitude},${widget.request.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final fmt = DateFormat('MMM d, yyyy · h:mm a');
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.35,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.devices, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.deviceType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        fmt.format(r.createdAt.toLocal()),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (widget.distanceKm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepBlue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoTile(
              icon: Icons.report_problem_outlined,
              label: 'Problem',
              value: r.problemDescription,
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: r.address,
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Customer',
              value: _customerName ?? 'Loading…',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _navigate,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: BorderSide(color: AppTheme.deepBlue, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _accepting ? null : _accept,
                    icon: _accepting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_accepting ? 'Sending…' : 'Accept Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.deepBlue, size: 18),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
        ),
      ],
    );
  }
}