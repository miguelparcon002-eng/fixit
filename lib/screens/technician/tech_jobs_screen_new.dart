import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import 'widgets/customer_location_sheet.dart';

// Provider for the initial tab to show in jobs screen
// 0 = Request, 1 = Active, 2 = Complete, 3 = All
final techJobsInitialTabProvider = StateProvider<int>((ref) => 0);

enum _TechJobsTab { request, active, complete, all }

// ─── Filter model ─────────────────────────────────────────────────────────────

enum _TechSortOrder { newest, oldest }

class _TechJobFilter {
  final Set<String> statuses; // empty = all
  final DateTime? fromDate;
  final DateTime? toDate;
  final _TechSortOrder sort;
  final bool? emergencyOnly; // null = both, true = only emergency, false = only regular

  const _TechJobFilter({
    this.statuses = const {},
    this.fromDate,
    this.toDate,
    this.sort = _TechSortOrder.newest,
    this.emergencyOnly,
  });

  bool get isActive =>
      statuses.isNotEmpty ||
      fromDate != null ||
      toDate != null ||
      emergencyOnly != null;

  _TechJobFilter copyWith({
    Set<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFrom = false,
    bool clearTo = false,
    _TechSortOrder? sort,
    Object? emergencyOnly = _sentinel,
  }) {
    return _TechJobFilter(
      statuses: statuses ?? this.statuses,
      fromDate: clearFrom ? null : (fromDate ?? this.fromDate),
      toDate: clearTo ? null : (toDate ?? this.toDate),
      sort: sort ?? this.sort,
      emergencyOnly:
          identical(emergencyOnly, _sentinel) ? this.emergencyOnly : emergencyOnly as bool?,
    );
  }

  static const _sentinel = Object();
}

// ─────────────────────────────────────────────────────────────────────────────

class TechJobsScreenNew extends ConsumerStatefulWidget {
  const TechJobsScreenNew({super.key});

  @override
  ConsumerState<TechJobsScreenNew> createState() => _TechJobsScreenNewState();
}

class _TechJobsScreenNewState extends ConsumerState<TechJobsScreenNew> {
  _TechJobsTab _selectedTab = _TechJobsTab.request;
  _TechJobFilter _filter = const _TechJobFilter();

