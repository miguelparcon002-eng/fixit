import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/earnings_provider.dart';
import '../auth/privacy_policy_screen.dart';
import '../auth/terms_conditions_screen.dart';
class TechTermsPoliciesScreen extends StatelessWidget {
  const TechTermsPoliciesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tech-profile');
            }
          },
        ),
        title: const Text(
          'Terms & Policies',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryCyan.withValues(alpha: 0.12),
                      AppTheme.deepBlue.withValues(alpha: 0.07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: AppTheme.darkCyan, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Rights & Responsibilities',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Review the policies that govern your use of FixIt as a technician.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Legal Documents'),
              const SizedBox(height: 12),
              _PolicyTile(
                icon: Icons.description_rounded,
                iconColor: AppTheme.lightBlue,
                title: 'Terms of Service',
                subtitle: 'Platform rules and service agreement',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const TermsConditionsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _PolicyTile(
                icon: Icons.shield_rounded,
                iconColor: Colors.purple,
                title: 'Privacy Policy',
                subtitle: 'How we collect, use and protect your data',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Technician Policies'),
              const SizedBox(height: 12),
              _PolicyTile(
                icon: Icons.handshake_rounded,
                iconColor: Colors.orange,
                title: 'Technician Agreement',
                subtitle: 'Your rights as an independent contractor',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const _TechAgreementScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _PolicyTile(
                icon: Icons.payments_rounded,
                iconColor: AppTheme.successColor,
                title: 'Payment Terms',
                subtitle: 'Earnings breakdown and payout schedule',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const _TechPaymentTermsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _PolicyTile(
                icon: Icons.gavel_rounded,
                iconColor: Colors.red,
                title: 'Code of Conduct',
                subtitle: 'Professional standards we expect from you',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const _TechCodeOfConductScreen()),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'About'),
              const SizedBox(height: 12),
              _PolicyTile(
                icon: Icons.info_rounded,
                iconColor: AppTheme.deepBlue,
                title: 'About FixIt',
                subtitle: 'Version 1.0.0 · Build 2025.01.001',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _TechAboutScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondaryColor,
        letterSpacing: 1.1,
      ),
    );
  }
}
class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PolicyTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
class _TechAgreementScreen extends StatelessWidget {
  const _TechAgreementScreen();
  @override
  Widget build(BuildContext context) {
    return _PolicyFullScreen(
      title: 'Technician Agreement',
      icon: Icons.handshake_rounded,
      iconColor: Colors.orange,
      lastUpdated: 'January 2026',
      sections: const [
        _PolicySection(
          title: 'Independent Contractor Status',
          icon: Icons.badge_rounded,
          iconColor: Colors.orange,
          content:
              'As a FixIt technician, you operate as an independent contractor — not an employee of FixIt. You have full control over when and how you work, while FixIt provides the platform that connects you with customers.',
        ),
        _PolicySection(
          title: 'Your Rights',
          icon: Icons.check_circle_rounded,
          iconColor: AppTheme.successColor,
          bullets: [
            'Set your own working schedule and availability',
            'Accept or decline any job request freely',
            'Set your own service rates (within platform guidelines)',
            'Work simultaneously on other platforms or independently',
            'Request account deactivation at any time',
          ],
        ),
        _PolicySection(
          title: 'Your Responsibilities',
          icon: Icons.assignment_rounded,
          iconColor: AppTheme.lightBlue,
          bullets: [
            'Maintain all required licenses, certifications, and insurance',
            'Pay your own income taxes and statutory contributions',
            'Provide your own tools, equipment, and transportation',
            'Uphold professional standards on every job',
            'Keep your profile, skills, and availability up to date',
          ],
        ),
        _PolicySection(
          title: 'Quality Standards',
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          bullets: [
            'Maintain a minimum rating of 4.0 stars',
            'Complete at least 80% of accepted jobs',
            'Respond to new job requests within 24 hours',
            'Follow all safety protocols and guidelines',
            'Notify customers of any delays promptly',
          ],
        ),
        _PolicySection(
          title: 'Platform Use',
          icon: Icons.phone_android_rounded,
          iconColor: Colors.purple,
          content:
              'You agree to use the FixIt app solely for legitimate service delivery. Misuse, unauthorized data collection, or circumventing the platform\'s payment system are grounds for immediate termination.',
        ),
      ],
    );
  }
}
class _TechPaymentTermsScreen extends ConsumerWidget {
  const _TechPaymentTermsScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekEarningsAsync = ref.watch(weekEarningsProvider);
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment Terms',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              weekEarningsAsync.when(
                loading: () => _WeeklyEarningsCard(
                    gross: null, loading: true),
                error: (_, _) => _WeeklyEarningsCard(
                    gross: 0, loading: false),
                data: (gross) => _WeeklyEarningsCard(
                    gross: gross, loading: false),
              ),
              const SizedBox(height: 24),
              _InfoCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppTheme.successColor,
                title: 'Earning Structure',
                child: Column(
                  children: [
                    _EarningsRow(
                      label: 'Your service rate',
                      value: '100%',
                      valueColor: AppTheme.textPrimaryColor,
                    ),
                    const Divider(height: 20),
                    _EarningsRow(
                      label: 'FixIt platform fee',
                      value: '− 3%',
                      valueColor: Colors.red,
                    ),
                    const Divider(height: 20),
                    _EarningsRow(
                      label: 'You receive',
                      value: '97%',
                      valueColor: AppTheme.successColor,
                      bold: true,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.successColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16,
                              color: AppTheme.successColor.withValues(alpha: 0.8)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Example: ₱500 job → ₱15 platform fee → You keep ₱485',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.calendar_month_rounded,
                iconColor: AppTheme.lightBlue,
                title: 'Payment Schedule',
                child: Column(
                  children: const [
                    _BulletItem(
                        text: 'Payments are released every Friday'),
                    _BulletItem(
                        text: 'Minimum payout balance: ₱500'),
                    _BulletItem(
                        text: 'Processing time: 1–2 business days'),
                    _BulletItem(
                        text:
                            'Payments via GCash, bank transfer, or Maya'),
                    _BulletItem(
                        text:
                            'Payment history available in the Earnings screen'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.gavel_rounded,
                iconColor: Colors.orange,
                title: 'Refunds & Disputes',
                child: Column(
                  children: const [
                    _BulletItem(
                        text: 'Customer disputes reviewed within 48 hours'),
                    _BulletItem(
                        text: 'Payment is held while dispute is active'),
                    _BulletItem(
                        text:
                            'Both parties are heard before a decision is made'),
                    _BulletItem(
                        text: 'Appeal process available for all decisions'),
                    _BulletItem(
                        text:
                            'Fraudulent disputes result in account review'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.purple,
                title: 'Tax Information',
                child: Column(
                  children: const [
                    _BulletItem(
                        text:
                            'You are responsible for declaring your own income'),
                    _BulletItem(
                        text: 'FixIt provides earnings summaries for reference'),
                    _BulletItem(
                        text: 'Quarterly estimated tax payments are advised'),
                    _BulletItem(
                        text:
                            'Contact support for official earnings certificates'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _WeeklyEarningsCard extends StatelessWidget {
  final double? gross;
  final bool loading;
  static const double _feeRate = 0.03;
  const _WeeklyEarningsCard({required this.gross, required this.loading});
  @override
  Widget build(BuildContext context) {
    final fee = gross != null ? gross! * _feeRate : 0.0;
    final net = gross != null ? gross! - fee : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryCyan, AppTheme.deepBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.trending_up_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'This Week\'s Earnings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _EarningSummaryItem(
                        label: 'Gross',
                        value: '₱${gross!.toStringAsFixed(2)}',
                        sub: 'Before fee',
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3)),
                    Expanded(
                      child: _EarningSummaryItem(
                        label: 'App Fee (3%)',
                        value: '− ₱${fee.toStringAsFixed(2)}',
                        sub: 'Platform charge',
                        valueColor: Colors.red.shade200,
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3)),
                    Expanded(
                      child: _EarningSummaryItem(
                        label: 'Net',
                        value: '₱${net.toStringAsFixed(2)}',
                        sub: 'You receive',
                        valueColor: Colors.greenAccent.shade200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 6),
                      Text(
                        'Based on completed jobs in the last 7 days',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
class _EarningSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? valueColor;
  const _EarningSummaryItem({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
class _EarningsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  const _EarningsRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: bold ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
class _TechCodeOfConductScreen extends StatelessWidget {
  const _TechCodeOfConductScreen();
  @override
  Widget build(BuildContext context) {
    return _PolicyFullScreen(
      title: 'Code of Conduct',
      icon: Icons.gavel_rounded,
      iconColor: Colors.red,
      lastUpdated: 'January 2026',
      sections: const [
        _PolicySection(
          title: 'Customer Interaction',
          icon: Icons.people_rounded,
          iconColor: AppTheme.primaryCyan,
          bullets: [
            'Be respectful, courteous, and professional at all times',
            'Communicate clearly and promptly with customers',
            'Respect customer property and personal space',
            'Maintain strict confidentiality of customer information',
            'Never request payment outside the FixIt app',
          ],
        ),
        _PolicySection(
          title: 'Work Quality',
          icon: Icons.build_rounded,
          iconColor: AppTheme.lightBlue,
          bullets: [
            'Perform thorough diagnostics before starting work',
            'Use quality parts and materials only',
            'Test all repairs fully before marking a job complete',
            'Clean up the work area after every job',
            'Provide honest assessments — never invent issues',
          ],
        ),
        _PolicySection(
          title: 'Honesty & Integrity',
          icon: Icons.verified_rounded,
          iconColor: AppTheme.successColor,
          bullets: [
            'Provide accurate, transparent cost estimates',
            'Never overcharge or add undisclosed fees',
            'Report actual findings — no unnecessary repairs',
            'Do not misrepresent your qualifications or experience',
          ],
        ),
        _PolicySection(
          title: 'Safety',
          icon: Icons.health_and_safety_rounded,
          iconColor: Colors.orange,
          bullets: [
            'Follow all safety protocols during repairs',
            'Use appropriate protective equipment when needed',
            'Ensure a safe work environment for yourself and others',
            'Report any hazardous conditions to FixIt support',
          ],
        ),
        _PolicySection(
          title: 'Prohibited Conduct',
          icon: Icons.block_rounded,
          iconColor: Colors.red,
          bullets: [
            'Harassment, discrimination, or offensive behavior',
            'Soliciting customers to bypass FixIt for direct work',
            'Requesting or accepting off-platform payments',
            'Submitting fraudulent job reports or ratings',
            'Sharing customer data with third parties',
          ],
        ),
        _PolicySection(
          title: 'Violations & Consequences',
          icon: Icons.warning_rounded,
          iconColor: Colors.amber,
          content:
              'Violations of this Code of Conduct are taken seriously.\n\n• First offense — Written warning\n• Second offense — Temporary suspension (7–30 days)\n• Serious or repeated violations — Permanent account termination\n\nAll decisions may be appealed by contacting FixIt Support within 14 days.',
        ),
      ],
    );
  }
}
class _TechAboutScreen extends StatelessWidget {
  const _TechAboutScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About FixIt',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryCyan, AppTheme.deepBlue],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.build_rounded,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'FixIt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'On-Demand Tech Repair Services',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Version 1.0.0  •  Build 2025.01.001',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _InfoCard(
                icon: Icons.info_rounded,
                iconColor: AppTheme.deepBlue,
                title: 'What is FixIt?',
                child: const Text(
                  'FixIt is a Philippines-based on-demand platform that connects skilled technicians with customers who need fast, reliable phone and laptop repair services. We make it easy for technicians like you to find work and for customers to get quality repairs at their doorstep.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.people_rounded,
                iconColor: AppTheme.primaryCyan,
                title: 'Our Mission',
                child: const Text(
                  'To empower skilled technicians with a fair, transparent platform — and give every customer access to trusted, vetted repair professionals without the hassle.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.support_agent_rounded,
                iconColor: Colors.purple,
                title: 'Contact & Support',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _BulletItem(text: 'support@fixit.ph'),
                    _BulletItem(text: 'Available Mon–Sat, 8 AM – 8 PM'),
                    _BulletItem(
                        text: 'In-app Help & Support for faster response'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '© 2025 FixIt. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _PolicySection {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? content;
  final List<String>? bullets;
  const _PolicySection({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.content,
    this.bullets,
  });
}
class _PolicyFullScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String lastUpdated;
  final List<_PolicySection> sections;
  const _PolicyFullScreen({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.lastUpdated,
    required this.sections,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Last updated: $lastUpdated',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...sections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _InfoCard(
                      icon: s.icon,
                      iconColor: s.iconColor,
                      title: s.title,
                      child: s.bullets != null
                          ? Column(
                              children: s.bullets!
                                  .map((b) => _BulletItem(text: b))
                                  .toList(),
                            )
                          : Text(
                              s.content ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                                height: 1.6,
                              ),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: const BoxDecoration(
              color: AppTheme.primaryCyan,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}