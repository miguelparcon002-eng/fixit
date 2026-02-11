import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../models/admin_booking_view.dart';
import '../../providers/admin_booking_provider.dart';
import 'widgets/admin_notifications_dialog.dart';

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

enum _TimeRange { day, week, month }

class _AdminAppointmentsScreenState
    extends ConsumerState<AdminAppointmentsScreen> {

  bool _appliedInitialFilters = false;

  void _applyInitialFiltersIfNeeded() {
    if (_appliedInitialFilters) return;

    final r = (widget.initialRange ?? '').toLowerCase();
    final s = (widget.initialStatus ?? '').toLowerCase();

    if (r.isNotEmpty) {
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
  _TimeRange _timeRange = _TimeRange.week;

  String _shortBookingCode(String id) {
    final compact = id.replaceAll('-', '');
    if (compact.length <= 6) return compact.toUpperCase();
    return compact.substring(0, 6).toUpperCase();
  }

  bool _matchesTimeRange(DateTime createdAt) {
    final now = DateTime.now();
    switch (_timeRange) {
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
    final b = item.booking;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking #${_shortBookingCode(b.id)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${b.status.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _DetailsSection(
                    title: 'People',
                    children: [
                      _DetailsRow(label: 'Customer', value: item.customerName),
                      _DetailsRow(label: 'Technician', value: item.technicianName),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _DetailsSection(
                    title: 'Service',
                    children: [
                      _DetailsRow(label: 'Service', value: item.serviceName),
                      _DetailsRow(label: 'Service ID', value: b.serviceId),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _DetailsSection(
                    title: 'Schedule & Location',
                    children: [
                      _DetailsRow(
                        label: 'Created',
                        value: b.createdAt.toLocal().toString(),
                      ),
                      _DetailsRow(
                        label: 'Scheduled',
                        value: b.scheduledDate?.toLocal().toString() ?? '—',
                      ),
                      _DetailsRow(
                        label: 'Address',
                        value: b.customerAddress ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _DetailsSection(
                    title: 'Cost & Payment',
                    children: [
                      _DetailsRow(
                        label: 'Estimated cost',
                        value: b.estimatedCost?.toStringAsFixed(2) ?? '—',
                      ),
                      _DetailsRow(
                        label: 'Final cost',
                        value: b.finalCost?.toStringAsFixed(2) ?? '—',
                      ),
                      _DetailsRow(
                        label: 'Payment method',
                        value: b.paymentMethod ?? '—',
                      ),
                      _DetailsRow(
                        label: 'Payment status',
                        value: b.paymentStatus ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _DetailsSection(
                    title: 'Notes',
                    children: [
                      _DetailsRow(
                        label: 'Diagnostic notes',
                        value: (b.diagnosticNotes == null ||
                                b.diagnosticNotes!.trim().isEmpty)
                            ? '—'
                            : b.diagnosticNotes!.trim(),
                        multiline: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.go('/booking-detail/${b.id}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Open full details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                        'Range: ${_timeRange == _TimeRange.day ? 'Day' : _timeRange == _TimeRange.week ? 'Week' : 'Month'}',
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
                    if (_statusFilter != 'all' && status != _statusFilter) {
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'ongoing':
        return AppTheme.lightBlue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;
    final status = booking.status;
    final statusColor = _statusColor(status);

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
                    status.toUpperCase(),
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
                    'Service: ${item.serviceName}',
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
