import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ratings_service.dart';
import '../../models/booking_model.dart';

// ─── Filter model ─────────────────────────────────────────────────────────────

class _BookingFilter {
  final Set<String> statuses; // empty = all
  final DateTime? fromDate;
  final DateTime? toDate;
  final _SortOrder sort;

  const _BookingFilter({
    this.statuses = const {},
    this.fromDate,
    this.toDate,
    this.sort = _SortOrder.newest,
  });

  bool get isActive =>
      statuses.isNotEmpty || fromDate != null || toDate != null;

  _BookingFilter copyWith({
    Set<String>? statuses,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearFrom = false,
    bool clearTo = false,
    _SortOrder? sort,
  }) {
    return _BookingFilter(
      statuses: statuses ?? this.statuses,
      fromDate: clearFrom ? null : (fromDate ?? this.fromDate),
      toDate: clearTo ? null : (toDate ?? this.toDate),
      sort: sort ?? this.sort,
    );
  }
}

enum _SortOrder { newest, oldest }

// ─── Main screen ──────────────────────────────────────────────────────────────

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

enum _CustomerBookingsTab { upcoming, active, complete, all }

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  _CustomerBookingsTab _selectedTab = _CustomerBookingsTab.upcoming;
  _BookingFilter _filter = const _BookingFilter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
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
            Expanded(child: _buildBookingsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBanner() {
    final parts = <String>[];
    if (_filter.statuses.isNotEmpty) {
      parts.add(_filter.statuses.map(_displayStatus).join(', '));
    }
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
            onTap: () => setState(() => _filter = const _BookingFilter()),
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

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SegmentedButton<_CustomerBookingsTab>(
        segments: const [
          ButtonSegment(value: _CustomerBookingsTab.upcoming, label: Text('Upcoming')),
          ButtonSegment(value: _CustomerBookingsTab.active, label: Text('Active')),
          ButtonSegment(value: _CustomerBookingsTab.complete, label: Text('Complete')),
          ButtonSegment(value: _CustomerBookingsTab.all, label: Text('All')),
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

  Widget _buildBookingsList() {
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue))),
      error: (error, stack) => _buildError(error.toString()),
      data: (bookings) => _buildBookingsContent(bookings),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBookingsContent(List<BookingModel> allBookings) {
    // 1. Tab filter
    List<BookingModel> filteredBookings;
    String emptyMessage;
    IconData emptyIcon;

    switch (_selectedTab) {
      case _CustomerBookingsTab.upcoming:
        filteredBookings = allBookings.where((b) => ['requested', 'accepted', 'scheduled'].contains(b.status)).toList();
        emptyMessage = 'No upcoming appointments';
        emptyIcon = Icons.calendar_today_outlined;
        break;
      case _CustomerBookingsTab.active:
        filteredBookings = allBookings.where((b) => b.status == 'in_progress').toList();
        emptyMessage = 'No active bookings';
        emptyIcon = Icons.work_outline;
        break;
      case _CustomerBookingsTab.complete:
        filteredBookings = allBookings.where((b) => b.status == 'completed').toList();
        emptyMessage = 'No completed bookings';
        emptyIcon = Icons.check_circle_outline;
        break;
      case _CustomerBookingsTab.all:
        filteredBookings = allBookings;
        emptyMessage = 'No bookings yet';
        emptyIcon = Icons.inbox_outlined;
        break;
    }

    // 2. Advanced filter
    if (_filter.statuses.isNotEmpty) {
      filteredBookings = filteredBookings.where((b) => _filter.statuses.contains(b.status)).toList();
    }
    if (_filter.fromDate != null) {
      final from = DateTime(_filter.fromDate!.year, _filter.fromDate!.month, _filter.fromDate!.day);
      filteredBookings = filteredBookings.where((b) {
        final d = b.scheduledDate ?? b.createdAt;
        return !d.isBefore(from);
      }).toList();
    }
    if (_filter.toDate != null) {
      final to = DateTime(_filter.toDate!.year, _filter.toDate!.month, _filter.toDate!.day, 23, 59, 59);
      filteredBookings = filteredBookings.where((b) {
        final d = b.scheduledDate ?? b.createdAt;
        return !d.isAfter(to);
      }).toList();
    }

    // 3. Sort
    filteredBookings.sort((a, b) {
      final aDate = a.scheduledDate ?? a.createdAt;
      final bDate = b.scheduledDate ?? b.createdAt;
      if (_filter.sort == _SortOrder.oldest) {
        return aDate.compareTo(bDate);
      }
      return bDate.compareTo(aDate);
    });

    if (filteredBookings.isEmpty) {
      final hasFilter = _filter.isActive;
      return _buildEmptyState(
        emptyIcon,
        hasFilter ? 'No results for your filter' : emptyMessage,
        hasFilter ? 'Try adjusting or clearing your filter.' : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildBookingCard(filteredBookings[index]),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message, [String? subtitle]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final (statusColor, displayStatus) = _getBookingStatus(booking.status);
    final isCompleted = booking.status == 'completed';
    final isActive = booking.status == 'in_progress';
    final points = isCompleted ? ((booking.finalCost ?? booking.estimatedCost ?? 0.0) / 50).floor() : null;
    final amount = booking.finalCost ?? booking.estimatedCost ?? 0.0;
    final currentUser = ref.watch(currentUserProvider).value;

    return _BookingCard(
      bookingId: booking.id,
      technicianId: booking.technicianId,
      customerName: currentUser?.fullName ?? 'Customer',
      status: displayStatus,
      statusColor: statusColor,
      date: _formatDate(booking.scheduledDate),
      time: _formatTime(booking.scheduledDate),
      location: booking.customerAddress ?? 'N/A',
      total: '₱${amount.toStringAsFixed(2)}',
      moreDetails: booking.diagnosticNotes,
      showBookAgain: isCompleted,
      pointsEarned: points,
      showPayButton: isActive,
      paymentAmount: amount,
      paymentStatus: booking.paymentStatus,
      onCardTap: () => _showBookingSheet(context, booking),
    );
  }

  void _showBookingSheet(BuildContext context, BookingModel booking) {
    final (statusColor, displayStatus) = _getBookingStatus(booking.status);
    final isActive = booking.status == 'in_progress';
    final isCompleted = booking.status == 'completed';
    // Use finalCost (technician-adjusted price) if set, otherwise use estimate.
    // This ensures the customer pays the correct adjusted amount.
    final amount = booking.finalCost ?? booking.estimatedCost ?? 0.0;
    final points = isCompleted ? (amount / 50).floor() : null;
    final currentUser = ref.read(currentUserProvider).value;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BookingDetailSheet(
        booking: booking,
        displayStatus: displayStatus,
        statusColor: statusColor,
        amount: amount,
        isActive: isActive,
        isCompleted: isCompleted,
        pointsEarned: points,
        customerName: currentUser?.fullName ?? 'Customer',
        onOpenFull: () {
          Navigator.of(ctx).pop();
          context.push('/booking/${booking.id}');
        },
        onRate: (ctx2) {
          Navigator.of(ctx).pop();
          _showRatingDialogFor(context, booking, currentUser?.fullName ?? 'Customer');
        },
      ),
    );
  }

  void _showRatingDialogFor(BuildContext context, BookingModel booking, String customerName) {
    int rating = 0;
    final reviewController = TextEditingController();
    final technicianName = ref.read(userByIdProvider(booking.technicianId)).value?.fullName ?? 'Technician';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Column(
            children: [
              Icon(Icons.star_rate, size: 48, color: Colors.amber),
              SizedBox(height: 8),
              Text('Rate Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience?', style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => GestureDetector(
                    onTap: () => setS(() => rating = index + 1),
                    child: Icon(index < rating ? Icons.star : Icons.star_border, size: 40, color: Colors.amber),
                  )),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Write your review (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a rating'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                final newRating = Rating(
                  id: '${booking.id}_rating',
                  customerName: customerName,
                  technician: technicianName,
                  rating: rating,
                  review: reviewController.text,
                  date: DateFormat('MM/dd/yyyy').format(DateTime.now()),
                  service: 'Repair Service',
                  device: 'Device',
                  bookingId: booking.id,
                );
                await ref.read(ratingsProvider.notifier).addRating(newRating);
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your rating!'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _getBookingStatus(String status) {
    return switch (status) {
      'requested' => (const Color(0xFFFF9800), 'Requested'),
      'accepted' || 'scheduled' => (const Color(0xFFFF9800), 'Scheduled'),
      'in_progress' => (AppTheme.lightBlue, 'In Progress'),
      'completed' => (Colors.green, 'Completed'),
      'cancelled' => (Colors.red, 'Cancelled'),
      _ => (Colors.grey, status),
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return DateFormat('MM/dd/yyyy').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'TBD';
    return DateFormat('h:mm a').format(date);
  }

  String _displayStatus(String s) => switch (s) {
        'requested' => 'Requested',
        'accepted' => 'Accepted',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => s,
      };

  // ─── Filter bottom sheet ───────────────────────────────────────────────────

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_BookingFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerFilterSheet(current: _filter),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _CustomerFilterSheet extends StatefulWidget {
  final _BookingFilter current;
  const _CustomerFilterSheet({required this.current});

  @override
  State<_CustomerFilterSheet> createState() => _CustomerFilterSheetState();
}

class _CustomerFilterSheetState extends State<_CustomerFilterSheet> {
  late Set<String> _statuses;
  late DateTime? _from;
  late DateTime? _to;
  late _SortOrder _sort;

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
    'requested': Color(0xFFFF9800),
    'in_progress': AppTheme.accentPurple,
    'completed': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _statuses = Set.from(widget.current.statuses);
    _from = widget.current.fromDate;
    _to = widget.current.toDate;
    _sort = widget.current.sort;
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
                        child: Text('Filter Bookings',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _statuses = {};
                          _from = null;
                          _to = null;
                          _sort = _SortOrder.newest;
                        }),
                        child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status
                  _SectionLabel(label: 'Status', icon: Icons.label_outline),
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

                  // Date range
                  _SectionLabel(label: 'Date Range', icon: Icons.calendar_today_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
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
                        child: _DateButton(
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
                  _SectionLabel(label: 'Sort Order', icon: Icons.sort),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SortChip(
                          label: 'Newest First',
                          icon: Icons.arrow_downward,
                          selected: _sort == _SortOrder.newest,
                          onTap: () => setState(() => _sort = _SortOrder.newest),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SortChip(
                          label: 'Oldest First',
                          icon: Icons.arrow_upward,
                          selected: _sort == _SortOrder.oldest,
                          onTap: () => setState(() => _sort = _SortOrder.oldest),
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
                        _BookingFilter(
                          statuses: _statuses,
                          fromDate: _from,
                          toDate: _to,
                          sort: _sort,
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

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

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

class _DateButton extends StatelessWidget {
  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateButton({
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

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
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

// ─── Booking card (slim) ──────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final String bookingId;
  final String technicianId;
  final String customerName;
  final String status;
  final Color statusColor;
  final String date;
  final String time;
  final String location;
  final String total;
  final String? moreDetails;
  final bool showBookAgain;
  final int? pointsEarned;
  final bool showPayButton;
  final double paymentAmount;
  final String? paymentStatus;
  final VoidCallback onCardTap;

  const _BookingCard({
    required this.bookingId,
    required this.technicianId,
    required this.customerName,
    required this.status,
    required this.statusColor,
    required this.date,
    required this.time,
    required this.location,
    required this.total,
    this.moreDetails,
    this.showBookAgain = false,
    this.pointsEarned,
    this.showPayButton = false,
    this.paymentAmount = 0.0,
    this.paymentStatus,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job #${bookingId.replaceAll('-', '').substring(0, 6).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '$date · $time',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    total,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Booking detail bottom sheet ─────────────────────────────────────────────

class _BookingDetailSheet extends StatefulWidget {
  final BookingModel booking;
  final String displayStatus;
  final Color statusColor;
  final double amount;
  final bool isActive;
  final bool isCompleted;
  final int? pointsEarned;
  final String customerName;
  final VoidCallback onOpenFull;
  final void Function(BuildContext) onRate;

  const _BookingDetailSheet({
    required this.booking,
    required this.displayStatus,
    required this.statusColor,
    required this.amount,
    required this.isActive,
    required this.isCompleted,
    this.pointsEarned,
    required this.customerName,
    required this.onOpenFull,
    required this.onRate,
  });

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  bool _expanded = false;

  String _fmt(DateTime? dt) {
    if (dt == null) return 'TBD';
    return DateFormat('MMM d, y · h:mm a').format(dt);
  }

  String _shortCode() {
    final compact = widget.booking.id.replaceAll('-', '');
    return compact.substring(0, 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.52,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: widget.statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      widget.displayStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: widget.statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Job #${_shortCode()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Summary ───────────────────────────────────────────
              _SheetSection(
                children: [
                  _SheetRow(icon: Icons.calendar_today, label: 'Scheduled', value: _fmt(booking.scheduledDate)),
                  _SheetRow(icon: Icons.location_on_outlined, label: 'Location', value: booking.customerAddress ?? 'N/A'),
                  _SheetRow(
                    icon: Icons.attach_money,
                    label: 'Total',
                    value: '₱${widget.amount.toStringAsFixed(2)}',
                    valueStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Points earned ─────────────────────────────────────
              if (widget.pointsEarned != null && widget.pointsEarned! > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '+${widget.pointsEarned} Points Earned!',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Expand / collapse ─────────────────────────────────
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _expanded ? 'Hide details' : 'Show all details',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down, color: AppTheme.deepBlue, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expanded details ──────────────────────────────────
              if (_expanded) ...[
                const SizedBox(height: 12),
                _SheetSection(
                  title: 'Booking Details',
                  children: [
                    _SheetRow(icon: Icons.tag, label: 'Booking ID', value: booking.id.substring(0, 8).toUpperCase()),
                    _SheetRow(icon: Icons.event_available, label: 'Created', value: _fmt(booking.createdAt)),
                    if (booking.acceptedAt != null)
                      _SheetRow(icon: Icons.check_circle_outline, label: 'Accepted', value: _fmt(booking.acceptedAt)),
                    if (booking.completedAt != null)
                      _SheetRow(icon: Icons.done_all, label: 'Completed', value: _fmt(booking.completedAt)),
                    if (booking.cancelledAt != null)
                      _SheetRow(icon: Icons.cancel_outlined, label: 'Cancelled', value: _fmt(booking.cancelledAt)),
                  ],
                ),
                const SizedBox(height: 12),
                _SheetSection(
                  title: 'Payment',
                  children: [
                    _SheetRow(
                      icon: booking.paymentMethod == 'gcash'
                          ? Icons.phone_android_rounded
                          : Icons.payments_rounded,
                      label: 'Method',
                      value: booking.paymentMethod == 'gcash'
                          ? 'GCash'
                          : booking.paymentMethod == 'cash'
                              ? 'Cash'
                              : booking.paymentMethod ?? '—',
                    ),
                    _SheetRow(icon: Icons.receipt_outlined, label: 'Status', value: booking.paymentStatus ?? '—'),
                    if (booking.estimatedCost != null)
                      _SheetRow(icon: Icons.calculate_outlined, label: 'Estimate', value: '₱${booking.estimatedCost!.toStringAsFixed(2)}'),
                    // Final price only shown once payment is completed
                    if (booking.paymentStatus == 'completed' && booking.finalCost != null)
                      _SheetRow(icon: Icons.price_check, label: 'Final', value: '₱${booking.finalCost!.toStringAsFixed(2)}'),
                  ],
                ),
                if (booking.moreDetails != null && booking.moreDetails!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SheetSection(
                    title: 'Notes',
                    children: [
                      _SheetRow(icon: Icons.notes, label: 'Details', value: booking.moreDetails!, multiline: true),
                      if (booking.technicianNotes != null && booking.technicianNotes!.isNotEmpty)
                        _SheetRow(icon: Icons.engineering, label: 'Tech Notes', value: booking.technicianNotes!, multiline: true),
                    ],
                  ),
                ],
                if (booking.cancellationReason != null) ...[
                  const SizedBox(height: 12),
                  _SheetSection(
                    title: 'Cancellation',
                    children: [
                      _SheetRow(icon: Icons.info_outline, label: 'Reason', value: booking.cancellationReason!, multiline: true),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────
              if (widget.isActive) ...[
                _PayButton(booking: booking, amount: widget.amount),
                const SizedBox(height: 10),
              ],
              if (widget.isCompleted) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onRate(context),
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text('Rate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.deepBlue,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onOpenFull,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onOpenFull,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View Full Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PayButton extends StatelessWidget {
  final BookingModel booking;
  final double amount;

  const _PayButton({required this.booking, required this.amount});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bgColor) = switch (booking.paymentStatus) {
      'completed' => ('Payment Completed', Icons.check_circle, Colors.green),
      'submitted' => ('Waiting for Verification', Icons.hourglass_top, Colors.orange),
      _ => ('Pay Now', Icons.payment, AppTheme.deepBlue),
    };

    final isDone = booking.paymentStatus == 'completed';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isDone
            ? null
            : () => context.push('/payment/${booking.id}?amount=${amount.toStringAsFixed(2)}'),
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.green.shade100,
          disabledForegroundColor: Colors.green.shade700,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Sheet helper widgets ─────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SheetSection({this.title, required this.children});

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
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;
  final TextStyle? valueStyle;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

