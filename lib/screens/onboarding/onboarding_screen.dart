import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.build_circle_rounded,
      secondaryIcon: Icons.handyman,
      title: 'Welcome to FixIT',
      subtitle: 'Repair made simple',
      gradientColors: [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
      iconColor: const Color(0xFF01579B),
    ),
    OnboardingPage(
      icon: Icons.engineering,
      secondaryIcon: Icons.settings_suggest,
      title: 'Welcome to FixIT',
      subtitle: 'Your one-stop app for all\nrepair needs.',
      gradientColors: [const Color(0xFF81C784), const Color(0xFF388E3C)],
      iconColor: const Color(0xFF1B5E20),
    ),
    OnboardingPage(
      icon: Icons.home_repair_service_rounded,
      secondaryIcon: Icons.electrical_services,
      title: 'Welcome to FixIT',
      subtitle: 'We connect you to trusted\ntechnicians nearby.',
      gradientColors: [const Color(0xFFFFB74D), const Color(0xFFF57C00)],
      iconColor: const Color(0xFFE65100),
    ),
    OnboardingPage(
      icon: Icons.verified_user_rounded,
      secondaryIcon: Icons.thumb_up_alt_rounded,
      title: 'Welcome to FixIT',
      subtitle: 'Fast, reliable, and\nguaranteed satisfaction.',
      gradientColors: [const Color(0xFF9575CD), const Color(0xFF512DA8)],
      iconColor: const Color(0xFF311B92),
    ),
  ];

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkipPressed() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 20),
                child: TextButton(
                  onPressed: _onSkipPressed,
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Skip' : '',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom section: dots + button
            Padding(
              padding: const EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: 48,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  // Next / Get Started button
                  GestureDetector(
                    onTap: _onNextPressed,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == _pages.length - 1 ? 160 : 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _currentPage == _pages.length - 1
                            ? const Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          // Illustration container
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.gradientColors[0].withValues(alpha: 0.15),
                  page.gradientColors[1].withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background decorative ring
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.gradientColors[0].withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
                // Logo inside gradient circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: page.gradientColors[1].withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            page.icon,
                            size: 64,
                            color: page.gradientColors[1],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Secondary floating icon
                Positioned(
                  top: 30,
                  right: 30,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      page.secondaryIcon,
                      size: 24,
                      color: page.iconColor,
                    ),
                  ),
                ),
                // Small decorative dot
                Positioned(
                  bottom: 40,
                  left: 25,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: page.gradientColors[0].withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.deepBlue : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final IconData secondaryIcon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color iconColor;

  const OnboardingPage({
    required this.icon,
    required this.secondaryIcon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.iconColor,
  });
}
