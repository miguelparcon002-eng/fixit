import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryCyan,
              AppTheme.darkCyan,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.deepBlue,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Last updated: January 2026',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Section
                          _buildSectionHeader(
                            icon: Icons.handshake_rounded,
                            title: 'Welcome to FIXIT',
                            gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Thank you for choosing FIXIT for your device repair needs. These Terms and Conditions govern your use of our mobile application and services. By creating an account, you agree to be bound by these terms.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Account Registration
                          _buildSectionHeader(
                            icon: Icons.person_add_rounded,
                            title: '1. Account Registration',
                            gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('You must provide accurate and complete information during registration.'),
                          _buildBulletPoint('You are responsible for maintaining the security of your account credentials.'),
                          _buildBulletPoint('You must be at least 18 years old or have parental consent to use our services.'),
                          _buildBulletPoint('One person may only maintain one active account.'),
                          const SizedBox(height: 28),

                          // Services
                          _buildSectionHeader(
                            icon: Icons.build_circle_rounded,
                            title: '2. Our Services',
                            gradientColors: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('FIXIT connects customers with certified technicians for device repair services.'),
                          _buildBulletPoint('Services include laptop repairs, mobile phone repairs, tablet repairs, and related accessories.'),
                          _buildBulletPoint('Service availability may vary based on your location within San Francisco, Agusan del Sur.'),
                          _buildBulletPoint('Technicians are independent contractors and not employees of FIXIT.'),
                          const SizedBox(height: 28),

                          // Bookings & Payments
                          _buildSectionHeader(
                            icon: Icons.calendar_today_rounded,
                            title: '3. Bookings & Payments',
                            gradientColors: [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('All bookings are subject to technician availability and confirmation.'),
                          _buildBulletPoint('Prices displayed are estimates and may vary based on actual repair requirements.'),
                          _buildBulletPoint('Payment is due upon completion of services unless otherwise agreed.'),
                          _buildBulletPoint('Cancellations must be made at least 2 hours before the scheduled appointment.'),
                          const SizedBox(height: 28),

                          // User Responsibilities
                          _buildSectionHeader(
                            icon: Icons.verified_user_rounded,
                            title: '4. User Responsibilities',
                            gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'As a user of FIXIT, you agree to:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Provide accurate device information and issue descriptions.'),
                          _buildBulletPoint('Ensure a safe environment for technicians during home visits.'),
                          _buildBulletPoint('Backup your data before submitting devices for repair.'),
                          _buildBulletPoint('Treat technicians and staff with respect and courtesy.'),
                          _buildBulletPoint('Not use the app for any illegal or unauthorized purposes.'),
                          const SizedBox(height: 28),

                          // Warranty & Liability
                          _buildSectionHeader(
                            icon: Icons.shield_rounded,
                            title: '5. Warranty & Liability',
                            gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('Repair services come with a 30-day warranty for the same issue.'),
                          _buildBulletPoint('Warranty does not cover physical damage, water damage, or software issues.'),
                          _buildBulletPoint('FIXIT is not liable for data loss during repairs - always backup your device.'),
                          _buildBulletPoint('Maximum liability is limited to the service fee paid.'),
                          const SizedBox(height: 28),

                          // Privacy
                          _buildSectionHeader(
                            icon: Icons.privacy_tip_rounded,
                            title: '6. Privacy & Data',
                            gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('We collect and process personal data as described in our Privacy Policy.'),
                          _buildBulletPoint('Your information is used to provide and improve our services.'),
                          _buildBulletPoint('We do not sell your personal information to third parties.'),
                          _buildBulletPoint('You may request deletion of your data at any time.'),
                          const SizedBox(height: 28),

                          // Termination
                          _buildSectionHeader(
                            icon: Icons.cancel_rounded,
                            title: '7. Termination',
                            gradientColors: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('You may close your account at any time through the app settings.'),
                          _buildBulletPoint('We reserve the right to suspend or terminate accounts that violate these terms.'),
                          _buildBulletPoint('Outstanding payments remain due even after account termination.'),
                          const SizedBox(height: 28),

                          // Changes to Terms
                          _buildSectionHeader(
                            icon: Icons.update_rounded,
                            title: '8. Changes to Terms',
                            gradientColors: [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We may update these Terms and Conditions from time to time. We will notify you of any significant changes through the app or via email. Continued use of the app after changes constitutes acceptance of the new terms.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Contact
                          _buildSectionHeader(
                            icon: Icons.contact_support_rounded,
                            title: '9. Contact Us',
                            gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.deepBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.deepBlue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContactItem(Icons.email_rounded, 'support@fixit.ph'),
                                const SizedBox(height: 10),
                                _buildContactItem(Icons.phone_rounded, '+63 XXX XXX XXXX'),
                                const SizedBox(height: 10),
                                _buildContactItem(Icons.location_on_rounded, 'San Francisco, Agusan del Sur'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Agreement Footer
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF667eea).withValues(alpha: 0.1),
                                  const Color(0xFF764ba2).withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'By creating an account, you acknowledge that you have read, understood, and agree to these Terms and Conditions.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Accept Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'I Understand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.deepBlue,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.deepBlue,
          size: 18,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