  @override
  Widget build(BuildContext context) {
    final providerTab = ref.watch(techJobsInitialTabProvider);
    final mapped = _tabFromInt(providerTab);
    if (providerTab != 0 && mapped != _selectedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedTab = mapped);
        ref.read(techJobsInitialTabProvider.notifier).state = 0;
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Jobs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(technicianBookingsProvider),
            icon: const Icon(Icons.refresh, color: AppTheme.deepBlue),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Filter',
                onPressed: _openFilterSheet,
                icon: const Icon(Icons.tune_rounded, color: AppTheme.deepBlue),
              ),
              if (_filter.isActive)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _buildTabs(),
            ),
            if (_filter.isActive) _buildActiveFilterBanner(),
            const SizedBox(height: 4),
            Expanded(child: _buildJobsList()),
          ],
        ),
      ),
    );
  }

  // ─── Filter helpers ──────────────────────────────────────────────────────

  Widget _buildActiveFilterBanner() {
    final parts = <String>[];
    if (_filter.statuses.isNotEmpty) {
      parts.add(_filter.statuses.map(_displayStatus).join(', '));
    }
    if (_filter.emergencyOnly == true) parts.add('Emergency only');
    if (_filter.emergencyOnly == false) parts.add('Regular only');
    if (_filter.fromDate != null) {
      parts.add('From ${DateFormat('MMM d').format(_filter.fromDate!)}');
    }
    if (_filter.toDate != null) {
      parts.add('To ${DateFormat('MMM d').format(_filter.toDate!)}');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 14, color: AppTheme.deepBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepBlue,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _filter = const _TechJobFilter()),
            child: const Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayStatus(String s) => switch (s) {
        'requested' => 'Requested',
        'accepted' => 'Accepted',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => s,
      };

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_TechJobFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TechFilterSheet(current: _filter),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  _TechJobsTab _tabFromInt(int value) {
    return switch (value) {
      0 => _TechJobsTab.request,
      1 => _TechJobsTab.active,
      2 => _TechJobsTab.complete,
      3 => _TechJobsTab.all,
      _ => _TechJobsTab.request,
    };
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SegmentedButton<_TechJobsTab>(
        segments: const [
          ButtonSegment(value: _TechJobsTab.request, label: Text('Request')),
          ButtonSegment(value: _TechJobsTab.active, label: Text('Active')),
          ButtonSegment(value: _TechJobsTab.complete, label: Text('Complete')),
          ButtonSegment(value: _TechJobsTab.all, label: Text('All')),
        ],
        selected: {_selectedTab},
        showSelectedIcon: false,
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.white
                : AppTheme.textPrimaryColor;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppTheme.deepBlue
                : Colors.transparent;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        onSelectionChanged: (value) {
          setState(() => _selectedTab = value.first);
        },
      ),
    );
  }

  Widget _buildJobsList() {
    final bookingsAsync = ref.watch(technicianBookingsProvider);

    return RefreshIndicator(
      color: AppTheme.deepBlue,
      onRefresh: () async {
        ref.invalidate(technicianBookingsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
      child: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue),
          ),
        ),
        error: (error, stack) => _ErrorState(
          title: 'Couldn\'t load jobs',
          message: error.toString(),
          onRetry: () => ref.invalidate(technicianBookingsProvider),
        ),
        data: (allBookings) => _buildJobsContent(allBookings),
      ),
    );
  }

  Widget _buildJobsContent(List<BookingModel> allBookings) {
    // 1. Tab filter
    List<BookingModel> filtered = _filterBookings(allBookings);

    // 2. Advanced filters
    if (_filter.statuses.isNotEmpty) {
      filtered = filtered.where((b) => _filter.statuses.contains(b.status)).toList();
    }
    if (_filter.emergencyOnly != null) {
      filtered = filtered.where((b) => b.isEmergency == _filter.emergencyOnly).toList();
    }
    if (_filter.fromDate != null) {
      final from = DateTime(_filter.fromDate!.year, _filter.fromDate!.month, _filter.fromDate!.day);
      filtered = filtered.where((b) {
        final d = b.scheduledDate ?? b.createdAt;
        return !d.isBefore(from);
      }).toList();
    }
    if (_filter.toDate != null) {
      final to = DateTime(_filter.toDate!.year, _filter.toDate!.month, _filter.toDate!.day, 23, 59, 59);
      filtered = filtered.where((b) {
        final d = b.scheduledDate ?? b.createdAt;
        return !d.isAfter(to);
      }).toList();
    }

    if (filtered.isEmpty) {
      final (icon, title, subtitle) = _emptyStateForTab();
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          _EmptyState(
            icon: icon,
            title: _filter.isActive ? 'No results for your filter' : title,
            subtitle: _filter.isActive ? 'Try adjusting or clearing your filter.' : subtitle,
          ),
        ],
      );
    }

    // 3. Sort
    final sorted = [...filtered]..sort((a, b) {
        if (_filter.sort == _TechSortOrder.oldest) {
          final aDate = a.scheduledDate ?? a.createdAt;
          final bDate = b.scheduledDate ?? b.createdAt;
          return aDate.compareTo(bDate);
        }
        // Default: emergency first, then newest
        final prio = (b.isEmergency ? 1 : 0).compareTo(a.isEmergency ? 1 : 0);
        if (prio != 0) return prio;
        final aDate = a.scheduledDate ?? a.createdAt;
        final bDate = b.scheduledDate ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final booking = sorted[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TechJobCard(booking: booking, selectedTab: _selectedTab),
        );
      },
    );
  }

  List<BookingModel> _filterBookings(List<BookingModel> allBookings) {
    return switch (_selectedTab) {
      _TechJobsTab.request => allBookings
          .where((b) => b.status == 'requested' || b.status == 'accepted')
          .toList(),
      _TechJobsTab.active =>
        allBookings.where((b) => b.status == 'in_progress').toList(),
      _TechJobsTab.complete =>
        allBookings.where((b) => b.status == 'completed').toList(),
      _TechJobsTab.all => allBookings,
    };
  }

  (IconData, String, String) _emptyStateForTab() {
    return switch (_selectedTab) {
      _TechJobsTab.request => (
          Icons.inbox_outlined,
          'No job requests',
          'New job requests will appear here.',
        ),
      _TechJobsTab.active => (
          Icons.work_outline,
          'No active jobs',
          'When you accept a job it will show up here.',
        ),
      _TechJobsTab.complete => (
          Icons.check_circle_outline,
          'No completed jobs',
          'Completed jobs will appear here for reference.',
        ),
      _TechJobsTab.all => (
          Icons.inbox_outlined,
          'No jobs yet',
          'Once you receive jobs, they will show up here.',
        ),
    };
  }
}

