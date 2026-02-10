import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  
  final List<bool> _expandedSections = List.generate(10, (index) => false);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.gradientStart,
              AppTheme.gradientEnd,
              AppTheme.accentPurple,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.gradientStart, AppTheme.accentPurple],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gradientStart.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
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
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.deepBlue,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last updated: January 2026',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppTheme.textSecondaryColor,
                        iconSize: 28,
                      ),
                    ],
                  ),
                ),
              ),
              // Content with enhanced scrolling
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(24),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          // Introduction Card
                          _buildIntroCard(),
                          const SizedBox(height: 24),

                          // Section 1
                          _buildExpandableSection(
                            index: 0,
                            icon: Icons.folder_rounded,
                            title: '1. Information We Collect',
                            gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSubHeader('Personal Information'),
                                _buildBulletPoint('Full name and username'),
                                _buildBulletPoint('Email address'),
                                _buildBulletPoint('Phone number'),
                                _buildBulletPoint('Home or service address'),
                                _buildBulletPoint('Profile picture (optional)'),
                                const SizedBox(height: 16),
                                _buildSubHeader('Device & Usage Information'),
                                _buildBulletPoint('Device type and operating system'),
                                _buildBulletPoint('App usage patterns and preferences'),
                                _buildBulletPoint('Service booking history'),
                                _buildBulletPoint('Reviews and ratings submitted'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Section 2
                          _buildExpandableSection(
                            index: 1,
                            icon: Icons.settings_rounded,
                            title: '2. How We Use Your Information',
                            gradientColors: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBulletPoint('To create and manage your account'),
                                _buildBulletPoint('To connect you with qualified technicians'),
                                _buildBulletPoint('To process and track your service bookings'),
                                _buildBulletPoint('To send booking confirmations and updates'),
                                _buildBulletPoint('To improve our services and user experience'),
                                _buildBulletPoint('To respond to your inquiries and support requests'),
                                _buildBulletPoint('To send promotional offers (with your consent)'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Section 3
                          _buildExpandableSection(
                            index: 2,
                            icon: Icons.share_rounded,
                            title: '3. Information Sharing',
                            gradientColors: [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sections 4-9 (Expandable)
                          _buildExpandableSection(
                            index: 3,
                            icon: Icons.security_rounded,
                            title: '4. Data Security',
                            gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'We implement industry-standard security measures to protect your data:',
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                _buildBulletPoint('Encrypted data transmission (SSL/TLS)'),
                                _buildBulletPoint('Secure cloud storage with access controls'),
                                _buildBulletPoint('Regular security audits and updates'),
                                _buildBulletPoint('Password hashing and secure authentication'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildExpandableSection(
                            index: 4,
                            icon: Icons.gavel_rounded,
                            title: '5. Your Rights',
                            gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('You have the right to:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                                const SizedBox(height: 8),
                                _buildBulletPoint('Access your personal data'),
                                _buildBulletPoint('Correct inaccurate information'),
                                _buildBulletPoint('Request deletion of your account and data'),
                                _buildBulletPoint('Opt-out of marketing communications'),
                                _buildBulletPoint('Export your data in a portable format'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildExpandableSection(
                            index: 5,
                            icon: Icons.access_time_filled_rounded,
                            title: '6. Data Retention',
                            gradientColors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBulletPoint('Active account data: Retained while your account is active'),
                                _buildBulletPoint('Booking history: Kept for 3 years for reference'),
                                _buildBulletPoint('Deleted accounts: Data removed within 30 days'),
                                _buildBulletPoint('Legal compliance: Some data may be retained as required by law'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildExpandableSection(
                            index: 6,
                            icon: Icons.cookie_rounded,
                            title: '7. Cookies & Analytics',
                            gradientColors: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                            content: const Text(
                              'We use analytics tools to understand app usage and improve our services. This data is anonymized and aggregated. You can opt-out of analytics in the app settings.',
                              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildExpandableSection(
                            index: 7,
                            icon: Icons.child_care_rounded,
                            title: '8. Children\'s Privacy',
                            gradientColors: [const Color(0xFFfc4a1a), const Color(0xFFf7b733)],
                            content: const Text(
                              'FIXIT is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If we become aware that a child has provided us with personal information, we will take steps to delete it.',
                              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildExpandableSection(
                            index: 8,
                            icon: Icons.update_rounded,
                            title: '9. Policy Updates',
                            gradientColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                            content: const Text(
                              'We may update this Privacy Policy periodically. We will notify you of any material changes through the app or via email. Your continued use of the app after changes indicates acceptance of the updated policy.',
                              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Section 10 - Contact
                          _buildExpandableSection(
                            index: 9,
                            icon: Icons.contact_mail_rounded,
                            title: '10. Contact Us',
                            gradientColors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'If you have questions about this Privacy Policy or our data practices, please contact us:',
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Footer
                          _buildFooter(),
                          const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          // Scroll to top button
                          if (_showScrollToTop)
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: FloatingActionButton(
                                mini: true,
                                backgroundColor: AppTheme.gradientStart,
                                onPressed: () {
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Accept Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppTheme.deepBlue, AppTheme.accentPurple],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepBlue.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 24, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'I Understand & Accept',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // Helper Methods

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gradientStart.withValues(alpha: 0.1),
            AppTheme.accentPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gradientStart.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.gradientStart, AppTheme.accentPurple],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gradientStart.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Privacy Matters',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.deepBlue,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'At FIXIT, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required int index,
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
    required Widget content,
  }) {
    final isExpanded = _expandedSections[index];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isExpanded ? gradientColors[0].withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded 
              ? gradientColors[0].withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedSections[index] = !_expandedSections[index];
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isExpanded ? gradientColors[0] : Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: gradientColors[0],
                        size: 28,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: content,
                  ),
                  crossFadeState: isExpanded 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.deepBlue,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF11998e).withValues(alpha: 0.12),
            const Color(0xFF38ef7d).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF11998e).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF11998e).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your privacy is our priority',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11998e),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are committed to being transparent about our data practices and giving you control over your information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.gradientStart, AppTheme.accentPurple],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.accentPurple],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
