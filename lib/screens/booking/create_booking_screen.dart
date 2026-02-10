import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Minimal create booking screen.
///
/// The original implementation was missing from the workspace but the router
/// depends on it. This placeholder keeps the app compiling.
class CreateBookingScreen extends StatelessWidget {
  final String serviceId;
  final bool isEmergency;

  const CreateBookingScreen({
    super.key,
    required this.serviceId,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Create Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service ID: $serviceId'),
                const SizedBox(height: 8),
                Text('Emergency: ${isEmergency ? 'Yes' : 'No'}'),
                const SizedBox(height: 16),
                const Text(
                  'This screen is currently a placeholder because the original file was missing.\n\n'
                  'Tell me what fields you want here (device details, schedule, address, notes, etc.) and I can rebuild it.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
