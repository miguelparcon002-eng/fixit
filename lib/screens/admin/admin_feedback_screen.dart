import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../services/feedback_service.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allFeedback = [];
  bool _loading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFeedback();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedback() async {
    setState(() => _loading = true);
    try {
      final data = await FeedbackService.getAllFeedback();
      if (!mounted) return;
      setState(() {
        _allFeedback = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _getFiltered(String type) {
    var items = _allFeedback.where((f) => f['type'] == type).toList();
    if (_filterStatus != 'all') {
      items = items.where((f) => f['status'] == _filterStatus).toList();
    }
    return items;
  }

  int _countByType(String type) =>
      _allFeedback.where((f) => f['type'] == type).length;

  int _countNew(String type) => _allFeedback
      .where((f) => f['type'] == type && f['status'] == 'new')
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Feedback & Bug Reports',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedback,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.deepBlue,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.deepBlue,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.feedback_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Feedback'),
                  if (_countNew('feedback') > 0) ...[
                    const SizedBox(width: 6),
                    _BadgeCount(count: _countNew('feedback')),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Bug Reports'),
                  if (_countNew('bug_report') > 0) ...[
                    const SizedBox(width: 6),
                    _BadgeCount(count: _countNew('bug_report')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.deepBlue),
              ),
            )
          : Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('New', 'new'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Reviewed', 'reviewed'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Resolved', 'resolved'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList('feedback'),
                      _buildList('bug_report'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.deepBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildList(String type) {
    final items = _getFiltered(type);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'feedback'
                  ? Icons.feedback_outlined
                  : Icons.bug_report_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              type == 'feedback' ? 'No feedback yet' : 'No bug reports yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedback,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildFeedbackCard(items[index]),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? 'feedback';
    final status = item['status'] as String? ?? 'new';
    final message = item['message'] as String? ?? '';
    final userName = item['user_name'] as String? ?? 'Unknown';
    final rating = item['rating'] as int?;
    final createdAt = item['created_at'] != null
        ? DateFormat('MMM dd, yyyy h:mm a')
            .format(DateTime.parse(item['created_at']).toLocal())
        : '-';
    final adminNote = item['admin_note'] as String?;

    final isBug = type == 'bug_report';
    final accentColor = isBug ? AppTheme.errorColor : AppTheme.primaryCyan;

    final (statusColor, statusLabel) = switch (status) {
      'reviewed' => (Colors.orange, 'Reviewed'),
      'resolved' => (AppTheme.successColor, 'Resolved'),
      _ => (AppTheme.lightBlue, 'New'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBug ? Icons.bug_report : Icons.feedback,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      createdAt,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          // Rating (if feedback with rating)
          if (rating != null && rating > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: i < rating ? Colors.amber : Colors.grey.shade300,
                ),
              ),
            ),
          ],

          // Message
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimaryColor,
                height: 1.4,
              ),
            ),
          ),

          // Admin note
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.deepBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.deepBlue.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 14, color: AppTheme.deepBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      adminNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.deepBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (status == 'new' || status == 'reviewed') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (status == 'new')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(item, 'reviewed'),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Mark Reviewed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (status == 'new') const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showResolveDialog(item),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(
      Map<String, dynamic> item, String status) async {
    try {
      await FeedbackService.updateFeedbackStatus(
        feedbackId: item['id'].toString(),
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as $status'),
          backgroundColor: AppTheme.deepBlue,
        ),
      );
      _loadFeedback();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showResolveDialog(Map<String, dynamic> item) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a note (optional):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Fixed in next update, Thank you for the feedback...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FeedbackService.updateFeedbackStatus(
                  feedbackId: item['id'].toString(),
                  status: 'resolved',
                  adminNote: noteController.text.trim().isNotEmpty
                      ? noteController.text.trim()
                      : null,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marked as resolved!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                _loadFeedback();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final int count;
  const _BadgeCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
