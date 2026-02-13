import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../services/payment_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _amountController = TextEditingController();

  Map<String, dynamic>? _qrSettings;
  bool _loadingQr = true;
  XFile? _proofImage;
  bool _submitting = false;
  Map<String, dynamic>? _existingPayment;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amount.toStringAsFixed(2);
    _loadData();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _senderNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      PaymentService.getAdminQrSettings(),
      PaymentService.getPaymentForBooking(widget.bookingId),
    ]);
    if (!mounted) return;
    setState(() {
      _qrSettings = results[0];
      _existingPayment = results[1];
      _loadingQr = false;
    });
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _proofImage = image);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach your payment proof screenshot'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final userId =
          SupabaseConfig.client.auth.currentUser?.id ?? '';

      // Upload proof image
      final proofUrl = await PaymentService.uploadPaymentProof(
        bookingId: widget.bookingId,
        customerId: userId,
        imageFile: _proofImage!,
      );

      // Submit payment record
      await PaymentService.submitPayment(
        bookingId: widget.bookingId,
        customerId: userId,
        amount: double.tryParse(_amountController.text) ?? widget.amount,
        referenceNumber: _referenceController.text.trim(),
        senderName: _senderNameController.text.trim(),
        proofImageUrl: proofUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted! Waiting for admin verification.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _loadingQr
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.deepBlue)))
          : _existingPayment != null
              ? _buildExistingPaymentView()
              : _buildPaymentForm(),
    );
  }

  Future<void> _resubmitPayment() async {
    final paymentId = _existingPayment?['id']?.toString();
    if (paymentId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resubmit Payment',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'This will remove your current payment submission and let you submit a new one. Continue?',
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
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await PaymentService.deletePayment(paymentId);
      // Reset booking payment status so it shows "Pay Now" again
      await SupabaseConfig.client.from('bookings').update({
        'payment_status': 'pending',
      }).eq('id', widget.bookingId);

      if (!mounted) return;
      setState(() {
        _existingPayment = null;
        _proofImage = null;
        _referenceController.clear();
        _senderNameController.clear();
        _amountController.text = widget.amount.toStringAsFixed(2);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildExistingPaymentView() {
    final status = _existingPayment!['status'] as String? ?? 'pending';
    final (statusColor, statusLabel, statusIcon, statusMessage) = switch (status) {
      'verified' => (
          Colors.green,
          'Verified',
          Icons.check_circle,
          'Your payment has been verified by the admin.'
        ),
      'rejected' => (
          Colors.red,
          'Rejected',
          Icons.cancel,
          'Your payment was rejected. Please resubmit or contact support.'
        ),
      _ => (
          Colors.orange,
          'Pending Verification',
          Icons.hourglass_top,
          'Your payment proof has been submitted and is awaiting admin verification.'
        ),
    };

    final proofUrl = _existingPayment!['proof_image_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Icon(statusIcon, size: 52, color: statusColor),
                const SizedBox(height: 12),
                Text(
                  'Payment $statusLabel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Details',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 12),
                _buildDetailRow('Amount',
                    '₱${((_existingPayment!['amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                _buildDetailRow('Reference #',
                    _existingPayment!['reference_number'] ?? '-'),
                _buildDetailRow(
                    'Sender', _existingPayment!['sender_name'] ?? '-'),
                _buildDetailRow('Method', 'GCash'),
                if (_existingPayment!['admin_note'] != null &&
                    (_existingPayment!['admin_note'] as String).isNotEmpty)
                  _buildDetailRow(
                      'Admin Note', _existingPayment!['admin_note']),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Proof image
          if (proofUrl != null && proofUrl.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Proof',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      proofUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        height: 150,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Action buttons
          if (status != 'verified') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resubmitPayment,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(status == 'rejected'
                    ? 'Submit New Payment'
                    : 'Edit & Resubmit Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.deepBlue, AppTheme.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount to Pay',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Job #${widget.bookingId.substring(0, 8)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // GCash QR Code section
            _buildSectionLabel('GCash QR Code'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _qrSettings != null
                  ? Column(
                      children: [
                        if (_qrSettings!['qr_image_url'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _qrSettings!['qr_image_url'],
                              height: 280,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Container(
                                height: 200,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 48, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (_qrSettings!['gcash_name'] != null)
                          Text(
                            _qrSettings!['gcash_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        if (_qrSettings!['gcash_number'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _qrSettings!['gcash_number'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.lightBlue,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: _qrSettings!['gcash_number']));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('GCash number copied!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(Icons.copy,
                                    size: 16, color: AppTheme.lightBlue),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: AppTheme.lightBlue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Scan the QR code or send to the GCash number above, then fill out the form below.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.lightBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(24),
                      child: const Column(
                        children: [
                          Icon(Icons.qr_code,
                              size: 64, color: AppTheme.textSecondaryColor),
                          SizedBox(height: 12),
                          Text(
                            'QR code not yet set up by admin.\nPlease contact support.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Payment details form
            _buildSectionLabel('Payment Details'),
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
                  TextFormField(
                    controller: _senderNameController,
                    decoration: _inputDecoration(
                      label: 'GCash Sender Name',
                      hint: 'Enter the name on your GCash account',
                      icon: Icons.person_outline,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _referenceController,
                    decoration: _inputDecoration(
                      label: 'GCash Reference Number',
                      hint: 'e.g. 1234 5678 9012',
                      icon: Icons.receipt_long_outlined,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(
                      label: 'Amount Sent',
                      hint: '0.00',
                      icon: Icons.payments_outlined,
                      prefix: '₱ ',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final amount = double.tryParse(v);
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Proof of payment
            _buildSectionLabel('Proof of Payment'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickProofImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _proofImage != null
                        ? AppTheme.successColor
                        : Colors.grey.shade300,
                    width: _proofImage != null ? 2 : 1,
                  ),
                ),
                child: _proofImage != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_proofImage!.path),
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 18, color: AppTheme.successColor),
                              const SizedBox(width: 6),
                              const Text(
                                'Screenshot attached',
                                style: TextStyle(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _pickProofImage,
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: AppTheme.lightBlue,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to upload payment screenshot',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG supported',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.deepBlue.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      prefixText: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
