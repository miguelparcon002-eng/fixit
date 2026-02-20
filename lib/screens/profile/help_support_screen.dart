import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../services/feedback_service.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketCount = ref.watch(customerTicketsProvider).length;

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
          _SupportHeroCard(
            title: 'How can we help?',
            subtitle: 'Find answers, submit a ticket, or track an existing request.',
            trailing: _TicketCountBadge(count: ticketCount),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.support_agent,
                  title: 'New Ticket',
                  subtitle: 'Get help fast',
                  color: AppTheme.warningColor,
                  onTap: () => context.push('/submit-ticket'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.confirmation_number,
                  title: 'My Tickets',
                  subtitle: 'Track status',
                  color: AppTheme.deepBlue,
                  onTap: () => context.push('/my-tickets'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          const _SectionTitle('FAQs & Resources'),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.help,
            iconColor: AppTheme.lightBlue,
            title: 'FAQs',
            subtitle: 'Frequently asked questions',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const _FAQScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.menu_book,
            iconColor: AppTheme.primaryCyan,
            title: 'User Guide',
            subtitle: 'Learn how to use FixIt',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const _UserGuideScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.video_library,
            iconColor: AppTheme.darkCyan,
            title: 'Video Tutorials',
            subtitle: 'Watch step-by-step guides',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const _VideoTutorialsScreen()),
              );
            },
          ),

          const SizedBox(height: 22),
          const _SectionTitle('Other'),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.feedback,
            iconColor: AppTheme.primaryCyan,
            title: 'Send Feedback',
            subtitle: 'Help us improve our service',
            onTap: () => _showFeedbackDialog(context, ref),
          ),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.bug_report,
            iconColor: AppTheme.errorColor,
            title: 'Report a Bug',
            subtitle: 'Let us know about issues',
            onTap: () => _showBugReportDialog(context, ref),
          ),
          const SizedBox(height: 10),
          _SupportOptionTile(
            icon: Icons.info,
            iconColor: Colors.grey,
            title: 'About FixIt',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FixIt',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.build, size: 48),
                children: const [
                  Text(
                    'FixIt is your trusted device repair service platform, connecting you with skilled technicians for all your repair needs.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FeedbackFormScreen(
          type: 'feedback',
          ref: ref,
        ),
      ),
    );
  }

  void _showBugReportDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FeedbackFormScreen(
          type: 'bug_report',
          ref: ref,
        ),
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

class _TicketCountBadge extends StatelessWidget {
  final int count;

  const _TicketCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$count open',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SupportHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SupportHeroCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

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
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
            ),
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
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
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

