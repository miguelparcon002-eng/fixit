import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_upload_service.dart';

class TechEditProfileScreen extends ConsumerStatefulWidget {
  const TechEditProfileScreen({super.key});

  @override
  ConsumerState<TechEditProfileScreen> createState() =>
      _TechEditProfileScreenState();
}

class _TechEditProfileScreenState extends ConsumerState<TechEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();

    // Load profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load user image URL
      final userAsync = ref.read(currentUserProvider);
      userAsync.whenData((user) {
        if (!mounted) return;
        setState(() {
          _profileImageUrl = user?.profilePicture;
        });
      });

      // Load profile data
      final profileAsync = ref.read(profileProvider);
      profileAsync.whenData((profile) {
        if (!mounted) return;
        setState(() {
          _emailController.text = profile.email;
          _phoneController.text = profile.phone;
          _locationController.text = profile.location;
        });
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_isUploadingImage) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        throw Exception('User not found');
      }

      final newUrl = await ImageUploadService.uploadAndSaveProfileImage(
        userId: user.id,
        imageFile: pickedFile,
        oldImageUrl: user.profilePicture,
      );

      if (newUrl == null || newUrl.isEmpty) {
        throw Exception('Failed to upload image');
      }

      if (!mounted) return;
      setState(() {
        _profileImageUrl = newUrl;
      });

      // Refresh user/profile so the image persists across screens/app restarts
      ref.invalidate(currentUserProvider);
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {  

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update profile information in local storage
      await ref
          .read(profileProvider.notifier)
          .updateEmail(_emailController.text.trim());
      await ref
          .read(profileProvider.notifier)
          .updatePhone(_phoneController.text.trim());
      await ref
          .read(profileProvider.notifier)
          .updateLocation(_locationController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/tech-profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tech-profile'),
        ),
        title: const Text('Edit Personal Information'),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveProfile,
            icon: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isLoading ? 'Saving…' : 'Save changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              disabledBackgroundColor: Colors.grey,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 700
                ? 560.0
                : double.infinity;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        child: Row(
                          children: [
                            Consumer(
                              builder: (context, ref, child) {
                                final userAsync = ref.watch(
                                  currentUserProvider,
                                );
                                final initials = userAsync.when(
                                  data: (user) {
                                    final fullName = user?.fullName ?? '';
                                    final parts = fullName
                                        .split(' ')
                                        .where((s) => s.trim().isNotEmpty)
                                        .take(2)
                                        .toList();
                                    if (parts.isEmpty) return '?';
                                    return parts
                                        .map((s) => s[0].toUpperCase())
                                        .join();
                                  },
                                  loading: () => '…',
                                  error: (error, stackTrace) => '?',
                                );

                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickAndUploadProfileImage,
                                      child: CircleAvatar(
                                        radius: 34,
                                        backgroundColor: AppTheme.deepBlue,
                                        backgroundImage: (_profileImageUrl != null &&
                                                _profileImageUrl!.isNotEmpty)
                                            ? NetworkImage(_profileImageUrl!)
                                            : null,
                                        child: (_profileImageUrl != null &&
                                                _profileImageUrl!.isNotEmpty)
                                            ? null
                                            : Text(
                                                initials,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppTheme.deepBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: _isUploadingImage
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.camera_alt_outlined,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Update your contact details so customers can reach you.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              title: 'Personal details',
                              subtitle:
                                  'These details appear on your technician profile.',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email address',
                              icon: Icons.email_outlined,
                              enabled: false,
                              hint: 'Email can’t be changed',
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _locationController,
                              label: 'Location',
                              icon: Icons.location_on_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your location';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Consumer(
                        builder: (context, ref, child) {
                          final userAsync = ref.watch(currentUserProvider);
                          final isVerified = userAsync.when(
                            data: (user) => user?.verified ?? false,
                            loading: () => false,
                            error: (error, stackTrace) => false,
                          );

                          final statusText = isVerified
                              ? 'Certified technician'
                              : 'Pending verification';
                          final statusColor = isVerified
                              ? AppTheme.successColor
                              : AppTheme.warningColor;

                          return _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SectionHeader(
                                        title: 'Technician information',
                                        subtitle:
                                            'Your current account status.',
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: statusColor.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Rating',
                                  '0.0',
                                  valueColor: AppTheme.textSecondaryColor,
                                ),
                                const SizedBox(height: 10),
                                _buildInfoRow('Jobs completed', '0'),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: enabled
            ? AppTheme.textPrimaryColor
            : AppTheme.textSecondaryColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixIconColor: enabled
            ? AppTheme.deepBlue
            : AppTheme.textSecondaryColor,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}
