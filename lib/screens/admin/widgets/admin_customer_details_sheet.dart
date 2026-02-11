import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/admin_customer_user.dart';
import '../../../providers/admin_booking_provider.dart';
import '../../../providers/admin_customers_provider.dart';
import '../../../providers/admin_customer_actions_provider.dart';

class AdminCustomerDetailsSheet extends ConsumerWidget {
  final AdminCustomerUser customer;

  const AdminCustomerDetailsSheet({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminBookingsByCustomerProvider(customer.id));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: (customer.profilePicture != null &&
                            customer.profilePicture!.isNotEmpty)
                        ? NetworkImage(customer.profilePicture!)
                        : null,
                    child: (customer.profilePicture != null &&
                            customer.profilePicture!.isNotEmpty)
                        ? null
                        : Text(
                            customer.fullName.isNotEmpty
                                ? customer.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _Section(
                title: 'Details',
                child: Column(
                  children: [
                    _Row(label: 'Phone', value: customer.phone ?? '—'),
                    _Row(label: 'Address', value: customer.address ?? '—'),
                    _Row(label: 'City', value: customer.city ?? '—'),
                    _Row(label: 'Status', value: customer.isSuspended ? 'Suspended' : (customer.isActive ? 'Active' : 'Inactive')),
                    _Row(label: 'Verified', value: customer.verified ? 'Yes' : 'No'),
                    if (customer.createdAt != null)
                      _Row(
                        label: 'Joined',
                        value: customer.createdAt!.toLocal().toString(),
                      ),
                    if (customer.lastBookingAt != null)
                      _Row(
                        label: 'Last booking',
                        value: customer.lastBookingAt!.toLocal().toString(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _Section(
                title: 'Recent bookings',
                child: bookingsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text(
                        'No bookings found for this customer.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      );
                    }
                    return Column(
                      children: items.take(5).map((b) {
                        final booking = b.booking;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            b.serviceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          subtitle: Text(
                            'Status: ${booking.status} • Tech: ${b.technicianName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/booking-detail/${booking.id}');
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    'Error loading bookings: $e',
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final actions = ref.read(adminCustomerActionsServiceProvider);
                        await actions.setSuspended(
                          customerId: customer.id,
                          suspended: !customer.isSuspended,
                        );
                        ref.invalidate(adminCustomersProvider);
                        ref.invalidate(adminCustomerByIdProvider(customer.id));

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                customer.isSuspended
                                    ? 'Customer unsuspended'
                                    : 'Customer suspended',
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        customer.isSuspended
                            ? Icons.lock_open
                            : Icons.block,
                      ),
                      label: Text(customer.isSuspended ? 'Unsuspend' : 'Suspend'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            customer.isSuspended ? Colors.green : Colors.red,
                        side: BorderSide(
                          color: customer.isSuspended ? Colors.green : Colors.red,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/admin-customer/${customer.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Full details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
