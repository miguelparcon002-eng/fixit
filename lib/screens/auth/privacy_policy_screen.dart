import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                            'Privacy Policy',
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
                          // Introduction
                          _buildSectionHeader(
                            icon: Icons.privacy_tip_rounded,
                            title: 'Your Privacy Matters',
                            gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'At FIXIT, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Information We Collect
                          _buildSectionHeader(
                            icon: Icons.folder_rounded,
                            title: '1. Information We Collect',
                            gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Full name and username'),
                          _buildBulletPoint('Email address'),
                          _buildBulletPoint('Phone number'),
                          _buildBulletPoint('Home or service address'),
                          _buildBulletPoint('Profile picture (optional)'),
                          const SizedBox(height: 12),
                          const Text(
                            'Device & Usage Information',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Device type and operating system'),
                          _buildBulletPoint('App usage patterns and preferences'),
                          _buildBulletPoint('Service booking history'),
                          _buildBulletPoint('Reviews and ratings submitted'),
                          const SizedBox(height: 28),

                          // How We Use Information
                          _buildSectionHeader(
                            icon: Icons.settings_rounded,
                            title: '2. How We Use Your Information',
                            gradientColors: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('To create and manage your account'),
                          _buildBulletPoint('To connect you with qualified technicians'),
                          _buildBulletPoint('To process and track your service bookings'),
                          _buildBulletPoint('To send booking confirmations and updates'),
                          _buildBulletPoint('To improve our services and user experience'),
                          _buildBulletPoint('To respond to your inquiries and support requests'),
                          _buildBulletPoint('To send promotional offers (with your consent)'),
                          const SizedBox(height: 28),

                          // Information Sharing
                          _buildSectionHeader(
                            icon: Icons.share_rounded,
                            title: '3. Information Sharing',
                            gradientColors: [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We may share your information with:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Technicians: Name, address, and contact details for service delivery'),
                          _buildBulletPoint('Payment processors: For secure transaction processing'),
                          _buildBulletPoint('Service providers: Who assist in operating our app'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'We never sell your personal information to third parties.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Data Security
                          _buildSectionHeader(
                            icon: Icons.security_rounded,
                            title: '4. Data Security',
                            gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We implement industry-standard security measures to protect your data:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Encrypted data transmission (SSL/TLS)'),
                          _buildBulletPoint('Secure cloud storage with access controls'),
                          _buildBulletPoint('Regular security audits and updates'),
                          _buildBulletPoint('Password hashing and secure authentication'),
                          const SizedBox(height: 28),

                          // Your Rights
                          _buildSectionHeader(
                            icon: Icons.gavel_rounded,
                            title: '5. Your Rights',
                            gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'You have the right to:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Access your personal data'),
                          _buildBulletPoint('Correct inaccurate information'),
                          _buildBulletPoint('Request deletion of your account and data'),
                          _buildBulletPoint('Opt-out of marketing communications'),
                          _buildBulletPoint('Export your data in a portable format'),
                          const SizedBox(height: 28),

                          // Data Retention
                          _buildSectionHeader(
                            icon: Icons.access_time_filled_rounded,
                            title: '6. Data Retention',
                            gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('Active account data: Retained while your account is active'),
                          _buildBulletPoint('Booking history: Kept for 3 years for reference'),
                          _buildBulletPoint('Deleted accounts: Data removed within 30 days'),
                          _buildBulletPoint('Legal compliance: Some data may be retained as required by law'),
                          const SizedBox(height: 28),

                          // Cookies & Tracking
                          _buildSectionHeader(
                            icon: Icons.cookie_rounded,
                            title: '7. Cookies & Analytics',
                            gradientColors: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We use analytics tools to understand app usage and improve our services. This data is anonymized and aggregated. You can opt-out of analytics in the app settings.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Children's Privacy
                          _buildSectionHeader(
                            icon: Icons.child_care_rounded,
                            title: '8. Children\'s Privacy',
                            gradientColors: [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'FIXIT is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If we become aware that a child has provided us with personal information, we will take steps to delete it.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Policy Updates
                          _buildSectionHeader(
                            icon: Icons.update_rounded,
                            title: '9. Policy Updates',
                            gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We may update this Privacy Policy periodically. We will notify you of any material changes through the app or via email. Your continued use of the app after changes indicates acceptance of the updated policy.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Contact
                          _buildSectionHeader(
                            icon: Icons.contact_mail_rounded,
                            title: '10. Contact Us',
                            gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'If you have questions about this Privacy Policy or our data practices, please contact us:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
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
                                _buildContactItem(Icons.email_rounded, 'privacy@fixit.ph'),
                                const SizedBox(height: 10),
                                _buildContactItem(Icons.phone_rounded, '+63 XXX XXX XXXX'),
                                const SizedBox(height: 10),
                                _buildContactItem(Icons.location_on_rounded, 'San Francisco, Agusan del Sur'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Footer
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF11998e).withValues(alpha: 0.1),
                                  const Color(0xFF38ef7d).withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFF11998e),
                                  size: 40,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Your privacy is our priority. We are committed to being transparent about our data practices and giving you control over your information.',
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
