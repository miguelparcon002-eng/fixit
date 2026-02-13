import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/payment_service.dart';

class AdminPaymentSettingsScreen extends ConsumerStatefulWidget {
  const AdminPaymentSettingsScreen({super.key});

  @override
  ConsumerState<AdminPaymentSettingsScreen> createState() =>
      _AdminPaymentSettingsScreenState();
}

class _AdminPaymentSettingsScreenState
    extends ConsumerState<AdminPaymentSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // QR settings state
  final _gcashNameController = TextEditingController();
  final _gcashNumberController = TextEditingController();
  bool _loadingQr = true;
  bool _saving = false;
  XFile? _newQrImage;
  String? _currentQrUrl;

  // Payments list state
  List<Map<String, dynamic>> _payments = [];
  bool _loadingPayments = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gcashNameController.dispose();
    _gcashNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await PaymentService.getAdminQrSettings();
    if (!mounted) return;
    setState(() {
      if (settings != null) {
        _gcashNameController.text = settings['gcash_name'] ?? '';
        _gcashNumberController.text = settings['gcash_number'] ?? '';
        _currentQrUrl = settings['qr_image_url'];
      }
      _loadingQr = false;
    });
  }

  Future<void> _loadPayments() async {
    setState(() => _loadingPayments = true);
    try {
      final payments = await PaymentService.getAllPayments();
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _loadingPayments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPayments = false);
    }
  }

  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
    if (image != null) {
      setState(() => _newQrImage = image);
    }
  }

  Future<void> _saveSettings() async {
    final name = _gcashNameController.text.trim();
    final number = _gcashNumberController.text.trim();

    if (name.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in GCash name and number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_newQrImage == null && _currentQrUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a QR code image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String qrUrl = _currentQrUrl ?? '';

      if (_newQrImage != null) {
        final adminId = SupabaseConfig.client.auth.currentUser?.id ?? 'admin';
        qrUrl = await PaymentService.uploadAdminQrCode(
          adminId: adminId,
          imageFile: _newQrImage!,
        );
      }

      await PaymentService.saveAdminQrSettings(
        qrImageUrl: qrUrl,
        gcashName: name,
        gcashNumber: number,
      );

      if (!mounted) return;
      setState(() {
        _currentQrUrl = qrUrl;
        _newQrImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GCash settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPayments {
    if (_filterStatus == 'all') return _payments;
    return _payments.where((p) => p['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          'Payment Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.deepBlue,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.deepBlue,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 18),
                  const SizedBox(width: 6),
                  const Text('Payments'),
                  if (_payments.where((p) => p['status'] == 'pending_verification').isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_payments.where((p) => p['status'] == 'pending_verification').length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 18),
                  SizedBox(width: 6),
                  Text('QR Code'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPaymentsTab(),
          _buildQrSettingsTab(),
        ],
      ),
    );
  }

  // ─── PAYMENTS TAB ───────────────────────────────────────────────────

  Widget _buildPaymentsTab() {
    if (_loadingPayments) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.deepBlue),
        ),
      );
    }

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending_verification'),
              const SizedBox(width: 8),
              _buildFilterChip('Verified', 'verified'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _filteredPayments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No payments found',
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
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filteredPayments.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildPaymentCard(_filteredPayments[index]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    final count = status == 'all'
        ? _payments.length
        : _payments.where((p) => p['status'] == status).length;

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
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final status = payment['status'] as String? ?? 'pending_verification';
    final (statusColor, statusLabel) = switch (status) {
      'verified' => (Colors.green, 'Verified'),
      'rejected' => (Colors.red, 'Rejected'),
      _ => (Colors.orange, 'Pending'),
    };

    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = payment['created_at'] != null
        ? DateFormat('MMM dd, yyyy h:mm a')
            .format(DateTime.parse(payment['created_at']).toLocal())
        : '-';

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
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking #${(payment['booking_id'] as String? ?? '').length >= 8 ? (payment['booking_id'] as String).substring(0, 8) : payment['booking_id'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
          const SizedBox(height: 10),

          // Payment details
          _buildPaymentInfoRow(Icons.person_outline, 'Sender', payment['sender_name'] ?? '-'),
          const SizedBox(height: 6),
          _buildPaymentInfoRow(Icons.receipt_long, 'Reference #', payment['reference_number'] ?? '-'),
          const SizedBox(height: 6),
          _buildPaymentInfoRow(Icons.payments_outlined, 'Amount', '₱${amount.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _buildPaymentInfoRow(Icons.schedule, 'Submitted', createdAt),

          if (payment['admin_note'] != null && (payment['admin_note'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildPaymentInfoRow(Icons.note_outlined, 'Note', payment['admin_note']),
          ],

          // Proof image button
          if (payment['proof_image_url'] != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showProofImage(payment['proof_image_url']),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('View Payment Proof'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.lightBlue,
                  side: BorderSide(color: AppTheme.lightBlue.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],

          // Action buttons (only for pending)
          if (status == 'pending_verification') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(payment),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmPayment(payment),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildPaymentInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Payment Proof',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
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
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Verify payment of ₱${((payment['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} '
          'from ${payment['sender_name'] ?? 'Unknown'}?\n\n'
          'Ref #: ${payment['reference_number'] ?? '-'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        const SnackBar(content: Text('Payment verified!'), backgroundColor: Colors.green),
      );
      _loadPayments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(Map<String, dynamic> payment) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline Payment', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decline payment of ₱${((payment['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} '
              'from ${payment['sender_name'] ?? 'Unknown'}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Invalid reference number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await PaymentService.updatePaymentStatus(
                  paymentId: payment['id'].toString(),
                  status: 'rejected',
                  adminNote: noteController.text.trim().isNotEmpty
                      ? noteController.text.trim()
                      : null,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment declined'), backgroundColor: Colors.orange),
                );
                _loadPayments();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  // ─── QR SETTINGS TAB ───────────────────────────────────────────────

  Widget _buildQrSettingsTab() {
    if (_loadingQr) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.deepBlue),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: AppTheme.lightBlue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upload your GCash QR code so customers can pay for their bookings. This will be shown on the payment screen.',
                    style: TextStyle(fontSize: 13, color: AppTheme.lightBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionLabel('GCash QR Code'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickQrImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  if (_newQrImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_newQrImage!.path),
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                    )
                  else if (_currentQrUrl != null && _currentQrUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _currentQrUrl!,
                        height: 250,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _buildUploadPlaceholder(),
                      ),
                    )
                  else
                    _buildUploadPlaceholder(),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickQrImage,
                    icon: const Icon(Icons.upload, size: 18),
                    label: Text(
                      _currentQrUrl != null || _newQrImage != null
                          ? 'Change QR Image'
                          : 'Upload QR Image',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.deepBlue,
                      side: const BorderSide(color: AppTheme.deepBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionLabel('GCash Account Details'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _gcashNameController,
                  decoration: InputDecoration(
                    labelText: 'GCash Account Name',
                    hintText: 'e.g. Juan Dela Cruz',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _gcashNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'GCash Number',
                    hintText: 'e.g. 09171234567',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.deepBlue.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Settings',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Tap to upload QR code',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}
