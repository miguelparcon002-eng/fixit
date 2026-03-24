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
import '../../models/job_request_model.dart';
import '../../providers/job_request_provider.dart';

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
          );
          // Do NOT reset _dialogShown so the dialog doesn't re-trigger on rebuild
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

  void _showNewJobRequestPopup(BuildContext context, JobRequestModel req) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) => _NewJobRequestPopup(
        request: req,
        onViewMap: () {
          Navigator.of(ctx).pop();
          context.push('/tech-job-map');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a popup banner whenever a new open job request arrives
    ref.listen<AsyncValue<List<JobRequestModel>>>(
      openJobRequestsProvider,
      (previous, next) {
        final prevList = previous?.valueOrNull;
        final nextList = next.valueOrNull;
        if (prevList != null &&
            nextList != null &&
            nextList.length > prevList.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showNewJobRequestPopup(context, nextList.first);
          });
        }
      },
    );

    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        // If the auth session exists but the profile is still loading/being created,
        // don't immediately bounce back to login (this can cause "login twice").
        // Instead show a loading state and let currentUserProvider retry.
        if (user == null) {
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
                          return 'Your verification is being processed. You are in read-only mode until admin approval.';
                        }
                        if (req.status == AppConstants.verificationRejected) {
                          return 'Verification rejected: ${req.adminNotes ?? 'Contact support for more information.'}';
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
                            onPressed: () => context.push('/verification-submission'),
                            child: const Text('Submit verification'),
                          );
                        }
                        if (req.status == AppConstants.verificationResubmit) {
                          return TextButton(
                            onPressed: () => context.push('/verification-submission'),
                            child: const Text('Resubmit now'),
                          );
                        }
                        if (req.status == AppConstants.verificationRejected) {
                          // Rejected: no action available until admin allows resubmission
                          return const SizedBox.shrink();
                        }
                        // Pending: allow viewing submission
                        return TextButton(
                          onPressed: () => context.push('/verification-submission'),
                          child: const Text('View submission'),
                        );
                      },
                      orElse: () => TextButton(
                        onPressed: () => context.push('/verification-submission'),
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

// ── New-job-request popup banner ─────────────────────────────────────────────

class _NewJobRequestPopup extends StatefulWidget {
  final JobRequestModel request;
  final VoidCallback onViewMap;

  const _NewJobRequestPopup({required this.request, required this.onViewMap});

  @override
  State<_NewJobRequestPopup> createState() => _NewJobRequestPopupState();
}

class _NewJobRequestPopupState extends State<_NewJobRequestPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    // Auto-dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'New Job Request!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.request.deviceType} · ${widget.request.address}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onViewMap,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: AppTheme.deepBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.7), size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