class _TechJobCard extends ConsumerWidget {
  final BookingModel booking;
  final _TechJobsTab selectedTab;

  const _TechJobCard({required this.booking, required this.selectedTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingService = ref.read(bookingServiceProvider);

    final (statusColor, statusLabel, statusIcon) = _status(booking.status);
    final scheduled = booking.scheduledDate;

    final dateLabel = scheduled == null ? 'TBD' : DateFormat('MMM d').format(scheduled);
    final timeLabel = scheduled == null ? 'TBD' : DateFormat('h:mm a').format(scheduled);

    final total = booking.finalCost ?? booking.estimatedCost ?? 0.0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/booking/${booking.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor),
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
                                'Job #${booking.id.substring(0, 8)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StatusChip(label: statusLabel, color: statusColor),
                                const SizedBox(width: 8),
                                _TypeChip(isEmergency: booking.isEmergency),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MetaPill(icon: Icons.calendar_today, label: dateLabel),
                            const SizedBox(width: 8),
                            _MetaPill(icon: Icons.access_time, label: timeLabel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _MetaLine(
                          icon: Icons.location_on_outlined,
                          text: booking.customerAddress ?? 'No address set',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '₱${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.deepBlue,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
              if (booking.diagnosticNotes != null && booking.diagnosticNotes!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _NotesBox(text: booking.diagnosticNotes!),
              ],
              const SizedBox(height: 12),
              _buildActionButtons(context, ref, bookingService),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String, IconData) _status(String status) {
    return switch (status) {
      'requested' => (AppTheme.warningColor, 'New request', Icons.inbox_outlined),
      'accepted' || 'scheduled' => (AppTheme.lightBlue, 'Accepted', Icons.event_available),
      'in_progress' => (AppTheme.accentPurple, 'In progress', Icons.play_circle_outline),
      'completed' => (AppTheme.successColor, 'Completed', Icons.check_circle_outline),
      'cancelled' => (AppTheme.errorColor, 'Cancelled', Icons.cancel_outlined),
      _ => (Colors.grey, status, Icons.info_outline),
    };
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) {
    // Request tab - show accept/decline for requested
    if (selectedTab == _TechJobsTab.request && booking.status == 'requested') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _declineJob(context, ref, bookingService),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Decline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptJob(context, ref, bookingService),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // Active tab - show payment status + adjust price + mark complete
    if (selectedTab == _TechJobsTab.active && booking.status == 'in_progress') {
      final payStatus = booking.paymentStatus ?? 'pending';
      final (payLabel, payIcon, payColor) = switch (payStatus) {
        'completed' => ('Payment Completed', Icons.check_circle, AppTheme.successColor),
        'submitted' => ('Payment Submitted - Awaiting Verification', Icons.hourglass_top, Colors.orange),
        _ => ('Payment Pending', Icons.payment, Colors.grey),
      };

      return Column(
        children: [
          // Payment status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: payColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: payColor.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                Icon(payIcon, size: 18, color: payColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: payColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Track customer location button — only if coordinates were pinned
          if (booking.customerLatitude != null && booking.customerLongitude != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CustomerLocationSheet(
                      latitude: booking.customerLatitude!,
                      longitude: booking.customerLongitude!,
                      customerName: booking.customerAddress ?? 'Customer',
                      address: booking.customerAddress ?? 'No address provided',
                    ),
                  );
                },
                icon: const Icon(Icons.location_searching, size: 18),
                label: const Text('Track Customer Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4A5FE0),
                  side: const BorderSide(color: Color(0xFF4A5FE0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (payStatus == 'completed' || payStatus == 'submitted')
                      ? null
                      : () => _adjustPrice(context, ref, bookingService),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Adjust price'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.deepBlue,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: payStatus == 'completed'
                      ? () => _completeJob(context, ref, bookingService)
                      : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Completed state
    if ((selectedTab == _TechJobsTab.complete || selectedTab == _TechJobsTab.all) &&
        booking.status == 'completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
            SizedBox(width: 8),
            Text(
              'Completed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _acceptJob(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) async {
    try {
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: 'in_progress',
      );

      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'booking_accepted',
        title: 'Booking Accepted',
        message: 'Your booking has been accepted by the technician and is now in progress.',
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
      );

      // Mark the redeemed voucher as used now that the job is accepted
      final voucherId = booking.redeemedVoucherId;
      if (voucherId != null) {
        final voucherService = ref.read(redeemedVoucherServiceProvider);
        await voucherService.markVoucherAsUsed(
          voucherId: voucherId,
          bookingId: booking.id,
        );
      }

      ref.invalidate(technicianBookingsProvider);
      ref.read(techJobsInitialTabProvider.notifier).state = 1;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted and started!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept job: $e')),
      );
    }
  }

  Future<void> _declineJob(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline job?'),
        content: const Text('Are you sure you want to decline this job request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: 'cancelled',
      );

      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'booking_declined',
        title: 'Booking Declined',
        message: 'Unfortunately, the technician was unable to accept your booking. Please try booking another technician.',
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
      );

      ref.invalidate(technicianBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job declined.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline job: $e')),
      );
    }
  }

  Future<void> _adjustPrice(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) async {
    final noteController = TextEditingController();
    // Track mutable state outside StatefulBuilder so it survives rebuilds
    double adjustmentAmount = 0;
    bool isIncrease = true; // true = increase, false = decrease
    bool saving = false;

    try {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setState) {
              final note = noteController.text.trim();
              final hasValidAmount = adjustmentAmount > 0;
              final canSave = !saving && hasValidAmount && note.isNotEmpty;

              final signedAmount = isIncrease ? adjustmentAmount : -adjustmentAmount;
              final basePrice = booking.estimatedCost ?? booking.finalCost ?? 0.0;
              final newPrice = (basePrice + signedAmount).clamp(0.0, double.infinity);

              void stepAmount(double delta) {
                setState(() {
                  adjustmentAmount = (adjustmentAmount + delta).clamp(0.0, 99999.0);
                });
              }

              void setQuickAmount(double amount) {
                setState(() => adjustmentAmount = amount);
              }

              Future<void> save() async {
                setState(() => saving = true);
                try {
                  final reason = noteController.text.trim();
                  await bookingService.addTechnicianNotes(
                    bookingId: booking.id,
                    technicianNotes: 'Price adjustment note: $reason',
                    priceAdjustment: signedAmount,
                  );
                  // Pop the sheet first, then invalidate so the provider
                  // refresh happens outside the sheet's widget tree.
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext, true);
                } catch (e) {
                  if (!sheetContext.mounted) return;
                  setState(() => saving = false);
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text('Failed to adjust price: $e')),
                  );
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.deepBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.tune_rounded, color: AppTheme.deepBlue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Adjust Price',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: saving ? null : () => Navigator.pop(sheetContext, false),
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Current price display
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Original Price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${basePrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade400),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Adjusted Price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${newPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: hasValidAmount
                                            ? (isIncrease ? AppTheme.errorColor : AppTheme.successColor)
                                            : AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Increase / Decrease toggle
                          const Text(
                            'Adjustment Type',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: saving ? null : () => setState(() => isIncrease = true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isIncrease ? AppTheme.errorColor : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isIncrease ? AppTheme.errorColor : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward_rounded,
                                          size: 18,
                                          color: isIncrease ? Colors.white : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Increase',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: isIncrease ? Colors.white : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: saving ? null : () => setState(() => isIncrease = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: !isIncrease ? AppTheme.successColor : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: !isIncrease ? AppTheme.successColor : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward_rounded,
                                          size: 18,
                                          color: !isIncrease ? Colors.white : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Decrease',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: !isIncrease ? Colors.white : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Amount stepper
                          const Text(
                            'Amount (₱)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Minus button
                              _StepButton(
                                icon: Icons.remove_rounded,
                                color: AppTheme.errorColor,
                                enabled: !saving && adjustmentAmount > 0,
                                onTap: () => stepAmount(-50),
                                onLongPress: () => stepAmount(-100),
                              ),
                              const SizedBox(width: 12),
                              // Amount display / input
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final inputController = TextEditingController(
                                      text: adjustmentAmount > 0 ? adjustmentAmount.toStringAsFixed(0) : '',
                                    );
                                    await showDialog(
                                      context: sheetContext,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Enter amount'),
                                        content: TextField(
                                          controller: inputController,
                                          autofocus: true,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            prefixText: '₱ ',
                                            border: OutlineInputBorder(),
                                            hintText: '0',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              final v = double.tryParse(inputController.text.replaceAll(',', '').trim());
                                              if (v != null && v >= 0) {
                                                setState(() => adjustmentAmount = v);
                                              }
                                              Navigator.pop(ctx);
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepBlue, foregroundColor: Colors.white),
                                            child: const Text('Set'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: hasValidAmount
                                            ? (isIncrease ? AppTheme.errorColor : AppTheme.successColor)
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '₱${adjustmentAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: hasValidAmount
                                                ? (isIncrease ? AppTheme.errorColor : AppTheme.successColor)
                                                : Colors.grey.shade400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tap to type exact amount',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Plus button
                              _StepButton(
                                icon: Icons.add_rounded,
                                color: AppTheme.successColor,
                                enabled: !saving,
                                onTap: () => stepAmount(50),
                                onLongPress: () => stepAmount(100),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Tap +/− to step by ₱50 · Hold for ₱100',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Quick presets
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [100, 200, 300, 500, 1000].map((preset) {
                              final isSelected = adjustmentAmount == preset.toDouble();
                              return GestureDetector(
                                onTap: saving ? null : () => setQuickAmount(preset.toDouble()),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isIncrease ? AppTheme.errorColor : AppTheme.successColor)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isIncrease ? AppTheme.errorColor : AppTheme.successColor)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    '₱$preset',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Note field
                          const Text(
                            'Reason *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            enabled: !saving,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'e.g. Additional parts required, labour cost, discount applied…',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppTheme.deepBlue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: canSave ? save : null,
                              icon: saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: Text(
                                saving ? 'Saving…' : 'Confirm Adjustment',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canSave ? AppTheme.deepBlue : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade200,
                                disabledForegroundColor: Colors.grey.shade400,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: canSave ? 2 : 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (confirmed != true) return;
      // Invalidate after the sheet is fully closed to avoid _dependents assertion
      ref.invalidate(technicianBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price adjustment saved.'),
          backgroundColor: AppTheme.deepBlue,
        ),
      );
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _completeJob(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) async {
    try {
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: 'completed',
      );

      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'booking_completed',
        title: 'Booking Completed',
        message: 'Your repair has been completed! Please rate your experience with the technician.',
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
      );

      ref.invalidate(technicianBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job marked as completed!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete job: $e')),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final bool isEmergency;

  const _TypeChip({required this.isEmergency});

  @override
  Widget build(BuildContext context) {
    final color = isEmergency ? Colors.red : AppTheme.lightBlue;
    final label = isEmergency ? 'Emergency' : 'Regular';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NotesBox extends StatelessWidget {
  final String text;

  const _NotesBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_rounded, size: 16, color: AppTheme.deepBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.deepBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 30, color: AppTheme.deepBlue),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 30,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tech filter bottom sheet ─────────────────────────────────────────────────

class _TechFilterSheet extends StatefulWidget {
  final _TechJobFilter current;
  const _TechFilterSheet({required this.current});

  @override
  State<_TechFilterSheet> createState() => _TechFilterSheetState();
}

class _TechFilterSheetState extends State<_TechFilterSheet> {
  late Set<String> _statuses;
  late DateTime? _from;
  late DateTime? _to;
  late _TechSortOrder _sort;
  late bool? _emergencyOnly;

  static const _allStatuses = [
    'requested',
    'in_progress',
    'completed',
    'cancelled',
  ];

  static const _statusLabels = {
    'requested': 'Requested',
    'in_progress': 'Active',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static const _statusColors = {
    'requested': AppTheme.warningColor,
    'in_progress': AppTheme.accentPurple,
    'completed': AppTheme.successColor,
    'cancelled': AppTheme.errorColor,
  };

  @override
  void initState() {
    super.initState();
    _statuses = Set.from(widget.current.statuses);
    _from = widget.current.fromDate;
    _to = widget.current.toDate;
    _sort = widget.current.sort;
    _emergencyOnly = widget.current.emergencyOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Filter Jobs',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _statuses = {};
                          _from = null;
                          _to = null;
                          _sort = _TechSortOrder.newest;
                          _emergencyOnly = null;
                        }),
                        child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status chips
                  _SheetSection(label: 'Status', icon: Icons.label_outline),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allStatuses.map((s) {
                      final selected = _statuses.contains(s);
                      final color = _statusColors[s] ?? Colors.grey;
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _statuses = Set.from(_statuses)..remove(s);
                          } else {
                            _statuses = Set.from(_statuses)..add(s);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? color : Colors.grey.shade300,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            _statusLabels[s] ?? s,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? color : AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Job type
                  _SheetSection(label: 'Job Type', icon: Icons.bolt_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TypeToggle(
                        label: 'All Types',
                        selected: _emergencyOnly == null,
                        color: AppTheme.deepBlue,
                        onTap: () => setState(() => _emergencyOnly = null),
                      ),
                      const SizedBox(width: 8),
                      _TypeToggle(
                        label: 'Emergency',
                        selected: _emergencyOnly == true,
                        color: Colors.red,
                        onTap: () => setState(() => _emergencyOnly = true),
                      ),
                      const SizedBox(width: 8),
                      _TypeToggle(
                        label: 'Regular',
                        selected: _emergencyOnly == false,
                        color: AppTheme.lightBlue,
                        onTap: () => setState(() => _emergencyOnly = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date range
                  _SheetSection(label: 'Date Range', icon: Icons.calendar_today_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TechDateButton(
                          label: _from == null ? 'From date' : DateFormat('MMM d, y').format(_from!),
                          hasValue: _from != null,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _from ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _from = d);
                          },
                          onClear: _from != null ? () => setState(() => _from = null) : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TechDateButton(
                          label: _to == null ? 'To date' : DateFormat('MMM d, y').format(_to!),
                          hasValue: _to != null,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _to ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _to = d);
                          },
                          onClear: _to != null ? () => setState(() => _to = null) : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sort
                  _SheetSection(label: 'Sort Order', icon: Icons.sort),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TechSortChip(
                          label: 'Newest First',
                          icon: Icons.arrow_downward,
                          selected: _sort == _TechSortOrder.newest,
                          onTap: () => setState(() => _sort = _TechSortOrder.newest),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TechSortChip(
                          label: 'Oldest First',
                          icon: Icons.arrow_upward,
                          selected: _sort == _TechSortOrder.oldest,
                          onTap: () => setState(() => _sort = _TechSortOrder.oldest),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Apply
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _TechJobFilter(
                          statuses: _statuses,
                          fromDate: _from,
                          toDate: _to,
                          sort: _sort,
                          emergencyOnly: _emergencyOnly,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Apply Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SheetSection({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            )),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? color : AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TechDateButton extends StatelessWidget {
  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _TechDateButton({
    required this.label,
    required this.hasValue,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? AppTheme.deepBlue.withValues(alpha: 0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppTheme.deepBlue.withValues(alpha: 0.40) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14,
                color: hasValue ? AppTheme.deepBlue : AppTheme.textSecondaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasValue ? AppTheme.deepBlue : AppTheme.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _TechSortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TechSortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.deepBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.deepBlue : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.textSecondaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// Step button used in the price adjustment bottom sheet
class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StepButton({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 26,
          color: enabled ? color : Colors.grey.shade300,
        ),
      ),
    );
  }
}
