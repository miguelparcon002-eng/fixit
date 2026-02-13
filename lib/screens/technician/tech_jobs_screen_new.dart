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
    final adjustmentController = TextEditingController();
    final noteController = TextEditingController();

    double? parseSignedAmount(String input) {
      final raw = input.replaceAll(',', '').trim();
      if (raw.isEmpty) return null;
      // Accept values like: +200, -150, 200, -200.50
      return double.tryParse(raw);
    }

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;
          return StatefulBuilder(
            builder: (dialogContext, setState) {
              final amount = parseSignedAmount(adjustmentController.text);
              final note = noteController.text.trim();
              final hasValidAmount = amount != null && amount != 0;
              final canSave = !saving && hasValidAmount && note.isNotEmpty;

              return AlertDialog(
                title: const Text('Adjust price'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adjustment amount',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: adjustmentController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        prefixText: '₱',
                        hintText: '+200 or -150',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        helperText: 'Use + to increase or - to decrease',
                        errorText: (adjustmentController.text.trim().isEmpty || hasValidAmount)
                            ? null
                            : 'Enter a non-zero number (e.g. +200 or -150)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Note *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Why did you adjust the price?',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: canSave
                        ? () async {
                            setState(() => saving = true);
                            try {
                              final signedAmount = parseSignedAmount(adjustmentController.text) ?? 0.0;
                              final reason = noteController.text.trim();

                              // Persist technician note + adjustment (preserves customer notes)
                              await bookingService.addTechnicianNotes(
                                bookingId: booking.id,
                                technicianNotes: 'Price adjustment note: $reason',
                                priceAdjustment: signedAmount,
                              );

                              ref.invalidate(technicianBookingsProvider);
                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext, true);
                            } catch (e) {
                              if (!dialogContext.mounted) return;
                              setState(() => saving = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Failed to adjust price: $e')),
                              );
                            }
                          }
                        : null,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(saving ? 'Saving…' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price adjustment saved.'),
          backgroundColor: AppTheme.deepBlue,
        ),
      );
    } finally {
      adjustmentController.dispose();
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
