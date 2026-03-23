import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/job_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/job_request_provider.dart';
import '../../services/distance_fee_service.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final Widget child;
  const MainNavigation({super.key, required this.child});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  final Set<String> _shownDialogs = {};

  int _locationToTabIndex(String location) {
    if (location.startsWith('/bookings') || location.startsWith('/booking/')) return 1;
    if (location.startsWith('/help-support') || location.startsWith('/live-chat')) return 2;
    if (location.startsWith('/profile') || location.startsWith('/edit-profile') || location.startsWith('/addresses')) return 3;
    return 0;
  }

  void _onTabSelected(int index) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/bookings'); break;
      case 2: context.go('/help-support'); break;
      case 3: context.go('/profile'); break;
    }
  }

  void _handleRequests(List<JobRequestModel> requests) {
    final pending = requests
        .where((r) =>
            r.status == 'pending_customer_approval' && r.technicianId != null)
        .toList();
    for (final r in pending) {
      if (!_shownDialogs.contains(r.id)) {
        _shownDialogs.add(r.id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _TechApprovalDialog(
              request: r,
              onDeclined: () => _shownDialogs.remove(r.id),
            ),
          );
        });
        break; // show one dialog at a time
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToTabIndex(location);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          widget.child,
          // Invisible listener — only mounted for customer accounts
          if (user != null && user.role == AppConstants.roleCustomer)
            _PendingRequestListener(
              customerId: user.id,
              onRequests: _handleRequests,
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTabSelected,
        indicatorColor: AppTheme.deepBlue.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent_rounded),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Invisible listener widget ─────────────────────────────────────────────────

class _PendingRequestListener extends ConsumerWidget {
  final String customerId;
  final void Function(List<JobRequestModel>) onRequests;

  const _PendingRequestListener({
    required this.customerId,
    required this.onRequests,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current value — triggers on initial mount and every rebuild
    final current = ref.watch(customerJobRequestsProvider(customerId));
    current.whenData((requests) {
      if (requests.any((r) => r.status == 'pending_customer_approval')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onRequests(requests);
        });
      }
    });

    // Listen for future stream changes
    ref.listen<AsyncValue<List<JobRequestModel>>>(
      customerJobRequestsProvider(customerId),
      (_, next) => next.whenData(onRequests),
    );

    return const SizedBox.shrink();
  }
}

// ── Technician approval dialog ────────────────────────────────────────────────

class _TechApprovalDialog extends ConsumerStatefulWidget {
  final JobRequestModel request;
  final VoidCallback onDeclined;

  const _TechApprovalDialog({
    required this.request,
    required this.onDeclined,
  });

  @override
  ConsumerState<_TechApprovalDialog> createState() =>
      _TechApprovalDialogState();
}

class _TechApprovalDialogState extends ConsumerState<_TechApprovalDialog> {
  bool _loading = true;
  bool _accepting = false;
  bool _declining = false;
  String? _error;

