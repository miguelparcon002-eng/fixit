import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/support_ticket_model.dart';
import '../../providers/support_ticket_provider.dart';
import '../../core/widgets/app_logo.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  String _selectedPriority = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Reload tickets when screen is opened
    Future.microtask(() {
      ref.read(supportTicketsProvider.notifier).reload();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<SupportTicket> getFilteredTickets(List<SupportTicket> tickets) {
    return tickets.where((ticket) {
      // Filter by status tab
      bool matchesTab = true;
      switch (_tabController.index) {
        case 0: // All
          matchesTab = true;
          break;
        case 1: // Open
          matchesTab = ticket.status == 'open';
          break;
        case 2: // In Progress
          matchesTab = ticket.status == 'in_progress';
          break;
        case 3: // Resolved
          matchesTab = ticket.status == 'resolved' || ticket.status == 'closed';
          break;
      }

      // Filter by category
      bool matchesCategory =
          _selectedFilter == 'all' || ticket.category == _selectedFilter;

      // Filter by priority
      bool matchesPriority =
          _selectedPriority == 'all' || ticket.priority == _selectedPriority;

      return matchesTab && matchesCategory && matchesPriority;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportTicketsProvider);
    final openCount = ref.watch(openTicketsCountProvider);
    final inProgressCount = ref.watch(inProgressTicketsCountProvider);
    final resolvedCount = ref.watch(resolvedTicketsCountProvider);
    final filteredTickets = getFilteredTickets(tickets);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin-home'),
        ),
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 30, showText: false, assetPath: 'assets/images/logo_square.png'),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Customer Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(supportTicketsProvider.notifier).reload();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing tickets...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatBadge(
                  label: 'Open',
                  count: openCount,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatBadge(
                  label: 'In Progress',
                  count: inProgressCount,
                  color: AppTheme.lightBlue,
                ),
                const SizedBox(width: 12),
                _StatBadge(
                  label: 'Resolved',
                  count: resolvedCount,
                  color: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              indicator: BoxDecoration(
                color: AppTheme.deepBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Open'),
                Tab(text: 'Progress'),
                Tab(text: 'Resolved'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tickets List
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: filteredTickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.support_agent,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No support tickets yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Customer tickets will appear here\nwhen they submit issues',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = filteredTickets[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TicketCard(
                            ticket: ticket,
                            onTap: () => _openTicketDetail(ticket),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Tickets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedFilter = 'all';
                        _selectedPriority = 'all';
                      });
                      setState(() {});
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'all',
                    onTap: () {
                      setModalState(() => _selectedFilter = 'all');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'Booking Issue',
                    isSelected: _selectedFilter == 'booking_issue',
                    onTap: () {
                      setModalState(() => _selectedFilter = 'booking_issue');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'Payment',
                    isSelected: _selectedFilter == 'payment_issue',
                    onTap: () {
                      setModalState(() => _selectedFilter = 'payment_issue');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'Technician',
                    isSelected: _selectedFilter == 'technician_complaint',
                    onTap: () {
                      setModalState(
                        () => _selectedFilter = 'technician_complaint',
                      );
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'App Bug',
                    isSelected: _selectedFilter == 'app_bug',
                    onTap: () {
                      setModalState(() => _selectedFilter = 'app_bug');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'Other',
                    isSelected: _selectedFilter == 'other',
                    onTap: () {
                      setModalState(() => _selectedFilter = 'other');
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Priority',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedPriority == 'all',
                    onTap: () {
                      setModalState(() => _selectedPriority = 'all');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'Urgent',
                    isSelected: _selectedPriority == 'urgent',
                    color: Colors.red,
                    onTap: () {
                      setModalState(() => _selectedPriority = 'urgent');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'High',
                    isSelected: _selectedPriority == 'high',
                    color: Colors.orange,
                    onTap: () {
                      setModalState(() => _selectedPriority = 'high');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'Medium',
                    isSelected: _selectedPriority == 'medium',
                    color: Colors.amber,
                    onTap: () {
                      setModalState(() => _selectedPriority = 'medium');
                      setState(() {});
                    },
                  ),
                  _FilterChip(
                    label: 'Low',
                    isSelected: _selectedPriority == 'low',
                    color: Colors.green,
                    onTap: () {
                      setModalState(() => _selectedPriority = 'low');
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTicketDetail(SupportTicket ticket) {
    context.push('/admin-support/${ticket.id}');
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
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

  Color get priorityColor {
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

  Color get statusColor {
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

  IconData get categoryIcon {
    switch (ticket.category) {
      case 'booking_issue':
        return Icons.calendar_today;
      case 'payment_issue':
        return Icons.payment;
      case 'technician_complaint':
        return Icons.engineering;
      case 'app_bug':
        return Icons.bug_report;
      default:
        return Icons.help_outline;
    }
  }

  String get categoryLabel {
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

  String get timeAgo {
    final diff = DateTime.now().difference(ticket.createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ticket.status == 'open' && ticket.priority == 'urgent'
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: ticket.status == 'open' && ticket.priority == 'urgent' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(categoryIcon, color: priorityColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.id,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.subject,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.status.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        ticket.customerName.isNotEmpty
                            ? ticket.customerName[0]
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticket.customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        ticket.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ticket.bookingId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Booking: ${ticket.bookingId}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      categoryLabel,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    if (ticket.messages.isNotEmpty) ...[
                      const Spacer(),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.messages.length} message${ticket.messages.length > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.deepBlue)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.deepBlue)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
