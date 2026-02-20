import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../services/booking_service.dart';

// Provider for the initial tab to show in jobs screen
// 0 = Request, 1 = Active, 2 = Complete, 3 = All
final techJobsInitialTabProvider = StateProvider<int>((ref) => 0);

enum _TechJobsTab { request, active, complete, all }

class TechJobsScreenNew extends ConsumerStatefulWidget {
  const TechJobsScreenNew({super.key});

  @override
  ConsumerState<TechJobsScreenNew> createState() => _TechJobsScreenNewState();
}

class _TechJobsScreenNewState extends ConsumerState<TechJobsScreenNew> {
  _TechJobsTab _selectedTab = _TechJobsTab.request;

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
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildTabs(),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildJobsList()),
          ],
        ),
      ),
    );
  }

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
    final filtered = _filterBookings(allBookings);

    if (filtered.isEmpty) {
      final (icon, title, subtitle) = _emptyStateForTab();
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          _EmptyState(icon: icon, title: title, subtitle: subtitle),
        ],
      );
    }

    final sorted = [...filtered]..sort((a, b) {
        // Emergency bookings should be prioritized first (especially in Request tab)
        final prio = (b.isEmergency ? 1 : 0).compareTo(a.isEmergency ? 1 : 0);
        if (prio != 0) return prio;

        final aDate = a.scheduledDate ?? a.createdAt;
        final bDate = b.scheduledDate ?? b.createdAt;

        if (_selectedTab == _TechJobsTab.complete) {
          return bDate.compareTo(aDate);
        }
        return aDate.compareTo(bDate);
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _adjustPrice(context, ref, bookingService),
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
