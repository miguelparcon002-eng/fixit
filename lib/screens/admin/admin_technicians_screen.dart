import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../models/admin_technician_list_item.dart';
import '../../providers/admin_technicians_provider.dart';
import 'widgets/admin_notifications_dialog.dart';
import 'widgets/admin_technician_details_sheet.dart';

enum _TechnicianSort { experience, createdAt, jobsDone }

enum _VerifiedFilter { all, verified, unverified }

class AdminTechniciansScreen extends ConsumerStatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  ConsumerState<AdminTechniciansScreen> createState() =>
      _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState
    extends ConsumerState<AdminTechniciansScreen> {
  _TechnicianSort _sort = _TechnicianSort.jobsDone;
  _VerifiedFilter _verifiedFilter = _VerifiedFilter.all;

  String get _verifiedFilterLabel {
    switch (_verifiedFilter) {
      case _VerifiedFilter.all:
        return 'All';
      case _VerifiedFilter.verified:
        return 'Verified';
      case _VerifiedFilter.unverified:
        return 'Unverified';
    }
  }

  String get _sortLabel {
    switch (_sort) {
      case _TechnicianSort.experience:
        return 'Experience';
      case _TechnicianSort.createdAt:
        return 'Account created';
      case _TechnicianSort.jobsDone:
        return 'Bookings done';
    }
  }

  int _compare(AdminTechnicianListItem a, AdminTechnicianListItem b) {
    // Keep suspended at the bottom.
    if (a.isSuspended != b.isSuspended) {
      return a.isSuspended ? 1 : -1;
    }

    int desc(num x, num y) => y.compareTo(x);

    switch (_sort) {
      case _TechnicianSort.experience:
        return desc(a.profile?.yearsExperience ?? 0, b.profile?.yearsExperience ?? 0);
      case _TechnicianSort.createdAt:
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      case _TechnicianSort.jobsDone:
        return desc(a.completedBookings, b.completedBookings);
    }
  }

  void _pickVerifiedFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SortOption(
                  label: 'All',
                  isSelected: _verifiedFilter == _VerifiedFilter.all,
                  onTap: () {
                    setState(() => _verifiedFilter = _VerifiedFilter.all);
                    Navigator.of(dialogContext).pop();
                  },
                ),
                const SizedBox(height: 8),
                _SortOption(
                  label: 'Verified',
                  isSelected: _verifiedFilter == _VerifiedFilter.verified,
                  onTap: () {
                    setState(() => _verifiedFilter = _VerifiedFilter.verified);
                    Navigator.of(dialogContext).pop();
                  },
                ),
                const SizedBox(height: 8),
                _SortOption(
                  label: 'Unverified',
                  isSelected: _verifiedFilter == _VerifiedFilter.unverified,
                  onTap: () {
                    setState(() => _verifiedFilter = _VerifiedFilter.unverified);
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<AdminTechnicianListItem> _applyVerifiedFilter(List<AdminTechnicianListItem> items) {
    switch (_verifiedFilter) {
      case _VerifiedFilter.all:
        return items;
      case _VerifiedFilter.verified:
        return items.where((t) => t.verified).toList();
      case _VerifiedFilter.unverified:
        return items.where((t) => !t.verified).toList();
    }
  }

  void _pickSort(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SortOption(
                  label: 'Bookings done',
                  isSelected: _sort == _TechnicianSort.jobsDone,
                  onTap: () {
                    setState(() => _sort = _TechnicianSort.jobsDone);
                    Navigator.of(dialogContext).pop();
                  },
                ),
                const SizedBox(height: 8),
                _SortOption(
                  label: 'Experience',
                  isSelected: _sort == _TechnicianSort.experience,
                  onTap: () {
                    setState(() => _sort = _TechnicianSort.experience);
                    Navigator.of(dialogContext).pop();
                  },
                ),
                const SizedBox(height: 8),
                _SortOption(
                  label: 'Account created',
                  isSelected: _sort == _TechnicianSort.createdAt,
                  onTap: () {
                    setState(() => _sort = _TechnicianSort.createdAt);
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techsAsync = ref.watch(adminTechniciansProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin-home');
            }
          },
        ),
        title: Row(
          children: [
            const AppLogo(
              size: 28,
              showText: false,
              assetPath: 'assets/images/logo_square.png',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Technicians',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _pickVerifiedFilter(context),
            icon: const Icon(Icons.filter_list),
            label: Text(_verifiedFilterLabel),
          ),
          TextButton.icon(
            onPressed: () => _pickSort(context),
            icon: const Icon(Icons.sort),
            label: Text(_sortLabel),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminTechniciansProvider),
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AdminNotificationsDialog(),
              );
            },
          ),
        ],
      ),
      body: techsAsync.when(
        data: (items) {
          final filtered = _applyVerifiedFilter(items);
          final sorted = [...filtered]..sort(_compare);
          if (sorted.isEmpty) {
            return Center(
              child: Text(
                'No technicians found',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final t = sorted[index];
              return _TechnicianCard(
                technician: t,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (_) => AdminTechnicianDetailsSheet(technician: t),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading technicians: $e',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final AdminTechnicianListItem technician;
  final VoidCallback onTap;

  const _TechnicianCard({required this.technician, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = technician.profile;

    final specialties = profile?.specialties ?? const <String>[];
    final rating = profile?.rating ?? 0.0;
    final jobs = technician.completedBookings;
    final experienceYears = profile?.yearsExperience ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              technician.fullName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          if (technician.isSuspended)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.block, size: 16, color: Colors.red),
                                  SizedBox(width: 6),
                                  Text(
                                    'Suspended',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (technician.verified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppTheme.successColor
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: AppTheme.successColor,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        technician.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniStat(
                  icon: Icons.star,
                  value: rating.toStringAsFixed(1),
                  color: Colors.pink,
                ),
                _MiniStat(
                  icon: Icons.work,
                  value: '$jobs jobs',
                  color: AppTheme.lightBlue,
                ),
                _MiniStat(
                  icon: Icons.trending_up,
                  value: '${experienceYears}y exp',
                  color: AppTheme.accentPurple,
                ),
              ],
            ),
            if (specialties.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specialties.take(4).map((s) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            ],
            if ((technician.city ?? technician.address) != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      technician.city ?? technician.address ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
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
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.deepBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.deepBlue
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.deepBlue : Colors.black,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_box, color: AppTheme.deepBlue, size: 20)
            else
              Icon(
                Icons.check_box_outline_blank,
                color: Colors.grey.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
