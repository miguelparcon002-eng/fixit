import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Minimal Admin Verification Review screen placeholder.
///
/// The previous version was missing from the workspace. This keeps routing intact.
class VerificationReviewScreen extends ConsumerWidget {
  const VerificationReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text(
          'Verification Review',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Verification review UI is currently a placeholder because the original screen file was missing.\n\n'
            'If you want, I can rebuild it to list pending verification requests from the verification_requests table.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
