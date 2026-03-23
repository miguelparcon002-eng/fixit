import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../services/payment_service.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _allPayments = [];
  bool _loading = true;
  String _jobFilter = 'all';
  String _feeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final payments = await PaymentService.getAllPayments();
      if (!mounted) return;
      setState(() {
        _allPayments = payments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isCancellationFee(Map<String, dynamic> p) {
    // Primary: payment_type column (requires SQL migration).
    final pType = p['payment_type'] as String?;
    if (pType == 'cancellation_fee') return true;
    // Fallback: booking status join.
    final bStatus =
        (p['bookings'] as Map<String, dynamic>?)?['status'] as String?;
    return bStatus == 'cancelled';
  }

  List<Map<String, dynamic>> get _jobPayments =>
      _allPayments.where((p) => !_isCancellationFee(p)).toList();

  List<Map<String, dynamic>> get _cancellationFees =>
      _allPayments.where(_isCancellationFee).toList();

  List<Map<String, dynamic>> _filtered(
      List<Map<String, dynamic>> list, String filter) {
    if (filter == 'all') return list;
    return list.where((p) => p['status'] == filter).toList();
  }

  int _pendingCount(List<Map<String, dynamic>> list) =>
      list.where((p) => p['status'] == 'pending_verification').length;

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final jobPending = _pendingCount(_jobPayments);
    final feePending = _pendingCount(_cancellationFees);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.deepBlue,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.deepBlue,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payments_outlined, size: 17),
                  const SizedBox(width: 6),
                  const Text('Job Payments'),
                  if (jobPending > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: jobPending),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel_outlined, size: 17),
                  const SizedBox(width: 6),
                  const Text('Cancel Fees'),
                  if (feePending > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: feePending),
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
                  valueColor: AlwaysStoppedAnimation(AppTheme.deepBlue)))
          : TabBarView(
              controller: _tabController,
              children: [
                _PaymentList(
                  payments: _filtered(_jobPayments, _jobFilter),
                  allPayments: _jobPayments,
                  filterValue: _jobFilter,
                  onFilterChanged: (v) => setState(() => _jobFilter = v),
                  onRefresh: _load,
                  onVerify: _confirmPayment,
                  onReject: _showRejectDialog,
                  emptyLabel: 'No job payments yet',
                ),
                _PaymentList(
                  payments: _filtered(_cancellationFees, _feeFilter),
                  allPayments: _cancellationFees,
                  filterValue: _feeFilter,
                  onFilterChanged: (v) => setState(() => _feeFilter = v),
                  onRefresh: _load,
                  onVerify: _confirmPayment,
                  onReject: _showRejectDialog,
                  emptyLabel: 'No cancellation fees yet',
                  accentColor: Colors.red,
                ),
              ],
            ),
    );
  }

  Future<void> _confirmPayment(Map<String, dynamic> payment) async {
    final isFee = _isCancellationFee(payment);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isFee ? 'Confirm Fee Payment' : 'Confirm Payment',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '${isFee ? 'Verify cancellation fee' : 'Verify payment'} of '
          '₱${((payment['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} '
          'from ${payment['sender_name'] ?? 'Unknown'}?\n\n'
          'Ref #: ${payment['reference_number'] ?? '-'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PaymentService.updatePaymentStatus(
        paymentId: payment['id'].toString(),
        status: 'verified',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment verified!'),
            backgroundColor: Colors.green),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(Map<String, dynamic> payment) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Decline Payment',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decline ₱${((payment['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} '
              'from ${payment['sender_name'] ?? 'Unknown'}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Invalid reference number',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dctx);
              try {
                await PaymentService.updatePaymentStatus(
                  paymentId: payment['id'].toString(),
                  status: 'rejected',
                  adminNote: noteCtrl.text.trim().isNotEmpty
                      ? noteCtrl.text.trim()
                      : null,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Payment declined'),
                      backgroundColor: Colors.orange),
                );
                _load();
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable list + filter for one tab ──────────────────────────────────────

class _PaymentList extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> allPayments;
  final String filterValue;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic>) onVerify;
  final void Function(Map<String, dynamic>) onReject;
  final String emptyLabel;
  final Color accentColor;

  const _PaymentList({
    required this.payments,
    required this.allPayments,
    required this.filterValue,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onVerify,
    required this.onReject,
    required this.emptyLabel,
    this.accentColor = AppTheme.deepBlue,
  });

  int _count(String status) => status == 'all'
      ? allPayments.length
      : allPayments.where((p) => p['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                count: _count('all'),
                selected: filterValue == 'all',
                onTap: () => onFilterChanged('all'),
                color: accentColor,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pending',
                count: _count('pending_verification'),
                selected: filterValue == 'pending_verification',
                onTap: () => onFilterChanged('pending_verification'),
                color: accentColor,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Verified',
                count: _count('verified'),
                selected: filterValue == 'verified',
                onTap: () => onFilterChanged('verified'),
                color: accentColor,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Rejected',
                count: _count('rejected'),
                selected: filterValue == 'rejected',
                onTap: () => onFilterChanged('rejected'),
                color: accentColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        emptyLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: payments.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PaymentCard(
                        payment: payments[i],
                        onVerify: onVerify,
                        onReject: onReject,
                        accentColor: accentColor,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Payment card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Future<void> Function(Map<String, dynamic>) onVerify;
  final void Function(Map<String, dynamic>) onReject;
  final Color accentColor;

  const _PaymentCard({
    required this.payment,
    required this.onVerify,
    required this.onReject,
    required this.accentColor,
  });

  void _showProofImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Payment Proof',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child:
                      Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = payment['status'] as String? ?? 'pending_verification';
    final (Color sc, String sl) = switch (status) {
      'verified' => (Colors.green, 'Verified'),
      'rejected' => (Colors.red, 'Rejected'),
      _ => (Colors.orange, 'Pending'),
    };

    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = payment['created_at'] != null
        ? DateFormat('MMM dd, yyyy h:mm a')
            .format(DateTime.parse(payment['created_at']).toLocal())
        : '-';
    final bookingId = payment['booking_id'] as String? ?? '';
    final shortId = bookingId.length >= 8 ? bookingId.substring(0, 8) : bookingId;

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
              Expanded(
                child: Text(
                  'Booking #$shortId',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withValues(alpha: 0.3)),
                ),
                child: Text(
                  sl,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: sc),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _Row(Icons.person_outline, 'Sender', payment['sender_name'] ?? '-'),
          const SizedBox(height: 6),
          _Row(Icons.receipt_long, 'Reference #',
              payment['reference_number'] ?? '-'),
          const SizedBox(height: 6),
          _Row(Icons.payments_outlined, 'Amount',
              '₱${amount.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _Row(Icons.schedule, 'Submitted', createdAt),

          if (payment['admin_note'] != null &&
              (payment['admin_note'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            _Row(Icons.note_outlined, 'Note', payment['admin_note']),
          ],

          // View proof
          if (payment['proof_image_url'] != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showProofImage(context, payment['proof_image_url']),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('View Payment Proof'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.lightBlue,
                  side: BorderSide(
                      color: AppTheme.lightBlue.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          // Verify / Reject
          if (status == 'pending_verification') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReject(payment),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onVerify(payment),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondaryColor)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor)),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

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
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
