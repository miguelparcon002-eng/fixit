import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class LiveChatScreen extends ConsumerStatefulWidget {
  const LiveChatScreen({super.key});

  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showQuickChats = true;

  final List<String> _quickChats = [
    'How do I book a repair?',
    'What are your service hours?',
    'Track my booking',
    'Cancel my appointment',
    'Payment methods',
    'Technician availability',
    'Service pricing',
    'How to use rewards points?',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Hello! Welcome to FixIT Support. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _showQuickChats = false;
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response with delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final response = _getAIResponse(text);

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  String _getAIResponse(String message) {
    final msg = message.toLowerCase();

    // Greetings
    if (msg.contains('hi') || msg.contains('hello') || msg.contains('hey') || msg.contains('good morning') || msg.contains('good afternoon')) {
      return 'Hello! 👋 Welcome to FixIt Support. I\'m here to help you with bookings, payments, rewards, and more. What can I assist you with today?';
    }

    // Booking
    if (msg.contains('book') || msg.contains('appointment') || msg.contains('schedule') || msg.contains('repair')) {
      return 'To book a repair service:\n\n1. Tap the Home tab\n2. Choose a service type:\n   • 🚨 Emergency — within 1 hour\n   • ⚡ Same Day — within the day\n   • 📅 Scheduled — pick a date & time\n3. Select your device and describe the issue\n4. Choose a payment method (GCash)\n5. Confirm your booking\n\nYou\'ll receive a confirmation notification once a technician accepts. Need help with a specific step?';
    }

    // Tracking / Status
    if (msg.contains('track') || msg.contains('status') || msg.contains('where is') || msg.contains('my booking') || msg.contains('my order')) {
      return 'To track your booking:\n\n1. Tap the Bookings tab (bottom nav)\n2. Select your active booking\n3. View the current status:\n   • Pending → Accepted → In Progress → Completed\n\nYou\'ll also get push notifications at every status change. Is there a specific booking you need help with?';
    }

    // Cancel / Reschedule
    if (msg.contains('cancel') || msg.contains('reschedule') || msg.contains('change') && msg.contains('booking')) {
      return 'To cancel or reschedule a booking:\n\n1. Go to the Bookings tab\n2. Tap the booking you want to change\n3. Select "Cancel Booking" or contact your technician via chat\n\n⚠️ Note: Cancellations should be made as early as possible to avoid inconveniencing your assigned technician.\n\nNeed help with a specific booking?';
    }

    // Payment
    if (msg.contains('payment') || msg.contains('pay') || msg.contains('gcash') || msg.contains('how to pay')) {
      return 'FixIt currently accepts:\n\n📱 GCash — scan the QR code provided at checkout and upload your payment screenshot as proof\n\nPayment steps:\n1. Complete your booking\n2. Scan the GCash QR on the payment screen\n3. Upload a screenshot of your transaction\n4. Wait for admin confirmation\n\nHaving trouble with a payment? Let me know!';
    }

    // Pricing
    if (msg.contains('price') || msg.contains('pricing') || msg.contains('how much') || msg.contains('cost') || msg.contains('fee')) {
      return 'Pricing depends on the device and issue:\n\n📱 Phone Repair: ₱300–₱2,500\n💻 Laptop Repair: ₱500–₱5,500\n🔋 Battery Replacement: ₱400–₱1,200\n💾 Data Recovery: ₱1,000–₱3,000\n🔧 Hardware Upgrade: ₱1,500–₱5,500\n\nA diagnostic fee (₱300–₱800) applies and is waived if you proceed with the repair. Final cost is confirmed after diagnosis.';
    }

    // Rewards / Points / Vouchers
    if (msg.contains('reward') || msg.contains('point') || msg.contains('voucher') || msg.contains('promo') || msg.contains('discount')) {
      return 'FixIt Rewards Program:\n\n⭐ Earn 1 point for every ₱50 spent\n🎁 Redeem points for discount vouchers\n🎉 First-time users get a welcome bonus\n\nHow to redeem:\n1. Go to Profile → Rewards\n2. Choose a voucher to redeem\n3. Apply the voucher code at checkout\n\nVouchers are valid for 30 days after redemption. Check your current points in the Rewards section!';
    }

    // Technician
    if (msg.contains('technician') || msg.contains('mechanic') || msg.contains('who will') || msg.contains('qualified') || msg.contains('verified')) {
      return 'All FixIt technicians go through a strict verification process:\n\n✅ Government ID verified\n✅ Professional credentials checked\n✅ Background screening\n✅ Rated by real customers after every job\n\nYou can view a technician\'s profile, ratings, and completed jobs before and after they accept your booking. Only verified technicians can take jobs on FixIt.';
    }

    // Support ticket
    if (msg.contains('ticket') || msg.contains('report') || msg.contains('complaint') || msg.contains('issue') || msg.contains('problem')) {
      return 'For formal concerns, you can submit a support ticket:\n\n1. Go to Profile → Help & Support\n2. Tap "Submit a Ticket"\n3. Describe your issue in detail\n4. Our team will respond within 24 hours\n\nFor urgent issues, keep chatting here and I\'ll do my best to help right away!';
    }

    // Verification (technician asking)
    if (msg.contains('verif') || msg.contains('apply') || msg.contains('become a technician') || msg.contains('join')) {
      return 'To become a verified FixIt technician:\n\n1. Sign up and select the Technician role\n2. Go to Profile → Submit Verification\n3. Upload your valid government ID and credentials\n4. Wait for admin review (usually within 1–2 business days)\n\nOnce approved, you can start accepting repair jobs. Need help with your verification submission?';
    }

    // Notifications
    if (msg.contains('notification') || msg.contains('alert') || msg.contains('push')) {
      return 'To manage your notifications:\n\n1. Go to Profile → Notification Settings\n2. Toggle the alerts you want to receive:\n   • Booking updates\n   • Payment confirmations\n   • Promotions & rewards\n\nMake sure notifications are also enabled in your phone\'s system settings for the FixIt app.';
    }

    // Thanks
    if (msg.contains('thank') || msg.contains('thanks') || msg.contains('appreciate')) {
      return 'You\'re welcome! 😊 Don\'t hesitate to reach out if you need anything else. Have a great day!';
    }

    // Hours / Availability
    if (msg.contains('hour') || msg.contains('open') || msg.contains('available') || msg.contains('operating')) {
      return 'FixIt service availability:\n\n🚨 Emergency Repairs: 24/7\n⚡ Same-Day Repairs: 7:00 AM – 9:00 PM daily\n📅 Scheduled Repairs: 8:00 AM – 6:00 PM daily\n💬 Live Chat Support: 24/7\n\nService availability may vary by technician location. Is there anything else I can help you with?';
    }

    // Fallback
    return 'Thanks for reaching out! I can help you with:\n\n• 📅 Booking a repair\n• 🔍 Tracking your appointment\n• 💳 Payment & pricing\n• ⭐ Rewards & vouchers\n• 👨‍🔧 Technician information\n• 🎫 Submitting a support ticket\n\nCould you tell me more about what you need? Or tap one of the Quick Questions below to get started.';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.deepBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FixIt Support',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: const Text('Send Attachment'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attachment feature coming soon')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.red),
                        title: const Text('Block', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support blocked')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),

          // Quick chat options
          if (_showQuickChats && _messages.length <= 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Questions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickChats.map((chat) {
                      return _QuickChatChip(
                        label: chat,
                        onTap: () => _sendMessage(chat),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  // Attachment Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: AppTheme.deepBlue, size: 24),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Send Attachment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _AttachmentOption(
                                      icon: Icons.photo,
                                      label: 'Photo',
                                      color: Colors.purple,
                                      onTap: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Photo upload coming soon')),
                                        );
                                      },
                                    ),
                                    _AttachmentOption(
                                      icon: Icons.insert_drive_file,
                                      label: 'File',
                                      color: Colors.blue,
                                      onTap: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('File upload coming soon')),
                                        );
                                      },
                                    ),
                                    _AttachmentOption(
                                      icon: Icons.location_on,
                                      label: 'Location',
                                      color: Colors.red,
                                      onTap: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Location sharing coming soon')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (text) => _sendMessage(text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.deepBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_messageController.text),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypingDot(delay: 0),
            const SizedBox(width: 4),
            _TypingDot(delay: 200),
            const SizedBox(width: 4),
            _TypingDot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.deepBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTheme.deepBlue
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.black54,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChatChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChatChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.deepBlue, width: 1.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepBlue,
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