  String _techName = 'Technician';
  String? _techPicture;
  double? _distanceKm;
  double? _distanceFee;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const toRad = pi / 180;
    final dLat = (lat2 - lat1) * 111.0;
    final dLng =
        (lng2 - lng1) * 111.0 * cos((lat1 + lat2) / 2 * toRad);
    return sqrt(dLat * dLat + dLng * dLng);
  }

  Future<void> _loadData() async {
    try {
      final techId = widget.request.technicianId!;
      final row = await SupabaseConfig.client
          .from('users')
          .select('full_name, profile_picture, latitude, longitude')
          .eq('id', techId)
          .single();

      final techLat = (row['latitude'] as num?)?.toDouble();
      final techLng = (row['longitude'] as num?)?.toDouble();

      double? distKm;
      double? distFee;

      if (techLat != null && techLng != null) {
        distKm = _haversineKm(
          techLat, techLng,
          widget.request.latitude, widget.request.longitude,
        );
        distKm = double.parse(distKm.toStringAsFixed(1));
        final rate = await DistanceFeeService.getRate();
        distFee = (distKm * 10).round() * rate;
      }

      if (mounted) {
        setState(() {
          _techName = row['full_name'] as String? ?? 'Technician';
          _techPicture = row['profile_picture'] as String?;
          _distanceKm = distKm;
          _distanceFee = distFee;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Not logged in');
      final supabase = SupabaseConfig.client;
      final techId = widget.request.technicianId!;

      // Get service ID for this technician (same logic as create_booking_screen)
      var svcRow = await supabase
          .from('services')
          .select('id')
          .eq('technician_id', techId)
          .limit(1)
          .maybeSingle();
      svcRow ??= await supabase
          .from('services')
          .select('id')
          .limit(1)
          .maybeSingle();
      if (svcRow == null) throw Exception('No services available.');
      final serviceId = svcRow['id'] as String;

      // Scheduled 15 minutes from now
      final scheduledAt = DateTime.now().add(const Duration(minutes: 15));

      // Create booking directly as 'accepted' so it lands in the Active tab
      final booking = await ref.read(bookingServiceProvider).createBooking(
            customerId: user.id,
            technicianId: techId,
            serviceId: serviceId,
            status: AppConstants.bookingAccepted,
            scheduledDate: scheduledAt,
            customerAddress: widget.request.address,
            customerLatitude: widget.request.latitude,
            customerLongitude: widget.request.longitude,
            estimatedCost: _distanceFee,
            paymentMethod: 'gcash',
            bookingSource: 'post_problem',
          );

      // Store the problem description as diagnostic notes.
      // Prefix with [POST_PROBLEM] so the tech jobs screen can distinguish
      // post-problem bookings from regular schedule bookings.
      // Also embed the distance fee so payment breakdown shows it properly.
      final distanceNoteLine = (_distanceFee != null && _distanceFee! > 0)
          ? '\nDistance Fee: ₱${_distanceFee!.toStringAsFixed(2)}'
          : '';
      await supabase.from('bookings').update({
        'diagnostic_notes':
            '[POST_PROBLEM]\n${widget.request.problemDescription}$distanceNoteLine',
      }).eq('id', booking.id);

      // Mark job request as accepted
      await ref.read(jobRequestServiceProvider).acceptRequest(
            widget.request.id, techId);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Technician accepted! Check your Appointments tab.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      context.go('/bookings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
      setState(() => _accepting = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _declining = true);
    try {
      await ref
          .read(jobRequestServiceProvider)
          .customerDeclineRequest(widget.request.id);
      if (!mounted) return;
      widget.onDeclined();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Technician declined. Your request is still open.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
      setState(() => _declining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepBlue, AppTheme.primaryCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.engineering_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Technician Found!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A technician wants to take your ${widget.request.deviceType} request',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? _ErrorBody(error: _error!)
                    : _LoadedBody(
                        techName: _techName,
                        techPicture: _techPicture,
                        distanceKm: _distanceKm,
                        distanceFee: _distanceFee,
                        deviceType: widget.request.deviceType,
                        address: widget.request.address,
                      ),
          ),

          if (!_loading && _error == null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          (_declining || _accepting) ? null : _decline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _declining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red),
                            )
                          : const Text('Decline',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (_accepting || _declining) ? null : _accept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _accepting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Accept Technician',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Dialog sub-widgets ────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  final String techName;
  final String? techPicture;
  final double? distanceKm;
  final double? distanceFee;
  final String deviceType;
  final String address;

  const _LoadedBody({
    required this.techName,
    required this.techPicture,
    required this.distanceKm,
    required this.distanceFee,
    required this.deviceType,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Technician info
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.15),
              backgroundImage:
                  techPicture != null ? NetworkImage(techPicture!) : null,
              child: techPicture == null
                  ? Text(
                      techName.isNotEmpty ? techName[0].toUpperCase() : 'T',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepBlue),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    techName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Text(
                    'Certified FixIT Technician',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Info cards
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              if (distanceKm != null)
                _InfoRow(
                  icon: Icons.route_rounded,
                  label: 'Distance',
                  value: '${distanceKm!.toStringAsFixed(1)} km away',
                  iconColor: AppTheme.lightBlue,
                ),
              if (distanceKm != null) const Divider(height: 1),
              if (distanceFee != null)
                _InfoRow(
                  icon: Icons.directions_car_rounded,
                  label: 'Travel Fee',
                  value: '₱${distanceFee!.toStringAsFixed(2)}',
                  iconColor: AppTheme.primaryCyan,
                  valueColor: const Color(0xFF059669),
                  bold: true,
                ),
              if (distanceFee != null) const Divider(height: 1),
              _InfoRow(
                icon: Icons.devices_rounded,
                label: 'Device',
                value: deviceType,
                iconColor: AppTheme.deepBlue,
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.location_on_rounded,
                label: 'Your Location',
                value: address,
                iconColor: Colors.red,
                maxLines: 2,
              ),
            ],
          ),
        ),

        if (distanceFee == null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                Text(
                  'Travel fee will be calculated on arrival.',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;
  final bool bold;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueColor,
    this.bold = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: valueColor ?? AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String error;
  const _ErrorBody({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          const Text('Could not load technician info.',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(error,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
