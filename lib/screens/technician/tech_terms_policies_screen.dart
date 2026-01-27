import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/tech-profile'),
        ),
        title: const Text(
          'Terms & Policies',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PolicyTile(
              icon: Icons.description,
              iconColor: AppTheme.lightBlue,
              title: 'Terms of Service',
              subtitle: 'Technician service agreement',
              onTap: () => _showTermsDialog(context),
            ),
            const SizedBox(height: 12),
            _PolicyTile(
              icon: Icons.privacy_tip,
              iconColor: Colors.purple,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => _showPrivacyDialog(context),
            ),
            const SizedBox(height: 12),
            _PolicyTile(
              icon: Icons.work,
              iconColor: Colors.orange,
              title: 'Technician Agreement',
              subtitle: 'Your rights and responsibilities',
              onTap: () => _showTechnicianAgreementDialog(context),
            ),
            const SizedBox(height: 12),
            _PolicyTile(
              icon: Icons.payments,
              iconColor: Colors.green,
              title: 'Payment Terms',
              subtitle: 'Earnings and payment policies',
              onTap: () => _showPaymentTermsDialog(context),
            ),
            const SizedBox(height: 12),
            _PolicyTile(
              icon: Icons.gavel,
              iconColor: Colors.red,
              title: 'Code of Conduct',
              subtitle: 'Professional standards',
              onTap: () => _showCodeOfConductDialog(context),
            ),
            const SizedBox(height: 12),
            _PolicyTile(
              icon: Icons.info,
              iconColor: AppTheme.deepBlue,
              title: 'About FixIt',
              subtitle: 'Version 1.0.0',
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    _showPolicyDialog(
      context,
      'Terms of Service',
      '''
Last Updated: January 2025

1. ACCEPTANCE OF TERMS
By using the FixIt platform as a technician, you agree to these Terms of Service.

2. TECHNICIAN OBLIGATIONS
- Provide quality service to customers
- Maintain professional conduct
- Complete accepted jobs in a timely manner
- Keep your profile information accurate

3. SERVICE STANDARDS
- Arrive on time for scheduled appointments
- Use appropriate tools and materials
- Follow safety guidelines
- Provide accurate estimates

4. CANCELLATION POLICY
- Give at least 24 hours notice for cancellations
- Excessive cancellations may result in account suspension

5. ACCOUNT TERMINATION
FixIt reserves the right to suspend or terminate accounts for violations of these terms.

For full terms, visit: www.fixit.com/terms
      ''',
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    _showPolicyDialog(
      context,
      'Privacy Policy',
      '''
Last Updated: January 2025

1. INFORMATION WE COLLECT
- Profile information (name, contact details)
- Job history and performance metrics
- Location data during active jobs
- Payment and tax information

2. HOW WE USE YOUR DATA
- Match you with appropriate job requests
- Process payments
- Improve our services
- Communicate important updates

3. DATA SHARING
- Customer names and addresses for accepted jobs
- Your profile and ratings with customers
- Aggregate data with partners (anonymized)

4. DATA SECURITY
We use industry-standard encryption and security measures to protect your information.

5. YOUR RIGHTS
- Access your data
- Request data deletion
- Opt-out of marketing communications

For full privacy policy, visit: www.fixit.com/privacy
      ''',
    );
  }

  void _showTechnicianAgreementDialog(BuildContext context) {
    _showPolicyDialog(
      context,
      'Technician Agreement',
      '''
INDEPENDENT CONTRACTOR STATUS
As a FixIt technician, you are an independent contractor, not an employee.

YOUR RIGHTS:
- Set your own schedule
- Accept or decline job requests
- Set competitive pricing (within guidelines)
- Work with multiple platforms

YOUR RESPONSIBILITIES:
- Maintain required licenses and insurance
- Pay your own taxes
- Provide your own tools and transportation
- Maintain professional standards

QUALITY STANDARDS:
- Maintain a minimum 4.0 rating
- Complete at least 80% of accepted jobs
- Respond to requests within 24 hours
- Follow all safety protocols

EARNINGS:
- Platform fee: 15% per completed job
- Weekly direct deposit payments
- Access to detailed earning reports
      ''',
    );
  }

  void _showPaymentTermsDialog(BuildContext context) {
    _showPolicyDialog(
      context,
      'Payment Terms',
      '''
EARNING STRUCTURE:
- You set your service rates
- FixIt charges a 15% platform fee
- Customers pay through the app
- You receive 85% of the total

PAYMENT SCHEDULE:
- Weekly payments every Friday
- Minimum balance: \$50 for payout
- Payments via direct deposit
- 1-2 business days processing time

JOB PRICING:
- Set competitive rates
- Include parts and labor
- Additional charges require approval
- Transparent pricing to customers

REFUNDS & DISPUTES:
- Customer disputes reviewed within 48 hours
- Payment held during dispute resolution
- Final decisions made by FixIt support
- Appeal process available

TAX INFORMATION:
- You receive 1099 forms annually
- Responsible for your own taxes
- Quarterly estimated payments recommended
      ''',
    );
  }

  void _showCodeOfConductDialog(BuildContext context) {
    _showPolicyDialog(
      context,
      'Code of Conduct',
      '''
PROFESSIONAL STANDARDS:

1. CUSTOMER INTERACTION
- Be respectful and courteous
- Communicate clearly
- Respect customer property
- Maintain confidentiality

2. WORK QUALITY
- Perform thorough diagnostics
- Use quality parts and materials
- Test repairs before completion
- Clean up work area

3. HONESTY & INTEGRITY
- Provide accurate estimates
- Don't overcharge for services
- Report actual issues found
- No unnecessary repairs

4. SAFETY
- Follow all safety protocols
- Use proper protective equipment
- Ensure safe work environment
- Report hazardous conditions

5. PROHIBITED CONDUCT
- Harassment or discrimination
- Requesting payment outside the app
- Soliciting customers directly
- Fraudulent or deceptive practices

VIOLATIONS:
- First offense: Warning
- Second offense: Suspension
- Serious violations: Account termination
      ''',
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('About FixIt'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FixIt - On-Demand Tech Services',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              SizedBox(height: 4),
              Text('Build: 2025.01.001'),
              SizedBox(height: 16),
              Text(
                'Connecting skilled technicians with customers who need tech repairs and services.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 16),
              Text('© 2025 FixIt. All rights reserved.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