class _FAQScreen extends StatelessWidget {
  const _FAQScreen();

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'How do I book a repair service?',
        'answer':
            'To book a repair service, go to the home screen and select the type of service you need (Quick Fix, Emergency Repair, etc.). Follow the steps to provide device details, select a time, and choose a technician.',
      },
      {
        'question': 'What payment methods are accepted?',
        'answer':
            'We accept all major credit cards (Visa, Mastercard), debit cards, and digital wallets. You can manage your payment methods in the Profile section.',
      },
      {
        'question': 'How long does a typical repair take?',
        'answer':
            'Repair times vary depending on the issue. Quick fixes typically take 1-2 hours, while more complex repairs may take 24-48 hours. Emergency repairs are handled within 15-20 minutes.',
      },
      {
        'question': 'Can I cancel or reschedule a booking?',
        'answer':
            'Yes, you can cancel or reschedule your booking from the Bookings screen. Please note that cancellations within 2 hours of the scheduled time may incur a fee.',
      },
      {
        'question': 'Are the technicians certified?',
        'answer':
            'Yes, all technicians on our platform are verified and certified professionals. You can view their ratings and reviews before booking.',
      },
      {
        'question': 'What if I\'m not satisfied with the service?',
        'answer':
            'If you\'re not satisfied with the service, please contact our support team within 24 hours. We offer a satisfaction guarantee and will work to resolve any issues.',
      },
    ];

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
          'FAQs',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              children: [
                Text(
                  faq['answer']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
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

class _UserGuideScreen extends StatelessWidget {
  const _UserGuideScreen();

  @override
  Widget build(BuildContext context) {
    final sections = [
      _GuideSection(
        icon: Icons.app_registration,
        title: 'Getting Started',
        steps: [
          'Download and open the FixIt app.',
          'Create an account using your email or sign up with Google.',
          'Complete your profile by adding your name, phone number, and address.',
          'You\'re all set to book your first repair!',
        ],
      ),
      _GuideSection(
        icon: Icons.calendar_month,
        title: 'Booking a Repair',
        steps: [
          'Tap "Book a Repair" or "Emergency Repair" on the home screen.',
          'Select the type of damage(s) your device has.',
          'Provide your device details (brand, model, description).',
          'Choose your preferred schedule date and time.',
          'Add your address or use your current location.',
          'Review and confirm your booking.',
        ],
      ),
      _GuideSection(
        icon: Icons.payment,
        title: 'Making a Payment',
        steps: [
          'Once your booking is accepted and in progress, a "Pay Now" button will appear.',
          'Tap "Pay Now" to view the admin\'s GCash QR code.',
          'Scan the QR code using your GCash app and send the payment.',
          'Fill in the reference number, sender name, and amount.',
          'Upload a screenshot of your payment proof.',
          'Tap "Submit Payment" and wait for admin verification.',
        ],
      ),
      _GuideSection(
        icon: Icons.track_changes,
        title: 'Tracking Your Booking',
        steps: [
          'Go to the "Bookings" tab to see all your bookings.',
          'Active bookings show real-time status updates.',
          'You\'ll see payment status: "Pay Now", "Waiting for Verification", or "Payment Completed".',
          'Tap on any booking to view full details.',
        ],
      ),
      _GuideSection(
        icon: Icons.star,
        title: 'Rating & Reviews',
        steps: [
          'After your repair is completed, you can rate your technician.',
          'Give a star rating (1-5) and leave a written review.',
          'Your feedback helps other customers choose the right technician.',
        ],
      ),
      _GuideSection(
        icon: Icons.support_agent,
        title: 'Getting Help',
        steps: [
          'Go to Help & Support from your profile or bottom navigation.',
          'Submit a support ticket for any issues.',
          'Track your ticket status in "My Tickets".',
          'Check FAQs for quick answers to common questions.',
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
          'User Guide',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
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
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.deepBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section.steps[i],
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                              height: 1.4,
                            ),
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

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.steps,
  });
}

class _VideoTutorialsScreen extends StatelessWidget {
  const _VideoTutorialsScreen();

  @override
  Widget build(BuildContext context) {
    final tutorials = [
      _VideoTutorial(
        icon: Icons.play_circle_fill,
        title: 'How to Create an Account',
        duration: '2:30',
        description: 'Learn how to sign up and set up your FixIt profile step by step.',
        color: AppTheme.deepBlue,
      ),
      _VideoTutorial(
        icon: Icons.play_circle_fill,
        title: 'Booking Your First Repair',
        duration: '3:45',
        description: 'A complete walkthrough of how to book a repair service on FixIt.',
        color: AppTheme.primaryCyan,
      ),
      _VideoTutorial(
        icon: Icons.play_circle_fill,
        title: 'How to Pay via GCash',
        duration: '2:15',
        description: 'Step-by-step guide on making payments through GCash QR code.',
        color: Colors.blue,
      ),
      _VideoTutorial(
        icon: Icons.play_circle_fill,
        title: 'Tracking Your Booking Status',
        duration: '1:50',
        description: 'Learn how to check booking progress and payment verification status.',
        color: AppTheme.lightBlue,
      ),
      _VideoTutorial(
        icon: Icons.play_circle_fill,
        title: 'Rating Your Technician',
        duration: '1:30',
        description: 'How to leave a rating and review after your repair is completed.',
        color: Colors.amber.shade700,
      ),
      _VideoTutorial(
        icon: Icons.play_circle_fill,
        title: 'Submitting a Support Ticket',
        duration: '2:00',
        description: 'Need help? Learn how to submit and track support tickets.',
        color: AppTheme.errorColor,
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
          'Video Tutorials',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
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
                  SnackBar(
                    content: Text('Playing: ${tutorial.title}'),
                    backgroundColor: AppTheme.deepBlue,
                  ),
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
                      child: Icon(
                        tutorial.icon,
                        color: tutorial.color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tutorial.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tutorial.description,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tutorial.duration,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
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

  const _VideoTutorial({
    required this.icon,
    required this.title,
    required this.duration,
    required this.description,
    required this.color,
  });
}

class _FeedbackFormScreen extends StatefulWidget {
  final String type; // 'feedback' or 'bug_report'
  final WidgetRef ref;

  const _FeedbackFormScreen({required this.type, required this.ref});

  @override
  State<_FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<_FeedbackFormScreen> {
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
          content: Text(_isFeedback
              ? 'Please write your feedback before submitting'
              : 'Please describe the bug before submitting'),
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
          content: Text(_isFeedback
              ? 'Thank you for your feedback!'
              : 'Bug report submitted! We\'ll look into it.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
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
        title: Text(
          _title,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentColor,
                    _accentColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating section (only for feedback)
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
                    const Text(
                      'How would you rate your experience?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Optional - tap a star to rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRating =
                                  _selectedRating == starIndex ? 0 : starIndex;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              starIndex <= _selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 40,
                              color: starIndex <= _selectedRating
                                  ? Colors.amber
                                  : Colors.grey.shade300,
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
                            1 => 'Poor',
                            2 => 'Fair',
                            3 => 'Good',
                            4 => 'Great',
                            5 => 'Excellent',
                            _ => '',
                          },
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Message section
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
                      Icon(
                        _isFeedback ? Icons.edit_note : Icons.description_outlined,
                        size: 20,
                        color: _accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFeedback ? 'Your Feedback' : 'Bug Description',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
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
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accentColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),

            if (!_isFeedback) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Include steps to reproduce the bug for faster resolution.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(_isFeedback ? Icons.send : Icons.bug_report, size: 20),
                label: Text(
                  _submitting
                      ? 'Submitting...'
                      : (_isFeedback ? 'Send Feedback' : 'Submit Bug Report'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accentColor.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
