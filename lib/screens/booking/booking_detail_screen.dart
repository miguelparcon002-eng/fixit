import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(localBookingsProvider);
    final booking = bookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => LocalBooking(
        id: bookingId,
        icon: '📱',
        status: 'Not Found',
        deviceName: 'Unknown',
        serviceName: 'Unknown',
        date: '',
        time: '',
        location: '',
        technician: '',
        total: '',
        customerName: '',
        customerPhone: '',
        priority: 'low',
        moreDetails: '',
        promoCode: null,
        discountAmount: null,
        originalPrice: null,
      ),
    );

    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'scheduled':
        statusColor = const Color(0xFFFF6B6B);
        break;
      case 'in progress':
        statusColor = AppTheme.lightBlue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    Color priorityColor;
    switch (booking.priority) {
      case 'high':
        priorityColor = const Color(0xFFFF6B6B);
        break;
      case 'medium':
        priorityColor = Colors.yellow.shade700;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          booking.id,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Booking'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit booking feature coming soon')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cancel, color: Colors.red),
                        title: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cancel booking feature coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        booking.status,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${booking.priority.toUpperCase()} PRIORITY',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Customer Information
            _SectionCard(
              title: 'Customer Information',
              children: [
                _InfoRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: booking.customerName,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: booking.customerPhone,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: booking.location,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Details
            _SectionCard(
              title: 'Service Details',
              children: [
                _InfoRow(
                  icon: Icons.devices,
                  label: 'Device',
                  value: booking.deviceName,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.build,
                  label: 'Service',
                  value: booking.serviceName,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: booking.date,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: booking.time,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional Details (if provided)
            if (booking.moreDetails != null && booking.moreDetails!.isNotEmpty) ...[
              _SectionCard(
                title: 'Customer Notes',
                children: [
                  _InfoRow(
                    icon: Icons.notes,
                    label: 'Your Notes',
                    value: booking.moreDetails!,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Technician Notes (if provided and booking is completed or in progress)
            if (booking.technicianNotes != null && booking.technicianNotes!.isNotEmpty) ...[
              _SectionCard(
                title: 'Technician Notes',
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Additional Issues Found',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.technicianNotes!,
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

            // Technician Information
            _SectionCard(
              title: 'Technician',
              children: [
                _InfoRow(
                  icon: Icons.engineering,
                  label: 'Assigned To',
                  value: booking.technician,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Information
            _SectionCard(
              title: 'Payment',
              children: [
                if (booking.promoCode != null) ...[
                  // Show promo code applied
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_offer, color: AppTheme.successColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Promo Code Applied',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                booking.promoCode!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Original price (crossed out)
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
                        booking.originalPrice ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Discount amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discount',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '- ${booking.discountAmount ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.successColor,
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
                  label: booking.promoCode != null ? 'Final Amount' : 'Total Amount',
                  value: booking.total,
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
                        SnackBar(content: Text('Calling ${booking.customerName}...')),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Customer'),
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
  final List<Widget> children;

  const _SectionCard({
    required this.title,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
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
