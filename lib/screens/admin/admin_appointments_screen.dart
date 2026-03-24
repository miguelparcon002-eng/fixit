import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../models/admin_booking_view.dart';
import '../../models/booking_model.dart';
import '../../providers/admin_booking_provider.dart';
import 'widgets/admin_notifications_dialog.dart';

// ── Status helpers ─────────────────────────────────────────────────────────────

String _appointmentBucket(String status) {
  switch (status.toLowerCase()) {
    case 'requested':
      return 'requested';
    case 'accepted':
    case 'en_route':
    case 'arrived':
    case 'in_progress':
    case 'scheduled':
    case 'completed': // Awaiting Payment — still in progress until paid
      return 'in_progress';
    case 'paid':
    case 'closed':
      return 'completed';
    case 'cancelled':
    case 'cancellation_pending':
    case 'refunded':
      return 'cancelled';
    default:
      return 'other';
  }
}

String _appointmentStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'requested':            return 'Requested';
    case 'accepted':             return 'Accepted';
    case 'en_route':             return 'En Route';
    case 'arrived':              return 'Arrived';
    case 'in_progress':          return 'In Progress';
    case 'completed':            return 'Awaiting Payment';
    case 'paid':                 return 'Paid';
    case 'closed':               return 'Completed';
    case 'cancelled':            return 'Cancelled';
    case 'cancellation_pending': return 'Cancel Pending';
    case 'refunded':             return 'Refunded';
    default:                     return status.replaceAll('_', ' ');
  }
}

Color _appointmentStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'requested':
      return AppTheme.warningColor;
    case 'accepted':
    case 'en_route':
    case 'arrived':
    case 'in_progress':
      return AppTheme.lightBlue;
    case 'completed':
      return AppTheme.warningColor; // Awaiting Payment — not fully done yet
    case 'paid':
    case 'closed':
      return AppTheme.successColor;
    case 'cancelled':
    case 'cancellation_pending':
    case 'refunded':
      return AppTheme.errorColor;
    default:
      return AppTheme.textSecondaryColor;
  }
}

class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  final String? initialRange; // day|week|month
  final String? initialStatus; // all|requested|in_progress|completed|cancelled

  const AdminAppointmentsScreen({
    super.key,
    this.initialRange,
    this.initialStatus,
  });

  @override
  ConsumerState<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

enum _TimeRange { all, day, week, month }

