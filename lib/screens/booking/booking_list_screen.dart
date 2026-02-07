import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../services/ratings_service.dart';
import '../../models/booking_model.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'My Appointments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _TabButton(label: 'Upcoming', isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                    _TabButton(label: 'Active', isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                    _TabButton(label: 'Complete', isSelected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
                    _TabButton(label: 'All', isSelected: _selectedTab == 3, onTap: () => setState(() => _selectedTab = 3)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bookings List
            Expanded(
              child: Container(
                color: AppTheme.primaryCyan,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBookingsList(),
              ),
            ),
          ],
        ),
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
      case 0: // Upcoming
        filteredBookings = allBookings.where((b) => ['requested', 'accepted', 'scheduled'].contains(b.status)).toList();
        emptyMessage = 'No upcoming appointments';
        emptyIcon = Icons.calendar_today_outlined;
        break;
      case 1: // Active
        filteredBookings = allBookings.where((b) => b.status == 'in_progress').toList();
        emptyMessage = 'No active bookings';
        emptyIcon = Icons.work_outline;
        break;
      case 2: // Complete
        filteredBookings = allBookings.where((b) => b.status == 'completed').toList();
        emptyMessage = 'No completed bookings';
        emptyIcon = Icons.check_circle_outline;
        break;
      default: // All
        filteredBookings = allBookings;
        emptyMessage = 'No bookings yet';
        emptyIcon = Icons.inbox_outlined;
    }

    if (filteredBookings.isEmpty) {
      return _buildEmptyState(emptyIcon, emptyMessage);
    }

    return ListView.separated(
      itemCount: filteredBookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildBookingCard(filteredBookings[index]),
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
    final points = isCompleted ? ((booking.finalCost ?? booking.estimatedCost ?? 0.0) / 50).floor() : null;

    return _BookingCard(
      bookingId: booking.id,
      status: displayStatus,
      statusColor: statusColor,
      date: _formatDate(booking.scheduledDate),
      time: _formatTime(booking.scheduledDate),
      location: booking.customerAddress ?? 'N/A',
      total: '₱${(booking.finalCost ?? booking.estimatedCost ?? 0.0).toStringAsFixed(2)}',
      moreDetails: booking.diagnosticNotes,
      showBookAgain: isCompleted,
      pointsEarned: points,
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

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '#${bookingId.substring(0, 8)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Details
          _InfoRow(icon: Icons.calendar_today, label: 'Date', value: date),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.access_time, label: 'Time', value: time),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on, label: 'Location', value: location),
          if (moreDetails != null && moreDetails!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.info_outline, label: 'Details', value: moreDetails!),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
              Text(total, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.deepBlue)),
            ],
          ),
          // Points Earned
          if (pointsEarned != null && pointsEarned! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('+$pointsEarned Points Earned!', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ],
          // Actions
          if (showBookAgain) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRatingDialog(context, ref),
                    icon: const Icon(Icons.star_outline, size: 20),
                    label: const Text('Rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: const BorderSide(color: AppTheme.deepBlue, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Book Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
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
