import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/job_status_tracker.dart';
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
  // null = all, 'post_problem' = job-map accepted, 'booking' = regular bookings
  final String? bookingSource;

  const _TechJobFilter({
    this.statuses = const {},
    this.fromDate,
    this.toDate,
    this.sort = _TechSortOrder.newest,
    this.emergencyOnly,
    this.bookingSource,
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
    Object? bookingSource = _sentinel,
  }) {
    return _TechJobFilter(
      statuses: statuses ?? this.statuses,
      fromDate: clearFrom ? null : (fromDate ?? this.fromDate),
      toDate: clearTo ? null : (toDate ?? this.toDate),
      sort: sort ?? this.sort,
      emergencyOnly:
          identical(emergencyOnly, _sentinel) ? this.emergencyOnly : emergencyOnly as bool?,
      bookingSource:
          identical(bookingSource, _sentinel) ? this.bookingSource : bookingSource as String?,
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
            if (_selectedTab == _TechJobsTab.active) _buildSourceFilterChips(),
            if (_filter.isActive) _buildActiveFilterBanner(),
            const SizedBox(height: 4),
            Expanded(child: _buildJobsList()),
          ],
        ),
      ),
    );
  }

  // ─── Filter helpers ──────────────────────────────────────────────────────

  Widget _buildSourceFilterChips() {
    final options = [
      (null, 'All'),
      ('post_problem', 'Post Problem'),
      ('booking', 'Booking'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: options.map((opt) {
          final (value, label) = opt;
          final selected = _filter.bookingSource == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(
                () => _filter = _filter.copyWith(bookingSource: value),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.deepBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.deepBlue : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
          setState(() {
            _selectedTab = value.first;
            // Clear source filter when leaving Active tab
            if (_selectedTab != _TechJobsTab.active) {
              _filter = _filter.copyWith(bookingSource: null);
            }
          });
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
    if (_filter.bookingSource != null) {
      filtered = filtered.where((b) {
        return _filter.bookingSource == 'post_problem'
            ? _isPostProblem(b)
            : !_isPostProblem(b);
      }).toList();
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
        // Default: emergency first, then by date
        final prio = (b.isEmergency ? 1 : 0).compareTo(a.isEmergency ? 1 : 0);
        if (prio != 0) return prio;
        final aDate = a.scheduledDate ?? a.createdAt;
        final bDate = b.scheduledDate ?? b.createdAt;
        // Active tab: soonest first so today's jobs appear at top
        if (_selectedTab == _TechJobsTab.active) {
          return aDate.compareTo(bDate);
        }
        return bDate.compareTo(aDate); // other tabs: newest first
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
      _TechJobsTab.request =>
        allBookings.where((b) => b.status == AppConstants.bookingRequested).toList(),
      _TechJobsTab.active => allBookings.where((b) => [
            AppConstants.bookingAccepted,
            AppConstants.bookingEnRoute,
            AppConstants.bookingArrived,
            AppConstants.bookingInProgress,
            AppConstants.bookingCompleted,
            AppConstants.bookingPaid,   // stays in Active until tech marks complete
          ].contains(b.status)).toList(),
      _TechJobsTab.complete => allBookings.where((b) => [
            AppConstants.bookingClosed,
          ].contains(b.status)).toList(),
      _TechJobsTab.all => allBookings,
    };
  }

  /// Returns true if [b] originated from the "Post a Problem / Job Map" flow.
  ///
  /// Layer 1 — DB field (new bookings, most reliable):
  ///   booking_source = 'post_problem'
  ///
  /// Layer 2 — Explicit marker in notes (pre-DB-column, still in notes):
  ///   diagnostic_notes starts with '[POST_PROBLEM]'
  ///
  /// Layer 3 — accepted_at heuristic (legacy data):
  ///   Regular bookings go through requested→accepted via the set_booking_status
  ///   RPC, which writes accepted_at. Post-problem bookings are created directly
  ///   as 'accepted' via INSERT, so accepted_at is never set by the RPC.
  ///   accepted_at != null  →  went through normal flow  →  regular booking.
  ///
  /// Layer 4 — Notes format fallback (last resort):
  ///   All regular booking flows write notes starting with 'Repair Type:' or
  ///   'Device:'. Check the customer portion (before any '---TECHNICIAN NOTES---'
  ///   separator) so technician-appended text doesn't affect classification.
  bool _isPostProblem(BookingModel b) {
    // Layer 1
    if (b.bookingSource == 'post_problem') return true;
    // Layer 2
    final notes = b.diagnosticNotes;
    if (notes != null && notes.startsWith('[POST_PROBLEM]')) return true;
    // Layer 3 — has accepted_at → normal booking flow → NOT post-problem
    if (b.acceptedAt != null) return false;
    // Layer 4 — check notes format on the customer portion only
    if (notes == null || notes.isEmpty) return false;
    final customerPart = notes.split('---TECHNICIAN NOTES---').first.trim();
    if (customerPart.startsWith('Repair Type:') || customerPart.startsWith('Device:')) {
      return false;
    }
    return true;
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
              if (booking.moreDetails != null && booking.moreDetails!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _NotesBox(text: booking.moreDetails!),
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
      'requested'   => (AppTheme.warningColor,       'New Request',       Icons.inbox_outlined),
      'accepted'    => (AppTheme.lightBlue,           'Accepted',          Icons.check_circle_outline),
      'en_route'    => (const Color(0xFF0EA5E9),      'En Route',          Icons.directions_car_outlined),
      'arrived'     => (const Color(0xFF8B5CF6),      'Arrived',           Icons.place_outlined),
      'in_progress' => (AppTheme.accentPurple,        'In Progress',       Icons.build_circle_outlined),
      'completed'   => (Colors.orange,                'Awaiting Payment',  Icons.hourglass_top_rounded),
      'paid'        => (const Color(0xFF059669),      'Payment Received',  Icons.payments_outlined),
      'closed'      => (const Color(0xFF059669),      'Completed',         Icons.check_circle_outlined),
      'cancelled'   => (AppTheme.errorColor,          'Cancelled',         Icons.cancel_outlined),
      _             => (Colors.grey, status, Icons.info_outline),
    };
  }

  Widget _progressHeader() => const Row(
    children: [
      Icon(Icons.route_outlined, size: 14, color: AppTheme.deepBlue),
      SizedBox(width: 6),
      Text(
        'Job Progress',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.deepBlue,
        ),
      ),
    ],
  );

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

    // ── Pre-work active statuses (accepted / en_route): advance button ────────
    if (selectedTab == _TechJobsTab.active &&
        (booking.status == AppConstants.bookingAccepted ||
         booking.status == AppConstants.bookingEnRoute)) {
      final (nextStatus, btnLabel, btnIcon, notifTitle, notifMsg) =
          switch (booking.status) {
        AppConstants.bookingAccepted => (
            AppConstants.bookingEnRoute,
            "I'm On My Way",
            Icons.directions_car_outlined,
            'Technician En Route',
            'Your technician is on the way to your location!',
          ),
        _ => (
            AppConstants.bookingArrived,
            "I've Arrived",
            Icons.place_outlined,
            'Technician Arrived',
            'Your technician has arrived at your location!',
          ),
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Primary action: always visible at the top ─────────────────────
          ElevatedButton.icon(
            onPressed: () => _advanceJobStatus(
              context, ref, bookingService,
              nextStatus, notifTitle, notifMsg,
            ),
            icon: Icon(btnIcon, size: 18),
            label: Text(btnLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          // ── Progress tracker (next step is also tappable) ─────────────────
          _progressHeader(),
          const SizedBox(height: 10),
          JobStatusTracker(
            currentStatus: booking.status,
            onNextStepTap: (ns) => _advanceJobStatus(
              context, ref, bookingService,
              ns, notifTitle, notifMsg,
            ),
          ),
          if (booking.customerLatitude != null && booking.customerLongitude != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CustomerLocationSheet(
                  latitude: booking.customerLatitude!,
                  longitude: booking.customerLongitude!,
                  customerName: booking.customerAddress ?? 'Customer',
                  address: booking.customerAddress ?? 'No address provided',
                ),
              ),
              icon: const Icon(Icons.location_searching, size: 18),
              label: const Text('View Customer Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A5FE0),
                side: const BorderSide(color: Color(0xFF4A5FE0)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      );
    }

    // ── Arrived: assess & price + start work ─────────────────────────────────
    if (selectedTab == _TechJobsTab.active &&
        booking.status == AppConstants.bookingArrived) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _assessAndPrice(context, ref, bookingService),
            icon: const Icon(Icons.medical_services_rounded, size: 18),
            label: const Text('Assess & Price'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.deepBlue,
              side: const BorderSide(color: AppTheme.deepBlue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _adjustPrice(context, ref, bookingService),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Adjust Price'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _advanceJobStatus(
              context, ref, bookingService,
              AppConstants.bookingInProgress,
              'Repair Started',
              'Your technician has started working on your device.',
            ),
            icon: const Icon(Icons.build_circle_outlined, size: 18),
            label: const Text('Start Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          _progressHeader(),
          const SizedBox(height: 10),
          JobStatusTracker(
            currentStatus: booking.status,
            onNextStepTap: (ns) => _advanceJobStatus(
              context, ref, bookingService,
              ns, 'Repair Started', 'Your technician has started working on your device.',
            ),
          ),
          if (booking.customerLatitude != null && booking.customerLongitude != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CustomerLocationSheet(
                  latitude: booking.customerLatitude!,
                  longitude: booking.customerLongitude!,
                  customerName: booking.customerAddress ?? 'Customer',
                  address: booking.customerAddress ?? 'No address provided',
                ),
              ),
              icon: const Icon(Icons.location_searching, size: 18),
              label: const Text('View Customer Location'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A5FE0),
                side: const BorderSide(color: Color(0xFF4A5FE0)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      );
    }

    // ── In-progress: tracker + adjust price + mark done ───────────────────────
    if (selectedTab == _TechJobsTab.active &&
        booking.status == AppConstants.bookingInProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progressHeader(),
          const SizedBox(height: 10),
          JobStatusTracker(currentStatus: booking.status),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _adjustPrice(context, ref, bookingService),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Adjust Price'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.deepBlue,
              side: const BorderSide(color: AppTheme.deepBlue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _completeJob(context, ref, bookingService),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark as Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    // ── Completed in active tab: tracker + confirm paid ──────────────────
    if ((selectedTab == _TechJobsTab.active || selectedTab == _TechJobsTab.all) &&
        booking.status == AppConstants.bookingCompleted) {
      final payStatus = booking.paymentStatus ?? 'pending';
      final isPaid = payStatus == 'completed';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progressHeader(),
          const SizedBox(height: 10),
          JobStatusTracker(currentStatus: booking.status),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isPaid ? () => _markPaid(context, ref, bookingService) : null,
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: Text(isPaid ? 'Confirm Payment Received' : 'Awaiting Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    // ── Paid in active tab: tracker at "Paid" + Mark Complete button ──────
    if ((selectedTab == _TechJobsTab.active || selectedTab == _TechJobsTab.all) &&
        booking.status == AppConstants.bookingPaid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progressHeader(),
          const SizedBox(height: 10),
          JobStatusTracker(currentStatus: booking.status),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _closeJob(context, ref, bookingService),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Mark Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      );
    }

    // ── Closed: clean success card ─────────────────────────────────────────
    if ((selectedTab == _TechJobsTab.complete || selectedTab == _TechJobsTab.all) &&
        booking.status == AppConstants.bookingClosed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paid & Closed',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Job completed successfully',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.payments_outlined, color: Color(0xFF059669), size: 22),
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
        status: AppConstants.bookingAccepted,
      );

      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'booking_accepted',
        title: 'Booking Accepted',
        message: 'Your booking has been accepted! The technician will be on their way soon.',
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
      ref.invalidate(bookingByIdProvider(booking.id));
      ref.read(techJobsInitialTabProvider.notifier).state = 1;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted!'),
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

  Future<void> _advanceJobStatus(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
    String nextStatus,
    String notifTitle,
    String notifMsg,
  ) async {
    try {
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: nextStatus,
      );
      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'booking_update',
        title: notifTitle,
        message: notifMsg,
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
      );
      ref.invalidate(technicianBookingsProvider);
      ref.invalidate(bookingByIdProvider(booking.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notifTitle), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) async {
    try {
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: AppConstants.bookingPaid,
      );
      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'booking_paid',
        title: 'Payment Confirmed',
        message: 'Your payment has been confirmed. Thank you for using FixIT!',
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
      );
      // Notify admins
      try {
        final adminRows = await SupabaseConfig.client
            .from('users')
            .select('id')
            .eq('role', 'admin');
        for (final admin in (adminRows as List)) {
          await NotificationService().sendNotification(
            userId: admin['id'] as String,
            type: 'booking_paid',
            title: 'Booking Paid',
            message: 'Booking #${booking.id.substring(0, 8)} has been marked as paid.',
            data: {'booking_id': booking.id},
          );
        }
      } catch (_) {}
      ref.invalidate(technicianBookingsProvider);
      ref.invalidate(bookingByIdProvider(booking.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job marked as paid!'), backgroundColor: Color(0xFF059669)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _closeJob(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) async {
    try {
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: AppConstants.bookingClosed,
      );
      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: 'booking_update',
        title: 'Job Closed',
        message: 'Your job has been completed and closed. Thank you for using FixIT!',
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
      );
      ref.invalidate(technicianBookingsProvider);
      ref.invalidate(bookingByIdProvider(booking.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job marked as complete!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
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
      ref.invalidate(bookingByIdProvider(booking.id));
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
    final currentPrice = booking.finalCost ?? booking.estimatedCost ?? 0.0;
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final enteredAmt = double.tryParse(amountController.text.trim()) ?? 0.0;

          Future<void> apply(double sign) async {
            final amt = double.tryParse(amountController.text.trim());
            if (amt == null || amt <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter a valid amount')),
              );
              return;
            }
            setState(() => saving = true);
            try {
              final reason = reasonController.text.trim();
              final direction = sign > 0 ? 'increased' : 'decreased';
              final note = reason.isNotEmpty
                  ? 'Price $direction by ₱${amt.toStringAsFixed(2)} — Reason: $reason'
                  : 'Price $direction by ₱${amt.toStringAsFixed(2)}';
              await bookingService.addTechnicianNotes(
                bookingId: booking.id,
                technicianNotes: note,
                priceAdjustment: amt * sign,
              );
              ref.invalidate(technicianBookingsProvider);
              ref.invalidate(bookingByIdProvider(booking.id));
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sign > 0
                          ? 'Price increased by ₱${amt.toStringAsFixed(2)}'
                          : 'Price decreased by ₱${amt.toStringAsFixed(2)}',
                    ),
                    backgroundColor: sign > 0 ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                );
              }
            } catch (e) {
              setState(() => saving = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to adjust price: $e')),
                );
              }
            }
          }

          void setQuickAmount(double amt) {
            amountController.text = amt.toStringAsFixed(0);
            setState(() {});
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Gradient header ────────────────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adjust Price',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  'Update the repair cost for this job',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Price preview row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${currentPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 18,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: enteredAmt > 0
                                      ? Colors.white.withValues(alpha: 0.28)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: enteredAmt > 0
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AFTER ADJUST',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      enteredAmt > 0
                                          ? '₱${(currentPrice + enteredAmt).toStringAsFixed(2)}'
                                          : '—',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Body ──────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Quick presets
                        const Text(
                          'QUICK AMOUNTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final amt in [100.0, 250.0, 500.0, 1000.0])
                              GestureDetector(
                                onTap: () => setQuickAmount(amt),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: amountController.text == amt.toStringAsFixed(0)
                                        ? Color(0xFF8B5CF6)
                                        : Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '₱${amt.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: amountController.text == amt.toStringAsFixed(0)
                                          ? Colors.white
                                          : Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Amount field
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Custom Amount',
                            prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Reason field
                        TextField(
                          controller: reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Reason for adjustment',
                            hintText: 'e.g. Additional damage found on motherboard',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(Icons.notes_rounded, size: 20),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action buttons
                        if (saving)
                          const Center(child: CircularProgressIndicator())
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => apply(-1),
                                  icon: const Icon(Icons.arrow_downward_rounded, size: 17),
                                  label: const Text('Decrease'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.errorColor,
                                    side: const BorderSide(color: AppTheme.errorColor),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => apply(1),
                                  icon: const Icon(Icons.arrow_upward_rounded, size: 17),
                                  label: const Text('Increase'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF8B5CF6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    elevation: 0,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _assessAndPrice(
    BuildContext context,
    WidgetRef ref,
    BookingService bookingService,
  ) async {
    // ── Pricing catalogue per device type ─────────────────────────────────
    final Map<String, List<Map<String, dynamic>>> catalogue = {
      'Mobile Phone': [
        {'label': 'Screen Cracked / Broken', 'price': 800.0},
        {'label': 'Battery Replacement', 'price': 500.0},
        {'label': 'Charging Port Issue', 'price': 350.0},
        {'label': 'Speaker / Mic Issue', 'price': 300.0},
        {'label': 'Camera Not Working', 'price': 400.0},
        {'label': 'Water Damage', 'price': 700.0},
        {'label': 'Won\'t Power On', 'price': 600.0},
        {'label': 'Software / OS Problem', 'price': 250.0},
        {'label': 'Overheating', 'price': 300.0},
        {'label': 'Wi-Fi / Bluetooth Issue', 'price': 280.0},
      ],
      'Laptop': [
        {'label': 'Screen Cracked / Broken', 'price': 2500.0},
        {'label': 'Keyboard Damage', 'price': 1200.0},
        {'label': 'Battery Replacement', 'price': 1500.0},
        {'label': 'Won\'t Boot / No Power', 'price': 800.0},
        {'label': 'Overheating', 'price': 600.0},
        {'label': 'Virus / Malware Removal', 'price': 500.0},
        {'label': 'HDD / SSD Issue', 'price': 1000.0},
        {'label': 'Water Damage', 'price': 2000.0},
        {'label': 'RAM Issue', 'price': 800.0},
        {'label': 'Trackpad Issue', 'price': 700.0},
      ],
      'Tablet': [
        {'label': 'Screen Cracked / Broken', 'price': 1200.0},
        {'label': 'Battery Replacement', 'price': 600.0},
        {'label': 'Won\'t Power On', 'price': 700.0},
        {'label': 'Charging Issue', 'price': 400.0},
        {'label': 'Camera Not Working', 'price': 350.0},
        {'label': 'Water Damage', 'price': 800.0},
        {'label': 'Software / OS Problem', 'price': 300.0},
        {'label': 'Speaker Issue', 'price': 280.0},
      ],
      'TV': [
        {'label': 'No Power', 'price': 500.0},
        {'label': 'No Picture', 'price': 800.0},
        {'label': 'No Sound', 'price': 400.0},
        {'label': 'Remote Not Working', 'price': 200.0},
        {'label': 'HDMI Port Issue', 'price': 350.0},
        {'label': 'Backlight Issue', 'price': 700.0},
        {'label': 'Smart TV Software Issue', 'price': 400.0},
        {'label': 'Screen Lines / Flicker', 'price': 900.0},
      ],
      'Other': [
        {'label': 'Won\'t Turn On', 'price': 400.0},
        {'label': 'Power Supply Issue', 'price': 350.0},
        {'label': 'Mechanical Failure', 'price': 500.0},
        {'label': 'Control Board Issue', 'price': 600.0},
        {'label': 'Physical Damage', 'price': 450.0},
        {'label': 'Performance Issue', 'price': 350.0},
      ],
    };

    // ── Parse device info from booking notes ───────────────────────────────
    final notes = booking.diagnosticNotes ?? '';
    final rawDevice = RegExp(r'Device:\s*(.+)', caseSensitive: false)
            .firstMatch(notes)?.group(1)?.trim() ?? '';
    final deviceBrand = RegExp(r'Brand:\s*(.+)', caseSensitive: false)
            .firstMatch(notes)?.group(1)?.trim() ?? '';
    final deviceModel = RegExp(r'Model:\s*(.+)', caseSensitive: false)
            .firstMatch(notes)?.group(1)?.trim() ?? '';
    final deviceProblem = RegExp(r'Problem:\s*(.+)', caseSensitive: false)
            .firstMatch(notes)?.group(1)?.trim() ?? '';

    // Match device to catalogue key
    String deviceKey = 'Other';
    for (final key in catalogue.keys) {
      if (rawDevice.toLowerCase().contains(key.toLowerCase().split(' ').first)) {
        deviceKey = key;
        break;
      }
    }
    final items = catalogue[deviceKey]!;

    // ── Mutable state (captured by StatefulBuilder closure) ───────────────
    final diagNotesController = TextEditingController();
    final serviceFeeController = TextEditingController();
    final newPartController        = TextEditingController();
    final newPartPriceController   = TextEditingController();
    final customIssueController    = TextEditingController();
    final Set<String>  selectedIssues  = {};
    final List<String> customIssueOrder = [];
    final List<Map<String, dynamic>> addedParts = [
      for (final p in booking.partsList)
        {'name': p, 'price': 0.0},
    ];
    bool saving = false;

    try {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setState) {
            final serviceFee = double.tryParse(serviceFeeController.text.trim()) ?? 0.0;
            final partsTotal = addedParts.fold(0.0, (s, p) => s + (p['price'] as double));
            final distanceFee = booking.parsedDistanceFee ?? 0.0;
            final total = serviceFee + partsTotal + distanceFee;
            final canSave = !saving && (selectedIssues.isNotEmpty || serviceFee > 0 || partsTotal > 0);

            Future<void> save() async {
              setState(() => saving = true);
              try {
                final buf = StringBuffer();
                if (selectedIssues.isNotEmpty) {
                  buf.writeln('Identified Issues:');
                  for (final l in selectedIssues) {
                    buf.writeln('• $l');
                  }
                }
                if (serviceFee > 0) buf.writeln('Service Fee: ₱${serviceFee.toStringAsFixed(2)}');
                if (addedParts.isNotEmpty) {
                  buf.writeln('Parts Used:');
                  for (final p in addedParts) {
                    buf.writeln('• ${p['name']} — ₱${(p['price'] as double).toStringAsFixed(2)}');
                  }
                }
                final diagNote = diagNotesController.text.trim();
                if (diagNote.isNotEmpty) buf.writeln('Technician Notes: $diagNote');

                final customerPart = booking.moreDetails ?? notes;
                final combined = '$customerPart\n---TECHNICIAN NOTES---\n${buf.toString().trim()}';
                await bookingService.updateDiagnosticNotes(
                  bookingId: booking.id,
                  notes: combined,
                  partsList: addedParts.isEmpty ? null : addedParts
                      .map((p) => '${p['name']} — ₱${(p['price'] as double).toStringAsFixed(2)}')
                      .toList(),
                  finalCost: total,
                );
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext, true);
              } catch (e) {
                if (!sheetContext.mounted) return;
                setState(() => saving = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text('Failed to save assessment: $e')),
                );
              }
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              builder: (_, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.deepBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.medical_services_rounded, color: AppTheme.deepBlue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assess & Price',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                                Text('Diagnose device and set charges',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: saving ? null : () => Navigator.pop(sheetContext, false),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade100, height: 1),
                    // Scrollable body
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          // Device info banner
                          if (rawDevice.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.devices_rounded, size: 13, color: Colors.blue.shade700),
                                    const SizedBox(width: 5),
                                    Text("Customer's Device",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blue.shade700)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$rawDevice${deviceBrand.isNotEmpty ? ' · $deviceBrand' : ''}${deviceModel.isNotEmpty ? ' $deviceModel' : ''}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                                  ),
                                  if (deviceProblem.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text('Reported: $deviceProblem',
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                                  ],
                                ],
                              ),
                            ),

                          // ── Identified Issues ────────────────────────
                          Row(children: [
                            const Icon(Icons.build_circle_rounded, size: 15, color: AppTheme.deepBlue),
                            const SizedBox(width: 6),
                            Text('Identified Issues',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                            const SizedBox(width: 6),
                            Text('($deviceKey)',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          ]),
                          const SizedBox(height: 4),
                          Text('Select all damage found on the device',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 10),
                          // Catalogue issues
                          ...items.map((item) {
                            final label = item['label'] as String;
                            final isSelected = selectedIssues.contains(label);
                            return GestureDetector(
                              onTap: saving ? null : () => setState(() {
                                isSelected ? selectedIssues.remove(label) : selectedIssues.add(label);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.08) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.deepBlue : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.deepBlue : Colors.grey.shade400,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? AppTheme.deepBlue : AppTheme.textPrimaryColor,
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Custom issues added by technician
                          ...customIssueOrder.map((label) {
                            final isSelected = selectedIssues.contains(label);
                            return GestureDetector(
                              onTap: saving ? null : () => setState(() {
                                isSelected ? selectedIssues.remove(label) : selectedIssues.add(label);
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.08) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.deepBlue : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.deepBlue : Colors.grey.shade400,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? AppTheme.deepBlue : AppTheme.textPrimaryColor,
                                          )),
                                    ),
                                    // Remove custom issue
                                    if (!saving)
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          selectedIssues.remove(label);
                                          customIssueOrder.remove(label);
                                        }),
                                        child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          // Add custom issue input
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: customIssueController,
                                  enabled: !saving,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Other issue not listed above…',
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: ElevatedButton(
                                  onPressed: (saving || customIssueController.text.trim().isEmpty)
                                      ? null
                                      : () {
                                          final label = customIssueController.text.trim();
                                          if (label.isNotEmpty && !customIssueOrder.contains(label)) {
                                            setState(() {
                                              customIssueOrder.add(label);
                                              selectedIssues.add(label);
                                              customIssueController.clear();
                                            });
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.deepBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    elevation: 0,
                                  ),
                                  child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Service Fee ──────────────────────────────
                          const Text('Service Fee (₱)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                          const SizedBox(height: 4),
                          Text('Base labour / visit charge',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: serviceFeeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              prefixText: '₱ ',
                              hintText: '0',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Parts Used ───────────────────────────────
                          const Text('Parts Used',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                          const SizedBox(height: 4),
                          Text('Select from the list or add a custom part',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          if (addedParts.isNotEmpty) ...[
                            Column(
                              children: addedParts.map((part) {
                                final name  = part['name'] as String;
                                final price = part['price'] as double;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.build_circle_outlined, size: 16, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                            Text('₱${price.toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      if (!saving)
                                        GestureDetector(
                                          onTap: () => setState(() => addedParts.remove(part)),
                                          child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (!saving)
                            GestureDetector(
                              onTap: () {
                                final outerSetState = setState;
                                newPartController.clear();
                                newPartPriceController.clear();
                                showModalBottomSheet(
                                  context: sheetContext,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => StatefulBuilder(
                                    builder: (ctx2, innerSetState) {
                                      void addPart(String name, double price) {
                                        if (!addedParts.any((p) => p['name'] == name)) {
                                          addedParts.add({'name': name, 'price': price});
                                        }
                                        innerSetState(() {});
                                        outerSetState(() {});
                                      }
                                      void removePart(String name) {
                                        addedParts.removeWhere((p) => p['name'] == name);
                                        innerSetState(() {});
                                        outerSetState(() {});
                                      }
                                      return DraggableScrollableSheet(
                                        initialChildSize: 0.75,
                                        minChildSize: 0.5,
                                        maxChildSize: 0.95,
                                        builder: (_, scrollCtrl) => Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 12, bottom: 8),
                                                width: 40, height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                                child: Row(
                                                  children: [
                                                    const Text('Add Parts',
                                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                                    const Spacer(),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx),
                                                      child: const Text('Done'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Divider(height: 1),
                                              Expanded(
                                                child: ListView(
                                                  controller: scrollCtrl,
                                                  padding: const EdgeInsets.all(16),
                                                  children: [
                                                    Text('Available Parts',
                                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                                                    const SizedBox(height: 8),
                                                    ...items.map((item) {
                                                      final lbl         = item['label'] as String;
                                                      final price       = item['price'] as double;
                                                      final isAdded     = addedParts.any((p) => p['name'] == lbl);
                                                      final isSuggested = selectedIssues.contains(lbl);
                                                      return Container(
                                                        margin: const EdgeInsets.only(bottom: 6),
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                        decoration: BoxDecoration(
                                                          color: isAdded ? Colors.orange.shade50 : Colors.grey.shade50,
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: isAdded ? Colors.orange.shade200 : Colors.grey.shade200,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Text(lbl,
                                                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                                                      if (isSuggested) ...[
                                                                        const SizedBox(width: 6),
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.blue.shade50,
                                                                            borderRadius: BorderRadius.circular(8),
                                                                            border: Border.all(color: Colors.blue.shade200),
                                                                          ),
                                                                          child: Text('Suggested',
                                                                              style: TextStyle(fontSize: 10, color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 2),
                                                                  Text('₱${price.toStringAsFixed(2)}',
                                                                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                                                                ],
                                                              ),
                                                            ),
                                                            if (isAdded)
                                                              GestureDetector(
                                                                onTap: () => removePart(lbl),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(6),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.red.shade50,
                                                                    shape: BoxShape.circle,
                                                                    border: Border.all(color: Colors.red.shade200),
                                                                  ),
                                                                  child: Icon(Icons.remove, size: 14, color: Colors.red.shade400),
                                                                ),
                                                              )
                                                            else
                                                              GestureDetector(
                                                                onTap: () => addPart(lbl, price),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(6),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.blue.shade50,
                                                                    shape: BoxShape.circle,
                                                                    border: Border.all(color: Colors.blue.shade200),
                                                                  ),
                                                                  child: Icon(Icons.add, size: 14, color: Colors.blue.shade600),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                    const SizedBox(height: 12),
                                                    const Divider(),
                                                    const SizedBox(height: 12),
                                                    Text('Custom Part',
                                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                                                    const SizedBox(height: 8),
                                                    TextField(
                                                      controller: newPartController,
                                                      onChanged: (_) => innerSetState(() {}),
                                                      decoration: InputDecoration(
                                                        hintText: 'Part name (e.g. Replacement screen)',
                                                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                          borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                                                        ),
                                                        filled: true,
                                                        fillColor: Colors.grey.shade50,
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextField(
                                                            controller: newPartPriceController,
                                                            onChanged: (_) => innerSetState(() {}),
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            decoration: InputDecoration(
                                                              hintText: 'Price',
                                                              prefixText: '₱ ',
                                                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                                              enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                                borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                                                              ),
                                                              filled: true,
                                                              fillColor: Colors.grey.shade50,
                                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        ElevatedButton(
                                                          onPressed: newPartController.text.trim().isEmpty ? null : () {
                                                            final name  = newPartController.text.trim();
                                                            final price = double.tryParse(newPartPriceController.text.trim()) ?? 0.0;
                                                            addPart(name, price);
                                                            newPartController.clear();
                                                            newPartPriceController.clear();
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: AppTheme.deepBlue,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                                            elevation: 0,
                                                          ),
                                                          child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 20),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppTheme.deepBlue.withValues(alpha: 0.04),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 18, color: AppTheme.deepBlue),
                                    const SizedBox(width: 8),
                                    Text('Add Parts',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.deepBlue)),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // ── Diagnosis Notes ──────────────────────────
                          const Text('Diagnosis Notes',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                          const SizedBox(height: 4),
                          Text('Describe findings and recommendations',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: diagNotesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'e.g. Found corrosion on charging port, replaced screen and battery…',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                              ),
                              filled: true, fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Price Summary card ───────────────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.deepBlue, AppTheme.lightBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Price Summary',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                                const SizedBox(height: 10),
                                if (selectedIssues.isNotEmpty) ...[
                                  const Text('Identified Issues',
                                      style: TextStyle(fontSize: 11, color: Colors.white60)),
                                  const SizedBox(height: 4),
                                  ...selectedIssues.map((l) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text('• $l',
                                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  )),
                                  const Divider(color: Colors.white24, height: 16),
                                ],
                                if (serviceFee > 0) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Service Fee', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                      Text('₱${serviceFee.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24, height: 16),
                                ],
                                if (distanceFee > 0) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_car_rounded, size: 13, color: Colors.white60),
                                          const SizedBox(width: 5),
                                          const Text('Distance Fee', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                        ],
                                      ),
                                      Text('₱${distanceFee.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24, height: 16),
                                ],
                                if (addedParts.isNotEmpty) ...[
                                  ...addedParts.map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(p['name'] as String,
                                            style: const TextStyle(fontSize: 12, color: Colors.white70))),
                                        Text('₱${(p['price'] as double).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  )),
                                  const Divider(color: Colors.white24, height: 16),
                                ],
                                if (total == 0)
                                  const Text('Select issues or enter a service fee to see total',
                                      style: TextStyle(fontSize: 12, color: Colors.white60))
                                else if (distanceFee > 0 && serviceFee == 0 && partsTotal == 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Distance fee applied. Add service fee or parts to complete pricing.',
                                          style: TextStyle(fontSize: 11, color: Colors.white60)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Total',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                          Text('₱${total.toStringAsFixed(2)}',
                                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                      Text('₱${total.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Save button ──────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: canSave ? save : null,
                              icon: saving
                                  ? const SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: Text(saving ? 'Saving…' : 'Save Assessment',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                  ],
                ),
              ),
            );
          },
        ),
      );

      if (confirmed != true) return;
      ref.invalidate(technicianBookingsProvider);
      ref.invalidate(bookingByIdProvider(booking.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment saved successfully.'),
          backgroundColor: AppTheme.deepBlue,
        ),
      );
    } finally {
      diagNotesController.dispose();
      serviceFeeController.dispose();
      newPartController.dispose();
      newPartPriceController.dispose();
      customIssueController.dispose();
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
        message: 'Your repair has been completed! Please proceed with payment.',
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
      );

      ref.invalidate(technicianBookingsProvider);
      ref.invalidate(bookingByIdProvider(booking.id));
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

