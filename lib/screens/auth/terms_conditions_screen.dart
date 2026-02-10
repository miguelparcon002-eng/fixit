import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();

    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollToTop) {
        setState(() => _showScrollToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C3CE1),
              Color(0xFF4A5FE0),
              Color(0xFF2196F3),
              Color(0xFF17A2B8),
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  // Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Welcome badge
                                  _buildWelcomeBadge(),
                                  const SizedBox(height: 24),

                                  // Sections
                                  _buildSection(
                                    number: '01',
                                    icon: Icons.person_add_rounded,
                                    title: 'Account Registration',
                                    color: const Color(0xFF6C3CE1),
                                    content: [
                                      'You must provide accurate and complete information during registration.',
                                      'You are responsible for maintaining the security of your account credentials.',
                                      'You must be at least 18 years old or have parental consent to use our services.',
                                      'One person may only maintain one active account.',
                                    ],
                                  ),
                                  _buildSection(
                                    number: '02',
                                    icon: Icons.build_circle_rounded,
                                    title: 'Our Services',
                                    color: const Color(0xFF4A5FE0),
                                    content: [
                                      'FIXIT connects customers with certified technicians for device repair services.',
                                      'Services include laptop repairs, mobile phone repairs, and related accessories.',
                                      'Service availability may vary based on your location within San Francisco, Agusan del Sur.',
                                      'Technicians are independent contractors and not employees of FIXIT.',
                                    ],
                                  ),
                                  _buildSection(
                                    number: '03',
                                    icon: Icons.payments_rounded,
                                    title: 'Bookings & Payments',
                                    color: const Color(0xFF2196F3),
                                    content: [
                                      'All bookings are subject to technician availability and confirmation.',
                                      'Prices displayed are estimates and may vary based on actual repair requirements.',
                                      'Payment is due upon completion of services unless otherwise agreed.',
                                      'Cancellations must be made at least 2 hours before the scheduled appointment.',
                                    ],
                                  ),
                                  _buildSection(
                                    number: '04',
                                    icon: Icons.verified_user_rounded,
                                    title: 'User Responsibilities',
                                    color: const Color(0xFF17A2B8),
                                    description: 'As a user of FIXIT, you agree to:',
                                    content: [
                                      'Provide accurate device information and issue descriptions.',
                                      'Ensure a safe environment for technicians during home visits.',
                                      'Backup your data before submitting devices for repair.',
                                      'Treat technicians and staff with respect and courtesy.',
                                      'Not use the app for any illegal or unauthorized purposes.',
                                    ],
                                  ),
                                  _buildSection(
                                    number: '05',
                                    icon: Icons.shield_rounded,
                                    title: 'Warranty & Liability',
                                    color: const Color(0xFF6C3CE1),
                                    content: [
                                      'Repair services come with a 30-day warranty for the same issue.',
                                      'Warranty does not cover physical damage, water damage, or software issues.',
                                      'FIXIT is not liable for data loss during repairs - always backup your device.',
                                      'Maximum liability is limited to the service fee paid.',
                                    ],
                                  ),
                                  _buildSection(
                                    number: '06',
                                    icon: Icons.privacy_tip_rounded,
                                    title: 'Privacy & Data',
                                    color: const Color(0xFF4A5FE0),
                                    content: [
                                      'We collect and process personal data as described in our Privacy Policy.',
                                      'Your information is used to provide and improve our services.',
                                      'We do not sell your personal information to third parties.',
                                      'You may request deletion of your data at any time.',
                                    ],
                                  ),
                                  _buildSection(
                                    number: '07',
                                    icon: Icons.cancel_rounded,
                                    title: 'Termination',
                                    color: const Color(0xFF2196F3),
                                    content: [
                                      'You may close your account at any time through the app settings.',
                                      'We reserve the right to suspend or terminate accounts that violate these terms.',
                                      'Outstanding payments remain due even after account termination.',
                                    ],
                                  ),
                                  _buildSection(
                                    number: '08',
                                    icon: Icons.update_rounded,
                                    title: 'Changes to Terms',
                                    color: const Color(0xFF17A2B8),
                                    paragraph: 'We may update these Terms and Conditions from time to time. We will notify you of any significant changes through the app or via email. Continued use of the app after changes constitutes acceptance of the new terms.',
                                  ),

                                  const SizedBox(height: 8),

                                  // Contact card
                                  _buildContactCard(),
                                  const SizedBox(height: 20),

                                  // Agreement footer
                                  _buildAgreementFooter(),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                            // Scroll to top FAB
                            if (_showScrollToTop)
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: GestureDetector(
                                  onTap: () => _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A5FE0),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4A5FE0).withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom button
                  _buildBottomButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last updated: January 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBadge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C3CE1).withValues(alpha: 0.08),
            const Color(0xFF4A5FE0).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C3CE1).withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFF4A5FE0)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to FIXIT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'By creating an account, you agree to be bound by these terms.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required IconData icon,
    required String title,
    required Color color,
    String? description,
    List<String>? content,
    String? paragraph,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Divider line
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 14),
          // Description if any
          if (description != null) ...[
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Paragraph if any
          if (paragraph != null)
            Text(
              paragraph,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF4B5563),
              ),
            ),
          // Bullet points
          if (content != null)
            ...content.map((text) => _buildBulletPoint(text, color)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
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
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.contact_support_rounded, color: Color(0xFF17A2B8), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email_rounded, 'support@fixit.ph'),
          const SizedBox(height: 10),
          _buildContactItem(Icons.phone_rounded, '+63 XXX XXX XXXX'),
          const SizedBox(height: 10),
          _buildContactItem(Icons.location_on_rounded, 'San Francisco, Agusan del Sur'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4A5FE0), size: 18),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4B5563),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A5FE0).withValues(alpha: 0.06),
            const Color(0xFF6C3CE1).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A5FE0).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'By creating an account, you acknowledge that you have read, understood, and agree to these Terms and Conditions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF4A5FE0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, size: 22),
              SizedBox(width: 8),
              Text(
                'I Understand & Agree',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
