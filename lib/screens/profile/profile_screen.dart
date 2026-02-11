import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/user_session_service.dart';
import '../../services/redeemed_voucher_service.dart';
import '../../models/booking_model.dart';
import '../../models/reward.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: userAsync.when(
        data: (user) => user == null
            ? const Center(child: Text('Not logged in'))
            : CustomScrollView(
                slivers: [
                  // Modern gradient header with profile info
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryCyan,
                            AppTheme.darkCyan,
                            AppTheme.deepBlue.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          child: profileAsync.when(
                            data: (profile) {
                              final hasImage =
                                  profile.profileImagePath != null &&
                                  profile.profileImagePath!.isNotEmpty;
                              return Column(
                                children: [
                                  // Profile Picture with edit button overlay
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Color(0xFFF0F0F0),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 24,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: -2,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppTheme.primaryCyan
                                                  .withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 62,
                                            backgroundColor: Colors.white,
                                            backgroundImage:
                                                (hasImage && !kIsWeb)
                                                ? FileImage(
                                                    File(
                                                      profile.profileImagePath!,
                                                    ),
                                                  )
                                                : null,
                                            child: hasImage
                                                ? (kIsWeb
                                                      ? ClipOval(
                                                          child: Image.network(
                                                            profile
                                                                .profileImagePath!,
                                                            fit: BoxFit.cover,
                                                            width: 124,
                                                            height: 124,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return Text(
                                                                    user.fullName
                                                                        .split(
                                                                          ' ',
                                                                        )
                                                                        .map(
                                                                          (n) =>
                                                                              n[0],
                                                                        )
                                                                        .take(2)
                                                                        .join()
                                                                        .toUpperCase(),
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          38,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800,
                                                                      color: AppTheme
                                                                          .primaryCyan,
                                                                      letterSpacing:
                                                                          1,
                                                                    ),
                                                                  );
                                                                },
                                                          ),
                                                        )
                                                      : null)
                                                : Text(
                                                    user.fullName
                                                        .split(' ')
                                                        .map((n) => n[0])
                                                        .take(2)
                                                        .join()
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 38,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          AppTheme.primaryCyan,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () =>
                                              context.go('/edit-profile'),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppTheme.primaryCyan,
                                                  AppTheme.darkCyan,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.primaryCyan
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.edit_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Name
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Email with icon
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.25),
                                          Colors.white.withValues(alpha: 0.15),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.email_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          user.email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Profile Completion Bar
                                  _ProfileCompletionBar(
                                    user: user,
                                    profile: profile,
                                  ),
                                ],
                              );
                            },
                            loading: () => Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      user.fullName
                                          .split(' ')
                                          .map((n) => n[0])
                                          .take(2)
                                          .join()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryCyan,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            error: (e, _) => Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      user.fullName
                                          .split(' ')
                                          .map((n) => n[0])
                                          .take(2)
                                          .join()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryCyan,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content section with rounded top
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Stats Cards
                            _QuickStatsSection(ref: ref),
                            const SizedBox(height: 28),
                            // Recent Activity Section
                            _RecentActivitySection(ref: ref),
                            const SizedBox(height: 32),
                            // Account section header with modern badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryCyan.withValues(alpha: 0.1),
                                    AppTheme.deepBlue.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.primaryCyan.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.primaryCyan,
                                          AppTheme.darkCyan,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryCyan
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.settings_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Account Settings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimaryColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Settings Options Grid
                            _ModernSettingCard(
                              icon: Icons.location_on_rounded,
                              iconColor: AppTheme.primaryCyan,
                              title: 'Addresses',
                              subtitle: 'Manage delivery locations',
                              onTap: () => context.push('/addresses'),
                            ),
                            const SizedBox(height: 14),
                            _ModernSettingCard(
                              icon: Icons.notifications_rounded,
                              iconColor: AppTheme.lightBlue,
                              title: 'Notifications',
                              subtitle: 'Alerts & preferences',
                              onTap: () => context.push('/notifications'),
                            ),
                            const SizedBox(height: 14),
                            _ModernSettingCard(
                              icon: Icons.security_rounded,
                              iconColor: AppTheme.darkCyan,
                              title: 'Privacy & Security',
                              subtitle: 'Account protection',
                              onTap: () => context.push('/privacy-security'),
                            ),
                            const SizedBox(height: 14),
                            _ModernSettingCard(
                              icon: Icons.help_center_rounded,
                              iconColor: AppTheme.primaryCyan,
                              title: 'Help & Support',
                              subtitle: 'Get assistance anytime',
                              onTap: () => context.push('/help-support'),
                            ),
                            const SizedBox(height: 32),
                            // Logout Button with theme colors
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.errorColor,
                                    Color(0xFFDC2626),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.errorColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Clear session data first
                                  await ref
                                      .read(userSessionServiceProvider)
                                      .onUserLogout();
                                  await ref.read(authServiceProvider).signOut();
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
                                },
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 22,
                                ),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ModernSettingCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernSettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ModernSettingCard> createState() => _ModernSettingCardState();
}

