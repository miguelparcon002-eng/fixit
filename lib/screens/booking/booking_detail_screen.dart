import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_provider.dart';
import '../../models/booking_model.dart';
import '../../core/utils/booking_notes_parser.dart';
import '../../services/notification_service.dart';
import '../technician/widgets/customer_location_sheet.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load booking by ID so this screen works for both Customers and Technicians.
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));
    final currentUser = ref.watch(currentUserProvider).value;
    final isTechnician = currentUser?.role == 'technician';

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

        if (isTechnician) {
          return _TechBookingDetailView(booking: booking);
        }
        return _BookingDetailView(booking: booking);
      },
    );
  }
}

class _BookingDetailView extends ConsumerWidget {
  final BookingModel booking;

  const _BookingDetailView({required this.booking});

  /// Only 'requested' can be cancelled by the customer.
  bool get _isCancellable => booking.status == AppConstants.bookingRequested;

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final reasons = [
      'Change of plans',
      'Found another technician',
      'Wrong booking details',
      'Technician taking too long to respond',
      'Other',
    ];

    String? selectedReason;
    final otherController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
              SizedBox(width: 10),
              Text('Cancel Booking'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please tell us why you want to cancel:',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 12),
                ...reasons.map((r) {
                      final isSelected = selectedReason == r;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedReason = r),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.red : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  color: isSelected ? Colors.red : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.circle, color: Colors.white, size: 10)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(r, style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: otherController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Please describe your reason',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Booking'),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Cancel Booking'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final reason = selectedReason == 'Other'
        ? otherController.text.trim().isNotEmpty
            ? otherController.text.trim()
            : 'Other'
        : selectedReason!;

    try {
      final bookingService = ref.read(bookingServiceProvider);
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: AppConstants.bookingCancelled,
        cancellationReason: reason,
      );

      // Notify the technician
      await NotificationService().sendNotification(
        userId: booking.technicianId,
        type: 'booking_cancelled',
        title: 'Booking Cancelled',
        message: 'A customer has cancelled their booking. Reason: $reason',
        data: {'booking_id': booking.id, 'route': '/tech-jobs'},
      );

      ref.invalidate(bookingByIdProvider(booking.id));
      ref.invalidate(customerBookingsProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully.'),
          backgroundColor: Colors.red,
        ),
      );
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch technician contact number for Call/Message buttons
    final techUserAsync = booking.technicianId.isNotEmpty
        ? ref.watch(userByIdProvider(booking.technicianId))
        : const AsyncData(null);
    final techPhone = techUserAsync.value?.contactNumber;

