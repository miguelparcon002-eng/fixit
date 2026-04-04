import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/support_ticket_model.dart';
import '../../providers/support_ticket_provider.dart';
class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});
  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}
class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen> {
  String _selectedFilter = 'all';
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(customerTicketsProvider);
    });
  }
  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(customerTicketsProvider);
    final allTickets = ticketsAsync.valueOrNull ?? [];
    List<SupportTicket> filteredTickets;
    switch (_selectedFilter) {
      case 'open':
        filteredTickets = allTickets.where((t) => t.status == 'open').toList();
        break;
      case 'in_progress':
        filteredTickets = allTickets.where((t) => t.status == 'in_progress').toList();
        break;
      case 'resolved':
        filteredTickets = allTickets.where((t) => t.status == 'resolved' || t.status == 'closed').toList();
        break;
      default:
        filteredTickets = allTickets;
    }
    filteredTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
          'My Support Tickets',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => context.push('/submit-ticket'),
              icon: const Icon(Icons.add, size: 18, color: AppTheme.deepBlue),
              label: const Text(
                'New',
                style: TextStyle(
                  color: AppTheme.deepBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _TicketSummaryBar(tickets: allTickets),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: allTickets.length,
                    isSelected: _selectedFilter == 'all',
                    color: AppTheme.deepBlue,
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Open',
                    count: allTickets.where((t) => t.status == 'open').length,
                    isSelected: _selectedFilter == 'open',
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedFilter = 'open'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'In Progress',
                    count: allTickets.where((t) => t.status == 'in_progress').length,
                    isSelected: _selectedFilter == 'in_progress',
                    color: AppTheme.lightBlue,
                    onTap: () => setState(() => _selectedFilter = 'in_progress'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Resolved',
                    count: allTickets.where((t) => t.status == 'resolved' || t.status == 'closed').length,
                    isSelected: _selectedFilter == 'resolved',
                    color: Colors.green,
                    onTap: () => setState(() => _selectedFilter = 'resolved'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredTickets.isEmpty
                ? _EmptyState(
                    filter: _selectedFilter,
                    onNewTicket: () => context.push('/submit-ticket'),
                  )
                : RefreshIndicator(
                    color: AppTheme.deepBlue,
                    onRefresh: () async {
                      ref.invalidate(customerTicketsProvider);
                      await ref.read(customerTicketsProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filteredTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = filteredTickets[index];
                        return _TicketCard(
                          ticket: ticket,
                          onTap: () => context.push('/my-tickets/${ticket.id}'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
class _TicketSummaryBar extends StatelessWidget {
  final List<SupportTicket> tickets;
  const _TicketSummaryBar({required this.tickets});
  @override
  Widget build(BuildContext context) {
    final open = tickets.where((t) => t.status == 'open').length;
    final inProgress = tickets.where((t) => t.status == 'in_progress').length;
    final resolved = tickets.where((t) => t.status == 'resolved' || t.status == 'closed').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryItem(count: open, label: 'Open', color: Colors.orange),
          _Divider(),
          _SummaryItem(count: inProgress, label: 'Active', color: AppTheme.lightBlue),
          _Divider(),
          _SummaryItem(count: resolved, label: 'Resolved', color: Colors.green),
          _Divider(),
          _SummaryItem(count: tickets.length, label: 'Total', color: AppTheme.deepBlue),
        ],
      ),
    );
  }
}
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 32,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.grey.shade200,
      );
}
class _SummaryItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _SummaryItem({required this.count, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  final String filter;
  final VoidCallback onNewTicket;
  const _EmptyState({required this.filter, required this.onNewTicket});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.deepBlue.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 52,
                color: AppTheme.deepBlue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              filter == 'all' ? 'No tickets yet' : 'No ${filter.replaceAll('_', ' ')} tickets',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'all'
                  ? 'Have an issue? Our support team is ready to help.'
                  : 'No tickets match this filter right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
            if (filter == 'all') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onNewTicket,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Submit a Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});
  Color get _statusColor {
    switch (ticket.status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return AppTheme.lightBlue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  Color get _priorityColor {
    switch (ticket.priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  String get _categoryLabel {
    switch (ticket.category) {
      case 'booking_issue':
        return 'Booking Issue';
      case 'payment_issue':
        return 'Payment Issue';
      case 'technician_complaint':
        return 'Technician Complaint';
      case 'app_bug':
        return 'App Bug';
      default:
        return 'Other';
    }
  }
  IconData get _categoryIcon {
    switch (ticket.category) {
      case 'booking_issue':
        return Icons.calendar_today_rounded;
      case 'payment_issue':
        return Icons.payment_rounded;
      case 'technician_complaint':
        return Icons.engineering_rounded;
      case 'app_bug':
        return Icons.bug_report_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
  String get _timeAgo {
    final diff = DateTime.now().difference(ticket.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}';
  }
  int get _adminReplies =>
      ticket.messages.where((m) => m.senderRole == 'admin').length;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_categoryIcon, color: _statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.subject,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${ticket.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ticket.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TagChip(
                        label: _categoryLabel,
                        color: AppTheme.deepBlue,
                      ),
                      const SizedBox(width: 8),
                      _TagChip(
                        label: ticket.priority.toUpperCase(),
                        color: _priorityColor,
                        filled: true,
                      ),
                      const Spacer(),
                      if (_adminReplies > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.deepBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.reply_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '$_adminReplies',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textSecondaryColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _TagChip({required this.label, required this.color, this.filled = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: filled ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? color : AppTheme.textSecondaryColor,
        ),
      ),
    );
  }
}