class _ModernSettingCardState extends State<_ModernSettingCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.iconColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.iconColor.withValues(alpha: 0.12),
                      widget.iconColor.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.iconColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.iconColor.withValues(alpha: 0.1),
                      widget.iconColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: widget.iconColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Completion Bar Widget
class _ProfileCompletionBar extends ConsumerWidget {
  final dynamic user;
  final dynamic profile;

  const _ProfileCompletionBar({required this.user, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int completedFields = 0;
    int totalFields = 5;

    // Check completed fields
    if (user.fullName.isNotEmpty) completedFields++;
    if (user.email.isNotEmpty) completedFields++;
    if (user.contactNumber != null && user.contactNumber!.isNotEmpty)
      completedFields++;
    if (profile.profileImagePath != null &&
        profile.profileImagePath!.isNotEmpty)
      completedFields++;
    // Check if user has at least one address (you may need to add this check based on your data)
    completedFields++; // Assuming address is optional for now

    final completionPercentage = (completedFields / totalFields * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _ProfileCompletionDetailSheet(
              user: user,
              profile: profile,
              completionPercentage: completionPercentage,
              ref: ref,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Completion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$completionPercentage%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: completionPercentage / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completionPercentage == 100
                        ? AppTheme.successColor
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                completionPercentage == 100
                    ? 'Profile complete! Claim your reward 🎉'
                    : 'Tap to see details & earn ₱100 voucher',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: completionPercentage == 100
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Completion Detail Sheet
class _ProfileCompletionDetailSheet extends StatelessWidget {
  final dynamic user;
  final dynamic profile;
  final int completionPercentage;
  final WidgetRef ref;

  const _ProfileCompletionDetailSheet({
    required this.user,
    required this.profile,
    required this.completionPercentage,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final hasFullName = user.fullName.isNotEmpty;
    final hasEmail = user.email.isNotEmpty;
    final hasPhone =
        user.contactNumber != null && user.contactNumber!.isNotEmpty;
    final hasProfileImage =
        profile.profileImagePath != null &&
        profile.profileImagePath!.isNotEmpty;
    final hasAddress = true; // Assuming complete for now

    final isComplete = completionPercentage == 100;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isComplete
                          ? [
                              AppTheme.successColor,
                              AppTheme.successColor.withValues(alpha: 0.8),
                            ]
                          : [AppTheme.primaryCyan, AppTheme.darkCyan],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.account_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Completion',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completionPercentage% Complete',
                        style: TextStyle(
                          fontSize: 14,
                          color: isComplete
                              ? AppTheme.successColor
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Completion items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _CompletionItem(
                  icon: Icons.person_rounded,
                  title: 'Full Name',
                  isComplete: hasFullName,
                  value: hasFullName ? user.fullName : null,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/edit-profile');
                  },
                ),
                const SizedBox(height: 12),
                _CompletionItem(
                  icon: Icons.email_rounded,
                  title: 'Email Address',
                  isComplete: hasEmail,
                  value: hasEmail ? user.email : null,
                ),
                const SizedBox(height: 12),
                _CompletionItem(
                  icon: Icons.phone_rounded,
                  title: 'Phone Number',
                  isComplete: hasPhone,
                  value: hasPhone ? user.contactNumber : null,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/edit-profile');
                  },
                ),
                const SizedBox(height: 12),
                _CompletionItem(
                  icon: Icons.camera_alt_rounded,
                  title: 'Profile Picture',
                  isComplete: hasProfileImage,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/edit-profile');
                  },
                ),
                const SizedBox(height: 12),
                _CompletionItem(
                  icon: Icons.location_on_rounded,
                  title: 'Address',
                  isComplete: hasAddress,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/addresses');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Reward section
          if (isComplete)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _RewardClaimCard(ref: ref, userId: user.id),
            ),
          if (!isComplete)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warningColor.withValues(alpha: 0.1),
                      AppTheme.warningColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppTheme.warningColor,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '₱100 OFF Voucher',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete your profile to claim!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Completion Item Widget
class _CompletionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isComplete;
  final String? value;
  final VoidCallback? onTap;

  const _CompletionItem({
    required this.icon,
    required this.title,
    required this.isComplete,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isComplete
                ? AppTheme.successColor.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isComplete
                  ? AppTheme.successColor.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppTheme.successColor.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isComplete ? AppTheme.successColor : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        value!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isComplete ? Icons.check_circle : Icons.circle_outlined,
                color: isComplete ? AppTheme.successColor : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reward Claim Card Widget
class _RewardClaimCard extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String userId;

  const _RewardClaimCard({required this.ref, required this.userId});

  @override
  ConsumerState<_RewardClaimCard> createState() => _RewardClaimCardState();
}

class _RewardClaimCardState extends ConsumerState<_RewardClaimCard> {
  bool _isClaiming = false;
  bool _hasClaimed = false;

  @override
  void initState() {
    super.initState();
    _checkIfClaimed();
  }

  Future<void> _checkIfClaimed() async {
    // Check if user has already claimed the profile completion voucher
    final voucherService = ref.read(redeemedVoucherServiceProvider);
    final vouchers = await voucherService.getUserRedeemedVouchers(
      widget.userId,
    );

    // Check if there's a voucher with the profile completion reward ID
    final hasClaimed = vouchers.any(
      (v) => v.voucherId == 'voucherpr',
    );

    if (mounted) {
      setState(() {
        _hasClaimed = hasClaimed;
      });
    }
  }

  Future<void> _claimReward() async {
    if (_hasClaimed || _isClaiming) return;

    setState(() {
      _isClaiming = true;
    });

    try {
      final voucherService = ref.read(redeemedVoucherServiceProvider);

      // Create the profile completion reward voucher
      final rewardVoucher = RewardVoucher(
        id: 'voucherpr',
        title: '₱100 OFF - Profile Complete',
        description:
            'Congratulations on completing your profile! Enjoy ₱100 off on any repair service.',
        pointsCost: 0, // Free reward
        discountAmount: 100,
        discountType: 'fixed',
      );

      await voucherService.redeemVoucher(
        userId: widget.userId,
        voucher: rewardVoucher,
        expiresAt: DateTime.now().add(
          const Duration(days: 365),
        ), // Valid for 1 year
      );

      // Refresh the rewards provider
      ref.invalidate(rewardPointsProvider);
      ref.invalidate(redeemedVouchersProvider);

      if (mounted) {
        setState(() {
          _hasClaimed = true;
          _isClaiming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Congratulations! ₱100 voucher added to your rewards',
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );

        // Close the bottom sheet after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error claiming reward: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasClaimed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.successColor.withValues(alpha: 0.1),
              AppTheme.successColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successColor,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reward Claimed!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your ₱100 voucher is in your rewards',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.successColor, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isClaiming ? null : _claimReward,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '₱100 OFF Voucher',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isClaiming
                            ? 'Claiming...'
                            : 'Tap to claim your reward',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isClaiming)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to show Reward Points modal
void _showRewardPointsModal(BuildContext context, int points, int completedBookings) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RewardPointsModal(
      points: points,
      completedBookings: completedBookings,
    ),
  );
}

// Helper function to show Member Level modal
void _showMemberLevelModal(BuildContext context, String currentLevel, int completedBookings) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MemberLevelModal(
      currentLevel: currentLevel,
      completedBookings: completedBookings,
    ),
  );
}

// Reward Points Modal Widget
class _RewardPointsModal extends StatelessWidget {
  final int points;
  final int completedBookings;

  const _RewardPointsModal({
    required this.points,
    required this.completedBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.warningColor, Color(0xFFFFB020)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Reward Points System',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Points Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warningColor.withValues(alpha: 0.15),
                      AppTheme.warningColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.warningColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Points',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // How to Earn Points
              const Text(
                'How to Earn Points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              _PointsInfoCard(
                icon: Icons.check_circle_rounded,
                iconColor: AppTheme.successColor,
                title: 'Complete Repairs',
                description: 'Earn 1 point for every ₱50 spent',
                example: 'Example: ₱500 repair = 10 points',
              ),
              const SizedBox(height: 12),
              _PointsInfoCard(
                icon: Icons.account_circle_rounded,
                iconColor: AppTheme.primaryCyan,
                title: 'Complete Profile',
                description: 'Get ₱100 OFF voucher (one-time)',
                example: 'Fill all profile details to claim',
              ),
              const SizedBox(height: 24),

              // How to Use Points
              const Text(
                'How to Use Points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              _PointsInfoCard(
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFFE91E63),
                title: 'Redeem Vouchers',
                description: 'Exchange points for discount vouchers',
                example: '100 pts = ₱100 OFF voucher',
              ),
              const SizedBox(height: 12),
              _PointsInfoCard(
                icon: Icons.discount_rounded,
                iconColor: const Color(0xFF9C27B0),
                title: 'Apply to Bookings',
                description: 'Use vouchers on any repair service',
                example: 'Instant discount at checkout',
              ),
              const SizedBox(height: 24),

              // Your Progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.lightBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'ve completed $completedBookings repairs and earned $points points!',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Member Level Modal Widget
class _MemberLevelModal extends StatelessWidget {
  final String currentLevel;
  final int completedBookings;

  const _MemberLevelModal({
    required this.currentLevel,
    required this.completedBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFB020)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Member Levels',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current Level Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getLevelGradient(currentLevel),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Current Level',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentLevel,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Progress to Next Level
              if (currentLevel != 'Gold') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress to Next Level',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            '$completedBookings / ${_getNextLevelRequirement(currentLevel)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: completedBookings / _getNextLevelRequirement(currentLevel),
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_getNextLevelRequirement(currentLevel) - completedBookings} more repairs to ${_getNextLevel(currentLevel)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // All Member Levels
              const Text(
                'All Member Levels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              _LevelCard(
                level: 'Bronze',
                color: const Color(0xFFCD7F32),
                requirement: '0-9 completed repairs',
                benefits: [
                  'Earn 1 point per ₱50 spent',
                  'Access to standard vouchers',
                  'Email support',
                ],
                isCurrentLevel: currentLevel == 'Bronze',
              ),
              const SizedBox(height: 12),
              _LevelCard(
                level: 'Silver',
                color: const Color(0xFFC0C0C0),
                requirement: '10-19 completed repairs',
                benefits: [
                  'All Bronze benefits',
                  'Priority support',
                  'Exclusive Silver vouchers',
                  '5% bonus points on repairs',
                ],
                isCurrentLevel: currentLevel == 'Silver',
              ),
              const SizedBox(height: 12),
              _LevelCard(
                level: 'Gold',
                color: const Color(0xFFFFD700),
                requirement: '20+ completed repairs',
                benefits: [
                  'All Silver benefits',
                  '24/7 VIP support',
                  'Premium Gold vouchers',
                  '10% bonus points on repairs',
                  'Free diagnostics',
                ],
                isCurrentLevel: currentLevel == 'Gold',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getLevelGradient(String level) {
    switch (level) {
      case 'Gold':
        return [const Color(0xFFFFD700), const Color(0xFFFFB020)];
      case 'Silver':
        return [const Color(0xFFC0C0C0), const Color(0xFFA8A8A8)];
      default:
        return [const Color(0xFFCD7F32), const Color(0xFFB8681F)];
    }
  }

  int _getNextLevelRequirement(String level) {
    switch (level) {
      case 'Bronze':
        return 10;
      case 'Silver':
        return 20;
      default:
        return 20;
    }
  }

  String _getNextLevel(String level) {
    switch (level) {
      case 'Bronze':
        return 'Silver';
      case 'Silver':
        return 'Gold';
      default:
        return 'Gold';
    }
  }
}

// Points Info Card Widget
class _PointsInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String example;

  const _PointsInfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    example,
                    style: TextStyle(
                      fontSize: 11,
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Level Card Widget
class _LevelCard extends StatelessWidget {
  final String level;
  final Color color;
  final String requirement;
  final List<String> benefits;
  final bool isCurrentLevel;

  const _LevelCard({
    required this.level,
    required this.color,
    required this.requirement,
    required this.benefits,
    required this.isCurrentLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentLevel ? color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isCurrentLevel ? 0.5 : 0.2),
          width: isCurrentLevel ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                level,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (isCurrentLevel) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requirement,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...benefits.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// Quick Stats Section Widget
class _QuickStatsSection extends ConsumerWidget {
  final WidgetRef ref;

  const _QuickStatsSection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);
    final rewardPointsAsync = ref.watch(rewardPointsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        bookingsAsync.when(
          data: (bookings) {
            final completedBookings = bookings
                .where((b) => b.status == 'completed')
                .length;
            final activeBookings = bookings
                .where(
                  (b) =>
                      b.status == 'pending' ||
                      b.status == 'confirmed' ||
                      b.status == 'in_progress',
                )
                .length;

            // Calculate member level based on completed bookings
            String memberLevel = 'Bronze';
            Color levelColor = const Color(0xFFCD7F32);

            if (completedBookings >= 20) {
              memberLevel = 'Gold';
              levelColor = const Color(0xFFFFD700);
            } else if (completedBookings >= 10) {
              memberLevel = 'Silver';
              levelColor = const Color(0xFFC0C0C0);
            }

            return rewardPointsAsync.when(
              data: (points) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    icon: Icons.build_circle_rounded,
                    iconColor: AppTheme.lightBlue,
                    title: 'Total Repairs',
                    value: '$completedBookings',
                    gradient: [
                      AppTheme.lightBlue.withValues(alpha: 0.1),
                      AppTheme.lightBlue.withValues(alpha: 0.05),
                    ],
                  ),
                  _StatCard(
                    icon: Icons.stars_rounded,
                    iconColor: AppTheme.warningColor,
                    title: 'Reward Points',
                    value: '$points',
                    gradient: [
                      AppTheme.warningColor.withValues(alpha: 0.1),
                      AppTheme.warningColor.withValues(alpha: 0.05),
                    ],
                    onTap: () => _showRewardPointsModal(context, points, completedBookings),
                  ),
                  _StatCard(
                    icon: Icons.pending_actions_rounded,
                    iconColor: AppTheme.primaryCyan,
                    title: 'Active Bookings',
                    value: '$activeBookings',
                    gradient: [
                      AppTheme.primaryCyan.withValues(alpha: 0.1),
                      AppTheme.primaryCyan.withValues(alpha: 0.05),
                    ],
                  ),
                  _StatCard(
                    icon: Icons.military_tech_rounded,
                    iconColor: levelColor,
                    title: 'Member Level',
                    value: memberLevel,
                    gradient: [
                      levelColor.withValues(alpha: 0.1),
                      levelColor.withValues(alpha: 0.05),
                    ],
                    onTap: () => _showMemberLevelModal(context, memberLevel, completedBookings),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
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

// Recent Activity Section Widget
class _RecentActivitySection extends ConsumerWidget {
  final WidgetRef ref;

  const _RecentActivitySection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
                letterSpacing: 0.3,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/bookings'),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryCyan,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppTheme.textSecondaryColor.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No bookings yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Book a repair service to get started',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort bookings by date and take the last 3
            final recentBookings = bookings.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final displayBookings = recentBookings.take(3).toList();

            return Column(
              children: displayBookings.map((booking) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentActivityCard(booking: booking),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Unable to load recent activity',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Recent Activity Card Widget
class _RecentActivityCard extends StatelessWidget {
  final BookingModel booking;

  const _RecentActivityCard({required this.booking});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'confirmed':
      case 'in_progress':
        return AppTheme.lightBlue;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'confirmed':
      case 'in_progress':
        return Icons.build_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.15),
                      statusColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(booking.status),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(booking.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
