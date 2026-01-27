import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class TechHelpSupportScreen extends StatelessWidget {
  const TechHelpSupportScreen({super.key});

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
          'Help & Support',
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
            // Contact Support Section
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _SupportTile(
              icon: Icons.chat_bubble,
              iconColor: AppTheme.lightBlue,
              title: 'Live Chat',
              subtitle: 'Chat with our support team',
              onTap: () {
                context.push('/live-chat');
              },
            ),
            const SizedBox(height: 12),
            _SupportTile(
              icon: Icons.email,
              iconColor: Colors.orange,
              title: 'Email Support',
              subtitle: 'support@fixit.com',
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'support@fixit.com',
                  queryParameters: {
                    'subject': 'Technician Support Request',
                  },
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
            ),
            const SizedBox(height: 12),
            _SupportTile(
              icon: Icons.phone,
              iconColor: Colors.green,
              title: 'Phone Support',
              subtitle: '1-800-FIX-IT-NOW',
              onTap: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: '18003494866');
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
            ),
            const SizedBox(height: 32),

            // Resources Section
            const Text(
              'Resources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _SupportTile(
              icon: Icons.help_outline,
              iconColor: Colors.purple,
              title: 'FAQ',
              subtitle: 'Frequently asked questions',
              onTap: () {
                _showFAQDialog(context);
              },
            ),
            const SizedBox(height: 12),
            _SupportTile(
              icon: Icons.video_library,
              iconColor: Colors.red,
              title: 'Video Tutorials',
              subtitle: 'Learn how to use FixIt',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video tutorials coming soon')),
                );
              },
            ),
            const SizedBox(height: 12),
            _SupportTile(
              icon: Icons.article,
              iconColor: AppTheme.deepBlue,
              title: 'Technician Guide',
              subtitle: 'Best practices and tips',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Technician guide coming soon')),
                );
              },
            ),
            const SizedBox(height: 32),

            // Feedback Section
            const Text(
              'Feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _SupportTile(
              icon: Icons.rate_review,
              iconColor: Colors.amber,
              title: 'Rate Our App',
              subtitle: 'Share your experience',
              onTap: () {
                _showRatingDialog(context);
              },
            ),
            const SizedBox(height: 12),
            _SupportTile(
              icon: Icons.bug_report,
              iconColor: Colors.red,
              title: 'Report a Bug',
              subtitle: 'Help us improve',
              onTap: () {
                _showBugReportDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Frequently Asked Questions'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _FAQItem(
                  question: 'How do I accept a job request?',
                  answer: 'Go to the Jobs tab and tap on a job request to view details. Then tap "Accept Job" to confirm.',
                ),
                _FAQItem(
                  question: 'When do I get paid?',
                  answer: 'Payments are processed within 24-48 hours after job completion and customer approval.',
                ),
                _FAQItem(
                  question: 'How do I contact a customer?',
                  answer: 'Use the in-app messaging feature available in the job details screen.',
                ),
              ],
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

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rate FixIt'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How would you rate your experience?'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  Icon(Icons.star, color: Colors.amber, size: 32),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you for your feedback!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final TextEditingController bugController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Report a Bug'),
          content: TextField(
            controller: bugController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe the issue you encountered...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bug report submitted. Thank you!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
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

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