    // Determine colors based on booking status
    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'requested':
        statusColor = Colors.orange;
        break;
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
      case 'cancelled':
        statusColor = Colors.red;
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
          if (_isCancellable)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'cancel') _showCancelDialog(context, ref);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
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
                  trailing: (booking.customerLatitude != null && booking.customerLongitude != null)
                      ? GestureDetector(
                          onTap: () {
                            final customerUser = ref.read(userByIdProvider(booking.customerId)).value;
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CustomerLocationSheet(
                                latitude: booking.customerLatitude!,
                                longitude: booking.customerLongitude!,
                                customerName: customerUser?.fullName ?? 'Customer',
                                address: location,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A5FE0).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF4A5FE0).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined, size: 13, color: Color(0xFF4A5FE0)),
                                SizedBox(width: 4),
                                Text('Map', style: TextStyle(fontSize: 11, color: Color(0xFF4A5FE0), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

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
            _TechnicianSection(technicianId: booking.technicianId),
            const SizedBox(height: 16),

            // Payment Information
            _SectionCard(
              title: 'Payment',
              children: [
                // Payment method
                _InfoRow(
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
                const SizedBox(height: 12),
                // Payment status
                _InfoRow(
                  icon: Icons.receipt_outlined,
                  label: 'Payment Status',
                  value: booking.paymentStatus ?? '—',
                ),
                const SizedBox(height: 12),
                // Estimated cost always shown
                if (estimatedCost > 0) ...[
                  _InfoRow(
                    icon: Icons.calculate_outlined,
                    label: 'Estimated Amount',
                    value: '₱${estimatedCost.toStringAsFixed(2)}',
                  ),
                ],
                // Final cost + adjustment only shown after payment is completed
                if (booking.paymentStatus == 'completed') ...[
                  if (booking.finalCost != null && booking.finalCost != estimatedCost && estimatedCost > 0) ...[
                    const SizedBox(height: 12),
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
                  ],
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.price_check,
                    label: 'Final Amount',
                    value: '₱${finalCost.toStringAsFixed(2)}',
                    valueStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons — Call/Message only shown when job is in progress
            if (booking.status == 'in_progress') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: techPhone != null
                          ? () => launchUrl(Uri(scheme: 'tel', path: techPhone))
                          : null,
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
                      onPressed: techPhone != null
                          ? () => launchUrl(Uri(scheme: 'sms', path: techPhone))
                          : null,
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
              const SizedBox(height: 12),
            ],

            // Cancel button — only shown while still 'requested'
            if (_isCancellable)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, ref),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text(
                    'Cancel Booking Request',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            // Locked banner — shown once technician has accepted
            if (!_isCancellable &&
                booking.status != AppConstants.bookingCancelled &&
                booking.status != AppConstants.bookingCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This booking can no longer be cancelled because the technician has already accepted it.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianSection extends ConsumerWidget {
  final String technicianId;
  const _TechnicianSection({required this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(technicianId));
    final techAsync = ref.watch(technicianProfileProvider(technicianId));

    return _SectionCard(
      title: 'Assigned Technician',
      children: [
        userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const _InfoRow(
            icon: Icons.person,
            label: 'Technician',
            value: 'Unknown Technician',
          ),
          data: (user) => _InfoRow(
            icon: Icons.person,
            label: 'Technician',
            value: user?.fullName ?? 'Unknown Technician',
          ),
        ),
        const SizedBox(height: 12),
        techAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
          data: (tech) => tech != null
              ? Column(
                  children: [
                    _InfoRow(
                      icon: Icons.stars,
                      label: 'Rating',
                      value: tech.rating > 0
                          ? '${tech.rating.toStringAsFixed(1)} ⭐ (${tech.totalJobs} jobs)'
                          : 'No ratings yet',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.verified,
                      label: 'Certification',
                      value: tech.certifications.isNotEmpty
                          ? tech.certifications.join(', ')
                          : 'Verified & Certified',
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        _InfoRow(
          icon: Icons.badge,
          label: 'Technician ID',
          value: technicianId.length >= 12
              ? technicianId.substring(0, 12)
              : technicianId,
        ),
      ],
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
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.trailing,
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
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

// ─── Technician-specific booking detail view ───────────────────────────────

class _TechBookingDetailView extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _TechBookingDetailView({required this.booking});

  @override
  ConsumerState<_TechBookingDetailView> createState() => _TechBookingDetailViewState();
}

class _TechBookingDetailViewState extends ConsumerState<_TechBookingDetailView> {
  bool _isLoading = false;

  BookingModel get booking => widget.booking;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final bookingService = ref.read(bookingServiceProvider);
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: newStatus,
      );
      ref.invalidate(bookingByIdProvider(booking.id));
      ref.invalidate(technicianBookingsProvider);
      if (!mounted) return;
      final labels = {
        'in_progress': 'Job started!',
        'completed': 'Job marked as completed!',
        'cancelled': 'Job declined.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(labels[newStatus] ?? 'Status updated.'),
          backgroundColor: newStatus == 'cancelled' ? Colors.red : AppTheme.successColor,
        ),
      );
      if (newStatus == 'cancelled' || newStatus == 'completed') context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final bookingDate = booking.scheduledDate != null
        ? dateFormat.format(booking.scheduledDate!)
        : 'Not scheduled';
    final bookingTime = booking.scheduledDate != null
        ? timeFormat.format(booking.scheduledDate!)
        : 'Not scheduled';

    final parsedNotes = parseBookingNotes(booking.diagnosticNotes);
    final location = booking.customerAddress ?? 'No address provided';
    final estimatedCost = booking.estimatedCost ?? 0.0;
    final finalCost = booking.finalCost ?? estimatedCost;

    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'requested':
        statusColor = Colors.orange;
        break;
      case 'accepted':
      case 'scheduled':
        statusColor = AppTheme.lightBlue;
        break;
      case 'in_progress':
      case 'ongoing':
        statusColor = AppTheme.accentPurple;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    final customerUserAsync = ref.watch(userByIdProvider(booking.customerId));

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
          'Job #${booking.id.substring(0, 8)}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        booking.status.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer Info
                  _SectionCard(
                    title: 'Customer',
                    children: [
                      customerUserAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => const _InfoRow(icon: Icons.person, label: 'Customer', value: 'Unknown'),
                        data: (user) => Column(
                          children: [
                            _InfoRow(
                              icon: Icons.person,
                              label: 'Name',
                              value: user?.fullName ?? 'Unknown',
                            ),
                            if (user?.contactNumber != null) ...[
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.phone,
                                label: 'Contact',
                                value: user!.contactNumber!,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => launchUrl(Uri(scheme: 'tel', path: user.contactNumber)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.deepBlue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.call, size: 13, color: AppTheme.deepBlue),
                                            SizedBox(width: 4),
                                            Text('Call', style: TextStyle(fontSize: 11, color: AppTheme.deepBlue, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => launchUrl(Uri(scheme: 'sms', path: user.contactNumber)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.sms, size: 13, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text('SMS', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                        value: parsedNotes.device ?? 'Not specified',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.phone_iphone,
                        label: 'Model',
                        value: parsedNotes.model ?? 'Not specified',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.report_problem_outlined,
                        label: 'Problem',
                        value: parsedNotes.problem ?? 'Not specified',
                      ),
                      if (parsedNotes.details != null && parsedNotes.details!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.notes_rounded,
                          label: 'Notes',
                          value: parsedNotes.details!.trim(),
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
                        trailing: (booking.customerLatitude != null && booking.customerLongitude != null)
                            ? GestureDetector(
                                onTap: () {
                                  final customerUser = ref.read(userByIdProvider(booking.customerId)).value;
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => CustomerLocationSheet(
                                      latitude: booking.customerLatitude!,
                                      longitude: booking.customerLongitude!,
                                      customerName: customerUser?.fullName ?? 'Customer',
                                      address: location,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A5FE0).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF4A5FE0).withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map_outlined, size: 13, color: Color(0xFF4A5FE0)),
                                      SizedBox(width: 4),
                                      Text('Map', style: TextStyle(fontSize: 11, color: Color(0xFF4A5FE0), fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (booking.isEmergency) ...[
                        const SizedBox(height: 12),
                        const _InfoRow(
                          icon: Icons.warning_amber_rounded,
                          label: 'Priority',
                          value: 'Emergency',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Payment
                  _SectionCard(
                    title: 'Payment',
                    children: [
                      _InfoRow(
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
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.receipt_outlined,
                        label: 'Payment Status',
                        value: booking.paymentStatus ?? '—',
                      ),
                      if (estimatedCost > 0) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.calculate_outlined,
                          label: 'Estimated Amount',
                          value: '₱${estimatedCost.toStringAsFixed(2)}',
                        ),
                      ],
                      if (booking.paymentStatus == 'completed') ...[
                        if (booking.finalCost != null && booking.finalCost != estimatedCost && estimatedCost > 0) ...[
                          const SizedBox(height: 12),
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
                        ],
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.price_check,
                          label: 'Final Amount',
                          value: '₱${finalCost.toStringAsFixed(2)}',
                          valueStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.deepBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action buttons based on status
                  if (booking.status == 'requested') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus('cancelled'),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Decline', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.red, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('in_progress'),
                            icon: const Icon(Icons.check),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.deepBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (booking.status == 'in_progress') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: booking.paymentStatus == 'completed'
                            ? () => _updateStatus('completed')
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          booking.paymentStatus == 'completed'
                              ? 'Mark as Completed'
                              : 'Awaiting Payment to Complete',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
