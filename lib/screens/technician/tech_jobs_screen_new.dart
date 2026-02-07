import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';

// Provider for the initial tab to show in jobs screen
// 0 = Request, 1 = Active, 2 = Complete, 3 = All
final techJobsInitialTabProvider = StateProvider<int>((ref) => 0);

class TechJobsScreenNew extends ConsumerStatefulWidget {
  const TechJobsScreenNew({super.key});

  @override
  ConsumerState<TechJobsScreenNew> createState() => _TechJobsScreenNewState();
}

class _TechJobsScreenNewState extends ConsumerState<TechJobsScreenNew> {
  int _selectedTab = 0; // 0 = Request, 1 = Active, 2 = Complete, 3 = All

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    // Watch the tab provider and update when it changes
    final providerTab = ref.watch(techJobsInitialTabProvider);
    if (providerTab != 0 && providerTab != _selectedTab) {
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedTab = providerTab;
          });
          // Reset the provider after switching
          ref.read(techJobsInitialTabProvider.notifier).state = 0;
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.deepBlue,
      body: Column(
        children: [
          // Profile Header - Same as tech_home and tech_earnings
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.deepBlue, AppTheme.lightBlue],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FixIT Technician',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        userAsync.when(
                          data: (user) => Text(
                            user?.fullName ?? 'Technician',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          loading: () => const Text(
                            'Loading...',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          error: (_, __) => const Text(
                            'Technician',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: const Text(
                              '0',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    userAsync.when(
                      data: (user) => Text(
                        user?.address ?? 'Location not set',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      loading: () => const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      error: (_, __) => const Text(
                        'Location not set',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              color: AppTheme.primaryCyan,
              child: Column(
                children: [
                  // Jobs Title Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Text(
                          'My Jobs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            label: 'Request',
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
                  // Jobs List
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildJobsList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    final bookingsAsync = ref.watch(technicianBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading jobs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (allBookings) => _buildJobsContent(allBookings),
    );
  }

  Widget _buildJobsContent(List<BookingModel> allBookings) {
    List<BookingModel> filteredBookings;
    String emptyMessage;
    IconData emptyIcon;

    switch (_selectedTab) {
      case 0: // Request tab - Show requested and accepted jobs
        filteredBookings = allBookings.where((b) =>
          b.status == 'requested' || b.status == 'accepted'
        ).toList();
        emptyMessage = 'No job requests';
        emptyIcon = Icons.inbox_outlined;
        break;
      case 1: // Active tab - Show in_progress jobs
        filteredBookings = allBookings.where((b) => b.status == 'in_progress').toList();
        emptyMessage = 'No active jobs';
        emptyIcon = Icons.work_outline;
        break;
      case 2: // Complete tab - Show completed jobs
        filteredBookings = allBookings.where((b) => b.status == 'completed').toList();
        emptyMessage = 'No completed jobs';
        emptyIcon = Icons.check_circle_outline;
        break;
      case 3: // All tab - Show all jobs
        filteredBookings = allBookings;
        emptyMessage = 'No jobs';
        emptyIcon = Icons.inbox_outlined;
        break;
      default:
        filteredBookings = [];
        emptyMessage = 'No jobs';
        emptyIcon = Icons.inbox_outlined;
    }

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredBookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _JobCard(booking: booking, selectedTab: _selectedTab);
      },
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
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  final BookingModel booking;
  final int selectedTab;

  const _JobCard({
    required this.booking,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingService = ref.read(bookingServiceProvider);

    Color statusColor;
    String statusText;
    switch (booking.status) {
      case 'requested':
        statusColor = const Color(0xFFFF9800);
        statusText = 'New Request';
        break;
      case 'accepted':
      case 'scheduled':
        statusColor = const Color(0xFF2196F3);
        statusText = 'Accepted';
        break;
      case 'in_progress':
        statusColor = const Color(0xFF9C27B0);
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusText = booking.status;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.build_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Job #${booking.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Job Details
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Scheduled',
            value: booking.scheduledDate != null
                ? DateFormat('MMM dd, yyyy - hh:mm a').format(booking.scheduledDate!)
                : 'Not scheduled',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.location_on,
            label: 'Location',
            value: booking.customerAddress ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.attach_money,
            label: 'Cost',
            value: '₱${booking.finalCost?.toStringAsFixed(2) ?? booking.estimatedCost?.toStringAsFixed(2) ?? '0.00'}',
          ),
          if (booking.diagnosticNotes != null && booking.diagnosticNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.diagnosticNotes!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Action Buttons
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildActionButtons(context, ref, bookingService),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BookingService bookingService) {
    // Request tab (0) - Show Accept/Decline for requested jobs only
    if (selectedTab == 0 && booking.status == 'requested') {
      return Row(
        children: [
          // Decline button with red X
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _declineJob(context, ref, bookingService),
                icon: const Icon(Icons.close, color: Colors.red, size: 28),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Accept button with green checkmark
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _acceptJob(context, ref, bookingService),
                icon: const Icon(Icons.check, color: Colors.green, size: 28),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      );
    }
    // Active tab (1) - Navigate, Call, Edit, Mark Complete buttons
    else if (selectedTab == 1) {
      return Row(
        children: [
          // Navigate button
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implement map navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigation feature coming soon')),
                );
              },
              icon: const Icon(Icons.navigation, color: Colors.purple, size: 24),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 8),
          // Call button
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implement call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Call feature coming soon')),
                );
              },
              icon: const Icon(Icons.phone, color: Colors.blue, size: 24),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 8),
          // Edit/Notes button
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _editBookingDetails(context, ref, bookingService),
              icon: const Icon(Icons.edit, color: Colors.orange, size: 24),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 8),
          // Mark Complete button
          Expanded(
            child: ElevatedButton(
              onPressed: () => _completeJob(context, ref, bookingService),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Mark Complete',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }
    // Complete tab (2) or All tab (3) - Show "Completed" status
    else if ((selectedTab == 2 || selectedTab == 3) && booking.status == 'completed') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Completed',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      );
    }
    // Default - no buttons
    else {
      return const SizedBox.shrink();
    }
  }

  Future<void> _acceptJob(BuildContext context, WidgetRef ref, BookingService bookingService) async {
    try {
      // Accept and start job immediately (set to in_progress)
      await bookingService.updateBookingStatus(
        bookingId: booking.id,
        status: 'in_progress',
      );

      // Force refresh the technician bookings to show updated status immediately
      ref.invalidate(technicianBookingsProvider);

      // Switch to Active tab (index 1)
      ref.read(techJobsInitialTabProvider.notifier).state = 1;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job accepted and started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineJob(BuildContext context, WidgetRef ref, BookingService bookingService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Job?'),
        content: const Text('Are you sure you want to decline this job request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await bookingService.updateBookingStatus(
          bookingId: booking.id,
          status: 'cancelled',
        );

        // Force refresh the technician bookings to remove cancelled job immediately
        ref.invalidate(technicianBookingsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job declined'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to decline job: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeJob(BuildContext context, WidgetRef ref, BookingService bookingService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job?'),
        content: const Text('Mark this job as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await bookingService.updateBookingStatus(
          bookingId: booking.id,
          status: 'completed',
        );

        // Force refresh the technician bookings to move job to Done tab immediately
        ref.invalidate(technicianBookingsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete job: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editBookingDetails(BuildContext context, WidgetRef ref, BookingService bookingService) async {
    // DEBUG: Print booking details
    print('🔍 EDIT DIALOG OPENED (tech_jobs_screen_new.dart):');
    print('  Booking ID: ${booking.id}');
    print('  Promo Code: ${booking.promoCode}');
    print('  Discount: ${booking.discountAmount}');
    print('  Original Price: ${booking.originalPrice}');
    print('  Final Cost: ${booking.finalCost}');
    print('  Customer Details: ${booking.moreDetails}');

    // Start with empty notes - technician adds NEW notes each time
    final notesController = TextEditingController(text: '');
    final priceController = TextEditingController();

    // Get current cost information
    final currentCost = booking.finalCost ?? booking.estimatedCost ?? 0.0;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Booking Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Found additional issues? Update the booking with extra charges and details.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              // Show customer's original notes if they exist
              if (booking.moreDetails != null && booking.moreDetails!.isNotEmpty) ...[
                const Text(
                  'Customer Notes',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.deepBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.moreDetails!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Current price info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Price:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    Text(
                      '₱${currentCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Technician Notes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe additional issues found\n(e.g., battery also needs replacement)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Price Adjustment (₱)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter amount (use - for discount)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use positive values to increase price, negative values to decrease (e.g., -100 for ₱100 discount)',
                        style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final notes = notesController.text;
              final priceText = priceController.text.trim();
              final priceAdjustment = priceText.isNotEmpty ? double.tryParse(priceText) : null;

              Navigator.pop(context, {
                'notes': notes,
                'priceAdjustment': priceAdjustment,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update Booking'),
          ),
        ],
      ),
    );

    if (result != null) {
      final notes = result['notes'] as String?;
      final priceAdjustment = result['priceAdjustment'] as double?;

      // Only update if there's something to update
      if ((notes != null && notes.isNotEmpty) || priceAdjustment != null) {
        try {
          print('💾 SAVING BOOKING UPDATE:');
          print('  Booking ID: ${booking.id}');
          print('  Technician Notes: $notes');
          print('  Price Adjustment: $priceAdjustment');

          // Use addTechnicianNotes to preserve customer details and maintain discount
          await bookingService.addTechnicianNotes(
            bookingId: booking.id,
            technicianNotes: notes ?? '',
            priceAdjustment: priceAdjustment,
          );

          print('✅ BOOKING SAVED SUCCESSFULLY');

          // Force refresh the technician bookings
          ref.invalidate(technicianBookingsProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking details updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print('❌ SAVE FAILED: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update booking: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.deepBlue),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
