import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../core/utils/booking_notes_parser.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load booking by ID so this screen works for both Customers and Technicians.
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));

    return bookingAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Booking Details',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Booking Details',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(child: Text('Error: $error')),
      ),
      data: (booking) {
        if (booking == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF5F7FA),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Booking Not Found',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: const Center(child: Text('Booking not found')),
          );
        }

        return _BookingDetailView(booking: booking);
      },
    );
  }
}

class _BookingDetailView extends StatelessWidget {
  final BookingModel booking;

  const _BookingDetailView({required this.booking});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on booking status
    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'scheduled':
      case 'pending':
        statusColor = const Color(0xFFFF6B6B);
        break;
      case 'in_progress':
      case 'ongoing':
        statusColor = AppTheme.lightBlue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Format dates
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final bookingDate = booking.scheduledDate != null
        ? dateFormat.format(booking.scheduledDate!)
        : 'Not scheduled';
    final bookingTime = booking.scheduledDate != null
        ? timeFormat.format(booking.scheduledDate!)
        : 'Not scheduled';

    // Parse device details from diagnosticNotes (supports multiline details)
    final parsedNotes = parseBookingNotes(booking.diagnosticNotes);
    final deviceType = parsedNotes.device;
    final deviceModel = parsedNotes.model;
    final deviceProblem = parsedNotes.problem;
    final deviceDetails = parsedNotes.details;

    // Get location
    final location = booking.customerAddress ?? 'No address provided';

    // Calculate final amount
    final estimatedCost = booking.estimatedCost ?? 0.0;
    final finalCost = booking.finalCost ?? estimatedCost;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Booking #${booking.id.substring(0, 8)}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit booking feature coming soon')),
                  );
                  break;
                case 'cancel':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cancel booking feature coming soon')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Booking')),
              PopupMenuItem(value: 'cancel', child: Text('Cancel Booking')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  booking.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Device Details
            _SectionCard(
              title: 'Device Details',
              trailing: TextButton.icon(
                onPressed: () => context.push('/booking/${booking.id}/device'),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View'),
              ),
              children: [
                _InfoRow(
                  icon: Icons.devices,
                  label: 'Device Type',
                  value: deviceType ?? 'Not specified',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.phone_iphone,
                  label: 'Model',
                  value: deviceModel ?? 'Not specified',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.report_problem_outlined,
                  label: 'Problem',
                  value: deviceProblem ?? 'Not specified',
                ),
                if (deviceDetails != null && deviceDetails.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    value: deviceDetails.trim(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Booking Information
            _SectionCard(
              title: 'Booking Information',
              children: [
                _InfoRow(
                  icon: Icons.build_circle,
                  label: 'Service ID',
                  value: booking.serviceId.substring(0, 12),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Scheduled Date',
                  value: bookingDate,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Scheduled Time',
                  value: bookingTime,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'Service Location',
                  value: location,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Details (if provided)
            if (booking.diagnosticNotes != null && booking.diagnosticNotes!.isNotEmpty) ...[
              _SectionCard(
                title: 'Service Details',
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined, color: AppTheme.deepBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Booking Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.diagnosticNotes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Service Warranty Information
            _SectionCard(
              title: 'Service Warranty',
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '90-Day Quality Guarantee',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All repairs come with our 90-day warranty covering parts and labor.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Technician Information
            _SectionCard(
              title: 'Assigned Technician',
              children: [
                _InfoRow(
                  icon: Icons.person,
                  label: 'Technician',
                  value: 'Professional Technician',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.stars,
                  label: 'Rating',
                  value: '4.8 ⭐ (120+ reviews)',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.verified,
                  label: 'Certification',
                  value: 'Verified & Certified',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.badge,
                  label: 'Technician ID',
                  value: booking.technicianId.substring(0, 12),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Information
            _SectionCard(
              title: 'Payment',
              children: [
                if (finalCost != estimatedCost && estimatedCost > 0) ...[
                  // Show price adjustment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original Price',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₱${estimatedCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        finalCost > estimatedCost ? 'Price Increase' : 'Discount',
                        style: TextStyle(
                          fontSize: 14,
                          color: finalCost > estimatedCost ? Colors.orange : AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${finalCost > estimatedCost ? '+' : '-'} ₱${(finalCost - estimatedCost).abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: finalCost > estimatedCost ? Colors.orange : AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade300, height: 1),
                  const SizedBox(height: 12),
                ],
                _InfoRow(
                  icon: Icons.payments,
                  label: 'Total Amount',
                  value: '₱${finalCost.toStringAsFixed(2)}',
                  valueStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling technician...')),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Technician'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: const BorderSide(color: AppTheme.deepBlue, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening chat...')),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.deepBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

