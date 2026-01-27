import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const CreateBookingScreen({super.key, required this.serviceId});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Device selection
  String? _selectedDeviceType;
  final TextEditingController _modelController = TextEditingController();
  String? _selectedProblem;
  final TextEditingController _detailsController = TextEditingController();

  // Step 2: Time and location
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _selectedDate;
  final TextEditingController _addressController = TextEditingController();
  String? _selectedTechnician;

  // Step 3: Promo code
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  double _discountAmount = 0;
  String _discountType = 'none';

  // Pricing map based on device type and problem
  final Map<String, Map<String, double>> _pricing = {
    'Mobile Phone': {
      'Screen Cracked': 3450.0,
      'Battery Drains': 2700.0,
      'Won\'t power on': 3200.0,
      'Overheating': 2900.0,
      'Water damage': 5700.0,
      'Software Bug': 1900.0,
    },
    'Laptop': {
      'Screen Cracked': 8700.0,
      'Battery Drains': 4200.0,
      'Won\'t power on': 5500.0,
      'Overheating': 4800.0,
      'Water damage': 8900.0,
      'Software Bug': 2400.0,
    },
    'Tablet': {
      'Screen Cracked': 5200.0,
      'Battery Drains': 3100.0,
      'Won\'t power on': 4000.0,
      'Overheating': 3500.0,
      'Water damage': 6800.0,
      'Software Bug': 2100.0,
    },
  };

  final List<String> _problems = [
    'Screen Cracked',
    'Battery Drains',
    'Won\'t power on',
    'Overheating',
    'Water damage',
    'Software Bug',
  ];

  final List<Map<String, dynamic>> _technicians = [
    {'name': 'MetroFix', 'distance': '1.2km'},
    {'name': 'Estino', 'distance': '0.47km'},
    {'name': 'Sarsale', 'distance': '2.4km'},
    {'name': 'GizmoDoc', 'distance': '0.98km'},
  ];

  @override
  void initState() {
    super.initState();
    // Load default address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final addresses = ref.read(addressProvider);
        if (addresses.isNotEmpty) {
          final defaultAddress = addresses.firstWhere(
            (address) => address.isDefault,
            orElse: () => addresses.first,
          );
          setState(() {
            _addressController.text = '${defaultAddress.street}, ${defaultAddress.neighborhood}, ${defaultAddress.city}';
          });
        }
      } catch (e) {
        // Address loading failed, user can enter manually
      }
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _detailsController.dispose();
    _addressController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  double _getServicePrice() {
    if (_selectedDeviceType == null || _selectedProblem == null) return 0.0;
    return _pricing[_selectedDeviceType]?[_selectedProblem] ?? 0.0;
  }

  double _getDistanceFee() {
    if (_selectedTechnician == null) return 0.0;
    final tech = _technicians.firstWhere(
      (t) => t['name'] == _selectedTechnician,
      orElse: () => {'distance': '0km'},
    );
    final distanceStr = tech['distance'] as String;
    // Parse distance (e.g., "1.2km" -> 1.2)
    final distance = double.tryParse(distanceStr.replaceAll('km', '')) ?? 0.0;
    // Calculate fee: 0.1km = ₱5, so 1km = ₱50
    return (distance / 0.1) * 5;
  }

  double _calculatePrice() {
    return _getServicePrice() + _getDistanceFee();
  }

  double _calculateFinalPrice() {
    final basePrice = _calculatePrice();
    if (_discountType == 'percentage') {
      return basePrice - (basePrice * _discountAmount / 100);
    } else if (_discountType == 'fixed') {
      return basePrice - _discountAmount;
    }
    return basePrice;
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();

    // Hardcoded promo codes for demo (in production, fetch from Supabase)
    final Map<String, Map<String, dynamic>> promoCodes = {
      'WELCOME10': {'type': 'percentage', 'amount': 10.0},
      'SAVE500': {'type': 'fixed', 'amount': 500.0},
      'FIRSTTIME': {'type': 'percentage', 'amount': 15.0},
    };

    if (promoCodes.containsKey(code)) {
      setState(() {
        _appliedPromoCode = code;
        _discountType = promoCodes[code]!['type'];
        _discountAmount = promoCodes[code]!['amount'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.deepBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.deepBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_selectedDeviceType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a device type')),
          );
          return false;
        }
        if (_modelController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter device model')),
          );
          return false;
        }
        if (_selectedProblem == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a problem')),
          );
          return false;
        }
        return true;
      case 1:
        if (_selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a date')),
          );
          return false;
        }
        if (_addressController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your address')),
          );
          return false;
        }
        if (_selectedTechnician == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a technician')),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _confirmBooking() async {
    if (!_validateStep(_currentStep)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not logged in');

      final basePrice = _calculatePrice();
      final finalPrice = _calculateFinalPrice();

      final booking = LocalBooking(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        icon: _selectedDeviceType == 'Mobile Phone' ? 'phone_android' :
              _selectedDeviceType == 'Laptop' ? 'laptop' : 'tablet',
        status: 'Requesting',
        deviceName: _selectedDeviceType!,
        serviceName: _selectedProblem!,
        date: DateFormat('MMM dd, yyyy').format(_selectedDate!),
        time: _selectedTime.format(context),
        location: _addressController.text.trim(),
        technician: _selectedTechnician!,
        total: '₱${finalPrice.toStringAsFixed(0)}',
        customerName: user.fullName,
        customerPhone: user.contactNumber ?? 'No phone',
        priority: 'Normal',
        moreDetails: _detailsController.text.trim().isNotEmpty
            ? '${_modelController.text.trim()}\n\n${_detailsController.text.trim()}'
            : _modelController.text.trim(),
        promoCode: _appliedPromoCode,
        discountAmount: _discountAmount > 0
            ? '₱${(_discountType == 'percentage' ? basePrice * _discountAmount / 100 : _discountAmount).toStringAsFixed(0)}'
            : null,
        originalPrice: _appliedPromoCode != null ? '₱${basePrice.toStringAsFixed(0)}' : null,
      );

      await ref.read(localBookingsProvider.notifier).addBooking(booking);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Booking Confirmed!'),
            ],
          ),
          content: const Text(
            'Your service request has been submitted. A technician will be assigned shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.go('/'); // Go back to home
              },
              child: const Text('View Bookings'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.go('/'); // Go back to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        title: const Text(
          'Book Service',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Device'),
                Expanded(child: _buildStepDivider(0)),
                _buildStepIndicator(1, 'Schedule'),
                Expanded(child: _buildStepDivider(1)),
                _buildStepIndicator(2, 'Review'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Step content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(),
              ),
            ),
          ),
          // Bottom navigation
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.deepBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (_currentStep < 2) {
                        if (_validateStep(_currentStep)) {
                          setState(() {
                            _currentStep++;
                          });
                        }
                      } else {
                        _confirmBooking();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep < 2 ? 'Next' : 'Confirm Booking'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step <= _currentStep;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.deepBlue : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.deepBlue : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int step) {
    final isActive = step < _currentStep;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? AppTheme.deepBlue : Colors.grey.shade300,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDeviceStep();
      case 1:
        return _buildScheduleStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDeviceStep() {
    final servicePrice = _getServicePrice();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 20),

        // Device Type
        const Text(
          'Device Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _pricing.keys.map((device) {
            final isSelected = _selectedDeviceType == device;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDeviceType = device;
                  _selectedProblem = null; // Reset problem when device changes
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.deepBlue : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  device,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Device Model
        const Text(
          'Device Model',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _modelController,
          decoration: InputDecoration(
            hintText: 'e.g., iPhone 13 Pro, MacBook Air M1',
            filled: true,
            fillColor: Colors.grey.shade50,
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
              borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Problem
        const Text(
          'What\'s the Problem?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ..._problems.map((problem) {
          final isSelected = _selectedProblem == problem;
          final price = _selectedDeviceType != null ? (_pricing[_selectedDeviceType]?[problem] ?? 0.0) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedProblem = problem;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? AppTheme.deepBlue : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        problem,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    if (_selectedDeviceType != null)
                      Text(
                        '₱${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.deepBlue : AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Additional Details
        const Text(
          'Additional Details (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the issue in detail...',
            filled: true,
            fillColor: Colors.grey.shade50,
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
              borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
            ),
          ),
        ),

        // Price Preview
        if (servicePrice > 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service Price',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '₱${servicePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '* Distance fee will be added based on technician selection',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule & Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 20),

        // Date Selection
        const Text(
          'Preferred Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.deepBlue),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate == null ? Colors.grey.shade600 : AppTheme.textPrimaryColor,
                    fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Time Selection
        const Text(
          'Preferred Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.deepBlue),
                const SizedBox(width: 12),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Address
        const Text(
          'Service Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your complete address',
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: const Icon(Icons.location_on, color: AppTheme.deepBlue),
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
              borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Technician Selection
        const Text(
          'Select Technician',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Distance fee: ₱5 per 0.1km',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        ..._technicians.map((tech) {
          final isSelected = _selectedTechnician == tech['name'];
          final distanceStr = tech['distance'] as String;
          final distance = double.tryParse(distanceStr.replaceAll('km', '')) ?? 0.0;
          final distanceFee = (distance / 0.1) * 5;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTechnician = tech['name'];
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.engineering,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tech['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '${tech['distance']} away',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+₱${distanceFee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.deepBlue : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppTheme.deepBlue : Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewStep() {
    final servicePrice = _getServicePrice();
    final distanceFee = _getDistanceFee();
    final totalBeforeDiscount = _calculatePrice();
    final finalPrice = _calculateFinalPrice();
    final discount = totalBeforeDiscount - finalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 20),

        // Device Info
        _buildReviewSection(
          'Device Information',
          [
            _buildReviewItem('Device', _selectedDeviceType ?? ''),
            _buildReviewItem('Model', _modelController.text),
            _buildReviewItem('Problem', _selectedProblem ?? ''),
            if (_detailsController.text.isNotEmpty)
              _buildReviewItem('Details', _detailsController.text),
          ],
        ),
        const SizedBox(height: 20),

        // Schedule Info
        _buildReviewSection(
          'Schedule & Location',
          [
            _buildReviewItem(
              'Date & Time',
              '${DateFormat('MMM dd, yyyy').format(_selectedDate!)} at ${_selectedTime.format(context)}',
            ),
            _buildReviewItem('Address', _addressController.text),
            _buildReviewItem('Technician', _selectedTechnician ?? ''),
          ],
        ),
        const SizedBox(height: 20),

        // Promo Code
        const Text(
          'Promo Code (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoCodeController,
                enabled: _appliedPromoCode == null,
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.local_offer, color: AppTheme.deepBlue),
                  suffixIcon: _appliedPromoCode != null
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _appliedPromoCode = null;
                              _discountAmount = 0;
                              _discountType = 'none';
                              _promoCodeController.clear();
                            });
                          },
                        )
                      : null,
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
                    borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_appliedPromoCode == null)
              ElevatedButton(
                onPressed: _applyPromoCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply'),
              ),
          ],
        ),
        if (_appliedPromoCode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Promo code "$_appliedPromoCode" applied',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Price Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Fee',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '₱${servicePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Distance Fee',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_technicians.firstWhere((t) => t['name'] == _selectedTechnician)['distance']})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${distanceFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              if (discount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '- ₱${discount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '₱${finalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Terms
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'By confirming this booking, you agree to our terms and conditions. Cancellation fees may apply.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
