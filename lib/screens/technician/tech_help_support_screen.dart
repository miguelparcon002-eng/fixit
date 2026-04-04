import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/feedback_service.dart';
class TechHelpSupportScreen extends ConsumerWidget {
  const TechHelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tech-profile');
            }
          },
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _SupportHeroCard(
            title: 'Need help?',
            subtitle: 'Contact FixIt support or browse resources for technicians.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Live chat',
                  subtitle: 'Talk to support',
                  color: AppTheme.lightBlue,
                  onTap: () => context.push('/live-chat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.phone_outlined,
                  title: 'Call',
                  subtitle: '1-800-FIX-IT',
                  color: AppTheme.successColor,
                  onTap: () async {
                    final uri = Uri(scheme: 'tel', path: '18003494866');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Contact'),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.email_outlined,
            iconColor: AppTheme.warningColor,
            title: 'Email support',
            subtitle: 'support@fixit.com',
            onTap: () async {
              final emailUri = Uri(
                scheme: 'mailto',
                path: 'support@fixit.com',
                queryParameters: {'subject': 'Technician Support Request'},
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Resources'),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.help_outline,
            iconColor: AppTheme.deepBlue,
            title: 'FAQ',
            subtitle: 'Common technician questions',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _TechFAQScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.menu_book,
            iconColor: AppTheme.primaryCyan,
            title: 'Technician Guide',
            subtitle: 'Best practices and tips',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _TechGuideScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.video_library,
            iconColor: AppTheme.darkCyan,
            title: 'Video Tutorials',
            subtitle: 'Watch step-by-step guides',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _TechVideoTutorialsScreen()),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Feedback'),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.feedback,
            iconColor: AppTheme.primaryCyan,
            title: 'Send Feedback',
            subtitle: 'Help us improve our service',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _TechFeedbackFormScreen(type: 'feedback', ref: ref),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.bug_report,
            iconColor: AppTheme.errorColor,
            title: 'Report a Bug',
            subtitle: 'Let us know about issues',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _TechFeedbackFormScreen(type: 'bug_report', ref: ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}
class _SupportHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SupportHeroCard({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepBlue,
            AppTheme.deepBlue.withValues(alpha: 0.92),
            AppTheme.primaryCyan,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
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
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
class _SupportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SupportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
class _TechFAQScreen extends StatelessWidget {
  const _TechFAQScreen();
  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'question': 'How do I accept a job request?', 'answer': 'Go to the Jobs tab and open a pending request. Tap "Accept" to confirm and start the job.'},
      {'question': 'When do I get paid?', 'answer': 'Payments are processed within 24–48 hours after completion and customer approval.'},
      {'question': 'How do I contact a customer?', 'answer': 'Use in-app messaging from the job details screen to communicate with your customer.'},
      {'question': 'How do I update my profile?', 'answer': 'Go to your profile and tap "Edit Profile" to update your name, location, specialties, and bio.'},
      {'question': 'How do I set my location?', 'answer': 'In Edit Profile, tap the location field to open the map and pin your exact location.'},
      {'question': 'How are my ratings calculated?', 'answer': 'Your rating is the average of all ratings left by customers after completed jobs.'},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FAQs',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                faq['question']!,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
              ),
              children: [
                Text(
                  faq['answer']!,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor, height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class _TechGuideScreen extends StatelessWidget {
  const _TechGuideScreen();
  @override
  Widget build(BuildContext context) {
    final sections = [
      _GuideSection(
        icon: Icons.person_add,
        title: 'Setting Up Your Profile',
        steps: [
          'Complete your profile with your full name and contact number.',
          'Add your specialties so customers know what you can fix.',
          'Write a bio to introduce yourself.',
          'Set your location on the map so customers can see you nearby.',
          'Upload a profile picture to build trust.',
        ],
      ),
      _GuideSection(
        icon: Icons.work,
        title: 'Managing Job Requests',
        steps: [
          'New job requests appear in the Jobs tab.',
          'Review the job details, location, and schedule before accepting.',
          'Tap "Accept" to confirm or decline if unavailable.',
          'Once accepted, the customer is notified and the job begins.',
        ],
      ),
      _GuideSection(
        icon: Icons.build,
        title: 'Completing a Job',
        steps: [
          'Arrive at the customer\'s location at the scheduled time.',
          'Diagnose the issue and communicate the repair plan.',
          'Complete the repair and ensure the customer is satisfied.',
          'Mark the job as complete in the app.',
        ],
      ),
      _GuideSection(
        icon: Icons.payments,
        title: 'Payments & Earnings',
        steps: [
          'Payment is released after the customer confirms completion.',
          'View your earnings breakdown in the Earnings tab.',
          'Track today\'s, weekly, and monthly income.',
          'Payment is processed within 24–48 hours.',
        ],
      ),
      _GuideSection(
        icon: Icons.star,
        title: 'Ratings & Reviews',
        steps: [
          'Customers rate you after each completed job.',
          'Your average rating is shown on your profile.',
          'Maintain high ratings by being professional and punctual.',
          'View all your reviews in the Ratings tab.',
        ],
      ),
      _GuideSection(
        icon: Icons.support_agent,
        title: 'Getting Help',
        steps: [
          'Go to Help & Support from your profile.',
          'Use live chat or email for urgent issues.',
          'Submit a bug report or feedback to help us improve.',
          'Check FAQs for quick answers.',
        ],
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Technician Guide',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: AppTheme.deepBlue, size: 20),
              ),
              title: Text(
                section.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
              ),
              children: [
                for (int i = 0; i < section.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlue.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.deepBlue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section.steps[i],
                            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class _GuideSection {
  final IconData icon;
  final String title;
  final List<String> steps;
  const _GuideSection({required this.icon, required this.title, required this.steps});
}
class _TechVideoTutorialsScreen extends StatelessWidget {
  const _TechVideoTutorialsScreen();
  @override
  Widget build(BuildContext context) {
    final tutorials = [
      _VideoTutorial(icon: Icons.play_circle_fill, title: 'Setting Up Your Profile', duration: '2:15', description: 'Learn how to complete your technician profile for maximum visibility.', color: AppTheme.deepBlue),
      _VideoTutorial(icon: Icons.play_circle_fill, title: 'Accepting Your First Job', duration: '3:00', description: 'A complete walkthrough of how to find and accept job requests.', color: AppTheme.primaryCyan),
      _VideoTutorial(icon: Icons.play_circle_fill, title: 'Using the Map to Set Location', duration: '1:45', description: 'How to pin your exact location so customers nearby can find you.', color: Colors.blue),
      _VideoTutorial(icon: Icons.play_circle_fill, title: 'Tracking Your Earnings', duration: '2:00', description: 'Learn how to view your daily, weekly, and monthly earnings.', color: AppTheme.successColor),
      _VideoTutorial(icon: Icons.play_circle_fill, title: 'Completing a Job & Rating', duration: '1:50', description: 'How to mark a job complete and what happens after the customer rates you.', color: Colors.amber.shade700),
      _VideoTutorial(icon: Icons.play_circle_fill, title: 'Submitting a Support Ticket', duration: '2:00', description: 'Need help? Learn how to contact support and report issues.', color: AppTheme.errorColor),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Tutorials',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: tutorials.length,
        itemBuilder: (context, index) {
          final tutorial = tutorials[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playing: ${tutorial.title}'), backgroundColor: AppTheme.deepBlue),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: tutorial.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tutorial.icon, color: tutorial.color, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tutorial.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                          const SizedBox(height: 4),
                          Text(tutorial.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                      child: Text(tutorial.duration, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class _VideoTutorial {
  final IconData icon;
  final String title;
  final String duration;
  final String description;
  final Color color;
  const _VideoTutorial({required this.icon, required this.title, required this.duration, required this.description, required this.color});
}
class _TechFeedbackFormScreen extends StatefulWidget {
  final String type;
  final WidgetRef ref;
  const _TechFeedbackFormScreen({required this.type, required this.ref});
  @override
  State<_TechFeedbackFormScreen> createState() => _TechFeedbackFormScreenState();
}
class _TechFeedbackFormScreenState extends State<_TechFeedbackFormScreen> {
  final _messageController = TextEditingController();
  int _selectedRating = 0;
  bool _submitting = false;
  bool get _isFeedback => widget.type == 'feedback';
  String get _title => _isFeedback ? 'Send Feedback' : 'Report a Bug';
  String get _subtitle => _isFeedback
      ? 'Help us improve FixIt by sharing your experience'
      : 'Let us know what went wrong so we can fix it';
  IconData get _icon => _isFeedback ? Icons.feedback : Icons.bug_report;
  Color get _accentColor => _isFeedback ? AppTheme.primaryCyan : AppTheme.errorColor;
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFeedback ? 'Please write your feedback before submitting' : 'Please describe the bug before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = widget.ref.read(currentUserProvider).valueOrNull;
      final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
      final userName = user?.fullName ?? user?.email ?? 'Unknown';
      await FeedbackService.submitFeedback(
        userId: userId,
        userName: userName,
        type: widget.type,
        message: message,
        rating: _isFeedback && _selectedRating > 0 ? _selectedRating : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFeedback ? 'Thank you for your feedback!' : 'Bug report submitted! We\'ll look into it.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e'), backgroundColor: AppTheme.errorColor),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title, style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 22, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accentColor, _accentColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: Icon(_icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(_subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isFeedback) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How would you rate your experience?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                    const SizedBox(height: 4),
                    const Text('Optional - tap a star to rate', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRating = _selectedRating == starIndex ? 0 : starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 40,
                              color: starIndex <= _selectedRating ? Colors.amber : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_selectedRating > 0) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          switch (_selectedRating) {
                            1 => 'Poor', 2 => 'Fair', 3 => 'Good', 4 => 'Great', 5 => 'Excellent', _ => '',
                          },
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.amber.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_isFeedback ? Icons.edit_note : Icons.description_outlined, size: 20, color: _accentColor),
                      const SizedBox(width: 8),
                      Text(_isFeedback ? 'Your Feedback' : 'Bug Description',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 6,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: _isFeedback
                          ? 'Tell us what you think about FixIt. What do you like? What can we improve?'
                          : 'Please describe the bug in detail:\n- What were you doing?\n- What happened?\n- What did you expect?',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.4),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor, width: 2)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isFeedback ? Icons.send_rounded : Icons.bug_report_rounded),
                label: Text(
                  _submitting ? 'Submitting...' : (_isFeedback ? 'Send Feedback' : 'Submit Bug Report'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}