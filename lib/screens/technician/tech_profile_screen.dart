import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_stats_provider.dart';
import '../../services/user_session_service.dart';

// Uses currentUserProvider.user.profilePicture (users.profile_picture) for avatar

class TechProfileScreen extends ConsumerStatefulWidget {
  const TechProfileScreen({super.key});

  @override
  ConsumerState<TechProfileScreen> createState() => _TechProfileScreenState();
}

class _TechProfileScreenState extends ConsumerState<TechProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Reload stats when screen is opened
    Future.microtask(() {
      ref.read(technicianStatsProvider.notifier).reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(technicianStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => context.go('/tech-edit-profile'),
            icon: const Icon(Icons.edit_rounded, color: AppTheme.deepBlue),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              // Profile header card
              userAsync.when(
                data: (user) => _buildProfileHeader(
                  name: user?.fullName ?? 'Technician',
                  isVerified: user?.verified ?? false,
                  rating: statsAsync.value?.averageRating ?? 0.0,
                  jobsDone: statsAsync.value?.completedJobs ?? 0,
                  profileImageUrl: user?.profilePicture,
                ),
                loading: () => _buildProfileHeader(
                  name: 'Loading…',
                  isVerified: false,
                  rating: 0.0,
                  jobsDone: 0,
                  profileImageUrl: null,
                ),
                error: (_, _) => _buildProfileHeader(
                  name: 'Technician',
                  isVerified: false,
                  rating: 0.0,
                  jobsDone: 0,
                  profileImageUrl: null,
                ),
              ),
              const SizedBox(height: 24),

              // Stats cards - now using real data
              _StatsCards(stats: statsAsync.value),
              const SizedBox(height: 24),

              // Personal Information
              const _PersonalInfoCard(),
              const SizedBox(height: 20),

              // Specialties
              const _SpecialtiesCard(),
              const SizedBox(height: 20),

              // Settings & Support
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings & Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.settings,
                      iconColor: AppTheme.lightBlue,
                      label: 'Account Settings',
                      onTap: () => context.go('/tech-account-settings'),
                    ),
                    const SizedBox(height: 12),
                    _SettingsItem(
                      icon: Icons.notifications,
                      iconColor: Colors.orange,
                      label: 'Notifications',
                      onTap: () => context.go('/tech-notifications'),
                    ),
                    const SizedBox(height: 12),
                    _SettingsItem(
                      icon: Icons.help_outline,
                      iconColor: Colors.green,
                      label: 'Help & Support',
                      onTap: () => context.go('/tech-help-support'),
                    ),
                    const SizedBox(height: 12),
                    _SettingsItem(
                      icon: Icons.description,
                      iconColor: Colors.purple,
                      label: 'Terms & Policies',
                      onTap: () => context.go('/tech-terms-policies'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color(0xFFD32F2F)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await ref.read(userSessionServiceProvider).onUserLogout();
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required bool isVerified,
    required double rating,
    required int jobsDone,
    required String? profileImageUrl,
  }) {
    // Get initials from name
    final initials = name.split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepBlue,
            AppTheme.lightBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: AppTheme.primaryCyan,
              backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? null
                  : Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepBlue,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isVerified ? 'Certified Technician' : 'Pending Verification',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$jobsDone jobs',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  final TechnicianStats? stats;

  const _StatsCards({this.stats});

  @override
  Widget build(BuildContext context) {
    final experience = stats?.experience ?? 'New';
    final rating = stats?.averageRating ?? 0.0;
    final jobsDone = stats?.completedJobs ?? 0;

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up,
              iconColor: Colors.pink,
              label: 'Experience',
              value: experience,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.star,
              iconColor: Colors.green,
              label: 'Rating',
              value: rating.toStringAsFixed(1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.bookmark,
              iconColor: AppTheme.lightBlue,
              label: 'Jobs Done',
              value: '$jobsDone',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoCard extends ConsumerWidget {
  const _PersonalInfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: profileAsync.when(
        data: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => context.go('/tech-edit-profile'),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.lightBlue,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.email,
              iconColor: AppTheme.lightBlue,
              label: 'Email',
              value: profile.email,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.phone,
              iconColor: Colors.green,
              label: 'Phone',
              value: profile.phone,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on,
              iconColor: Colors.purple,
              label: 'Location',
              value: profile.location,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today,
              iconColor: Colors.orange,
              label: 'Member Since',
              value: profile.memberSince,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => context.go('/tech-edit-profile'),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.lightBlue,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.email,
              iconColor: AppTheme.lightBlue,
              label: 'Email',
              value: 'ethan.estino@fixit.com',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.phone,
              iconColor: Colors.green,
              label: 'Phone',
              value: '(415) 555-0234',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on,
              iconColor: Colors.purple,
              label: 'Location',
              value: 'San Francisco, Barangay 3',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today,
              iconColor: Colors.orange,
              label: 'Member Since',
              value: 'January 2022',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
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
      ],
    );
  }
}

// Available specialties for phone and laptop repair
const List<String> availableSpecialties = [
  'Screen Repair',
  'Battery Replacement',
  'Water Damage Repair',
  'iPhone Repair',
  'Android Repair',
  'Samsung Repair',
  'Laptop Repair',
  'MacBook Repair',
  'Charging Port Repair',
  'Camera Repair',
  'Speaker Repair',
  'Microphone Repair',
  'Software Issues',
  'Virus Removal',
  'Data Recovery',
  'Hardware Upgrade',
  'Keyboard Replacement',
  'Trackpad Repair',
  'SSD/HDD Upgrade',
  'RAM Upgrade',
  'Display Replacement',
  'Motherboard Repair',
  'Cooling System',
  'Power Button Repair',
  'Volume Button Repair',
];

class _SpecialtiesCard extends ConsumerWidget {
  const _SpecialtiesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: profileAsync.when(
        data: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Specialties',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showSpecialtiesDialog(context, ref, profile.specialties),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.lightBlue,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (profile.specialties.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No specialties selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.specialties
                    .map((specialty) => _SpecialtyChip(label: specialty, isSelected: true))
                    .toList(),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Specialties',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showSpecialtiesDialog(context, ref, []),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.lightBlue,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No specialties selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpecialtiesDialog(BuildContext context, WidgetRef ref, List<String> currentSpecialties) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _SpecialtiesDialog(
          initialSpecialties: currentSpecialties,
          onSave: (selectedSpecialties) {
            ref.read(profileProvider.notifier).updateSpecialties(selectedSpecialties);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Specialties updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }
}

class _SpecialtiesDialog extends StatefulWidget {
  final List<String> initialSpecialties;
  final Function(List<String>) onSave;

  const _SpecialtiesDialog({
    required this.initialSpecialties,
    required this.onSave,
  });

  @override
  State<_SpecialtiesDialog> createState() => _SpecialtiesDialogState();
}

class _SpecialtiesDialogState extends State<_SpecialtiesDialog> {
  late Set<String> _selectedSpecialties;

  @override
  void initState() {
    super.initState();
    _selectedSpecialties = Set.from(widget.initialSpecialties);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Your Specialties'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSpecialties.map((specialty) {
              final isSelected = _selectedSpecialties.contains(specialty);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSpecialties.remove(specialty);
                    } else {
                      _selectedSpecialties.add(specialty);
                    }
                  });
                },
                child: _SpecialtyChip(
                  label: specialty,
                  isSelected: isSelected,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedSpecialties.toList());
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.deepBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _SpecialtyChip({
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white
            : AppTheme.lightBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.lightBlue
              : AppTheme.lightBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? AppTheme.lightBlue : AppTheme.lightBlue,
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
