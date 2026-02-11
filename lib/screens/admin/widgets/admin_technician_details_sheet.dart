import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/admin_technician_list_item.dart';
import '../../../providers/admin_booking_provider.dart';
import '../../../providers/admin_technicians_provider.dart';
import '../../../providers/admin_technician_actions_provider.dart';

class AdminTechnicianDetailsSheet extends ConsumerWidget {
  final AdminTechnicianListItem technician;

  const AdminTechnicianDetailsSheet({
    super.key,
    required this.technician,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync =
        ref.watch(adminBookingsByTechnicianProvider(technician.userId));

    final profile = technician.profile;
    final specialties = profile?.specialties ?? const <String>[];

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
                    backgroundImage: (technician.profilePicture != null &&
                            technician.profilePicture!.isNotEmpty)
                        ? NetworkImage(technician.profilePicture!)
                        : null,
                    child: (technician.profilePicture != null &&
                            technician.profilePicture!.isNotEmpty)
                        ? null
                        : const Icon(Icons.engineering),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          technician.email,
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
                title: 'Technician details',
                child: Column(
                  children: [
                    _Row(label: 'Phone', value: technician.phone ?? '—'),
                    _Row(label: 'City', value: technician.city ?? '—'),
                    _Row(label: 'Address', value: technician.address ?? '—'),
                    _Row(
                      label: 'Verified',
                      value: technician.verified ? 'Yes' : 'No',
                    ),
                    _Row(
                      label: 'Status',
                      value: technician.isSuspended ? 'Suspended' : 'Active',
                    ),
                    if (profile != null) ...[
                      _Row(
                        label: 'Rating',
                        value: profile.rating.toStringAsFixed(1),
                      ),
                      _Row(
                        label: 'Jobs',
                        value: '${profile.totalJobs}',
                      ),
                      _Row(
                        label: 'Experience',
                        value: '${profile.yearsExperience} years',
                      ),
                      if ((profile.shopName ?? '').isNotEmpty)
                        _Row(label: 'Shop', value: profile.shopName!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (specialties.isNotEmpty)
                _Section(
                  title: 'Specialties',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (specialties.isNotEmpty) const SizedBox(height: 12),

              _Section(
                title: 'Recent bookings',
                child: bookingsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text(
                        'No bookings found for this technician.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      );
                    }

                    return Column(
                      children: items.take(6).map((b) {
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
                            'Customer: ${b.customerName} • Status: ${booking.status}',
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
                        final actions =
                            ref.read(adminTechnicianActionsServiceProvider);
                        await actions.setSuspended(
                          technicianId: technician.userId,
                          suspended: !technician.isSuspended,
                        );
                        ref.invalidate(adminTechniciansProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                technician.isSuspended
                                    ? 'Technician unsuspended'
                                    : 'Technician suspended',
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        technician.isSuspended
                            ? Icons.lock_open
                            : Icons.block,
                      ),
                      label: Text(
                        technician.isSuspended ? 'Unsuspend' : 'Suspend',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            technician.isSuspended ? Colors.green : Colors.red,
                        side: BorderSide(
                          color: technician.isSuspended ? Colors.green : Colors.red,
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
                        context.go('/technician-profile/${technician.userId}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Open profile'),
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
