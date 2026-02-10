import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Minimal Profile screen.
///
/// The original file was missing from the workspace but the router depends on it.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user?.profilePicture != null &&
                            user!.profilePicture!.isNotEmpty)
                        ? NetworkImage(user.profilePicture!)
                        : null,
                    child: (user?.profilePicture != null &&
                            user!.profilePicture!.isNotEmpty)
                        ? null
                        : const Icon(Icons.person),
                  ),
                  title: Text(user?.fullName ?? 'User'),
                  subtitle: Text(user?.email ?? ''),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit profile'),
                onTap: () => context.go('/edit-profile'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Addresses'),
                onTap: () => context.go('/addresses'),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => context.go('/settings'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
