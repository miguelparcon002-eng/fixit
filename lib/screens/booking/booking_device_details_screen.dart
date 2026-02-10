import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/booking_notes_parser.dart';
import '../../providers/booking_provider.dart';

class BookingDeviceDetailsScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDeviceDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return bookingsAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Device Details',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Device Details',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(child: Text('Error: $error')),
      ),
      data: (bookings) {
        final booking = bookings.where((b) => b.id == bookingId).firstOrNull;
        if (booking == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF5F7FA),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Not Found',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: const Center(child: Text('Booking not found')),
          );
        }

        final parsed = parseBookingNotes(booking.diagnosticNotes);
        final copyText = parsed.toPrettyText();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F7FA),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Device Details',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy, color: Colors.black),
                onPressed: copyText.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: copyText));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Device details copied')),
                        );
                      },
              ),
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: copyText.isEmpty
                    ? null
                    : () => Share.share(copyText, subject: 'FixIt booking device details'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Overview',
                  children: [
                    _InfoTile(icon: Icons.devices, label: 'Device', value: parsed.device ?? 'Not specified'),
                    const SizedBox(height: 12),
                    _InfoTile(icon: Icons.phone_iphone, label: 'Model', value: parsed.model ?? 'Not specified'),
                    const SizedBox(height: 12),
                    _InfoTile(icon: Icons.report_problem_outlined, label: 'Problem', value: parsed.problem ?? 'Not specified'),
                  ],
                ),
                const SizedBox(height: 16),
                if ((parsed.details ?? '').trim().isNotEmpty)
                  _SectionCard(
                    title: 'Customer Notes',
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          parsed.details!.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                if ((parsed.details ?? '').trim().isNotEmpty) const SizedBox(height: 16),
                if ((parsed.promoCode ?? '').trim().isNotEmpty || (parsed.discount ?? '').trim().isNotEmpty)
                  _SectionCard(
                    title: 'Promo / Discount',
                    children: [
                      if ((parsed.promoCode ?? '').trim().isNotEmpty)
                        _InfoTile(icon: Icons.local_offer_outlined, label: 'Promo Code', value: parsed.promoCode!),
                      if ((parsed.promoCode ?? '').trim().isNotEmpty && (parsed.discount ?? '').trim().isNotEmpty)
                        const SizedBox(height: 12),
                      if ((parsed.discount ?? '').trim().isNotEmpty)
                        _InfoTile(icon: Icons.percent, label: 'Discount', value: parsed.discount!),
                      if ((parsed.originalPrice ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _InfoTile(icon: Icons.payments_outlined, label: 'Original Price', value: parsed.originalPrice!),
                      ],
                    ],
                  ),
                if ((parsed.promoCode ?? '').trim().isNotEmpty || (parsed.discount ?? '').trim().isNotEmpty)
                  const SizedBox(height: 16),

                _SectionCard(
                  title: 'Raw Booking Notes',
                  children: [
                    _RawNotesBox(text: booking.diagnosticNotes ?? ''),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.deepBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RawNotesBox extends StatefulWidget {
  final String text;
  const _RawNotesBox({required this.text});

  @override
  State<_RawNotesBox> createState() => _RawNotesBoxState();
}

class _RawNotesBoxState extends State<_RawNotesBox> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.text.trim();
    final hasText = t.isNotEmpty;
    if (!hasText) {
      return Text(
        'No notes provided.',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            expanded ? t : _collapse(t),
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey[800]),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => expanded = !expanded),
          child: Text(expanded ? 'Show less' : 'Show more'),
        ),
      ],
    );
  }

  String _collapse(String input) {
    final lines = input.split('\n');
    if (lines.length <= 6) return input;
    return [...lines.take(6), '…'].join('\n');
  }
}
