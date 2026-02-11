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
    if (location.startsWith('/tech-notification-settings')) return 3;
    // Ratings is a full page, but keep the Dashboard tab highlighted.
    if (location.startsWith('/tech-ratings')) return 0;
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
          // After submission, do NOT keep interrupting the technician.
          // They stay in read-only mode and can wait for admin approval.
          AppLogger.p('Verification is pending - no pop-up shown');
          _dialogShown = false;
        } else if (verificationRequest.status == AppConstants.verificationRejected) {
          // Don't block the UI with a popup; technician can see status in the banner
          // and resubmit if needed.
          AppLogger.p('Verification is rejected - no pop-up shown');
          _dialogShown = false;
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
        // Do not show any popups while loading.
        _dialogShown = false;
      },
      error: (error, stack) {
        // Do not show popups on error; technician can still manually open
        // verification submission from the banner.
        AppLogger.p('Error loading verification request: $error');
        _dialogShown = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Read-only mode for unverified technicians: they can browse UI,
        // but write actions are blocked at the service layer.
        final isReadOnly = !user.verified;
        final verificationReqAsync = ref.watch(userVerificationRequestProvider);

        if (isReadOnly) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showVerificationDialog(user);
          });
        }

        // Normal tech navigation
        final currentLocation = GoRouterState.of(context).uri.toString();
        final currentIndex = _getIndexFromRoute(currentLocation);

        return Scaffold(
          body: Column(
            children: [
              if (isReadOnly)
                MaterialBanner(
                  backgroundColor: Colors.orange.withValues(alpha: 0.15),
                  content: Text(
                    verificationReqAsync.maybeWhen(
                      data: (req) {
                        if (req == null) {
                          return 'Your technician account is in read-only mode. Submit verification to unlock actions.';
                        }
                        if (req.status == AppConstants.verificationResubmit) {
                          return 'Resubmission required: ${req.adminNotes ?? 'Please update your verification documents.'}';
                        }
                        if (req.status == AppConstants.verificationPending) {
                          return 'Verification submitted. You are in read-only mode until admin approval.';
                        }
                        if (req.status == AppConstants.verificationRejected) {
                          return 'Verification rejected: ${req.adminNotes ?? 'Please review and resubmit.'}';
                        }
                        return 'Your technician account is in read-only mode until verification is approved.';
                      },
                      orElse: () => 'Your technician account is in read-only mode until verification is approved.',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  actions: [
                    verificationReqAsync.maybeWhen(
                      data: (req) {
                        if (req == null) {
                          return TextButton(
                            onPressed: () => context.go('/verification-submission'),
                            child: const Text('Submit verification'),
                          );
                        }
                        if (req.status == AppConstants.verificationResubmit) {
                          return TextButton(
                            onPressed: () => context.go('/verification-submission'),
                            child: const Text('Resubmit now'),
                          );
                        }
                        // Pending/rejected: allow viewing submission screen, but not required.
                        return TextButton(
                          onPressed: () => context.go('/verification-submission'),
                          child: const Text('View submission'),
                        );
                      },
                      orElse: () => TextButton(
                        onPressed: () => context.go('/verification-submission'),
                        child: const Text('Verification'),
                      ),
                    ),
                  ],
                ),
              Expanded(child: widget.child),
            ],
          ),
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
      },
    );
  }
}