class _AdminAppointmentsScreenState
    extends ConsumerState<AdminAppointmentsScreen> {

  bool _appliedInitialFilters = false;

  void _applyInitialFiltersIfNeeded() {
    if (_appliedInitialFilters) return;

    final r = (widget.initialRange ?? '').toLowerCase();
    final s = (widget.initialStatus ?? '').toLowerCase();

    if (r.isNotEmpty) {
      if (r == 'all') _timeRange = _TimeRange.all;
      if (r == 'day') _timeRange = _TimeRange.day;
      if (r == 'week') _timeRange = _TimeRange.week;
      if (r == 'month') _timeRange = _TimeRange.month;
    }

    if (s.isNotEmpty) {
      const allowed = {'all', 'requested', 'in_progress', 'completed', 'cancelled'};
      if (allowed.contains(s)) {
        _statusFilter = s;
      }
    }

    _appliedInitialFilters = true;
  }
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, requested, in_progress, completed, cancelled
  _TimeRange _timeRange = _TimeRange.all;

  String _shortBookingCode(String id) {
    final compact = id.replaceAll('-', '');
    if (compact.length <= 6) return compact.toUpperCase();
    return compact.substring(0, 6).toUpperCase();
  }

  bool _matchesTimeRange(DateTime createdAt) {
    final now = DateTime.now();
    switch (_timeRange) {
      case _TimeRange.all:
        return true;
      case _TimeRange.day:
        return createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day;
      case _TimeRange.week:
        return createdAt.isAfter(now.subtract(const Duration(days: 7)));
      case _TimeRange.month:
        return createdAt.isAfter(DateTime(now.year, now.month, 1));
    }
  }

  void _showBookingDetails(BuildContext context, AdminBookingView item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BookingDetailSheet(
        item: item,
        shortCode: _shortBookingCode(item.booking.id),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _applyInitialFiltersIfNeeded();
    final bookingsAsync = ref.watch(adminBookingsProvider);

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
                'Appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminBookingsProvider),
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AdminNotificationsDialog(),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by booking id / status / customer / technician…',
                      prefixIcon:
                          const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.deepBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Time range filter (interactive picker like Admin Reports)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PeriodOption(
                                    label: 'All',
                                    isSelected: _timeRange == _TimeRange.all,
                                    onTap: () {
                                      setState(() => _timeRange = _TimeRange.all);
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _PeriodOption(
                                    label: 'Day',
                                    isSelected: _timeRange == _TimeRange.day,
                                    onTap: () {
                                      setState(() => _timeRange = _TimeRange.day);
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _PeriodOption(
                                    label: 'Week',
                                    isSelected: _timeRange == _TimeRange.week,
                                    onTap: () {
                                      setState(() => _timeRange = _TimeRange.week);
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _PeriodOption(
                                    label: 'Month',
                                    isSelected: _timeRange == _TimeRange.month,
                                    onTap: () {
                                      setState(() => _timeRange = _TimeRange.month);
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        'Range: ${_timeRange == _TimeRange.all ? 'All' : _timeRange == _TimeRange.day ? 'Day' : _timeRange == _TimeRange.week ? 'Week' : 'Month'}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryColor,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status filters
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          value: 'all',
                          selected: _statusFilter,
                          onSelected: (v) => setState(() => _statusFilter = v),
                        ),
                        _FilterChip(
                          label: 'Requested',
                          value: 'requested',
                          selected: _statusFilter,
                          onSelected: (v) => setState(() => _statusFilter = v),
                        ),
                        _FilterChip(
                          label: 'In progress',
                          value: 'in_progress',
                          selected: _statusFilter,
                          onSelected: (v) => setState(() => _statusFilter = v),
                        ),
                        _FilterChip(
                          label: 'Completed',
                          value: 'completed',
                          selected: _statusFilter,
                          onSelected: (v) => setState(() => _statusFilter = v),
                        ),
                        _FilterChip(
                          label: 'Cancelled',
                          value: 'cancelled',
                          selected: _statusFilter,
                          onSelected: (v) => setState(() => _statusFilter = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading appointments:\n$e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
                data: (items) {
                  final filtered = items.where((item) {
                    final b = item.booking;

                    if (!_matchesTimeRange(b.createdAt)) return false;

                    final status = b.status.toLowerCase();
                    if (_statusFilter != 'all' && _appointmentBucket(status) != _statusFilter) {
                      return false;
                    }

                    if (_searchQuery.isEmpty) return true;

                    final q = _searchQuery.toLowerCase();
                    return b.id.toLowerCase().contains(q) ||
                        status.contains(q) ||
                        item.customerName.toLowerCase().contains(q) ||
                        item.technicianName.toLowerCase().contains(q) ||
                        item.serviceName.toLowerCase().contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Text(
                            'No appointments found',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _AppointmentCard(
                        item: item,
                        shortCode: _shortBookingCode(item.booking.id),
                        onTap: () => _showBookingDetails(context, item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.deepBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.deepBlue
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.deepBlue : Colors.black,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_box, color: AppTheme.deepBlue, size: 20)
            else
              Icon(
                Icons.check_box_outline_blank,
                color: Colors.grey.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.deepBlue : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AdminBookingView item;
  final String shortCode;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.item,
    required this.shortCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;
    final status = booking.status;
    final statusColor = _appointmentStatusColor(status);

    final createdAt = booking.createdAt as DateTime?;
    final dateText = createdAt == null
        ? '—'
        : '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

    final cost = booking.estimatedCost ?? booking.finalCost;

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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _appointmentStatusLabel(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Booking #$shortCode',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoPill(icon: Icons.calendar_today, text: dateText),
                _InfoPill(
                  icon: Icons.person,
                  text: 'Customer: ${item.customerName}',
                ),
                _InfoPill(
                  icon: Icons.engineering,
                  text: 'Tech: ${item.technicianName}',
                ),
                if (item.serviceName.isNotEmpty)
                  _InfoPill(
                    icon: Icons.build_circle_outlined,
                    text: item.serviceName,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.build,
                    size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.isEmergency ? 'Emergency Repair' : 'Regular Repair',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cost != null)
                  Text(
                    '₱${(cost as num).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.deepBlue,
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

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _DetailsRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Booking Detail Bottom Sheet ────────────────────────────────────────────

class _BookingDetailSheet extends StatefulWidget {
  final AdminBookingView item;
  final String shortCode;

  const _BookingDetailSheet({
    required this.item,
    required this.shortCode,
  });

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$m $period';
  }

  List<_StageData> _getJobStages(BookingModel booking) {
    final status = booking.status.toLowerCase();
    final isCancelled =
        status == 'cancelled' || status == 'cancellation_pending';

    final stages = <_StageData>[
      _StageData(
        label: 'Requested',
        icon: Icons.assignment_outlined,
        color: AppTheme.warningColor,
        done: true,
        isCurrent: status == 'requested',
        timestamp: _fmt(booking.createdAt),
      ),
      _StageData(
        label: 'Accepted',
        icon: Icons.handshake_outlined,
        color: AppTheme.lightBlue,
        done: booking.acceptedAt != null ||
            {'en_route', 'arrived', 'in_progress', 'completed', 'paid', 'closed'}
                .contains(status),
        isCurrent: status == 'accepted',
        timestamp: booking.acceptedAt != null ? _fmt(booking.acceptedAt) : null,
      ),
      _StageData(
        label: 'En Route',
        icon: Icons.directions_car_outlined,
        color: AppTheme.lightBlue,
        done: booking.enRouteAt != null ||
            {'arrived', 'in_progress', 'completed', 'paid', 'closed'}
                .contains(status),
        isCurrent: status == 'en_route',
        timestamp: booking.enRouteAt != null ? _fmt(booking.enRouteAt) : null,
      ),
      _StageData(
        label: 'Arrived at Location',
        icon: Icons.location_on_outlined,
        color: AppTheme.lightBlue,
        done: booking.arrivedAt != null ||
            {'in_progress', 'completed', 'paid', 'closed'}.contains(status),
        isCurrent: status == 'arrived',
        timestamp: booking.arrivedAt != null ? _fmt(booking.arrivedAt) : null,
      ),
      _StageData(
        label: 'Repair In Progress',
        icon: Icons.build_outlined,
        color: AppTheme.lightBlue,
        done: {'in_progress', 'completed', 'paid', 'closed'}.contains(status),
        isCurrent: status == 'in_progress',
        timestamp: null,
      ),
    ];

    if (!isCancelled) {
      stages.addAll([
        _StageData(
          label: 'Awaiting Payment',
          icon: Icons.payment_outlined,
          color: AppTheme.successColor,
          done: booking.completedAt != null ||
              {'paid', 'closed'}.contains(status),
          isCurrent: status == 'completed',
          timestamp:
              booking.completedAt != null ? _fmt(booking.completedAt) : null,
        ),
        _StageData(
          label: 'Payment Received',
          icon: Icons.receipt_long_outlined,
          color: AppTheme.successColor,
          done: booking.paidAt != null || status == 'closed',
          isCurrent: status == 'paid',
          timestamp: booking.paidAt != null ? _fmt(booking.paidAt) : null,
        ),
        _StageData(
          label: 'Job Completed',
          icon: Icons.task_alt_outlined,
          color: AppTheme.successColor,
          done: status == 'closed',
          isCurrent: status == 'closed',
          timestamp: null,
        ),
      ]);
    } else {
      stages.add(_StageData(
        label: status == 'cancellation_pending'
            ? 'Cancellation Pending'
            : 'Job Cancelled',
        icon: Icons.cancel_outlined,
        color: AppTheme.errorColor,
        done: true,
        isCurrent: true,
        timestamp:
            booking.cancelledAt != null ? _fmt(booking.cancelledAt) : null,
      ));
    }

    return stages;
  }

  Widget _buildJobProgress(BookingModel booking) {
    final stages = _getJobStages(booking);
    return _DetailsSection(
      title: 'Job Progress',
      children: [
        for (int i = 0; i < stages.length; i++)
          _TimelineStep(data: stages[i], isLast: i == stages.length - 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.item.booking;
    final status = booking.status;
    final statusColor = _appointmentStatusColor(status);
    final cost = booking.finalCost ?? booking.estimatedCost;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: status + code ──────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _appointmentStatusLabel(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Booking #${widget.shortCode}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (booking.isEmergency) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        'EMERGENCY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Summary ───────────────────────────────────────────
              _DetailsSection(
                title: 'Summary',
                children: [
                  _DetailsRow(label: 'Customer', value: widget.item.customerName),
                  _DetailsRow(label: 'Technician', value: widget.item.technicianName),
                  _DetailsRow(
                    label: 'Service',
                    value: booking.isEmergency ? 'Emergency Repair' : 'Regular Repair',
                  ),
                  _DetailsRow(
                    label: 'Cost',
                    value: cost != null ? '₱${(cost as num).toStringAsFixed(2)}' : '—',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Job Progress ───────────────────────────────────────
              _buildJobProgress(booking),

              const SizedBox(height: 12),

              // ── Schedule ──────────────────────────────────────────
              _DetailsSection(
                title: 'Schedule',
                children: [
                  _DetailsRow(label: 'Created', value: _fmt(booking.createdAt)),
                  if (booking.scheduledDate != null)
                    _DetailsRow(label: 'Scheduled', value: _fmt(booking.scheduledDate)),
                  if (booking.acceptedAt != null)
                    _DetailsRow(label: 'Accepted', value: _fmt(booking.acceptedAt)),
                  if (booking.completedAt != null)
                    _DetailsRow(label: 'Completed', value: _fmt(booking.completedAt)),
                  if (booking.cancelledAt != null)
                    _DetailsRow(label: 'Cancelled', value: _fmt(booking.cancelledAt)),
                ],
              ),
              const SizedBox(height: 12),

              // ── Location & Payment ────────────────────────────────
              _DetailsSection(
                title: 'Location & Payment',
                children: [
                  _DetailsRow(
                    label: 'Address',
                    value: booking.customerAddress ?? '—',
                    multiline: true,
                  ),
                  _DetailsRow(label: 'Payment', value: booking.paymentMethod ?? '—'),
                  _DetailsRow(label: 'Pay Status', value: booking.paymentStatus ?? '—'),
                  if (booking.estimatedCost != null)
                    _DetailsRow(
                      label: 'Est. Cost',
                      value: '₱${booking.estimatedCost!.toStringAsFixed(2)}',
                    ),
                  if (booking.finalCost != null)
                    _DetailsRow(
                      label: 'Final Cost',
                      value: '₱${booking.finalCost!.toStringAsFixed(2)}',
                    ),
                ],
              ),

              // ── Cancellation ──────────────────────────────────────
              if (booking.cancellationReason != null) ...[
                const SizedBox(height: 12),
                _DetailsSection(
                  title: 'Cancellation',
                  children: [
                    _DetailsRow(
                      label: 'Reason',
                      value: booking.cancellationReason!,
                      multiline: true,
                    ),
                  ],
                ),
              ],

              // ── Rating ────────────────────────────────────────────
              if (booking.rating != null) ...[
                const SizedBox(height: 12),
                _DetailsSection(
                  title: 'Rating',
                  children: [
                    _DetailsRow(
                      label: 'Stars',
                      value: '${'★' * booking.rating!}${'☆' * (5 - booking.rating!)} (${booking.rating}/5)',
                    ),
                    if (booking.review != null && booking.review!.isNotEmpty)
                      _DetailsRow(
                        label: 'Review',
                        value: booking.review!,
                        multiline: true,
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── Job progress data + widget ────────────────────────────────────────────────

class _StageData {
  final String label;
  final IconData icon;
  final Color color;
  final bool done;
  final bool isCurrent;
  final String? timestamp;

  const _StageData({
    required this.label,
    required this.icon,
    required this.color,
    required this.done,
    required this.isCurrent,
    this.timestamp,
  });
}

class _TimelineStep extends StatelessWidget {
  final _StageData data;
  final bool isLast;

  const _TimelineStep({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.done
                      ? data.color.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.done ? data.color : Colors.grey.shade300,
                    width: data.isCurrent ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  data.icon,
                  size: 14,
                  color: data.done ? data.color : Colors.grey.shade400,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: data.done
                        ? data.color.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Label + timestamp
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: data.isCurrent
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: data.done
                              ? (data.isCurrent
                                  ? data.color
                                  : AppTheme.textPrimaryColor)
                              : Colors.grey.shade400,
                        ),
                      ),
                      if (data.isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: data.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NOW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: data.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (data.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.timestamp!,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
