import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import 'widgets/admin_notifications_dialog.dart';

class AdminTechniciansScreen extends ConsumerWidget {
  const AdminTechniciansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
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
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search technicians…',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune),
                  label: const Text('Filters'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    foregroundColor: AppTheme.textPrimaryColor,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Adding new technician…')),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add technician'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: const [
                _TechnicianCard(
                  name: 'Shen Sarsale',
                  techId: 'TECH001',
                  status: 'active',
                  statusColor: Colors.green,
                  rating: '4.9',
                  jobs: '234',
                  experience: '3 years',
                  phone: '09723724672',
                  location: 'Barangay 7, SFADS',
                  specialties: ['Iphone', 'Samsung', 'Screen Repair'],
                  currentJob: '#FX156 - Hernan Miguel Parcon\nIphone 14 Pro',
                ),
                SizedBox(height: 12),
                _TechnicianCard(
                  name: 'Ethanjames Estino',
                  techId: 'TECH002',
                  status: 'active',
                  statusColor: Colors.green,
                  rating: '4.6',
                  jobs: '184',
                  experience: '2 years',
                  phone: '09723724672',
                  location: 'Barangay 2, SFADS',
                  specialties: ['Macbook', 'Laptop Repair', 'Battery'],
                  currentJob: '#FX189 - Emily Davis\nMacbook Air M2',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final String name;
  final String techId;
  final String status;
  final Color statusColor;
  final String rating;
  final String jobs;
  final String experience;
  final String phone;
  final String location;
  final List<String> specialties;
  final String currentJob;

  const _TechnicianCard({
    required this.name,
    required this.techId,
    required this.status,
    required this.statusColor,
    required this.rating,
    required this.jobs,
    required this.experience,
    required this.phone,
    required this.location,
    required this.specialties,
    required this.currentJob,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .map((n) => n[0])
        .take(2)
        .join()
        .toUpperCase();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.deepBlue.withValues(alpha: 0.10),
                child: Text(
                  initials,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.deepBlue,
                  ),
                ),
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
                            name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.30),
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      techId,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            icon: Icons.star,
                            value: rating,
                            label: 'Rating',
                            color: Colors.amber,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: _StatColumn(
                            icon: Icons.work_outline,
                            value: jobs,
                            label: 'Jobs',
                            color: AppTheme.lightBlue,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: _StatColumn(
                            icon: Icons.timelapse,
                            value: experience,
                            label: 'Exp',
                            color: AppTheme.accentPurple,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialties.take(4).map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  specialty,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Assigning job to $name...')),
                  );
                },
                icon: const Icon(Icons.assignment_add, size: 18),
                label: const Text('Assign'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deepBlue,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) {
                  switch (value) {
                    case 'call':
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling $name...')),
                      );
                      break;
                    case 'message':
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Messaging $name...')),
                      );
                      break;
                    case 'details':
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening $name details...')),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'details', child: Text('View details')),
                  PopupMenuItem(value: 'call', child: Text('Call')),
                  PopupMenuItem(value: 'message', child: Text('Message')),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (currentJob.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightBlue.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.build_outlined,
                    size: 16,
                    color: AppTheme.lightBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentJob,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool dense;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconSize = dense ? 16.0 : 20.0;
    final valueStyle = dense
        ? theme.textTheme.bodyMedium
        : theme.textTheme.titleSmall;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: iconSize),
        SizedBox(height: dense ? 2 : 4),
        Text(
          value,
          style: valueStyle?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
