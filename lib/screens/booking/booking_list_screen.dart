import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../services/ratings_service.dart';
import '../../models/booking_model.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

enum _CustomerBookingsTab { upcoming, active, complete, all }

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  _CustomerBookingsTab _selectedTab = _CustomerBookingsTab.upcoming;

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
            Expanded(child: _buildBookingsList()),
          ],
        ),
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

    if (filteredBookings.isEmpty) {
      return _buildEmptyState(emptyIcon, emptyMessage);
    }

    // Keep newest first for completed, otherwise show nearest appointments first.
    filteredBookings.sort((a, b) {
      final aDate = a.scheduledDate ?? a.createdAt;
      final bDate = b.scheduledDate ?? b.createdAt;
      if (_selectedTab == _CustomerBookingsTab.complete) {
        return bDate.compareTo(aDate);
      }
      return aDate.compareTo(bDate);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildBookingCard(filteredBookings[index]),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
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
    // Show payment button on active bookings (always show payment state)
    final showPay = isActive;

    return _BookingCard(
      bookingId: booking.id,
      status: displayStatus,
      statusColor: statusColor,
      date: _formatDate(booking.scheduledDate),
      time: _formatTime(booking.scheduledDate),
      location: booking.customerAddress ?? 'N/A',
      total: '₱${amount.toStringAsFixed(2)}',
      moreDetails: booking.diagnosticNotes,
      showBookAgain: isCompleted,
      pointsEarned: points,
      showPayButton: showPay,
      paymentAmount: amount,
      paymentStatus: booking.paymentStatus,
    );
  }

  (Color, String) _getBookingStatus(String status) {
    return switch (status) {
      'requested' || 'accepted' || 'scheduled' => (const Color(0xFFFF9800), 'Scheduled'),
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
}

class _BookingCard extends ConsumerWidget {
  final String bookingId;
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

  const _BookingCard({
    required this.bookingId,
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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/booking/$bookingId'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Job #${bookingId.substring(0, 8)}',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.calendar_today, label: 'Date', value: date),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.access_time, label: 'Time', value: time),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.location_on, label: 'Location', value: location),
            if (moreDetails != null && moreDetails!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.info_outline, label: 'Details', value: moreDetails!),
            ],
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
            if (showPayButton) ...[
              const SizedBox(height: 10),
              _buildPaymentButton(context),
            ],
            if (pointsEarned != null && pointsEarned! > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '+$pointsEarned Points Earned!',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showBookAgain) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRatingDialog(context, ref),
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Rate'),
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
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Book Again'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(BuildContext context) {
    final (label, icon, bgColor) = switch (paymentStatus) {
      'completed' => ('Payment Completed', Icons.check_circle, Colors.green),
      'submitted' => ('Waiting for Verification', Icons.hourglass_top, Colors.orange),
      _ => ('Pay Now', Icons.payment, AppTheme.deepBlue),
    };

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push(
              '/payment/$bookingId?amount=${paymentAmount.toStringAsFixed(2)}',
            ),
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.85),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
    int rating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                    onTap: () => setState(() => rating = index + 1),
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
                  id: '${bookingId}_rating',
                  customerName: 'Customer',
                  technician: 'Technician',
                  rating: rating,
                  review: reviewController.text,
                  date: DateFormat('MM/dd/yyyy').format(DateTime.now()),
                  service: 'Repair Service',
                  device: 'Device',
                  bookingId: bookingId,
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
