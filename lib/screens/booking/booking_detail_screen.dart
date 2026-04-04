import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/job_status_tracker.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_provider.dart';
import '../../models/booking_model.dart';
import '../../models/redeemed_voucher.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/booking_notes_parser.dart';
import '../../services/notification_service.dart';
import '../../services/payment_service.dart';
import '../technician/widgets/customer_location_sheet.dart';
class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  bool get _isCancellable => [
        AppConstants.bookingRequested,
        AppConstants.bookingAccepted,
        AppConstants.bookingEnRoute,
        AppConstants.bookingArrived,
        AppConstants.bookingInProgress,
      ].contains(booking.status);
  bool get _cancellationHasFee => [
        AppConstants.bookingAccepted,
        AppConstants.bookingEnRoute,
        AppConstants.bookingArrived,
        AppConstants.bookingInProgress,
      ].contains(booking.status);
  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final isInProgress = booking.status == AppConstants.bookingInProgress;
    final isArrived = booking.status == AppConstants.bookingArrived;
    final distanceFee = booking.parsedDistanceFee ?? 0.0;
    const convenenceFee = 100.0;
    final arrivedFee = (isArrived || isInProgress) ? convenenceFee : 0.0;
    final totalFee = distanceFee + arrivedFee;
    final hasFee = _cancellationHasFee && totalFee > 0;
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
                if (hasFee) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cancellation Fee Applies',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isInProgress
                                    ? 'The technician is already working on your device.'
                                    : isArrived
                                        ? 'The technician has arrived at your location.'
                                        : booking.status == AppConstants.bookingEnRoute
                                            ? 'The technician is on the way to you.'
                                            : 'The technician has already accepted your booking.',
                                style: TextStyle(fontSize: 12, color: Colors.red.shade700, height: 1.4),
                              ),
                              const SizedBox(height: 6),
                              if (distanceFee > 0)
                                Text(
                                  '• ₱${distanceFee.toStringAsFixed(2)} — Distance/travel fee',
                                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                                ),
                              if (arrivedFee > 0)
                                Text(
                                  '• ₱${arrivedFee.toStringAsFixed(2)} — Technician convenience fee',
                                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Total cancellation fee: ₱${totalFee.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
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
              child: Text(hasFee ? 'Cancel & Pay ₱${distanceFee.toStringAsFixed(2)}' : 'Cancel Booking'),
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
      final newStatus = hasFee
          ? AppConstants.bookingCancellationPending
          : AppConstants.bookingCancelled;
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: newStatus,
        cancellationReason: reason,
        cancellationFee: hasFee ? totalFee : null,
      );
      final techMessage = hasFee
          ? 'A customer has initiated a cancellation. A cancellation fee of ₱${totalFee.toStringAsFixed(2)} is pending admin confirmation. Reason: $reason'
          : 'A customer has cancelled their booking. Reason: $reason';
      await NotificationService().sendNotification(
        userId: booking.technicianId,
        type: 'booking_cancelled',
        title: hasFee ? 'Cancellation Pending' : 'Booking Cancelled',
        message: techMessage,
        data: {'booking_id': booking.id, 'route': '/tech-jobs'},
      );
      ref.invalidate(bookingByIdProvider(booking.id));
      ref.invalidate(customerBookingsProvider);
      if (!context.mounted) return;
      if (hasFee) {
        context.pushReplacement(
          '/payment/${booking.id}?amount=${totalFee.toStringAsFixed(2)}&type=cancellation_fee',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully.'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
      );
    }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techUserAsync = booking.technicianId.isNotEmpty
        ? ref.watch(userByIdProvider(booking.technicianId))
        : const AsyncData(null);
    final techPhone = techUserAsync.value?.contactNumber;
    Color statusColor;
    String statusLabel;
    switch (booking.status.toLowerCase()) {
      case 'requested':
        statusColor = Colors.orange;
        statusLabel = 'Requested';
        break;
      case 'accepted':
        statusColor = AppTheme.lightBlue;
        statusLabel = 'Accepted';
        break;
      case 'en_route':
        statusColor = const Color(0xFF0EA5E9);
        statusLabel = 'En Route';
        break;
      case 'arrived':
        statusColor = const Color(0xFF8B5CF6);
        statusLabel = 'Arrived';
        break;
      case 'in_progress':
        statusColor = AppTheme.lightBlue;
        statusLabel = 'In Progress';
        break;
      case 'completed':
        statusColor = Colors.orange;
        statusLabel = 'Awaiting Payment';
        break;
      case 'paid':
      case 'closed':
        statusColor = const Color(0xFF059669);
        statusLabel = 'Completed';
        break;
      case 'cancellation_pending':
        statusColor = Colors.orange;
        statusLabel = 'Cancellation Pending';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusLabel = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = booking.status.replaceAll('_', ' ').toUpperCase();
    }
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final bookingDate = booking.scheduledDate != null
        ? dateFormat.format(booking.scheduledDate!)
        : 'Not scheduled';
    final bookingTime = booking.scheduledDate != null
        ? timeFormat.format(booking.scheduledDate!)
        : 'Not scheduled';
    final parsedNotes = parseBookingNotes(booking.diagnosticNotes);
    final deviceType = parsedNotes.device;
    final deviceModel = parsedNotes.model;
    final deviceProblem = parsedNotes.problem;
    final deviceDetails = parsedNotes.details;
    final location = booking.customerAddress ?? 'No address provided';
    final estimatedCost = booking.estimatedCost ?? 0.0;
    final finalCost = booking.finalCost ?? estimatedCost;
    final techNotes = booking.technicianNotes;
    final adjRegex = RegExp(r'Price (increased|decreased) by ₱([\d.]+)(?:\s*—\s*Reason:\s*(.*))?');
    final skipLineRegex = RegExp(r'^(Service Fee:|Parts Used:|• .+ — [^\d]*[\d.]+$)');
    final techAdjustments = <(bool, double, String?)>[];
    final techGeneralLines = <String>[];
    if (techNotes != null) {
      for (final line in techNotes.split('\n')) {
        final trimmed = line.trim();
        final m = adjRegex.firstMatch(trimmed);
        if (m != null) {
          final isIncrease = m.group(1) == 'increased';
          final amt = double.tryParse(m.group(2)!) ?? 0.0;
          final reason = m.group(3)?.trim();
          if (amt > 0) techAdjustments.add((isIncrease, amt, reason));
        } else if (trimmed.isNotEmpty && !skipLineRegex.hasMatch(trimmed)) {
          techGeneralLines.add(trimmed);
        }
      }
    }
    final hasTechNotes = techGeneralLines.isNotEmpty;
    final techServiceFeeSet = techNotes != null &&
        RegExp(r'Service Fee:[^\d]*([\d.]+)').hasMatch(techNotes);
    final hasBreakdown = techServiceFeeSet ||
        booking.parsedServiceFee != null ||
        booking.parsedDistanceFee != null ||
        booking.partsList.isNotEmpty ||
        techAdjustments.isNotEmpty;
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
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _cancellationHasFee ? 'Cancel (Fee Applies)' : 'Cancel Booking',
                        style: const TextStyle(color: Colors.red),
                      ),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            _TechnicianSection(technicianId: booking.technicianId),
            const SizedBox(height: 16),
            if (hasTechNotes) ...[
              _SectionCard(
                title: 'Technician Notes',
                children: [
                  _InfoRow(
                    icon: Icons.engineering_rounded,
                    label: 'Assessment',
                    value: techGeneralLines.join('\n'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (techAdjustments.isNotEmpty) ...[
              _SectionCard(
                title: 'Price Adjustments',
                children: [
                  for (int i = 0; i < techAdjustments.length; i++) ...[
                    if (i > 0) ...[
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: techAdjustments[i].$1
                                ? Colors.orange.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            techAdjustments[i].$1
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: techAdjustments[i].$1
                                ? Colors.orange.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    techAdjustments[i].$1
                                        ? 'Price Increased'
                                        : 'Price Decreased',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: techAdjustments[i].$1
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${techAdjustments[i].$1 ? '+' : '-'}₱${techAdjustments[i].$2.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: techAdjustments[i].$1
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (techAdjustments[i].$3 != null &&
                                  techAdjustments[i].$3!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Note: ${techAdjustments[i].$3}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],
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
                if (hasBreakdown) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 16),
                  _CompletedPaymentBreakdown(
                    booking: booking,
                    finalCost: finalCost,
                    estimatedCost: estimatedCost,
                    isCompleted: booking.status == 'completed' ||
                        booking.status == 'paid' ||
                        booking.status == 'closed',
                  ),
                ] else if (estimatedCost > 0) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calculate_outlined,
                    label: 'Estimated Amount',
                    value: '₱${estimatedCost.toStringAsFixed(2)}',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if ([
              AppConstants.bookingAccepted,
              AppConstants.bookingEnRoute,
              AppConstants.bookingArrived,
              AppConstants.bookingInProgress,
            ].contains(booking.status)) ...[
              _SectionCard(
                title: 'Job Progress',
                children: [JobStatusTracker(currentStatus: booking.status)],
              ),
              const SizedBox(height: 16),
            ],
            if (booking.status != AppConstants.bookingCancelled &&
                booking.status != AppConstants.bookingCancellationPending &&
                booking.status != AppConstants.bookingCompleted &&
                booking.status != AppConstants.bookingPaid &&
                booking.status != AppConstants.bookingClosed)
              _CancellationPolicyCard(booking: booking),
            if ((booking.status == AppConstants.bookingCancellationPending ||
                    booking.status == AppConstants.bookingCancelled) &&
                (booking.parsedDistanceFee ?? 0) > 0)
              _CancellationFeeSection(booking: booking),
            const SizedBox(height: 24),
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
            if (_isCancellable)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, ref),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: Text(
                    _cancellationHasFee ? 'Cancel Booking (Fee Applies)' : 'Cancel Booking',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _CancellationPolicyCard extends StatelessWidget {
  final BookingModel booking;
  const _CancellationPolicyCard({required this.booking});
  @override
  Widget build(BuildContext context) {
    final isRequested = booking.status == AppConstants.bookingRequested;
    final isPostAcceptance = [
      AppConstants.bookingAccepted,
      AppConstants.bookingEnRoute,
      AppConstants.bookingArrived,
      AppConstants.bookingInProgress,
    ].contains(booking.status);
    final distanceFee = booking.parsedDistanceFee;
    final feeText = distanceFee != null && distanceFee > 0
        ? '₱${distanceFee.toStringAsFixed(2)} distance fee'
        : 'Distance/travel fee applies';
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.policy_outlined, size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                const Text(
                  'Cancellation Policy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _PolicyRow(
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            title: 'While Requesting',
            subtitle: 'Cancel anytime for free — technician hasn\'t responded yet.',
            feeLabel: 'FREE',
            feeLabelColor: Colors.green,
            isActive: isRequested,
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _PolicyRow(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: 'After Technician Accepts',
            subtitle: 'The technician committed to the job. You are responsible for the $feeText.',
            feeLabel: distanceFee != null && distanceFee > 0
                ? '₱${distanceFee.toStringAsFixed(2)}'
                : 'Fee',
            feeLabelColor: Colors.orange.shade700,
            isActive: isPostAcceptance,
          ),
        ],
      ),
    );
  }
}
class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String feeLabel;
  final Color feeLabelColor;
  final bool isActive;
  const _PolicyRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.feeLabel,
    required this.feeLabelColor,
    required this.isActive,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      color: isActive ? iconColor.withValues(alpha: 0.05) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isActive ? iconColor : Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppTheme.textPrimaryColor : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? AppTheme.textSecondaryColor : Colors.grey.shade400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? feeLabelColor.withValues(alpha: 0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              feeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isActive ? feeLabelColor : Colors.grey.shade400,
              ),
            ),
          ),
        ],
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
    final ratingsAsync = ref.watch(technicianActualRatingsProvider(technicianId));
    final user = userAsync.value;
    final tech = techAsync.value;
    if (userAsync.isLoading) {
      return _SectionCard(
        title: 'Assigned Technician',
        children: const [Center(child: CircularProgressIndicator())],
      );
    }
    return _SectionCard(
      title: 'Assigned Technician',
      children: [
        _InfoRow(
          icon: Icons.person,
          label: 'Name',
          value: user?.fullName ?? 'Unknown Technician',
        ),
        const SizedBox(height: 12),
        if (user?.contactNumber != null && user!.contactNumber!.isNotEmpty) ...[
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Contact',
            value: user.contactNumber!,
          ),
          const SizedBox(height: 12),
        ],
        ratingsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
          data: (data) {
            final (avg, count) = data;
            return _InfoRow(
              icon: Icons.star_rounded,
              label: 'Rating',
              value: count > 0
                  ? '${avg.toStringAsFixed(1)} ⭐ ($count ${count == 1 ? 'review' : 'reviews'})'
                  : 'No reviews yet',
            );
          },
        ),
        if (tech != null) ...[
          if (tech.specialties.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.build_rounded,
              label: 'Specialties',
              value: tech.specialties.join(', '),
            ),
          ],
          if (tech.yearsExperience > 0) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.workspace_premium_rounded,
              label: 'Experience',
              value: '${tech.yearsExperience} ${tech.yearsExperience == 1 ? 'year' : 'years'}',
            ),
          ],
          if (tech.shopName != null && tech.shopName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.storefront_rounded,
              label: 'Shop',
              value: tech.shopName!,
            ),
          ],
          if (tech.certifications.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.verified_rounded,
              label: 'Certifications',
              value: tech.certifications.join(', '),
            ),
          ],
        ],
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
  final Widget? trailing;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
                style: const TextStyle(
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
class _CompletedPaymentBreakdown extends StatefulWidget {
  final BookingModel booking;
  final double finalCost;
  final double estimatedCost;
  final bool isCompleted;
  const _CompletedPaymentBreakdown({
    required this.booking,
    required this.finalCost,
    required this.estimatedCost,
    this.isCompleted = false,
  });
  @override
  State<_CompletedPaymentBreakdown> createState() => _CompletedPaymentBreakdownState();
}
class _CompletedPaymentBreakdownState extends State<_CompletedPaymentBreakdown> {
  RedeemedVoucher? _voucher;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _loadVoucher();
  }
  Future<void> _loadVoucher() async {
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
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final booking = widget.booking;
    final voucher = _voucher;
    double preVoucherTotal;
    double voucherDiscount = 0;
    if (voucher != null) {
      if (voucher.discountType == 'percentage') {
        final rate = voucher.discountAmount / 100;
        preVoucherTotal = rate >= 1 ? widget.finalCost : widget.finalCost / (1 - rate);
        voucherDiscount = preVoucherTotal - widget.finalCost;
      } else {
        voucherDiscount = voucher.discountAmount;
        preVoucherTotal = widget.finalCost + voucherDiscount;
      }
    } else {
      preVoucherTotal = widget.finalCost;
    }
    final storedServiceFee = (() {
      final tn = booking.technicianNotes;
      if (tn != null) {
        final m = RegExp(r'Service Fee:[^\d]*([\d.]+)').firstMatch(tn);
        final v = m != null ? double.tryParse(m.group(1)!) : null;
        if (v != null && v > 0) return v;
      }
      return booking.parsedServiceFee;
    })();
    final storedDistanceFee = booking.parsedDistanceFee;
    final techAdditional = (preVoucherTotal - widget.estimatedCost).clamp(0.0, double.infinity);
    final parts = booking.partsList;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded, size: 15, color: AppTheme.deepBlue),
            const SizedBox(width: 6),
            const Text(
              'Expense Breakdown',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.deepBlue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BreakdownBlock(
          color: Colors.blue,
          icon: Icons.home_repair_service_rounded,
          label: 'Base Charges',
          child: Column(
            children: [
              if (storedDistanceFee != null)
                _BreakdownRow(
                  'Travel Fee${_distanceNote(booking)}',
                  storedDistanceFee,
                )
              else
                _BreakdownRow('Estimated Base Charge', widget.estimatedCost),
            ],
          ),
        ),
        if ((storedServiceFee != null && storedServiceFee > 0) ||
            adjustments.isNotEmpty ||
            parts.isNotEmpty ||
            techAdditional > 0) ...[
          const SizedBox(height: 10),
          _BreakdownBlock(
            color: Colors.orange,
            icon: Icons.engineering_rounded,
            label: 'Technician Additions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (storedServiceFee != null && storedServiceFee > 0)
                  _BreakdownRow('Service Fee', storedServiceFee, color: Colors.orange.shade800),
                for (final (isIncrease, amt, reason) in adjustments) ...[
                  _BreakdownRow(
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
                if (storedServiceFee == null && adjustments.isEmpty && techAdditional > 0)
                  _BreakdownRow('Service & Repair Charge', techAdditional, color: Colors.orange.shade800),
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
                            Expanded(
                              child: Text(p,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor)),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
        if (voucher != null) ...[
          const SizedBox(height: 10),
          _BreakdownBlock(
            color: Colors.green,
            icon: Icons.local_offer_rounded,
            label: 'Discount Applied',
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voucher.voucherTitle,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor)),
                      Text(
                        voucher.discountType == 'percentage'
                            ? '${voucher.discountAmount.toStringAsFixed(0)}% off'
                            : 'Fixed discount',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
                Text(
                  '- ₱${voucherDiscount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.isCompleted ? 'Total Paid' : 'Amount Due',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor)),
            Text(
              '₱${widget.finalCost.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.deepBlue),
            ),
          ],
        ),
      ],
    );
  }
  String _distanceNote(BookingModel b) {
    if (b.diagnosticNotes == null) return '';
    final m = RegExp(r'Distance: ([\d.]+)\s*km').firstMatch(b.diagnosticNotes!);
    return m != null ? ' (${m.group(1)} km)' : '';
  }
}
class _BreakdownBlock extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Widget child;
  const _BreakdownBlock({
    required this.color,
    required this.icon,
    required this.label,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;
  const _BreakdownRow(this.label, this.amount, {this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textPrimaryColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
      final (String notifType, String notifTitle, String notifMsg) = switch (newStatus) {
        'in_progress' => (
            'booking_accepted',
            'Booking Accepted',
            'Your booking has been accepted! The technician will start working soon.',
          ),
        'completed' => (
            'booking_completed',
            'Repair Completed',
            'Your repair has been completed. Please proceed with payment.',
          ),
        'cancelled' => (
            'booking_declined',
            'Booking Declined',
            'The technician was unable to accept your booking. Please try booking another technician.',
          ),
        _ => ('booking_update', 'Booking Updated', 'Your booking status has been updated.'),
      };
      await NotificationService().sendNotification(
        userId: booking.customerId,
        type: notifType,
        title: notifTitle,
        message: notifMsg,
        data: {'booking_id': booking.id, 'route': '/booking/${booking.id}'},
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
    final techNotes = booking.technicianNotes;
    final adjRegex = RegExp(r'Price (increased|decreased) by ₱([\d.]+)(?:\s*—\s*Reason:\s*(.*))?');
    final skipLineRegex = RegExp(r'^(Service Fee:|Parts Used:|• .+ — [^\d]*[\d.]+$)');
    final techAdjustments = <(bool, double, String?)>[];
    final techGeneralLines = <String>[];
    if (techNotes != null) {
      for (final line in techNotes.split('\n')) {
        final trimmed = line.trim();
        final m = adjRegex.firstMatch(trimmed);
        if (m != null) {
          final isIncrease = m.group(1) == 'increased';
          final amt = double.tryParse(m.group(2)!) ?? 0.0;
          final reason = m.group(3)?.trim();
          if (amt > 0) techAdjustments.add((isIncrease, amt, reason));
        } else if (trimmed.isNotEmpty && !skipLineRegex.hasMatch(trimmed)) {
          techGeneralLines.add(trimmed);
        }
      }
    }
    final hasTechNotes = techGeneralLines.isNotEmpty;
    final techServiceFeeSet = techNotes != null &&
        RegExp(r'Service Fee:[^\d]*([\d.]+)').hasMatch(techNotes);
    final hasBreakdown = techServiceFeeSet ||
        booking.parsedServiceFee != null ||
        booking.parsedDistanceFee != null ||
        booking.partsList.isNotEmpty ||
        techAdjustments.isNotEmpty;
    final String statusLabel;
    final Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'requested':
        statusLabel = 'Requested';
        statusColor = Colors.orange;
        break;
      case 'accepted':
      case 'scheduled':
        statusLabel = 'Accepted';
        statusColor = AppTheme.lightBlue;
        break;
      case 'en_route':
        statusLabel = 'En Route';
        statusColor = AppTheme.lightBlue;
        break;
      case 'arrived':
        statusLabel = 'Arrived';
        statusColor = AppTheme.accentPurple;
        break;
      case 'in_progress':
      case 'ongoing':
        statusLabel = 'In Progress';
        statusColor = AppTheme.accentPurple;
        break;
      case 'completed':
        statusLabel = 'Awaiting Payment';
        statusColor = Colors.amber.shade700;
        break;
      case 'paid':
        statusLabel = 'Payment Received';
        statusColor = Colors.teal;
        break;
      case 'closed':
        statusLabel = 'Completed';
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusLabel = 'Cancelled';
        statusColor = Colors.red;
        break;
      case 'cancellation_pending':
        statusLabel = 'Cancellation Pending';
        statusColor = Colors.orange.shade800;
        break;
      default:
        statusLabel = booking.status.replaceAll('_', ' ');
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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  if (hasTechNotes) ...[
                    _SectionCard(
                      title: 'Technician Notes',
                      children: [
                        _InfoRow(
                          icon: Icons.engineering_rounded,
                          label: 'Assessment',
                          value: techGeneralLines.join('\n'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (techAdjustments.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Price Adjustments',
                      children: [
                        for (int i = 0; i < techAdjustments.length; i++) ...[
                          if (i > 0) ...[
                            const SizedBox(height: 8),
                            Divider(color: Colors.grey.shade200, height: 1),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: techAdjustments[i].$1
                                      ? Colors.orange.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  techAdjustments[i].$1
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 14,
                                  color: techAdjustments[i].$1
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          techAdjustments[i].$1
                                              ? 'Price Increased'
                                              : 'Price Decreased',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: techAdjustments[i].$1
                                                ? Colors.orange.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                        Text(
                                          '${techAdjustments[i].$1 ? '+' : '-'}₱${techAdjustments[i].$2.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: techAdjustments[i].$1
                                                ? Colors.orange.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (techAdjustments[i].$3 != null &&
                                        techAdjustments[i].$3!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Note: ${techAdjustments[i].$3}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
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
                      if (hasBreakdown) ...[
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade200, height: 1),
                        const SizedBox(height: 16),
                        _CompletedPaymentBreakdown(
                          booking: booking,
                          finalCost: finalCost,
                          estimatedCost: estimatedCost,
                          isCompleted: booking.status == 'closed' ||
                              booking.status == 'paid',
                        ),
                      ] else if (estimatedCost > 0) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.calculate_outlined,
                          label: 'Estimated Amount',
                          value: '₱${estimatedCost.toStringAsFixed(2)}',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
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
class _CancellationFeeSection extends StatefulWidget {
  final BookingModel booking;
  const _CancellationFeeSection({required this.booking});
  @override
  State<_CancellationFeeSection> createState() =>
      _CancellationFeeSectionState();
}
class _CancellationFeeSectionState extends State<_CancellationFeeSection> {
  Map<String, dynamic>? _feePayment;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    final p = await PaymentService.getPaymentForBooking(
      widget.booking.id,
      paymentType: 'cancellation_fee',
    );
    if (!mounted) return;
    setState(() {
      _feePayment = p;
      _loading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    final fee = widget.booking.finalCost ?? 0.0;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final status = _feePayment?['status'] as String?;
    final (Color bg, Color border, Color textColor, IconData icon, String title, String subtitle) =
        switch (status) {
      'verified' => (
          Colors.green.shade50,
          Colors.green.shade200,
          Colors.green.shade700,
          Icons.check_circle,
          'Cancellation Fee Paid',
          'Your cancellation fee of ₱${fee.toStringAsFixed(2)} has been verified.',
        ),
      'pending_verification' => (
          Colors.orange.shade50,
          Colors.orange.shade200,
          Colors.orange.shade700,
          Icons.hourglass_top,
          'Fee Payment Pending Verification',
          'Your payment proof has been submitted. Awaiting admin confirmation.',
        ),
      _ => (
          Colors.red.shade50,
          Colors.red.shade200,
          Colors.red.shade700,
          Icons.warning_amber_rounded,
          'Cancellation Fee Due',
          'A cancellation fee of ₱${fee.toStringAsFixed(2)} applies to this booking.',
        ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: textColor, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (status == null || status == 'rejected') ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(
                '/payment/${widget.booking.id}'
                '?amount=${fee.toStringAsFixed(2)}&type=cancellation_fee',
              ),
              icon: const Icon(Icons.payment, size: 18),
              label: Text(
                status == 'rejected'
                    ? 'Resubmit Fee Payment'
                    : 'Pay Cancellation Fee  ₱${fee.toStringAsFixed(2)}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}