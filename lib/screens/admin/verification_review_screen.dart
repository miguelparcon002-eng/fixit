import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/verification_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/verification_provider.dart';

class VerificationReviewScreen extends ConsumerWidget {
  const VerificationReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final pendingAsync = ref.watch(pendingVerificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin-home');
            }
          },
        ),
        title: const Text(
          'Verification Requests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingVerificationsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading requests:\n$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No pending verification requests',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = requests[index];
              return _VerificationCard(
                request: req,
                onTap: () async {
                  final admin = userAsync.valueOrNull;
                  if (admin == null) return;
                  if (!context.mounted) return;

                  await showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (_) => _VerificationDetailsSheet(
                      request: req,
                      adminId: admin.id,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final VerificationRequestModel request;
  final VoidCallback onTap;

  const _VerificationCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_user, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fullName ?? 'Technician',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Submitted: ${request.submittedAt.toLocal()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${request.documents.length} document(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _VerificationDetailsSheet extends ConsumerStatefulWidget {
  final VerificationRequestModel request;
  final String adminId;

  const _VerificationDetailsSheet({
    required this.request,
    required this.adminId,
  });

  @override
  ConsumerState<_VerificationDetailsSheet> createState() =>
      _VerificationDetailsSheetState();
}

class _VerificationDetailsSheetState
    extends ConsumerState<_VerificationDetailsSheet> {
  final TextEditingController _notesController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _act(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) {
        ref.invalidate(pendingVerificationsProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final service = ref.read(verificationServiceProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                req.fullName ?? 'Verification Request',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Submitted details',
                child: Column(
                  children: [
                    _Row(label: 'User ID', value: req.userId),
                    _Row(label: 'Contact', value: req.contactNumber ?? '—'),
                    _Row(label: 'Address', value: req.address ?? '—'),
                    _Row(
                      label: 'Experience',
                      value: req.yearsExperience?.toString() ?? '—',
                    ),
                    _Row(label: 'Shop', value: req.shopName ?? '—'),
                    _Row(label: 'Bio', value: req.bio ?? '—'),
                    _Row(
                      label: 'Specialties',
                      value: (req.specialties ?? const <String>[]).join(', '),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Documents',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (req.documents.isEmpty)
                      const Text(
                        'No documents',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: req.documents.map((url) {
                          return _DocThumb(url: url);
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      ...req.documents.map((url) {
                        final label = _DocThumb.labelFromUrl(url);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $label',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Admin notes (optional)',
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add notes for the technician…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _act(() => service.requestResubmission(
                                requestId: req.id,
                                adminId: widget.adminId,
                                notes: _notesController.text.trim(),
                              )),
                      child: const Text('Resubmit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _act(() => service.rejectVerification(
                                requestId: req.id,
                                adminId: widget.adminId,
                                notes: _notesController.text.trim().isEmpty
                                    ? 'Rejected'
                                    : _notesController.text.trim(),
                              )),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () => _act(() => service.approveVerification(
                                requestId: req.id,
                                adminId: widget.adminId,
                                notes: _notesController.text.trim(),
                              )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DocThumb extends StatelessWidget {
  final String url;

  const _DocThumb({required this.url});

  static String labelFromUrl(String url) {
    // Try to extract the file name before query params.
    final noQuery = url.split('?').first;
    final file = noQuery.split('/').last;

    // Expected pattern: {timestamp}_{type}.jpg OR {timestamp}_{type}_something.jpg
    final parts = file.split('_');
    if (parts.length >= 2) {
      // Join everything after timestamp and remove extension
      final namePart = parts.sublist(1).join('_');
      final base = namePart.split('.').first;
      return base.replaceAll('_', ' ');
    }

    // Fallback: strip extension
    return file.split('.').first.replaceAll('_', ' ');
  }

  bool get _looksLikeImage {
    final u = url.toLowerCase();
    return u.contains('.jpg') ||
        u.contains('.jpeg') ||
        u.contains('.png') ||
        u.contains('.webp') ||
        u.contains('image');
  }

  @override
  Widget build(BuildContext context) {
    final label = labelFromUrl(url);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: _looksLikeImage
                        ? Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, st) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: SelectableText(
                                  url,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                url,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96,
        height: 112,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: _looksLikeImage
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, st) => const Center(
                        child: Icon(Icons.insert_drive_file,
                            color: AppTheme.textSecondaryColor),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.insert_drive_file,
                          color: AppTheme.textSecondaryColor),
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: Colors.white,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
