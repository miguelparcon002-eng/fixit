import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/verification_provider.dart';
import '../../services/verification_service.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class VerificationSubmissionScreen extends ConsumerStatefulWidget {
  const VerificationSubmissionScreen({super.key});

  @override
  ConsumerState<VerificationSubmissionScreen> createState() => _VerificationSubmissionScreenState();
}

class _VerificationSubmissionScreenState extends ConsumerState<VerificationSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  // Form fields
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _yearsExperienceController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Document storage
  final Map<String, Uint8List?> _documents = {
    'Government ID (Front)': null,
    'Government ID (Back)': null,
    'Professional License/Certification': null,
    'Business Permit (Optional)': null,
    'Proof of Technical Training': null,
  };
  
  // Selected specialties
  final Set<String> _selectedSpecialties = {};
  
  bool _isSubmitting = false;
  
  final List<String> _specialtyOptions = [
    'Mobile Phone Screen Repair',
    'Mobile Phone Battery Replacement',
    'Mobile Phone Water Damage Repair',
    'Mobile Phone Software Issues',
    'Laptop Screen Repair',
    'Laptop Battery Replacement',
    'Laptop Hardware Upgrades',
    'Laptop Software Installation',
    'Data Recovery',
    'Motherboard Repair',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) {
      setState(() {
        _fullNameController.text = user.fullName;
        _contactNumberController.text = user.contactNumber ?? '';
        _addressController.text = user.address ?? '';
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _yearsExperienceController.dispose();
    _shopNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _documents[documentType] = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check required documents
    final requiredDocs = [
      'Government ID (Front)',
      'Government ID (Back)',
      'Professional License/Certification',
      'Proof of Technical Training',
    ];

    for (final doc in requiredDocs) {
      if (_documents[doc] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload: $doc')),
        );
        return;
      }
    }

    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one specialty')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not found');

      final verificationService = ref.read(verificationServiceProvider);
      final documentUrls = <String>[];

      // Upload all documents
      for (final entry in _documents.entries) {
        if (entry.value != null) {
          final url = await verificationService.uploadDocument(
            userId: user.id,
            fileBytes: entry.value!,
            fileName: '${entry.key.replaceAll(' ', '_').toLowerCase()}.jpg',
          );
          documentUrls.add(url);
        }
      }

      // Submit verification request with all technician information
      await verificationService.submitVerificationRequest(
        userId: user.id,
        documentUrls: documentUrls,
        fullName: _fullNameController.text,
        contactNumber: _contactNumberController.text,
        address: _addressController.text,
        yearsExperience: int.tryParse(_yearsExperienceController.text),
        shopName: _shopNameController.text.isEmpty ? null : _shopNameController.text,
        bio: _bioController.text,
        specialties: _selectedSpecialties.toList(),
      );

      if (mounted) {
        // Show success dialog with SMS notification info
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verification Submitted!',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your verification has been submitted successfully.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.sms, color: AppTheme.lightBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'SMS Notification',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You will receive a text message at ${_contactNumberController.text} when your verification is:',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        _buildNotificationItem('✅ Approved - You can start accepting jobs'),
                        _buildNotificationItem('❌ Rejected - Review admin feedback'),
                        _buildNotificationItem('🔄 Needs correction - Resubmit documents'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verification usually takes 24-48 hours',
                            style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Logout user and navigate to login
        await ref.read(authServiceProvider).signOut();
        
        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting verification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Logout and go to login screen
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Verification?'),
            content: const Text('You must complete verification to use the app. Exiting will log you out.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
        );
        
        if (shouldLogout == true && context.mounted) {
          // Logout user
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) {
            context.go('/login');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Technician Verification'),
          backgroundColor: AppTheme.deepBlue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Logout and go to login screen
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exit Verification?'),
                  content: const Text('You must complete verification to use the app. Exiting will log you out.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (shouldLogout == true && context.mounted) {
                // Logout user
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, size: 48, color: AppTheme.lightBlue),
                  const SizedBox(height: 12),
                  const Text(
                    'Become a Verified Technician',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit your documents and information to get verified and start accepting repair jobs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _contactNumberController,
              label: 'Contact Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Complete Address',
              icon: Icons.location_on,
              maxLines: 2,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Professional Information
            _buildSectionTitle('Professional Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _yearsExperienceController,
              label: 'Years of Experience',
              icon: Icons.work,
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _shopNameController,
              label: 'Shop Name (Optional)',
              icon: Icons.store,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _bioController,
              label: 'Brief Bio / Description',
              icon: Icons.description,
              maxLines: 4,
              hint: 'Tell customers about your expertise and experience...',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Specialties
            _buildSectionTitle('Specialties (Select all that apply)'),
            const SizedBox(height: 12),
            _buildSpecialtiesSection(),
            const SizedBox(height: 24),

            // Required Documents
            _buildSectionTitle('Required Documents'),
            const SizedBox(height: 8),
            Text(
              'Please upload clear photos of the following documents:',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ..._documents.entries.map((entry) {
              final isRequired = entry.key != 'Business Permit (Optional)';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDocumentUploadCard(
                  documentType: entry.key,
                  isUploaded: entry.value != null,
                  isRequired: isRequired,
                  onTap: () => _pickDocument(entry.key),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit for Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.lightBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.lightBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _specialtyOptions.map((specialty) {
        final isSelected = _selectedSpecialties.contains(specialty);
        return FilterChip(
          label: Text(specialty),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSpecialties.add(specialty);
              } else {
                _selectedSpecialties.remove(specialty);
              }
            });
          },
          selectedColor: AppTheme.lightBlue.withValues(alpha: 0.3),
          checkmarkColor: AppTheme.deepBlue,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.deepBlue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentUploadCard({
    required String documentType,
    required bool isUploaded,
    required bool isRequired,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded
                ? Colors.green
                : (isRequired ? Colors.orange : Colors.grey.shade300),
            width: isUploaded ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUploaded
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUploaded ? Icons.check_circle : Icons.upload_file,
                color: isUploaded ? Colors.green : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          documentType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (isRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUploaded ? 'Uploaded ✓' : 'Tap to upload',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUploaded ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
