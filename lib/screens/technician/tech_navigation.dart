import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../providers/verification_provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/verification_pending_dialog.dart';
import '../../core/utils/app_logger.dart';

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
    AppLogger.p('=== Showing Verification Dialog for ${user.email} ===');
    AppLogger.p('User verified: ${user.verified}');
    
    // Check for verification request
    final verificationRequestAsync = ref.read(userVerificationRequestProvider);
    
    verificationRequestAsync.when(
      data: (verificationRequest) {
        AppLogger.p('Verification request: ${verificationRequest?.status ?? "NO REQUEST"}');
        
        // If no verification request exists, show prompt to submit
        if (verificationRequest == null) {
          AppLogger.p('Showing VerificationNotSubmittedDialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const VerificationNotSubmittedDialog(),
          ).then((_) {
            AppLogger.p('Dialog closed by user');
            // Don't reset flag - keep it true so dialog doesn't show again
            // until user comes back from verification screen
          });
        } else if (verificationRequest.status == AppConstants.verificationPending) {
          AppLogger.p('Showing VerificationPendingDialog');
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
          AppLogger.p('Showing VerificationRejectedDialog');
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
          AppLogger.p('Showing VerificationResubmitDialog');
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
        AppLogger.p('Verification request still loading...');
        // SHOW DIALOG EVEN WHEN LOADING - assume no verification request
        AppLogger.p('Showing VerificationNotSubmittedDialog (loading state)');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const VerificationNotSubmittedDialog(),
        ).then((_) {
          AppLogger.p('Dialog closed by user');
          // Don't reset flag - keep it true so dialog doesn't show again
        });
      },
      error: (error, stack) {
        AppLogger.p('Error loading verification request: $error');
        // SHOW DIALOG ON ERROR TOO - assume no verification request
        AppLogger.p('Showing VerificationNotSubmittedDialog (error state)');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const VerificationNotSubmittedDialog(),
        ).then((_) {
          AppLogger.p('Dialog closed by user');
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/tech-home');
              break;
            case 1:
              context.go('/tech-jobs');
              break;
            case 2:
              context.go('/tech-earnings');
              break;
            case 3:
              context.go('/tech-profile');
              break;
          }
        },
        indicatorColor: AppTheme.deepBlue.withValues(alpha: 0.12),
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money_rounded),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
