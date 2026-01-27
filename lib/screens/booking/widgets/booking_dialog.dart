import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/rewards_provider.dart';
import '../../../models/reward.dart';
import 'dart:math';

class BookingDialog extends ConsumerStatefulWidget {
  final bool isEmergency;
  final bool isWeekBooking;

  const BookingDialog({super.key, this.isEmergency = false, this.isWeekBooking = false});

  @override
  ConsumerState<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<BookingDialog> {
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

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
  String _discountType = 'none'; // 'percentage' or 'fixed'

  // Pricing map based on device type and problem (realistic PH prices)
  final Map<String, Map<String, double>> _pricing = {
    'Mobile Phone': {
      'Screen Cracked': 1500.0,
      'Battery Drains': 800.0,
      'Won\'t power on': 500.0,
      'Overheating': 450.0,
      'Water damage': 1200.0,
      'Software Bug': 350.0,
    },
    'Laptop': {
      'Screen Cracked': 3500.0,
      'Battery Drains': 2500.0,
      'Won\'t power on': 800.0,
      'Overheating': 650.0,
      'Water damage': 2000.0,
      'Software Bug': 500.0,
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
    // Ensure scroll starts at top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    // Load default address from address provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final addresses = ref.read(addressProvider);
        final defaultAddress = addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => addresses.isNotEmpty ? addresses.first : throw Exception('No addresses'),
        );

        if (mounted) {
          setState(() {
            _addressController.text = '${defaultAddress.street}, ${defaultAddress.city}, ${defaultAddress.neighborhood}';
          });
        }
      } catch (e) {
        // If there's an error or no addresses, just skip auto-fill
        debugPrint('Error loading default address: $e');
      }
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _detailsController.dispose();
    _addressController.dispose();
    _promoCodeController.dispose();
    try {
      _scrollController.dispose();
    } catch (e) {
      // Ignore disposal errors on web
    }
    super.dispose();
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();
    final redeemedVouchers = ref.read(redeemedVouchersProvider);

    // Check if it's a redeemed voucher
    final voucher = redeemedVouchers.cast<RewardVoucher?>().firstWhere(
      (v) => v != null && code == 'VOUCHER${v.id.toUpperCase()}',
      orElse: () => null,
    );

    if (voucher != null) {
      setState(() {
        _appliedPromoCode = code;
        _discountAmount = voucher.discountAmount.toDouble();
        _discountType = voucher.discountType;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${voucher.title} applied successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      return;
    }

    // Check standard promo codes
    final Map<String, Map<String, dynamic>> promoCodes = {
      'FIRST20': {'type': 'percentage', 'amount': 20},
      'SAVE100': {'type': 'fixed', 'amount': 100},
      'SAVE250': {'type': 'fixed', 'amount': 250},
      'DISCOUNT10': {'type': 'percentage', 'amount': 10},
    };

    if (promoCodes.containsKey(code)) {
      final promo = promoCodes[code]!;
      setState(() {
        _appliedPromoCode = code;
        _discountAmount = promo['amount'].toDouble();
        _discountType = promo['type'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied successfully!'),
          backgroundColor: AppTheme.successColor,
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

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _discountAmount = 0;
      _discountType = 'none';
      _promoCodeController.clear();
    });
  }

  double _getServicePrice() {
    if (_selectedDeviceType == null || _selectedProblem == null) {
      return 500.0; // Default price
    }
    return _pricing[_selectedDeviceType]?[_selectedProblem] ?? 500.0;
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

  double _getBasePrice() {
    return _getServicePrice() + _getDistanceFee();
  }

  double _calculateTotal() {
    final basePrice = _getBasePrice();
    if (_appliedPromoCode == null) return basePrice;

    if (_discountType == 'percentage') {
      return basePrice - (basePrice * _discountAmount / 100);
    } else if (_discountType == 'fixed') {
      return basePrice - _discountAmount;
    }
    return basePrice;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate step 1
      if (_selectedDeviceType == null || _modelController.text.isEmpty || _selectedProblem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validate step 2
      if (_addressController.text.isEmpty || _selectedTechnician == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      // Reset scroll position to top when moving to next step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      // Reset scroll position to top when moving to previous step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _confirmAppointment() async {
    // Generate random booking ID
    final random = Random();
    final bookingId = '#FX${(random.nextInt(900) + 100).toString().padLeft(3, '0')}';

    // Get actual user details from profile
    final user = await ref.read(currentUserProvider.future);
    final customerName = user?.fullName ?? 'Guest User';
    final customerPhone = user?.contactNumber ?? '09000000000';

    // Set priority based on booking type
    String priority;
    if (widget.isEmergency) {
      priority = 'high'; // Emergency repair = High priority
    } else if (widget.isWeekBooking) {
      priority = 'low'; // Week booking = Low priority
    } else {
      priority = 'medium'; // Same day booking = Medium priority
    }

    // Calculate time based on emergency or regular booking
    String timeSlot;
    if (widget.isEmergency) {
      // For emergency: technician arrives in 15-20 mins, no specific time slot
      timeSlot = 'ASAP (15-20 mins)';
    } else {
      // For regular booking: use selected time
      timeSlot = _selectedTime.format(context);
    }

    // Calculate final total with any applied discount
    final basePrice = _getBasePrice();
    final finalTotal = _calculateTotal();

    // Calculate discount amount for display
    String? discountAmountStr;
    if (_appliedPromoCode != null) {
      final discount = basePrice - finalTotal;
      discountAmountStr = '₱${discount.toStringAsFixed(0)}';
    }

    // Create and save the booking
    final newBooking = LocalBooking(
      id: bookingId,
      icon: _selectedDeviceType == 'Mobile Phone' ? '📱' : '💻',
      status: 'Scheduled',
      deviceName: _modelController.text,
      serviceName: _selectedProblem ?? 'Quick Fix',
      date: DateFormat('MMM dd, yyyy').format(_selectedDate ?? DateTime.now()),
      time: timeSlot,
      location: _addressController.text,
      technician: _selectedTechnician ?? 'TBD',
      total: '₱${finalTotal.toStringAsFixed(0)}',
      customerName: customerName,
      customerPhone: customerPhone,
      priority: priority,
      moreDetails: _detailsController.text,
      promoCode: _appliedPromoCode,
      discountAmount: discountAmountStr,
      originalPrice: _appliedPromoCode != null ? '₱${basePrice.toStringAsFixed(0)}' : null,
    );

    await ref.read(localBookingsProvider.notifier).addBooking(newBooking);

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Request Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close success dialog
                    Navigator.of(context).pop(); // Close booking dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 20),
                          onPressed: _previousStep,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.deepBlue,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _currentStep == 0
                            ? 'Device Details'
                            : _currentStep == 1
                                ? 'Schedule & Location'
                                : 'Confirmation',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepBlue,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < 2 ? 8 : 0,
                          ),
                          height: 4,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppTheme.deepBlue
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: _currentStep == 0
                    ? _buildDeviceSelectionStep()
                    : _currentStep == 1
                        ? _buildTimeLocationStep()
                        : _buildConfirmationStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your device',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DeviceTypeButton(
                icon: Icons.smartphone,
                label: 'Mobile Phone',
                isSelected: _selectedDeviceType == 'Mobile Phone',
                onTap: () => setState(() => _selectedDeviceType = 'Mobile Phone'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DeviceTypeButton(
                icon: Icons.laptop,
                label: 'Laptop',
                isSelected: _selectedDeviceType == 'Laptop',
                onTap: () => setState(() => _selectedDeviceType = 'Laptop'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Model',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          decoration: InputDecoration(
            hintText: 'ex. iPhone 14 Pro, MacBook Air M2',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            filled: true,
            fillColor: Colors.grey[50],
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'What\'s the problem?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _problems.map((problem) {
            final isSelected = _selectedProblem == problem;
            return InkWell(
              onTap: () => setState(() => _selectedProblem = problem),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.deepBlue : Colors.grey[50],
                  border: Border.all(
                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  problem,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'More details (optional)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add any details: when it started, previous repairs, etc.',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
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
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
        // Price Display
        if (_selectedDeviceType != null && _selectedProblem != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.deepBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, color: AppTheme.deepBlue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Service Price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${_getServicePrice().toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '* Distance fee will be added based on technician selection',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show date picker for week bookings
        if (widget.isWeekBooking) ...[
          const Text(
            'Select Date',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 7)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppTheme.deepBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Choose a date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedDate != null ? AppTheme.textPrimaryColor : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Hide time slot for emergency repairs, show for week and regular bookings
        if (!widget.isEmergency) ...[
          const Text(
            'Time Slot',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppTheme.deepBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (widget.isEmergency) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: AppTheme.warningColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Service',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Technician will arrive ASAP (15-20 mins)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Address',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter street, building or exact address',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 12, left: 12),
              child: Icon(Icons.location_on, color: Colors.grey[400], size: 20),
            ),
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
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Available Technicians',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Distance fee: ₱5 per 0.1km',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _technicians.asMap().entries.map((entry) {
              final index = entry.key;
              final tech = entry.value;
              final isSelected = _selectedTechnician == tech['name'];
              final distanceStr = tech['distance'] as String;
              final distance = double.tryParse(distanceStr.replaceAll('km', '')) ?? 0.0;
              final distanceFee = (distance / 0.1) * 5;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedTechnician = tech['name']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.deepBlue : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tech['name'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: AppTheme.successColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${tech['distance']} away',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
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
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppTheme.deepBlue : Colors.grey[600],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: AppTheme.deepBlue, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < _technicians.length - 1)
                    Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final basePrice = _getBasePrice();
    final total = _calculateTotal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.devices,
                label: 'Device',
                value: '$_selectedDeviceType - ${_modelController.text}',
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.build,
                label: 'Issue',
                value: _selectedProblem ?? '',
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.schedule,
                label: 'When',
                value: widget.isEmergency
                    ? 'ASAP (15-20 mins)'
                    : '${DateFormat('MMM dd, yyyy').format(_selectedDate ?? DateTime.now())}, ${_selectedTime.format(context)}',
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.location_on,
                label: 'Address',
                value: _addressController.text,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person,
                label: 'Technician',
                value: _selectedTechnician ?? 'Not selected',
              ),
              if (_detailsController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.notes,
                  label: 'Additional Details',
                  value: _detailsController.text,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Promo Code Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer, size: 20, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Have a promo code?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_appliedPromoCode == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCodeController,
                        decoration: InputDecoration(
                          hintText: 'Enter code',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _appliedPromoCode!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              _discountType == 'percentage'
                                  ? '$_discountAmount% discount applied'
                                  : '₱${_discountAmount.toStringAsFixed(0)} discount applied',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _removePromoCode,
                        color: Colors.grey[600],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Price Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Service Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Fee',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '₱${_getServicePrice().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Distance Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Distance Fee',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_technicians.firstWhere((t) => t['name'] == _selectedTechnician)['distance']})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${_getDistanceFee().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (_appliedPromoCode != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      _discountType == 'percentage'
                          ? '-₱${(basePrice * _discountAmount / 100).toStringAsFixed(0)}'
                          : '-₱${_discountAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '₱${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm Appointment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _previousStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.deepBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.deepBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Edit Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeviceTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.deepBlue : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? Colors.white : AppTheme.deepBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.deepBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.deepBlue),
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
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
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
