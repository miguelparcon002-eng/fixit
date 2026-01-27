import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_session_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      body: SafeArea(
        bottom: false,
        child: userAsync.when(
          data: (user) => user == null
              ? const Center(child: Text('Not logged in'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Cyan header section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryCyan,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Profile Picture & Info
                            profileAsync.when(
                              data: (profile) {
                                final hasImage = profile.profileImagePath != null &&
                                                profile.profileImagePath!.isNotEmpty;
                                return Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.white,
                                      backgroundImage: hasImage
                                          ? FileImage(File(profile.profileImagePath!))
                                          : null,
                                      child: hasImage
                                          ? null
                                          : Text(
                                              user.fullName.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryCyan,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => Column(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      user.fullName.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryCyan,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              error: (e, _) => Column(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      user.fullName.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryCyan,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // White content section
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              // Edit Profile Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.go('/edit-profile'),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.deepBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Account Settings
                              const Text(
                                'Account Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Settings Options
                              _SettingOption(
                                icon: Icons.location_on,
                                iconColor: AppTheme.errorColor,
                                title: 'Addresses',
                                onTap: () => context.push('/addresses'),
                              ),
                              const SizedBox(height: 12),
                              _SettingOption(
                                icon: Icons.credit_card,
                                iconColor: AppTheme.accentPurple,
                                title: 'Payment Methods',
                                onTap: () => context.push('/payment-method'),
                              ),
                              const SizedBox(height: 12),
                              _SettingOption(
                                icon: Icons.notifications,
                                iconColor: AppTheme.warningColor,
                                title: 'Notifications',
                                onTap: () => context.push('/notifications'),
                              ),
                              const SizedBox(height: 12),
                              _SettingOption(
                                icon: Icons.shield,
                                iconColor: AppTheme.successColor,
                                title: 'Privacy & Security',
                                onTap: () => context.push('/privacy-security'),
                              ),
                              const SizedBox(height: 12),
                              _SettingOption(
                                icon: Icons.settings,
                                iconColor: AppTheme.textSecondaryColor,
                                title: 'Settings',
                                onTap: () => context.push('/settings'),
                              ),
                              const SizedBox(height: 32),
                              // Logout Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    // Clear session data first
                                    await ref.read(userSessionServiceProvider).onUserLogout();
                                    await ref.read(authServiceProvider).signOut();
                                    if (context.mounted) {
                                      context.go('/login');
                                    }
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Logout'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _SettingOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
