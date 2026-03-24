import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_request_provider.dart';
import '../../services/distance_fee_service.dart';
import '../../services/notification_service.dart';
import '../../services/ratings_service.dart';
import '../../models/booking_model.dart';
import '../../models/job_request_model.dart';
import '../../models/redeemed_voucher.dart';
import '../../providers/rewards_provider.dart';
import '../../widgets/job_status_tracker.dart';
import '../../core/utils/booking_notes_parser.dart';

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
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(customerBookingsProvider);
            },
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.deepBlue),
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
        onSelectionChanged: (value) => setState(() => _selectedTab = value.first),
      ),
    );
  }

  Widget _buildBookingsList() {
    final bookingsAsync = ref.watch(customerBookingsProvider);

    if (_selectedTab == _CustomerBookingsTab.upcoming) {
      final user = ref.watch(currentUserProvider).valueOrNull;
      final requestsAsync = user != null
          ? ref.watch(customerJobRequestsProvider(user.id))
          : const AsyncData<List<JobRequestModel>>([]);
      return RefreshIndicator(
        color: AppTheme.deepBlue,
        onRefresh: () async {
          ref.invalidate(customerBookingsProvider);
          await Future<void>.delayed(const Duration(milliseconds: 150));
        },
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue))),
          error: (error, stack) => _buildError(error.toString()),
          data: (bookings) => _buildUpcomingContent(bookings, requestsAsync.valueOrNull ?? []),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.deepBlue,
      onRefresh: () async {
        ref.invalidate(customerBookingsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      },
      child: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue))),
        error: (error, stack) => _buildError(error.toString()),
        data: (bookings) => _buildBookingsContent(bookings),
      ),
    );
  }

  Widget _buildUpcomingContent(List<BookingModel> allBookings, List<JobRequestModel> requests) {
    final upcomingBookings = allBookings.where((b) => b.status == 'requested').toList();
    final activeRequests = requests
        .where((r) => r.status == 'open' || r.status == 'pending_customer_approval')
        .toList();

    if (upcomingBookings.isEmpty && activeRequests.isEmpty) {
      return _buildEmptyState(
        Icons.calendar_today_outlined,
        'No upcoming appointments',
        null,
      );
    }

    final hasBoth = activeRequests.isNotEmpty && upcomingBookings.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (activeRequests.isNotEmpty) ...[
          if (hasBoth) _buildListSectionLabel('Problem Requests'),
          ...activeRequests.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _JobRequestCard(request: r, onTap: () => _showRequestSheet(r)),
          )),
          if (hasBoth) const SizedBox(height: 4),
        ],
        if (upcomingBookings.isNotEmpty) ...[
          if (hasBoth) _buildListSectionLabel('Bookings'),
          ...upcomingBookings.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBookingCard(b),
          )),
        ],
      ],
    );
  }

  Widget _buildListSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showRequestSheet(JobRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobRequestDetailSheet(request: request),
    );
  }

  Widget _buildError(String error) {
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
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.error_outline, size: 30, color: Colors.red),
              ),
              const SizedBox(height: 12),
              const Text(
                'Couldn\'t load appointments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                error,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsContent(List<BookingModel> allBookings) {
    // 1. Tab filter
    List<BookingModel> filteredBookings;
    String emptyMessage;
    IconData emptyIcon;

    switch (_selectedTab) {
      case _CustomerBookingsTab.upcoming:
        filteredBookings = allBookings.where((b) => b.status == 'requested').toList();
        emptyMessage = 'No upcoming appointments';
        emptyIcon = Icons.calendar_today_outlined;
        break;
      case _CustomerBookingsTab.active:
        filteredBookings = allBookings.where((b) => [
          'accepted', 'en_route', 'arrived', 'in_progress', 'completed',
          'cancellation_pending',
        ].contains(b.status)).toList();
        emptyMessage = 'No active bookings';
        emptyIcon = Icons.work_outline;
        break;
      case _CustomerBookingsTab.complete:
        filteredBookings = allBookings.where((b) => ['paid', 'closed'].contains(b.status)).toList();
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
                  color: AppTheme.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: AppTheme.deepBlue),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor, height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final (statusColor, displayStatus) = _getBookingStatus(booking.status);
    final isCompleted = booking.status == 'paid' || booking.status == 'closed';
    final points = isCompleted ? ((booking.finalCost ?? booking.estimatedCost ?? 0.0) / 50).floor() : null;
    final amount = booking.finalCost ?? booking.estimatedCost ?? 0.0;
    final currentUser = ref.watch(currentUserProvider).value;

    return _BookingCard(
      bookingId: booking.id,
      technicianId: booking.technicianId,
      customerName: currentUser?.fullName ?? 'Customer',
      status: displayStatus,
      rawStatus: booking.status,
      statusColor: statusColor,
      date: _formatDate(booking.scheduledDate),
      time: _formatTime(booking.scheduledDate),
      location: booking.customerAddress ?? 'N/A',
      total: '₱${amount.toStringAsFixed(2)}',
      moreDetails: booking.diagnosticNotes,
      showBookAgain: isCompleted,
      pointsEarned: points,
      showPayButton: booking.status == 'completed',
      paymentAmount: amount,
      paymentStatus: booking.paymentStatus,
      onCardTap: () => _showBookingSheet(context, booking),
      onUseVoucher: () => _showVoucherDialog(context, booking),
    );
  }

  void _showBookingSheet(BuildContext context, BookingModel booking) {
    final (statusColor, displayStatus) = _getBookingStatus(booking.status);
    // isActive = show pay button (status 'completed' = job done, awaiting payment)
    final isActive = booking.status == 'completed';
    // isCompleted = show rate/book-again actions (payment confirmed or job closed)
    final isCompleted = booking.status == 'paid' || booking.status == 'closed';
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
        onUseVoucher: () {
          Navigator.of(ctx).pop();
          _showVoucherDialog(context, booking);
        },
      ),
    );
  }

  Future<void> _showVoucherDialog(BuildContext context, BookingModel booking) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // Check if a voucher has already been applied to this booking
    final existing = await SupabaseConfig.client
        .from('user_redeemed_vouchers')
        .select('id')
        .eq('booking_id', booking.id)
        .limit(1);
    if ((existing as List).isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A voucher has already been applied to this booking.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final voucherService = ref.read(redeemedVoucherServiceProvider);
    final vouchers = await voucherService.getUnusedVouchers(user.id);

    if (!context.mounted) return;

    if (vouchers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have no available vouchers.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a Voucher',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Apply a discount to booking #${booking.id.substring(0, 6).toUpperCase()}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...vouchers.map((voucher) => _VoucherTile(
              key: ValueKey(voucher.id),
              voucher: voucher,
              onApply: () async {
                Navigator.pop(context);

                // Calculate discounted price
                final currentAmount = booking.finalCost ?? booking.estimatedCost ?? 0.0;
                final double newAmount;
                if (voucher.discountType == 'percentage') {
                  newAmount = (currentAmount - currentAmount * voucher.discountAmount / 100).clamp(0, double.infinity);
                } else {
                  newAmount = (currentAmount - voucher.discountAmount).clamp(0, double.infinity);
                }

                // Apply discount to booking in Supabase
                await SupabaseConfig.client
                    .from('bookings')
                    .update({'final_cost': newAmount})
                    .eq('id', booking.id);

                await voucherService.markVoucherAsUsed(voucherId: voucher.id, bookingId: booking.id);
                ref.invalidate(redeemedVouchersProvider);
                ref.invalidate(customerBookingsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${voucher.voucherTitle} applied! New total: ₱${newAmount.toStringAsFixed(2)}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _showRatingDialogFor(BuildContext context, BookingModel booking, String customerName) async {
    int rating = 0;
    final reviewController = TextEditingController();

    // Fetch technician name directly from Supabase to guarantee it's loaded
    String technicianName = 'Technician';
    try {
      final row = await SupabaseConfig.client
          .from('users')
          .select('full_name')
          .eq('id', booking.technicianId)
          .single();
      technicianName = row['full_name'] as String? ?? 'Technician';
    } catch (_) {
      // Fallback to cached provider value if Supabase fetch fails
      technicianName = ref.read(userByIdProvider(booking.technicianId)).value?.fullName ?? 'Technician';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setS) => AlertDialog(
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
                  ScaffoldMessenger.of(builderContext).showSnackBar(
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
                // Save rating with technician_id so Supabase trigger auto-updates stats
                try {
                  await SupabaseConfig.client.from('app_ratings').insert({
                    'customer_name': customerName,
                    'technician': technicianName,
                    'technician_id': booking.technicianId,
                    'rating': rating,
                    'review': reviewController.text,
                    'date': DateFormat('MM/dd/yyyy').format(DateTime.now()),
                    'service': 'Repair Service',
                    'device': 'Device',
                  });
                } catch (_) {
                  // Fallback: insert without technician_id if column doesn't exist yet
                  await ref.read(ratingsProvider.notifier).addRating(newRating);
                }

                // Also write rating directly on the booking row
                try {
                  await SupabaseConfig.client
                      .from('bookings')
                      .update({'rating': rating, 'review': reviewController.text.isNotEmpty ? reviewController.text : null})
                      .eq('id', booking.id);
                } catch (e) {
                  debugPrint('Failed to update booking rating: $e');
                }

                // Recalculate and persist technician average from app_ratings (same source as ratings screen)
                try {
                  final rows = await SupabaseConfig.client
                      .from('app_ratings')
                      .select('rating')
                      .ilike('technician', technicianName);
                  final vals = (rows as List).map((r) => (r['rating'] as num).toInt()).toList();
                  if (vals.isNotEmpty) {
                    final avg = vals.reduce((a, b) => a + b) / vals.length;
                    await SupabaseConfig.client
                        .from('app_technician_stats')
                        .upsert({
                          'technician_id': booking.technicianId,
                          'average_rating': avg,
                          'total_reviews': vals.length,
                          'updated_at': DateTime.now().toIso8601String(),
                        }, onConflict: 'technician_id');
                  }
                } catch (e) {
                  debugPrint('Failed to update technician stats: $e');
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your rating!'), backgroundColor: Colors.green),
                );
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
      'requested'            => (const Color(0xFFFF9800), 'Requested'),
      'accepted'             => (AppTheme.lightBlue,       'Accepted'),
      'en_route'             => (const Color(0xFF0EA5E9),  'En Route'),
      'arrived'              => (const Color(0xFF8B5CF6),  'Arrived'),
      'in_progress'          => (AppTheme.lightBlue,       'In Progress'),
      'completed'            => (Colors.orange,            'Awaiting Payment'),
      'paid'                 => (const Color(0xFF059669),  'Completed'),
      'closed'               => (const Color(0xFF059669),  'Completed'),
      'cancellation_pending' => (Colors.orange,            'Cancellation Pending'),
      'cancelled'            => (Colors.red,               'Cancelled'),
      _                      => (Colors.grey, status),
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
        'requested'   => 'Requested',
        'accepted'    => 'Accepted',
        'en_route'    => 'En Route',
        'arrived'     => 'Arrived',
        'in_progress' => 'In Progress',
        'completed'   => 'Completed',
        'paid'        => 'Paid',
        'cancelled'   => 'Cancelled',
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
  final String rawStatus;
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
  final VoidCallback? onUseVoucher;

  const _BookingCard({
    required this.bookingId,
    required this.technicianId,
    required this.customerName,
    required this.status,
    required this.rawStatus,
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
    this.onUseVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (rawStatus) {
      'requested'            => Icons.inbox_outlined,
      'accepted'             => Icons.check_circle_outline,
      'en_route'             => Icons.directions_car_outlined,
      'arrived'              => Icons.place_outlined,
      'in_progress'          => Icons.build_circle_outlined,
      'completed'            => Icons.hourglass_top_rounded,
      'paid' || 'closed'     => Icons.payments_outlined,
      'cancellation_pending' => Icons.pending_outlined,
      'cancelled'            => Icons.cancel_outlined,
      _                      => Icons.info_outline,
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // ── Header row ──────────────────────────────────────────
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
                    child: Icon(icon, color: statusColor),
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
                                'Job #${bookingId.replaceAll('-', '').substring(0, 6).toUpperCase()}',
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
                            _StatusChip(label: status, color: statusColor),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MetaPill(icon: Icons.calendar_today, label: date),
                            const SizedBox(width: 8),
                            _MetaPill(icon: Icons.access_time, label: time),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _MetaLine(
                          icon: Icons.location_on_outlined,
                          text: location,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Job progress tracker ─────────────────────────────────
              if (['accepted', 'en_route', 'arrived', 'in_progress', 'completed'].contains(rawStatus)) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.route_outlined, size: 14, color: AppTheme.deepBlue),
                    SizedBox(width: 6),
                    Text(
                      'Job Progress',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.deepBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                JobStatusTracker(currentStatus: rawStatus),
              ],

              // ── Amount row ──────────────────────────────────────────
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      total,
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

              // ── Pay / voucher buttons ───────────────────────────────
              if (showPayButton) ...[
                const SizedBox(height: 12),
                if (paymentStatus == 'completed')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Payment Completed'),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.green.shade100,
                        disabledForegroundColor: Colors.green.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else if (paymentStatus == 'submitted')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.hourglass_top_rounded, size: 18),
                      label: const Text('Waiting for Verification'),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.orange.shade100,
                        disabledForegroundColor: Colors.orange.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else
                  Builder(builder: (ctx) => Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onUseVoucher,
                          icon: const Icon(Icons.local_offer_rounded, size: 17),
                          label: const Text('Use Voucher'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B5CF6),
                            side: const BorderSide(color: Color(0xFF8B5CF6)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ctx.push('/payment/$bookingId?amount=${paymentAmount.toStringAsFixed(2)}'),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Pay Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  )),
              ],
            ],
          ),
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
  final VoidCallback onUseVoucher;

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
    required this.onUseVoucher,
  });

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {

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

    // ── Parse customer booking details ──────────────────────────────
    final parsedNotes = parseBookingNotes(booking.diagnosticNotes);
    final hasBookingDetails = parsedNotes.device != null ||
        parsedNotes.model != null ||
        parsedNotes.problem != null ||
        (parsedNotes.details != null && parsedNotes.details!.trim().isNotEmpty);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
              // ── Booking Details (Customer Notes) ──────────────────
              if (hasBookingDetails) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Booking Details',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (parsedNotes.device != null)
                        _SheetRow(icon: Icons.devices_rounded, label: 'Device', value: parsedNotes.device!),
                      if (parsedNotes.model != null)
                        _SheetRow(icon: Icons.phone_iphone, label: 'Model', value: parsedNotes.model!),
                      if (parsedNotes.problem != null)
                        _SheetRow(icon: Icons.report_problem_outlined, label: 'Problem', value: parsedNotes.problem!),
                      if (parsedNotes.details != null && parsedNotes.details!.trim().isNotEmpty)
                        _SheetRow(icon: Icons.notes_rounded, label: 'Notes', value: parsedNotes.details!.trim()),
                    ],
                  ),
                ),
              ],

              // ── Points earned ─────────────────────────────────────
              if (widget.pointsEarned != null && widget.pointsEarned! > 0) ...[
                const SizedBox(height: 16),
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
              ],

              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────
              if (widget.isActive) ...[
                _PayButton(booking: booking, amount: widget.amount),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onUseVoucher,
                    icon: const Icon(Icons.local_offer_outlined, size: 18),
                    label: const Text('Use Voucher'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
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
  final List<Widget> children;

  const _SheetSection({required this.children});

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
        children: children,
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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

// ─── Payment breakdown sheet ──────────────────────────────────────────────────

class _PaymentBreakdownSheet extends StatefulWidget {
  final BookingModel booking;
  final double amount;
  final ScrollController scrollController;

  const _PaymentBreakdownSheet({
    required this.booking,
    required this.amount,
    required this.scrollController,
  });

  @override
  State<_PaymentBreakdownSheet> createState() => _PaymentBreakdownSheetState();
}

class _PaymentBreakdownSheetState extends State<_PaymentBreakdownSheet> {
  RedeemedVoucher? _voucher;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await SupabaseConfig.client
          .from('user_redeemed_vouchers')
          .select()
          .eq('booking_id', widget.booking.id)
          .limit(1);
      final list = rows as List;
      if (list.isNotEmpty && mounted) {
        _voucher = RedeemedVoucher.fromJson(Map<String, dynamic>.from(list.first as Map));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }

    final booking = widget.booking;
    final estimatedCost = booking.estimatedCost ?? 0.0;
    final voucher = _voucher;

    // Reconstruct pre-voucher total
    double preVoucherTotal;
    double voucherDiscount = 0;
    if (voucher != null) {
      if (voucher.discountType == 'percentage') {
        final rate = voucher.discountAmount / 100;
        preVoucherTotal = rate >= 1 ? widget.amount : widget.amount / (1 - rate);
        voucherDiscount = preVoucherTotal - widget.amount;
      } else {
        voucherDiscount = voucher.discountAmount;
        preVoucherTotal = widget.amount + voucherDiscount;
      }
    } else {
      preVoucherTotal = widget.amount;
    }

    // Tech additional charges above the initial estimate
    final techAdditional = (preVoucherTotal - estimatedCost).clamp(0.0, double.infinity);

    // Parsed breakdown (stored for new bookings)
    final storedServiceFee = booking.parsedServiceFee;
    final storedDistanceFee = booking.parsedDistanceFee;

    final parts = booking.partsList;

    // Parse individual price adjustments from technician notes
    final adjRegex = RegExp(r'Price (increased|decreased) by ₱([\d.]+)(?:\s*—\s*Reason:\s*(.*))?');
    final techNotes = booking.technicianNotes;
    final adjustments = <(bool, double, String?)>[];
    if (techNotes != null) {
      for (final line in techNotes.split('\n')) {
        final m = adjRegex.firstMatch(line.trim());
        if (m != null) {
          final isIncrease = m.group(1) == 'increased';
          final amt = double.tryParse(m.group(2)!) ?? 0.0;
          final reason = m.group(3)?.trim();
          if (amt > 0) adjustments.add((isIncrease, amt, reason));
        }
      }
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.deepBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Breakdown',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                  Text('Full itemization of charges',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── BASE CHARGES ─────────────────────────────────────────
          _BdSectionHeader(title: 'Base Charges', icon: Icons.home_repair_service_rounded, color: AppTheme.deepBlue),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                if (storedServiceFee != null && storedServiceFee > 0)
                  _BdRow('Service Fee', storedServiceFee),
                if (storedDistanceFee != null)
                  _BdRow(
                    'Travel Fee${_distanceNote(booking)}',
                    storedDistanceFee,
                  )
                else
                  _BdRow('Estimated Base Charge', estimatedCost),
              ],
            ),
          ),

          // ── TECHNICIAN ADDITIONS ──────────────────────────────────
          if ((storedServiceFee != null && storedServiceFee > 0) ||
              adjustments.isNotEmpty ||
              parts.isNotEmpty ||
              techAdditional > 0) ...[
            const SizedBox(height: 16),
            _BdSectionHeader(title: 'Technician Additions', icon: Icons.engineering_rounded, color: Colors.orange.shade700),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Fee (from assess & price)
                  if (storedServiceFee != null && storedServiceFee > 0)
                    _BdRow('Service Fee', storedServiceFee, color: Colors.orange.shade800),
                  // Individual price adjustments with reasons
                  for (final (isIncrease, amt, reason) in adjustments) ...[
                    _BdRow(
                      isIncrease ? 'Price Increase' : 'Price Decrease',
                      amt,
                      color: isIncrease ? Colors.orange.shade800 : Colors.red.shade700,
                    ),
                    if (reason != null && reason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.subdirectory_arrow_right_rounded, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  // Fallback for legacy bookings without parsed breakdown
                  if (storedServiceFee == null && adjustments.isEmpty && techAdditional > 0)
                    _BdRow('Service & Additional Charges', techAdditional, color: Colors.orange.shade800),
                  // Parts Used
                  if (parts.isNotEmpty) ...[
                    if (storedServiceFee != null || adjustments.isNotEmpty || techAdditional > 0)
                      const SizedBox(height: 8),
                    Text('Parts Used',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade800)),
                    const SizedBox(height: 6),
                    ...parts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 5, color: Colors.orange.shade400),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor))),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],

          // ── VOUCHER DISCOUNT ──────────────────────────────────────
          if (voucher != null) ...[
            const SizedBox(height: 16),
            _BdSectionHeader(title: 'Discount Applied', icon: Icons.local_offer_rounded, color: Colors.green.shade700),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(voucher.voucherTitle,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green)),
                        Text(
                          voucher.discountType == 'percentage'
                              ? '${voucher.discountAmount.toStringAsFixed(0)}% off'
                              : 'Fixed discount',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                        ),
                      ],
                    ),
                  ),
                  Text('- ₱${voucherDiscount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green)),
                ],
              ),
            ),
          ],

          // ── TOTAL ─────────────────────────────────────────────────
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
              Text(
                '₱${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.deepBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _distanceNote(BookingModel booking) {
    if (booking.diagnosticNotes == null) return '';
    final m = RegExp(r'Distance: ([\d.]+)\s*km').firstMatch(booking.diagnosticNotes!);
    return m != null ? ' (${m.group(1)} km)' : '';
  }
}

