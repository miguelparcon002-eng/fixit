import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/verification_provider.dart';
import '../../core/constants/app_constants.dart';
import 'tech_profile_screen.dart' show availableSpecialties;
import 'package:go_router/go_router.dart';

class VerificationSubmissionScreen extends ConsumerStatefulWidget {
  const VerificationSubmissionScreen({super.key});

  @override
  ConsumerState<VerificationSubmissionScreen> createState() =>
      _VerificationSubmissionScreenState();
}

class _VerificationSubmissionScreenState
    extends ConsumerState<VerificationSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  int _expYears = 0;
  int _expMonths = 0;
  final _shopNameController = TextEditingController();
  final _bioController = TextEditingController();

  final Map<String, Uint8List?> _documents = {
    'Government ID (Front)': null,
    'Government ID (Back)': null,
    'Professional License/Certification': null,
    'Business Permit (Optional)': null,
    'Proof of Technical Training': null,
  };

  final Set<String> _selectedSpecialties = {};
  bool _isSubmitting = false;
  bool _isLeavingDialogOpen = false;
  bool _isEditingPending = false;
  LatLng? _pinnedLocation;

  // Step tracking: 0 = Personal, 1 = Professional, 2 = Documents
  int _currentStep = 0;


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await ref.read(currentUserProvider.future);
    if (user != null) {
      _fullNameController.text = user.fullName;
      _contactNumberController.text = user.contactNumber ?? '';
      _addressController.text = user.address ?? '';
    }

    // Also pre-fill from existing verification request if available
    final verificationReq = await ref.read(userVerificationRequestProvider.future);
    if (verificationReq != null && mounted) {
      setState(() {
        _isEditingPending = verificationReq.status == AppConstants.verificationPending ||
            verificationReq.status == AppConstants.verificationResubmit;
        if (verificationReq.fullName != null && verificationReq.fullName!.isNotEmpty) {
          _fullNameController.text = verificationReq.fullName!;
        }
        if (verificationReq.contactNumber != null && verificationReq.contactNumber!.isNotEmpty) {
          _contactNumberController.text = verificationReq.contactNumber!;
        }
        if (verificationReq.address != null && verificationReq.address!.isNotEmpty) {
          _addressController.text = verificationReq.address!;
        }
        if (verificationReq.shopName != null) {
          _shopNameController.text = verificationReq.shopName!;
        }
        if (verificationReq.bio != null) {
          _bioController.text = verificationReq.bio!;
        }
        if (verificationReq.specialties != null && verificationReq.specialties!.isNotEmpty) {
          _selectedSpecialties.addAll(verificationReq.specialties!);
        }
        if (verificationReq.yearsExperience != null && verificationReq.yearsExperience! > 0) {
          _expYears = verificationReq.yearsExperience! ~/ 12;
          _expMonths = verificationReq.yearsExperience! % 12;
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
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
        setState(() => _documents[documentType] = bytes);
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
    if (!_formKey.currentState!.validate()) return;

    final requiredDocs = [
      'Government ID (Front)',
      'Government ID (Back)',
      'Professional License/Certification',
      'Proof of Technical Training',
    ];

    for (final doc in requiredDocs) {
      if (_documents[doc] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload: $doc'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_expYears == 0 && _expMonths == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 month of experience'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one specialty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('User not found');

      final verificationService = ref.read(verificationServiceProvider);
      final documentUrls = <String>[];

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

      await verificationService.submitVerificationRequest(
        userId: user.id,
        documentUrls: documentUrls,
        fullName: _fullNameController.text,
        contactNumber: _contactNumberController.text,
        address: _addressController.text,
        yearsExperience: _expYears * 12 + _expMonths,
        shopName:
            _shopNameController.text.isEmpty ? null : _shopNameController.text,
        bio: _bioController.text,
        specialties: _selectedSpecialties.toList(),
      );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 52),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Submitted!',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your verification is under review. We\'ll notify you within 24–48 hours.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.deepBlue.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: AppTheme.deepBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'We\'ll send an update to your email when your verification is approved, rejected, or needs correction.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700], height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Done',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Refresh verification state so the banner updates immediately
        ref.invalidate(userVerificationRequestProvider);
        if (mounted) context.go('/tech-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onBackPressed() async {
    if (_isLeavingDialogOpen) return;
    _isLeavingDialogOpen = true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Verification?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Your progress will not be saved. You can complete verification later from your profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    _isLeavingDialogOpen = false;
    if (shouldLeave == true && mounted) {
      context.pop();
    }
  }

  int get _uploadedRequiredCount => [
        'Government ID (Front)',
        'Government ID (Back)',
        'Professional License/Certification',
        'Proof of Technical Training',
      ].where((d) => _documents[d] != null).length;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // ── Gradient App Bar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _onBackPressed,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.deepBlue, AppTheme.lightBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.verified_user,
                                  color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Get Verified',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Complete all steps to start accepting jobs',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Step Progress Bar ─────────────────────────────
                      _StepProgressBar(currentStep: _currentStep),
                      const SizedBox(height: 20),

                      // ── Step 0: Personal Info ─────────────────────────
                      _AnimatedStep(
                        visible: _currentStep == 0,
                        child: _buildPersonalInfoStep(),
                      ),

                      // ── Step 1: Professional Info ─────────────────────
                      _AnimatedStep(
                        visible: _currentStep == 1,
                        child: _buildProfessionalInfoStep(),
                      ),

                      // ── Step 2: Documents ─────────────────────────────
                      _AnimatedStep(
                        visible: _currentStep == 2,
                        child: _buildDocumentsStep(),
                      ),

                      const SizedBox(height: 24),

                      // ── Navigation Buttons ────────────────────────────
                      _buildNavButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 0: Personal Info ────────────────────────────────────────────────
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: 'Your basic contact details',
        ),
        const SizedBox(height: 16),
        _ModernField(
          controller: _fullNameController,
          label: 'Full Name',
          icon: Icons.person_outline,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _ModernField(
          controller: _contactNumberController,
          label: 'Contact Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _ModernField(
          controller: _addressController,
          label: 'Complete Address',
          icon: Icons.location_on_outlined,
          maxLines: 2,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _PinLocationCard(
          pinnedLocation: _pinnedLocation,
          onTap: () => _showMapPicker(),
          onClear: () => setState(() => _pinnedLocation = null),
        ),
      ],
    );
  }

  void _showMapPicker() {
    // San Francisco, Agusan del Sur
    const sanFrancisco = LatLng(8.5069, 125.9728);
    // Bounds roughly enclosing San Francisco municipality
    final sfBounds = LatLngBounds(
      const LatLng(8.3500, 125.8000), // SW
      const LatLng(8.6500, 126.1500), // NE
    );
    LatLng currentPin = _pinnedLocation ?? sanFrancisco;
    final mapController = MapController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_pin,
                          color: AppTheme.deepBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pin Your Location',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimaryColor)),
                          Text('San Francisco, Agusan del Sur — tap to drop your pin',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: sanFrancisco,
                      initialZoom: 13,
                      minZoom: 11,
                      maxZoom: 18,
                      cameraConstraint: CameraConstraint.containCenter(
                        bounds: sfBounds,
                      ),
                      onTap: (_, point) {
                        setModalState(() => currentPin = point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.fixit.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentPin,
                            width: 48,
                            height: 48,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 48),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Coordinates display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.deepBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location,
                          color: AppTheme.deepBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${currentPin.latitude.toStringAsFixed(5)}, ${currentPin.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.deepBlue),
                      ),
                    ],
                  ),
                ),
              ),
              // Confirm button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _pinnedLocation = currentPin);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Confirm Location',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Professional Info ────────────────────────────────────────────
  Widget _buildProfessionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.work_outline,
          title: 'Professional Details',
          subtitle: 'Tell us about your expertise',
        ),
        const SizedBox(height: 16),
        // Experience picker — years + months
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star_outline,
                        color: AppTheme.lightBlue, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Experience',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Years dropdown
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _expYears,
                      decoration: InputDecoration(
                        labelText: 'Years',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: List.generate(
                        21,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text('$i yr${i == 1 ? '' : 's'}'),
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() => _expYears = v ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Months dropdown
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _expMonths,
                      decoration: InputDecoration(
                        labelText: 'Months',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text('$i mo${i == 1 ? '' : 's'}'),
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() => _expMonths = v ?? 0),
                    ),
                  ),
                ],
              ),
              if (_expYears == 0 && _expMonths == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Please select at least 1 month of experience',
                    style: TextStyle(
                        fontSize: 11, color: Colors.red.shade400),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ModernField(
          controller: _shopNameController,
          label: 'Shop Name (Optional)',
          icon: Icons.store_outlined,
        ),
        const SizedBox(height: 12),
        _ModernField(
          controller: _bioController,
          label: 'Brief Bio / Description',
          icon: Icons.notes_outlined,
          maxLines: 4,
          hint: 'Tell customers about your expertise and experience...',
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          icon: Icons.build_outlined,
          title: 'Specialties',
          subtitle: 'Select all that apply',
        ),
        const SizedBox(height: 12),
        _buildSpecialtiesSection(),
      ],
    );
  }

  // ── Step 2: Documents ────────────────────────────────────────────────────
  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.folder_copy_outlined,
          title: 'Required Documents',
          subtitle: 'Upload clear photos of each document',
        ),
        const SizedBox(height: 8),
        // Upload progress indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.deepBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.upload_rounded,
                  color: AppTheme.deepBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                '$_uploadedRequiredCount of 4 required documents uploaded',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._documents.entries.map((entry) {
          final isRequired = entry.key != 'Business Permit (Optional)';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DocumentCard(
              documentType: entry.key,
              imageBytes: entry.value,
              isRequired: isRequired,
              onTap: () => _pickDocument(entry.key),
            ),
          );
        }),
      ],
    );
  }

  // ── Specialties Section ──────────────────────────────────────────────────
  Widget _buildSpecialtiesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSpecialties.map((specialty) {
        final isSelected = _selectedSpecialties.contains(specialty);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _selectedSpecialties.remove(specialty);
            } else {
              _selectedSpecialties.add(specialty);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.deepBlue
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? AppTheme.deepBlue
                    : Colors.grey.shade300,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.deepBlue.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                ],
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Navigation Buttons ───────────────────────────────────────────────────
  Widget _buildNavButtons() {
    final isLast = _currentStep == 2;
    final isFirst = _currentStep == 0;

    return Row(
      children: [
        if (!isFirst)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.deepBlue,
                side: const BorderSide(color: AppTheme.deepBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        if (!isFirst) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (isLast) {
                      _submitVerification();
                    } else {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep++);
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast
                            ? (_isEditingPending ? 'Update Submission' : 'Submit for Verification')
                            : 'Continue',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Step Progress Bar ────────────────────────────────────────────────────────
class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  const _StepProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Personal', 'Professional', 'Documents'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = i < currentStep;
        final isActive = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDone || isActive
                            ? AppTheme.deepBlue
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppTheme.successColor
                                : isActive
                                    ? AppTheme.deepBlue
                                    : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 12)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? AppTheme.deepBlue
                                : isDone
                                    ? AppTheme.successColor
                                    : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.deepBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.deepBlue, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ],
    );
  }
}

