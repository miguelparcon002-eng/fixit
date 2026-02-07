import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  int? _expandedIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(String text) {
    if (_searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppLogo(size: 48),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, size: 28, color: Colors.black),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ask any question regarding to our business',
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for help...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.black54),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Contact Us Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Contact Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_matchesSearch('Live Chat') || _matchesSearch('Chat') || _matchesSearch('support'))
                      _LiveChatOption(
                        onTap: () {
                          context.push('/live-chat');
                        },
                      ),
                    if (_matchesSearch('Live Chat') || _matchesSearch('Chat') || _matchesSearch('support'))
                      const SizedBox(height: 12),
                    if (_matchesSearch('Call Support') || _matchesSearch('Phone') || _matchesSearch('Call') || _matchesSearch('technician'))
                      _ContactOption(
                        icon: Icons.phone,
                        iconColor: AppTheme.lightBlue,
                        iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.15),
                        title: 'Call Support',
                        subtitle: 'Speak with a technician',
                        statusText: '24/7 Available',
                        statusColor: AppTheme.lightBlue,
                        onTap: () async {
                          final Uri phoneUri = Uri(scheme: 'tel', path: '+639171234567');
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open dialer')),
                              );
                            }
                          }
                        },
                      ),
                    if (_matchesSearch('Call Support') || _matchesSearch('Phone') || _matchesSearch('Call') || _matchesSearch('technician'))
                      const SizedBox(height: 12),
                    if (_matchesSearch('Email Support') || _matchesSearch('Email') || _matchesSearch('questions'))
                      _ContactOption(
                        icon: Icons.email,
                        iconColor: Colors.purple,
                        iconBgColor: Colors.purple.withValues(alpha: 0.15),
                        title: 'Email Support',
                        subtitle: 'Send us your questions',
                        statusText: 'Response in 2 hrs',
                        statusColor: Colors.purple,
                        onTap: () async {
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'support@fixit.com',
                            queryParameters: {'subject': 'FixIT Support Request'},
                          );
                          if (await canLaunchUrl(emailUri)) {
                            await launchUrl(emailUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open email client')),
                              );
                            }
                          }
                        },
                      ),
                    if (_matchesSearch('Email Support') || _matchesSearch('Email') || _matchesSearch('questions'))
                      const SizedBox(height: 12),
                    if (_matchesSearch('Help Center') || _matchesSearch('Help') || _matchesSearch('FAQs') || _matchesSearch('guides'))
                      _ContactOption(
                        icon: Icons.help_center,
                        iconColor: Colors.orange,
                        iconBgColor: Colors.orange.withValues(alpha: 0.15),
                        title: 'Help Center',
                        subtitle: 'Browse FAQs and guides',
                        statusText: 'Explore Resources',
                        statusColor: Colors.orange,
                        onTap: () {
                          context.push('/help-support');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // FAQ Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // FAQ List
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_matchesSearch('How long do repairs') || _matchesSearch('repair time') || _matchesSearch('take') || _matchesSearch('quick fixes'))
                      _FAQItem(
                        question: 'How long do repairs typically take?',
                        answer: 'Hi! the repair time depends on the issue on your device\n\n• Quick fixes: 30 mins – 2 hrs\n• Standard: 2 – 24 hrs\n• Complex: 1 – 5 days',
                        isExpanded: _expandedIndex == 0,
                        onTap: () => setState(() => _expandedIndex = _expandedIndex == 0 ? null : 0),
                      ),
                    if (_matchesSearch('How long do repairs') || _matchesSearch('repair time') || _matchesSearch('take') || _matchesSearch('quick fixes'))
                      const Divider(height: 1),
                    if (_matchesSearch('What devices') || _matchesSearch('devices') || _matchesSearch('repair') || _matchesSearch('smartphones') || _matchesSearch('tablets') || _matchesSearch('laptops'))
                      _FAQItem(
                        question: 'What devices do you repair?',
                        answer: 'We repair smartphones, tablets, laptops, desktops, and other electronic devices.',
                        isExpanded: _expandedIndex == 1,
                        onTap: () => setState(() => _expandedIndex = _expandedIndex == 1 ? null : 1),
                      ),
                    if (_matchesSearch('What devices') || _matchesSearch('devices') || _matchesSearch('repair') || _matchesSearch('smartphones') || _matchesSearch('tablets') || _matchesSearch('laptops'))
                      const Divider(height: 1),
                    if (_matchesSearch('How much') || _matchesSearch('cost') || _matchesSearch('price') || _matchesSearch('quote'))
                      _FAQItem(
                        question: 'How much do repairs cost?',
                        answer: 'Repair costs vary depending on the device and issue. Contact us for a quote.',
                        isExpanded: _expandedIndex == 2,
                        onTap: () => setState(() => _expandedIndex = _expandedIndex == 2 ? null : 2),
                      ),
                    if (_matchesSearch('How much') || _matchesSearch('cost') || _matchesSearch('price') || _matchesSearch('quote'))
                      const Divider(height: 1),
                    if (_matchesSearch('track') || _matchesSearch('status') || _matchesSearch('appointments'))
                      _FAQItem(
                        question: 'Can I track my repair status?',
                        answer: 'Yes! You can track your repair status in the Appointments section.',
                        isExpanded: _expandedIndex == 3,
                        onTap: () => setState(() => _expandedIndex = _expandedIndex == 3 ? null : 3),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveChatOption extends StatelessWidget {
  final VoidCallback onTap;

  const _LiveChatOption({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.deepBlue,
                AppTheme.lightBlue,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: AppTheme.deepBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Chat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chat with our support team',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.greenAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Available Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
        ),
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FAQItem({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