class _BdSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _BdSectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _BdRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _BdRow(this.label, this.amount, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textPrimaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: c))),
          Text('₱${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }
}

// ─── Voucher tile for the voucher selection sheet ─────────────────────────────

class _VoucherTile extends StatelessWidget {
  final RedeemedVoucher voucher;
  final VoidCallback onApply;

  const _VoucherTile({super.key, required this.voucher, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final discount = voucher.discountType == 'percentage'
        ? '${voucher.discountAmount.toStringAsFixed(0)}% off'
        : '₱${voucher.discountAmount.toStringAsFixed(0)} off';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.local_offer, color: Colors.green.shade700, size: 22),
        ),
        title: Text(
          voucher.voucherTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          discount,
          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        trailing: ElevatedButton(
          onPressed: onApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ── Job Request Card ──────────────────────────────────────────────────────────

class _JobRequestCard extends StatelessWidget {
  final JobRequestModel request;
  final VoidCallback onTap;
  const _JobRequestCard({required this.request, required this.onTap});

  (Color, IconData, String) get _statusStyle => switch (request.status) {
        'open' => (Colors.orange, Icons.hourglass_top_rounded, 'Open'),
        'pending_customer_approval' => (
            const Color(0xFF8B5CF6),
            Icons.notification_important_rounded,
            'Awaiting Approval'
          ),
        'accepted' => (
            const Color(0xFF0EA5E9),
            Icons.engineering_rounded,
            'Accepted'
          ),
        'completed' => (
            const Color(0xFF059669),
            Icons.check_circle_rounded,
            'Completed'
          ),
        'cancelled' => (Colors.red, Icons.cancel_rounded, 'Cancelled'),
        _ => (Colors.grey, Icons.circle, request.status),
      };

  @override
  Widget build(BuildContext context) {
    final (color, statusIcon, label) = _statusStyle;
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    String? parsedBrand;
    String? parsedModel;
    String? parsedIssues;
    for (final line in request.problemDescription.split('\n')) {
      if (line.startsWith('Brand: ')) parsedBrand = line.substring(7).trim();
      if (line.startsWith('Model: ')) parsedModel = line.substring(7).trim();
      if (line.startsWith('Issues: ')) parsedIssues = line.substring(8).trim();
    }

    final deviceIcon = request.deviceType == 'Laptop'
        ? Icons.laptop_rounded
        : Icons.smartphone_rounded;
    final deviceLabel = [request.deviceType, parsedBrand, parsedModel]
        .whereType<String>()
        .join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
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
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(deviceIcon, color: color),
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
                                deviceLabel,
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
                            _StatusChip(label: label, color: color),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _MetaPill(
                          icon: Icons.access_time_rounded,
                          label: fmt.format(request.createdAt.toLocal()),
                        ),
                        const SizedBox(height: 8),
                        _MetaLine(
                          icon: Icons.location_on_outlined,
                          text: request.address,
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
                      parsedIssues ?? 'No issues listed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Job Request Detail Sheet ──────────────────────────────────────────────────

class _JobRequestDetailSheet extends ConsumerStatefulWidget {
  final JobRequestModel request;
  const _JobRequestDetailSheet({required this.request});

  @override
  ConsumerState<_JobRequestDetailSheet> createState() =>
      _JobRequestDetailSheetState();
}

class _JobRequestDetailSheetState
    extends ConsumerState<_JobRequestDetailSheet> {
  bool _accepting = false;
  bool _declining = false;

  (Color, IconData, String) get _statusStyle =>
      switch (widget.request.status) {
        'open' => (Colors.orange, Icons.hourglass_top_rounded, 'Open'),
        'pending_customer_approval' => (
            const Color(0xFF8B5CF6),
            Icons.notification_important_rounded,
            'Awaiting Your Approval'
          ),
        'accepted' => (
            const Color(0xFF0EA5E9),
            Icons.engineering_rounded,
            'Accepted'
          ),
        'completed' => (
            const Color(0xFF059669),
            Icons.check_circle_rounded,
            'Completed'
          ),
        'cancelled' => (Colors.red, Icons.cancel_rounded, 'Cancelled'),
        _ => (Colors.grey, Icons.circle, widget.request.status),
      };

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const toRad = pi / 180;
    final dLat = (lat2 - lat1) * 111.0;
    final dLng = (lng2 - lng1) * 111.0 * cos((lat1 + lat2) / 2 * toRad);
    return sqrt(dLat * dLat + dLng * dLng);
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Not logged in');
      final supabase = SupabaseConfig.client;
      final techId = widget.request.technicianId!;

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

      final techRow = await supabase
          .from('users')
          .select('latitude, longitude')
          .eq('id', techId)
          .single();
      final techLat = (techRow['latitude'] as num?)?.toDouble();
      final techLng = (techRow['longitude'] as num?)?.toDouble();
      double? distFee;
      if (techLat != null && techLng != null) {
        final distKm = _haversineKm(
          techLat, techLng,
          widget.request.latitude, widget.request.longitude,
        );
        final rate = await DistanceFeeService.getRate();
        distFee = (distKm * 10).round() * rate;
      }

      final scheduledAt = DateTime.now().add(const Duration(minutes: 15));
      final booking = await ref.read(bookingServiceProvider).createBooking(
            customerId: user.id,
            technicianId: techId,
            serviceId: serviceId,
            status: AppConstants.bookingAccepted,
            scheduledDate: scheduledAt,
            customerAddress: widget.request.address,
            customerLatitude: widget.request.latitude,
            customerLongitude: widget.request.longitude,
            estimatedCost: distFee,
            paymentMethod: 'gcash',
            bookingSource: 'post_problem',
          );

      final distanceNoteLine = (distFee != null && distFee > 0)
          ? '\nDistance Fee: ₱${distFee.toStringAsFixed(2)}'
          : '';
      await supabase.from('bookings').update({
        'diagnostic_notes':
            '[POST_PROBLEM]\n${widget.request.problemDescription}$distanceNoteLine',
      }).eq('id', booking.id);

      await ref
          .read(jobRequestServiceProvider)
          .acceptRequest(widget.request.id, techId);

      // Notify the technician their proposal was accepted
      await NotificationService().sendNotification(
        userId: techId,
        type: 'job_request_accepted',
        title: 'Proposal Accepted!',
        message: 'The customer accepted your proposal for ${widget.request.deviceType} repair. Check your jobs.',
        data: {'route': '/tech-jobs'},
      );

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
    // Save before customerDeclineRequest clears it in the DB
    final declinedTechId = widget.request.technicianId;
    try {
      await ref
          .read(jobRequestServiceProvider)
          .customerDeclineRequest(widget.request.id);

      // Notify the technician their proposal was declined
      if (declinedTechId != null) {
        await NotificationService().sendNotification(
          userId: declinedTechId,
          type: 'job_request_declined',
          title: 'Proposal Declined',
          message: 'The customer declined your proposal for ${widget.request.deviceType} repair. The request is still open.',
          data: {'route': '/tech-job-map'},
        );
      }

      if (!mounted) return;
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
    final (color, icon, label) = _statusStyle;
    final fmt = DateFormat('MMM d, yyyy · h:mm a');

    // Parse fields
    String? parsedBrand;
    String? parsedModel;
    String? parsedIssues;
    String? parsedNotes;
    for (final line in widget.request.problemDescription.split('\n')) {
      if (line.startsWith('Brand: ')) parsedBrand = line.substring(7).trim();
      if (line.startsWith('Model: ')) parsedModel = line.substring(7).trim();
      if (line.startsWith('Issues: ')) parsedIssues = line.substring(8).trim();
    }
    final sepIdx = widget.request.problemDescription.indexOf('---\n');
    if (sepIdx != -1) {
      parsedNotes =
          widget.request.problemDescription.substring(sepIdx + 4).trim();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            // Handle
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.request.deviceType == 'Laptop'
                        ? Icons.laptop_rounded
                        : Icons.smartphone_rounded,
                    color: AppTheme.deepBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.deviceType,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryColor),
                      ),
                      Text(
                        fmt.format(widget.request.createdAt.toLocal()),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: 5),
                      Text(label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Details card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  if (parsedBrand != null)
                    _DetailRow(
                        icon: Icons.business_rounded,
                        label: 'Brand',
                        value: parsedBrand),
                  if (parsedBrand != null) const Divider(height: 1),
                  if (parsedModel != null)
                    _DetailRow(
                        icon: Icons.perm_device_information_rounded,
                        label: 'Model',
                        value: parsedModel),
                  if (parsedModel != null) const Divider(height: 1),
                  if (parsedIssues != null)
                    _DetailRow(
                        icon: Icons.build_circle_rounded,
                        label: 'Issues',
                        value: parsedIssues),
                  if (parsedIssues != null) const Divider(height: 1),
                  if (parsedNotes != null)
                    _DetailRow(
                        icon: Icons.notes_rounded,
                        label: 'Additional Notes',
                        value: parsedNotes),
                  if (parsedNotes != null) const Divider(height: 1),
                  _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value: widget.request.address),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Accept / Decline buttons (pending_customer_approval only)
            if (widget.request.status == 'pending_customer_approval' &&
                widget.request.technicianId != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_accepting || _declining) ? null : _decline,
                      icon: _declining
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_accepting || _declining) ? null : _accept,
                      icon: _accepting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
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

            // Cancel button (open requests only)
            if (widget.request.status == 'open')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Cancel Request'),
                        content: const Text(
                            'Are you sure you want to cancel this request?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('No')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Yes, Cancel',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true || !context.mounted) return;
                    await ref
                        .read(jobRequestServiceProvider)
                        .cancelRequest(widget.request.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 18),
                  label: const Text('Cancel Request',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.deepBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared card helper widgets ───────────────────────────────────────────────

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
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade800),
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