// ── Modern Text Field ────────────────────────────────────────────────────────
class _ModernField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ModernField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          fontSize: 14, color: AppTheme.textPrimaryColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13, color: AppTheme.textSecondaryColor),
        prefixIcon:
            Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.deepBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

// ── Document Upload Card ─────────────────────────────────────────────────────
class _DocumentCard extends StatelessWidget {
  final String documentType;
  final Uint8List? imageBytes;
  final bool isRequired;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.documentType,
    required this.imageBytes,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUploaded = imageBytes != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded
                ? AppTheme.successColor
                : isRequired
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
            width: isUploaded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isUploaded
                  ? Image.memory(imageBytes!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover)
                  : Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isRequired
                            ? AppTheme.deepBlue.withValues(alpha: 0.07)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.upload_file_outlined,
                        color: isRequired
                            ? AppTheme.deepBlue
                            : Colors.grey.shade400,
                        size: 26,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (isRequired && !isUploaded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      if (isUploaded)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.successColor, size: 20),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isUploaded
                        ? 'Uploaded — tap to replace'
                        : 'Tap to upload a photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUploaded
                          ? AppTheme.successColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pin Location Card ────────────────────────────────────────────────────────
class _PinLocationCard extends StatelessWidget {
  final LatLng? pinnedLocation;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _PinLocationCard({
    required this.pinnedLocation,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isPinned = pinnedLocation != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPinned ? AppTheme.successColor : Colors.grey.shade200,
            width: isPinned ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPinned
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : AppTheme.deepBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPinned ? Icons.location_on : Icons.add_location_alt_outlined,
                color: isPinned ? AppTheme.successColor : AppTheme.deepBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pin Location on Map',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isPinned
                              ? AppTheme.successColor
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPinned
                        ? '${pinnedLocation!.latitude.toStringAsFixed(5)}, ${pinnedLocation!.longitude.toStringAsFixed(5)}'
                        : 'Tap to pin your exact location in Agusan del Sur',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPinned
                          ? AppTheme.successColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isPinned)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 20),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Animated Step Wrapper ────────────────────────────────────────────────────
class _AnimatedStep extends StatelessWidget {
  final bool visible;
  final Widget child;
  const _AnimatedStep({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: visible ? child : const SizedBox.shrink(),
    );
  }
}
