import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../models/support_ticket_model.dart';

class SubmitSupportTicketScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  const SubmitSupportTicketScreen({super.key, this.bookingId});

  @override
  ConsumerState<SubmitSupportTicketScreen> createState() =>
      _SubmitSupportTicketScreenState();
}

class _SubmitSupportTicketScreenState
    extends ConsumerState<SubmitSupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'booking_issue';
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  static const _categories = [
    {
      'value': 'booking_issue',
      'label': 'Booking Issue',
      'icon': Icons.calendar_today_rounded,
      'description': 'Scheduling, cancellations, or appointments',
    },
    {
      'value': 'payment_issue',
      'label': 'Payment Issue',
      'icon': Icons.payment_rounded,
      'description': 'Billing errors, refunds, or payment processing',
    },
    {
      'value': 'technician_complaint',
      'label': 'Technician Complaint',
      'icon': Icons.engineering_rounded,
      'description': 'Technician service, behavior, or quality',
    },
    {
      'value': 'app_bug',
      'label': 'App Bug / Technical Issue',
      'icon': Icons.bug_report_rounded,
      'description': 'App crashes, errors, or technical problems',
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.help_outline_rounded,
      'description': 'General inquiries or other issues',
    },
  ];

  static const _priorities = [
    {
      'value': 'low',
      'label': 'Low',
      'icon': Icons.arrow_downward_rounded,
      'color': Colors.green,
      'description': 'General inquiry, not urgent',
    },
    {
      'value': 'medium',
      'label': 'Medium',
      'icon': Icons.remove_rounded,
      'color': Colors.amber,
      'description': 'Affecting my experience',
    },
    {
      'value': 'high',
      'label': 'High',
      'icon': Icons.arrow_upward_rounded,
      'color': Colors.orange,
      'description': 'Needs quick resolution',
    },
    {
      'value': 'urgent',
      'label': 'Urgent',
      'icon': Icons.priority_high_rounded,
      'color': Colors.red,
      'description': 'Immediate attention needed',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _subjectController.text = 'Issue with booking ${widget.bookingId}';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit a ticket'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ticketId = 'TKT-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      final ticket = SupportTicket(
        id: ticketId,
        customerId: user.id,
        customerName: user.fullName,
        customerEmail: user.email,
        customerPhone: user.contactNumber,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        status: 'open',
        bookingId: widget.bookingId,
        createdAt: DateTime.now(),
        messages: [
          TicketMessage(
            id: 'msg_${const Uuid().v4().substring(0, 8)}',
            ticketId: ticketId,
            senderId: user.id,
            senderName: user.fullName,
            senderRole: 'customer',
            message: _descriptionController.text.trim(),
            createdAt: DateTime.now(),
          ),
        ],
      );

      await ref.read(supportTicketsProvider.notifier).createTicket(ticket);

      if (mounted) {
        _showSuccessDialog(ticketId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ticket. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String ticketId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ticket Submitted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticketId,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepBlue,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Our support team will review your request and respond within 24–48 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

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
          'Report an Issue',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User card
              _UserInfoCard(user: user),
              const SizedBox(height: 20),

              // Category section
              _SectionLabel(label: 'What type of issue?'),
              const SizedBox(height: 10),
              ..._categories.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CategoryOption(
                      icon: c['icon'] as IconData,
                      label: c['label'] as String,
                      description: c['description'] as String,
                      isSelected: _selectedCategory == c['value'],
                      onTap: () => setState(() => _selectedCategory = c['value'] as String),
                    ),
                  )),
              const SizedBox(height: 20),

              // Priority section
              _SectionLabel(label: 'How urgent is this?'),
              const SizedBox(height: 10),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _selectedPriority == p['value'];
                  final color = p['color'] as Color;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = p['value'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(
                          right: p != _priorities.last ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              p['icon'] as IconData,
                              color: isSelected ? color : Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? color : AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Subject field
              _SectionLabel(label: 'Subject'),
              const SizedBox(height: 10),
              _ModernField(
                controller: _subjectController,
                hint: 'Brief summary of the issue',
                icon: Icons.subject_rounded,
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a subject' : null,
              ),
              const SizedBox(height: 16),

              // Description field
              _SectionLabel(label: 'Description'),
              const SizedBox(height: 10),
              _ModernField(
                controller: _descriptionController,
                hint: 'Describe your issue in detail — include booking IDs, dates, or error messages if relevant.',
                icon: Icons.notes_rounded,
                maxLines: 5,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please describe your issue';
                  if (v.length < 10) return 'Please provide more details (at least 10 characters)';
                  return null;
                },
              ),

              // Booking ID tag
              if (widget.bookingId != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_rounded, color: AppTheme.lightBlue, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Related Booking: ${widget.bookingId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.lightBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.deepBlue, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Our support team typically responds within 24–48 hours. For urgent issues, select "Urgent" priority.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}

// ─── User Info Card ─────────────────────────────────────────────────────────

class _UserInfoCard extends StatelessWidget {
  final dynamic user;
  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Customer';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.lightBlue, AppTheme.deepBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'VERIFIED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modern Text Field ───────────────────────────────────────────────────────

class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ModernField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

// ─── Category Option ─────────────────────────────────────────────────────────

class _CategoryOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.deepBlue.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.deepBlue.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.deepBlue : Colors.grey.shade500,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.deepBlue : AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.deepBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
