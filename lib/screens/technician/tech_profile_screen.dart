import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_stats_provider.dart';
import '../../services/user_session_service.dart';
import '../../services/technician_service.dart';
import 'tech_jobs_screen_new.dart';

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
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimaryColor),
            onPressed: () => ref.read(profileProvider.notifier).reload(),
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

              // Bio / About Me
              const _BioCard(),
              const SizedBox(height: 20),

              // Specialties
              const _SpecialtiesCard(),
              const SizedBox(height: 20),

              // Availability Schedule
              const _ScheduleCard(),
              const SizedBox(height: 20),

              // Job Preferences
              const _JobPreferencesCard(),
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
                      onTap: () => context.go('/tech-notification-settings'),
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
                    onTap: () {
                      // Navigate away immediately so technician screens don't
                      // briefly render stream/provider errors during sign-out.
                      context.go('/login');

                      // Perform logout cleanup after navigation.
                      Future.microtask(() async {
                        await ref.read(userSessionServiceProvider).onUserLogout();
                        await ref.read(authServiceProvider).signOut();
                      });
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

class _StatsCards extends ConsumerWidget {
  final TechnicianStats? stats;

  const _StatsCards({this.stats});

  void _showExperienceDetails(BuildContext context) {
    final completedJobs = stats?.completedJobs ?? 0;
    final totalReviews = stats?.totalReviews ?? 0;
    final averageRating = stats?.averageRating ?? 0.0;
    final currentLevel = stats?.experience ?? 'New';

    const levels = <String, int>{
      'New': 0,
      'Beginner': 1,
      'Intermediate': 2,
      'Skilled': 3,
      'Expert': 4,
      'Master': 5,
    };

    // Thresholds must match TechnicianStats.calculateExperience
    const thresholds = <String, int>{
      'New': 0,
      'Beginner': 1,
      'Intermediate': 10,
      'Skilled': 25,
      'Expert': 50,
      'Master': 100,
    };

    final currentRank = levels[currentLevel] ?? 0;
    final nextLevel = levels.entries
        .firstWhere(
          (e) => e.value == currentRank + 1,
          orElse: () => const MapEntry('Master', 5),
        )
        .key;

    final nextThreshold = thresholds[nextLevel] ?? 100;
    final remainingJobs = (nextThreshold - completedJobs).clamp(0, 1000000);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Experience details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _ExperienceRow(label: 'Current level', value: currentLevel),
                _ExperienceRow(label: 'Completed jobs', value: '$completedJobs'),
                _ExperienceRow(label: 'Total reviews', value: '$totalReviews'),
                _ExperienceRow(
                  label: 'Average rating',
                  value: averageRating.toStringAsFixed(1),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  currentLevel == 'Master'
                      ? 'You’ve reached the highest level.'
                      : 'Next level: $nextLevel',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                if (currentLevel != 'Master')
                  Text(
                    remainingJobs == 0
                        ? 'You’re ready to level up!'
                        : 'Complete $remainingJobs more job(s) to reach $nextLevel.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'How to increase your experience',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const _ChecklistItem(
                  text: 'Finish more bookings (completed jobs are what level you up).',
                ),
                const _ChecklistItem(
                  text: 'Ask customers to leave a review after each job.',
                ),
                const _ChecklistItem(
                  text: 'Maintain a high rating by communicating clearly and arriving on time.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onTap: () => _showExperienceDetails(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.star,
              iconColor: Colors.green,
              label: 'Rating',
              value: rating.toStringAsFixed(1),
              onTap: () => context.go('/tech-ratings'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.bookmark,
              iconColor: AppTheme.lightBlue,
              label: 'Jobs Done',
              value: '$jobsDone',
              onTap: () {
                // Jump to Completed tab
                ref.read(techJobsInitialTabProvider.notifier).state = 2;
                context.go('/tech-jobs');
              },
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
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}

class _ExperienceRow extends StatelessWidget {
  final String label;
  final String value;

  const _ExperienceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;

  const _ChecklistItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 18, color: Colors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.3,
              ),
            ),
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
    final userAsync = ref.watch(currentUserProvider);
    final lat = userAsync.value?.latitude;
    final lng = userAsync.value?.longitude;

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
              value: profile.location.isNotEmpty ? profile.location : 'Not set',
            ),
            if (lat != null && lng != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showPinnedLocationMap(context, lat, lng),
                child: Container(
                  margin: const EdgeInsets.only(left: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pin_drop, size: 14, color: Colors.purple),
                      const SizedBox(width: 6),
                      Text(
                        'Pinned: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12, color: Colors.purple),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new, size: 12, color: Colors.purple),
                    ],
                  ),
                ),
              ),
            ],
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

  void _showPinnedLocationMap(BuildContext context, double lat, double lng) {
    final point = LatLng(lat, lng);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pinned Location',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fixit',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 48,
                          height: 48,
                          child: const Icon(Icons.location_pin, size: 48, color: Colors.purple),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

class _BioCard extends ConsumerWidget {
  const _BioCard();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'About Me',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: profileAsync.value == null
                    ? null
                    : () => _showBioDialog(context, ref, profileAsync.value!.bio ?? ''),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.lightBlue,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          profileAsync.when(
            data: (profile) => Text(
              (profile.bio != null && profile.bio!.isNotEmpty)
                  ? profile.bio!
                  : 'No description yet. Tap edit to add a short bio so customers know more about you.',
              style: TextStyle(
                fontSize: 14,
                color: (profile.bio != null && profile.bio!.isNotEmpty)
                    ? AppTheme.textPrimaryColor
                    : Colors.grey.shade500,
                height: 1.5,
                fontStyle: (profile.bio != null && profile.bio!.isNotEmpty)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
            loading: () => Text(
              'Loading…',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            error: (e, s) => Text(
              'No description yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBioDialog(BuildContext context, WidgetRef ref, String currentBio) {
    final controller = TextEditingController(text: currentBio);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Bio'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Tell customers about yourself, your experience, and what makes you great at repairs...',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(profileProvider.notifier).updateBio(controller.text.trim());
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bio updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update bio. Please run the SQL migration first.\n${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
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
      child: Column(
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
                onPressed: profileAsync.value == null
                    ? null
                    : () => _showSpecialtiesDialog(context, ref, profileAsync.value!.specialties),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.lightBlue.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.lightBlue,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          profileAsync.when(
            data: (profile) => profile.specialties.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No specialties selected',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.specialties
                        .map((s) => _SpecialtyChip(label: s, isSelected: true))
                        .toList(),
                  ),
            loading: () => Text(
              'Loading…',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            error: (e, s) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No specialties selected',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            ),
          ),
        ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Availability Schedule Card
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

class _ScheduleCard extends ConsumerStatefulWidget {
  const _ScheduleCard();

  @override
  ConsumerState<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends ConsumerState<_ScheduleCard> {
  final _service = TechnicianService();

  // Local mutable schedule state: day → {enabled, start, end}
  final Map<String, Map<String, dynamic>> _schedule = {
    for (final d in _kDays)
      d: {
        'enabled': false,
        'start': const TimeOfDay(hour: 9, minute: 0),
        'end': const TimeOfDay(hour: 18, minute: 0),
      },
  };

  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final profile = await _service.getProfileByUserId(user.id);
    if (!mounted) return;
    final saved = profile?.weeklySchedule;
    if (saved != null) {
      for (final day in _kDays) {
        final d = saved[day];
        if (d == null) continue;
        final startStr = (d['start'] as String?) ?? '09:00';
        final endStr   = (d['end']   as String?) ?? '18:00';
        _schedule[day] = {
          'enabled': d['enabled'] as bool? ?? false,
          'start': _parseTime(startStr),
          'end':   _parseTime(endStr),
        };
      }
    }
    setState(() => _loaded = true);
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _displayTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  bool get _isOnlineNow {
    final now = DateTime.now();
    final dayName = _kDays[now.weekday - 1];
    final d = _schedule[dayName]!;
    if (d['enabled'] != true) return false;
    final start = d['start'] as TimeOfDay;
    final end   = d['end']   as TimeOfDay;
    final nowMin   = now.hour * 60 + now.minute;
    final startMin = start.hour * 60 + start.minute;
    final endMin   = end.hour * 60 + end.minute;
    return nowMin >= startMin && nowMin < endMin;
  }

  Future<void> _pickTime(String day, bool isStart) async {
    final current = _schedule[day]![isStart ? 'start' : 'end'] as TimeOfDay;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    // Enforce start < end
    if (isStart) {
      final end = _schedule[day]!['end'] as TimeOfDay;
      final pickedMin = picked.hour * 60 + picked.minute;
      final endMin    = end.hour * 60 + end.minute;
      if (pickedMin >= endMin) return; // silently ignore invalid range
      setState(() => _schedule[day]!['start'] = picked);
    } else {
      final start = _schedule[day]!['start'] as TimeOfDay;
      final pickedMin = picked.hour * 60 + picked.minute;
      final startMin  = start.hour * 60 + start.minute;
      if (pickedMin <= startMin) return;
      setState(() => _schedule[day]!['end'] = picked);
    }
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final toSave = <String, Map<String, dynamic>>{
        for (final day in _kDays)
          day: {
            'enabled': _schedule[day]!['enabled'] as bool,
            'start': _fmtTime(_schedule[day]!['start'] as TimeOfDay),
            'end':   _fmtTime(_schedule[day]!['end']   as TimeOfDay),
          },
      };
      await _service.updateWeeklySchedule(user.id, toSave);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule saved!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineNow = _loaded ? _isOnlineNow : false;
    final anyEnabled = _schedule.values.any((d) => d['enabled'] == true);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.schedule_rounded, color: AppTheme.deepBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Availability Schedule',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                ),
              ),
              // Online/offline badge
              if (_loaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: onlineNow
                        ? AppTheme.successColor.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: onlineNow
                          ? AppTheme.successColor.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: onlineNow ? AppTheme.successColor : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        onlineNow ? 'Online Now' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: onlineNow ? AppTheme.successColor : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            anyEnabled
                ? 'Customers see you as available during your set hours'
                : 'Set working hours so customers know when you\'re available',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),

          if (!_loaded)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else ...[
            // Day rows
            ...List.generate(_kDays.length, (i) {
              final day = _kDays[i];
              final d = _schedule[day]!;
              final enabled = d['enabled'] as bool;
              final start   = d['start'] as TimeOfDay;
              final end     = d['end']   as TimeOfDay;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppTheme.deepBlue.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: enabled ? AppTheme.deepBlue.withValues(alpha: 0.25) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Toggle
                          GestureDetector(
                            onTap: _saving ? null : () => setState(() => d['enabled'] = !enabled),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42, height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: enabled ? AppTheme.deepBlue : Colors.grey.shade300,
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 18, height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Day name
                          Expanded(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: enabled ? FontWeight.w700 : FontWeight.w500,
                                color: enabled ? AppTheme.textPrimaryColor : Colors.grey.shade400,
                              ),
                            ),
                          ),
                          // Day-off label or time range
                          if (!enabled)
                            Text('Day off',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade400))
                          else
                            Row(
                              children: [
                                _TimeButton(
                                  label: _displayTime(start),
                                  onTap: _saving ? null : () => _pickTime(day, true),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text('–', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w700)),
                                ),
                                _TimeButton(
                                  label: _displayTime(end),
                                  onTap: _saving ? null : () => _pickTime(day, false),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _saving ? 'Saving…' : 'Save Schedule',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _TimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.deepBlue,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job Preferences Card
// ─────────────────────────────────────────────────────────────────────────────

class _JobPreferencesCard extends ConsumerStatefulWidget {
  const _JobPreferencesCard();

  @override
  ConsumerState<_JobPreferencesCard> createState() => _JobPreferencesCardState();
}

class _JobPreferencesCardState extends ConsumerState<_JobPreferencesCard> {
  final _service = TechnicianService();

  bool _acceptWhileBusy = false;
  bool _isBusy = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final profile = await _service.getProfileByUserId(user.id);
    if (!mounted) return;
    setState(() {
      _acceptWhileBusy = profile?.acceptRequestsWhileBusy ?? false;
      _isBusy = profile?.isBusy ?? false;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool value) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() { _saving = true; _acceptWhileBusy = value; });
    try {
      await _service.setAcceptRequestsWhileBusy(user.id, value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acceptWhileBusy = !value); // revert on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.engineering_rounded, color: Colors.orange.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Job Preferences',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                ),
              ),
              // Busy indicator badge
              if (_loaded && _isBusy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'On a Job',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_loaded)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else ...[
            // Toggle row
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _acceptWhileBusy
                    ? Colors.orange.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acceptWhileBusy
                      ? Colors.orange.shade300
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  // Custom toggle
                  GestureDetector(
                    onTap: _saving ? null : () => _toggle(!_acceptWhileBusy),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42, height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _acceptWhileBusy ? Colors.orange.shade600 : Colors.grey.shade300,
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _acceptWhileBusy ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 18, height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accept requests while working',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _acceptWhileBusy
                                ? Colors.orange.shade800
                                : AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _acceptWhileBusy
                              ? 'Customers can book you even when you\'re on a job'
                              : 'You won\'t appear in results while on an active job',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  if (_saving)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Info note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.deepBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.deepBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'When on a job, customers will see a "Busy" badge on your profile. '
                      'If this is off, you will be hidden from search results until your current job is done.',
                      style: TextStyle(fontSize: 11, color: AppTheme.deepBlue.withValues(alpha: 0.8), height: 1.4),
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
