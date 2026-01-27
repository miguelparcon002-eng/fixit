import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../services/ratings_service.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  int _selectedTab = 0; // 0 = Upcoming, 1 = Active, 2 = Complete, 3 = All

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with Title and Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Appointments',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
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
                    _TabButton(
                      label: 'Upcoming',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _TabButton(
                      label: 'Active',
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                    _TabButton(
                      label: 'Complete',
                      isSelected: _selectedTab == 2,
                      onTap: () => setState(() => _selectedTab = 2),
                    ),
                    _TabButton(
                      label: 'All',
                      isSelected: _selectedTab == 3,
                      onTap: () => setState(() => _selectedTab = 3),
                    ),
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
    final allBookings = ref.watch(localBookingsProvider);

    // Upcoming tab - show only bookings with "Scheduled" status
    if (_selectedTab == 0) {
      final scheduledBookings = allBookings.where((booking) => booking.status == 'Scheduled').toList();

      if (scheduledBookings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No upcoming appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your scheduled bookings will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        itemCount: scheduledBookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final booking = scheduledBookings[index];
          return _BookingCard(
            bookingId: booking.id,
            icon: booking.icon,
            status: 'Requesting',
            statusColor: const Color(0xFFFF9800), // Orange for Scheduled
            deviceName: booking.deviceName,
            serviceName: booking.serviceName,
            date: booking.date,
            time: booking.time,
            location: booking.location,
            technician: booking.technician,
            total: booking.total,
            customerName: booking.customerName,
            moreDetails: booking.moreDetails,
            technicianNotes: booking.technicianNotes,
            promoCode: booking.promoCode,
            discountAmount: booking.discountAmount,
            originalPrice: booking.originalPrice,
          );
        },
      );
    }

    // Active tab - show in progress bookings
    if (_selectedTab == 1) {
      final activeBookings = allBookings.where((booking) => booking.status == 'In Progress').toList();

      // Build list of widgets
      final activeWidgets = <Widget>[];

      // Add dynamic bookings
      for (var booking in activeBookings) {
        activeWidgets.add(
          _BookingCard(
            bookingId: booking.id,
            icon: booking.icon,
            status: booking.status,
            statusColor: AppTheme.lightBlue,
            deviceName: booking.deviceName,
            serviceName: booking.serviceName,
            date: booking.date,
            time: booking.time,
            location: booking.location,
            technician: booking.technician,
            total: booking.total,
            customerName: booking.customerName,
            moreDetails: booking.moreDetails,
            technicianNotes: booking.technicianNotes,
            promoCode: booking.promoCode,
            discountAmount: booking.discountAmount,
            originalPrice: booking.originalPrice,
          ),
        );
        activeWidgets.add(const SizedBox(height: 16));
      }

      if (activeWidgets.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No active bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accepted bookings will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return ListView(
        children: activeWidgets,
      );
    }

    // Complete tab - show completed bookings
    if (_selectedTab == 2) {
      final completedWidgets = <Widget>[];

      // Add completed bookings from provider
      for (var booking in allBookings.where((b) => b.status == 'Completed')) {
        completedWidgets.add(
          _BookingCard(
            bookingId: booking.id,
            icon: booking.icon,
            status: 'Completed',
            statusColor: Colors.green,
            deviceName: booking.deviceName,
            serviceName: booking.serviceName,
            date: booking.date,
            time: booking.time,
            location: booking.location,
            technician: booking.technician,
            total: booking.total,
            customerName: booking.customerName,
            showBookAgain: true,
            moreDetails: booking.moreDetails,
            technicianNotes: booking.technicianNotes,
            promoCode: booking.promoCode,
            discountAmount: booking.discountAmount,
            originalPrice: booking.originalPrice,
          ),
        );
        completedWidgets.add(const SizedBox(height: 16));
      }

      if (completedWidgets.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No completed bookings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completed jobs will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return ListView(
        children: completedWidgets,
      );
    }

    // All tab - show all bookings (scheduled + completed + in progress)
    final allBookingsWidgets = <Widget>[];

    // Add dynamic bookings from provider
    for (var booking in allBookings) {
      Color statusColor;
      String displayStatus;
      switch (booking.status) {
        case 'Scheduled':
          statusColor = const Color(0xFFFF9800); // Orange
          displayStatus = 'Requesting';
          break;
        case 'In Progress':
          statusColor = AppTheme.lightBlue;
          displayStatus = 'In Progress';
          break;
        case 'Completed':
          statusColor = Colors.green;
          displayStatus = 'Completed';
          break;
        default:
          statusColor = Colors.grey;
          displayStatus = booking.status;
      }

      allBookingsWidgets.add(
        _BookingCard(
          bookingId: booking.id,
          icon: booking.icon,
          status: displayStatus,
          statusColor: statusColor,
          deviceName: booking.deviceName,
          serviceName: booking.serviceName,
          date: booking.date,
          time: booking.time,
          location: booking.location,
          technician: booking.technician,
          total: booking.total,
          customerName: booking.customerName,
          moreDetails: booking.moreDetails,
          technicianNotes: booking.technicianNotes,
          promoCode: booking.promoCode,
          discountAmount: booking.discountAmount,
          originalPrice: booking.originalPrice,
        ),
      );
      allBookingsWidgets.add(const SizedBox(height: 16));
    }

    return ListView(
      children: allBookingsWidgets,
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
  final String icon;
  final String status;
  final Color statusColor;
  final String deviceName;
  final String serviceName;
  final String date;
  final String time;
  final String location;
  final String technician;
  final String total;
  final String customerName;
  final bool showBookAgain;
  final String? moreDetails;
  final String? technicianNotes;
  final String? promoCode;
  final String? discountAmount;
  final String? originalPrice;

  const _BookingCard({
    required this.bookingId,
    required this.icon,
    required this.status,
    required this.statusColor,
    required this.deviceName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.location,
    required this.technician,
    required this.total,
    required this.customerName,
    this.showBookAgain = false,
    this.moreDetails,
    this.technicianNotes,
    this.promoCode,
    this.discountAmount,
    this.originalPrice,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    bookingId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            deviceName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            serviceName,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoRow(label: 'Date:', value: date),
          const SizedBox(height: 6),
          _InfoRow(label: 'Time:', value: time),
          const SizedBox(height: 6),
          _InfoRow(label: 'Location:', value: location),
          const SizedBox(height: 6),
          _InfoRow(label: 'Technician:', value: technician),
          if (moreDetails != null && moreDetails!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Details:', value: moreDetails!),
          ],
          if (technicianNotes != null && technicianNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.engineering, size: 16, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Technician Notes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          technicianNotes!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (promoCode != null) ...[
            // Show discount badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer, size: 14, color: AppTheme.successColor),
                  const SizedBox(width: 6),
                  Text(
                    promoCode!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(-$discountAmount)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Original:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  originalPrice ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                promoCode != null ? 'Final Total:' : 'Total:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                total,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepBlue,
                ),
              ),
            ],
          ),
          if (showBookAgain) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRatingDialog(context, ref);
                    },
                    icon: const Icon(Icons.star_outline, size: 20),
                    label: const Text(
                      'Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: const BorderSide(color: AppTheme.deepBlue, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Book Again',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                children: [
                  const Icon(
                    Icons.star_rate,
                    size: 48,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rate $technician',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'How was your experience?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                          child: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            size: 40,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Review TextField
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write your review here (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (rating > 0) {
                      // Save rating and review
                      final now = DateTime.now();
                      final formattedDate = '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';

                      final newRating = Rating(
                        id: '${bookingId}_rating',
                        customerName: customerName,
                        technician: technician,
                        rating: rating,
                        review: reviewController.text,
                        date: formattedDate,
                        service: serviceName,
                        device: deviceName,
                        bookingId: bookingId,
                      );

                      await ref.read(ratingsProvider.notifier).addRating(newRating);

                      Navigator.of(dialogContext).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Thank you for rating $technician!'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a rating'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
