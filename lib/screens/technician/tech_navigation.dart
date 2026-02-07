import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/verification_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/verification_pending_dialog.dart';

class TechNavigation extends ConsumerStatefulWidget {
  final Widget child;

  const TechNavigation({super.key, required this.child});

  @override
  ConsumerState<TechNavigation> createState() => _TechNavigationState();
}

class _TechNavigationState extends ConsumerState<TechNavigation> {
  bool _dialogShown = false;

  int _getIndexFromRoute(String location) {
    if (location.startsWith('/tech-home')) return 0;
    if (location.startsWith('/tech-jobs')) return 1;
    if (location.startsWith('/tech-earnings')) return 2;
    if (location.startsWith('/tech-profile')) return 3;
    return 0;
  }

  void _showVerificationDialog(UserModel user) {
    // Prevent showing multiple dialogs
    if (_dialogShown) return;
    _dialogShown = true;
    print('=== Showing Verification Dialog for ${user.email} ===');
    print('User verified: ${user.verified}');
    
    // Check for verification request
    final verificationRequestAsync = ref.read(userVerificationRequestProvider);
    
    verificationRequestAsync.when(
      data: (verificationRequest) {
        print('Verification request: ${verificationRequest?.status ?? "NO REQUEST"}');
        
        // If no verification request exists, show prompt to submit
        if (verificationRequest == null) {
          print('Showing VerificationNotSubmittedDialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const VerificationNotSubmittedDialog(),
          ).then((_) {
            print('Dialog closed by user');
            // Don't reset flag - keep it true so dialog doesn't show again
            // until user comes back from verification screen
          });
        } else if (verificationRequest.status == AppConstants.verificationPending) {
          print('Showing VerificationPendingDialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => VerificationPendingDialog(
              verificationRequest: verificationRequest,
            ),
          ).then((_) {
            _dialogShown = false;
            // Check again after a delay
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && !user.verified) {
                _showVerificationDialog(user);
              }
            });
          });
        } else if (verificationRequest.status == AppConstants.verificationRejected) {
          print('Showing VerificationRejectedDialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => VerificationRejectedDialog(
              verificationRequest: verificationRequest,
            ),
          ).then((_) {
            _dialogShown = false;
          });
        } else if (verificationRequest.status == AppConstants.verificationResubmit) {
          print('Showing VerificationResubmitDialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => VerificationResubmitDialog(
              verificationRequest: verificationRequest,
            ),
          ).then((_) {
            _dialogShown = false;
          });
        }
      },
      loading: () {
        print('Verification request still loading...');
        // SHOW DIALOG EVEN WHEN LOADING - assume no verification request
        print('Showing VerificationNotSubmittedDialog (loading state)');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const VerificationNotSubmittedDialog(),
        ).then((_) {
          print('Dialog closed by user');
          // Don't reset flag - keep it true so dialog doesn't show again
        });
      },
      error: (error, stack) {
        print('Error loading verification request: $error');
        // SHOW DIALOG ON ERROR TOO - assume no verification request
        print('Showing VerificationNotSubmittedDialog (error state)');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const VerificationNotSubmittedDialog(),
        ).then((_) {
          print('Dialog closed by user');
          // Don't reset flag - keep it true so dialog doesn't show again
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user and verification status
    final userAsync = ref.watch(currentUserProvider);
    
    // Show verification dialog if needed
    userAsync.whenData((user) {
      if (user != null && !user.verified && !_dialogShown) {
        // Use addPostFrameCallback to ensure context is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_dialogShown) {
            _showVerificationDialog(user);
          }
        });
      }
    });
    
    // Get current index from route
    final currentLocation = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndexFromRoute(currentLocation);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: currentIndex == 0,
                  onTap: () {
                    context.go('/tech-home');
                  },
                ),
                _NavItem(
                  icon: Icons.work_outline,
                  label: 'Jobs',
                  isSelected: currentIndex == 1,
                  onTap: () {
                    context.go('/tech-jobs');
                  },
                ),
                _NavItem(
                  icon: Icons.attach_money,
                  label: 'Earnings',
                  isSelected: currentIndex == 2,
                  onTap: () {
                    context.go('/tech-earnings');
                  },
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: currentIndex == 3,
                  onTap: () {
                    context.go('/tech-profile');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
