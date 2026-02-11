import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/supabase_config.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../models/redeemed_voucher.dart';
import '../../services/redeemed_voucher_service.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String serviceId;
  final bool isEmergency;
  const CreateBookingScreen({super.key, required this.serviceId, this.isEmergency = false});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Repair type
  bool _isEmergency = false;

  // Step 1: Device selection
  String? _selectedDeviceType;
  String? _selectedBrand;
  String? _selectedModel;
  final TextEditingController _modelController = TextEditingController();
  String? _selectedProblem;
  final TextEditingController _detailsController = TextEditingController();

  // Step 2: Time and location
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _selectedDate;
  final TextEditingController _addressController = TextEditingController();
  String? _selectedTechnician;

  // Step 3: Promo code / voucher
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  double _discountAmount = 0;
  String _discountType = 'none';
  RedeemedVoucher? _appliedVoucher; // The actual voucher object if applied
  List<RedeemedVoucher> _availableVouchers = [];

  // Pricing map based on device type and problem (PH market rates)
  final Map<String, Map<String, double>> _pricing = {
    'Mobile Phone': {
      'Screen Cracked': 800.0,
      'Battery Drains': 500.0,
      'Won\'t power on': 600.0,
      'Overheating': 500.0,
      'Water damage': 1200.0,
      'Software Bug': 350.0,
    },
    'Laptop': {
      'Screen Cracked': 2500.0,
      'Battery Drains': 1200.0,
      'Won\'t power on': 1500.0,
      'Overheating': 1000.0,
      'Water damage': 2800.0,
      'Software Bug': 500.0,
    },
  };

  // Brand → device models mapping
  final Map<String, Map<String, List<String>>> _brandDevices = {
    'Mobile Phone': {
      'Apple': ['iPhone 16 Pro Max', 'iPhone 16 Pro', 'iPhone 16', 'iPhone 15 Pro Max', 'iPhone 15 Pro', 'iPhone 15', 'iPhone 14 Pro Max', 'iPhone 14', 'iPhone 13', 'iPhone 12', 'iPhone SE'],
      'Samsung': ['Galaxy S24 Ultra', 'Galaxy S24+', 'Galaxy S24', 'Galaxy S23 Ultra', 'Galaxy S23', 'Galaxy Z Fold 5', 'Galaxy Z Flip 5', 'Galaxy A54', 'Galaxy A34', 'Galaxy A14'],
      'Xiaomi': ['Xiaomi 14 Ultra', 'Xiaomi 14', 'Xiaomi 13T Pro', 'Redmi Note 13 Pro+', 'Redmi Note 13 Pro', 'Redmi Note 13', 'Redmi 13C', 'POCO X6 Pro', 'POCO X6', 'POCO M6 Pro'],
      'Oppo': ['Oppo Find X7 Ultra', 'Oppo Reno 11 Pro', 'Oppo Reno 11', 'Oppo A98', 'Oppo A78', 'Oppo A58', 'Oppo A38', 'Oppo A18'],
      'Vivo': ['Vivo X100 Pro', 'Vivo X100', 'Vivo V30 Pro', 'Vivo V30', 'Vivo Y100', 'Vivo Y36', 'Vivo Y27'],
      'Realme': ['Realme GT 5 Pro', 'Realme 12 Pro+', 'Realme 12 Pro', 'Realme C67', 'Realme C55', 'Realme Narzo 60'],
      'Huawei': ['Huawei P60 Pro', 'Huawei Nova 12', 'Huawei Nova 11', 'Huawei Y90', 'Huawei Y70'],
      'Other': [],
    },
    'Laptop': {
      'Apple': ['MacBook Air M3', 'MacBook Air M2', 'MacBook Air M1', 'MacBook Pro 16" M3', 'MacBook Pro 14" M3', 'MacBook Pro 13" M2'],
      'Lenovo': ['ThinkPad X1 Carbon', 'ThinkPad T14', 'IdeaPad Slim 5', 'IdeaPad 3', 'Legion 5 Pro', 'Legion 5'],
      'HP': ['Pavilion 15', 'Pavilion x360', 'Envy x360', 'Victus 16', 'Omen 16', 'EliteBook 840'],
      'Acer': ['Aspire 5', 'Aspire 3', 'Swift Go 14', 'Nitro 5', 'Predator Helios 16'],
      'Asus': ['VivoBook 15', 'ZenBook 14', 'ROG Strix G16', 'ROG Zephyrus G14', 'TUF Gaming A15'],
      'Dell': ['Inspiron 15', 'Inspiron 14', 'Latitude 5540', 'XPS 15', 'XPS 13'],
      'Other': [],
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
    _isEmergency = widget.isEmergency;
    // Load default address and vouchers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVouchers();
      try {
        final addressesAsync = ref.read(userAddressesProvider);
        addressesAsync.whenData((addresses) {
          if (addresses.isNotEmpty) {
            final defaultAddress = addresses.firstWhere(
              (address) => address.isDefault,
              orElse: () => addresses.first,
            );
            if (mounted) {
              setState(() {
                _addressController.text = defaultAddress.address;
              });
            }
          }
        });
      } catch (e) {
        // Address loading failed, user can enter manually
      }
    });
  }

  Future<void> _loadVouchers() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final voucherService = ref.read(redeemedVoucherServiceProvider);
    final vouchers = await voucherService.getUnusedVouchers(user.id);
    if (mounted) {
      setState(() {
        _availableVouchers = vouchers;
      });
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _detailsController.dispose();
    _addressController.dispose();
    _promoCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _getServicePrice() {
    if (_selectedDeviceType == null || _selectedProblem == null) return 0.0;
    final base = _pricing[_selectedDeviceType]?[_selectedProblem] ?? 0.0;
    return _isEmergency ? base * 1.10 : base;
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

    // 1. Check hardcoded promo codes
    final Map<String, Map<String, dynamic>> promoCodes = {
      'WELCOME10': {'type': 'percentage', 'amount': 10.0},
      'FIRST20': {'type': 'percentage', 'amount': 20.0},
      'SAVE500': {'type': 'fixed', 'amount': 500.0},
      'FIRSTTIME': {'type': 'percentage', 'amount': 15.0},
    };

    if (promoCodes.containsKey(code)) {
      setState(() {
        _appliedPromoCode = code;
        _discountType = promoCodes[code]!['type'];
        _discountAmount = promoCodes[code]!['amount'];
        _appliedVoucher = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // 2. Check user's redeemed vouchers by code pattern VOUCHER{ID}
    final matchingVoucher = _availableVouchers.where((v) {
      final voucherCode = 'VOUCHER${v.voucherId}'.toUpperCase();
      return voucherCode == code;
    }).toList();

    if (matchingVoucher.isNotEmpty) {
      final voucher = matchingVoucher.first;
      setState(() {
        _appliedPromoCode = code;
        _discountType = voucher.discountType;
        _discountAmount = voucher.discountAmount;
        _appliedVoucher = voucher;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher "${voucher.voucherTitle}" applied!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid promo code'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _applyVoucherDirectly(RedeemedVoucher voucher) {
    final code = 'VOUCHER${voucher.voucherId}'.toUpperCase();
    setState(() {
      _appliedPromoCode = code;
      _discountType = voucher.discountType;
      _discountAmount = voucher.discountAmount;
      _appliedVoucher = voucher;
      _promoCodeController.text = code;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher "${voucher.voucherTitle}" applied!'),
        backgroundColor: Colors.green,
      ),
    );
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
        if (_selectedBrand == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a brand')),
          );
          return false;
        }
        if (_modelController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or enter a device model')),
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

      final finalPrice = _calculateFinalPrice();

      // Combine date and time into scheduledDate
      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create booking details text
      final bookingDetails = [
        'Repair Type: ${_isEmergency ? "Emergency" : "Regular"}',
        'Device: $_selectedDeviceType',
        'Brand: $_selectedBrand',
        'Model: ${_modelController.text.trim()}',
        'Problem: $_selectedProblem',
        'Technician: $_selectedTechnician',
        if (_detailsController.text.trim().isNotEmpty) 'Details: ${_detailsController.text.trim()}',
        if (_appliedPromoCode != null) 'Promo Code: $_appliedPromoCode',
      ].join('\n');

      // Get all users to find a technician
      final supabase = SupabaseConfig.client;
      
      // Try to find a technician user (any user with role 'technician')
      String technicianId;
      try {
        // First, try to find technician with email fixittechnician@gmail.com (Ethan)
        var techResponse = await supabase
            .from('users')
            .select('id, email, full_name, role')
            .eq('email', 'fixittechnician@gmail.com')
            .maybeSingle();
        
        // If Ethan not found, try any technician
        if (techResponse == null) {
          print('Ethan not found, looking for any technician...');
          techResponse = await supabase
              .from('users')
              .select('id, email, full_name, role')
              .eq('role', 'technician')
              .limit(1)
              .maybeSingle();
        }
        
        if (techResponse != null) {
          technicianId = techResponse['id'] as String;
          print('✅ Found technician: ${techResponse['full_name']} (${techResponse['email']}) - ID: $technicianId');
        } else {
          print('❌ No technicians found in database');
          throw Exception('No technicians available. Please ensure Ethan Estino (fixittechnician@gmail.com) has role="technician" in the users table.');
        }
      } catch (e) {
        print('❌ Error fetching technician: $e');
        if (e is Exception && e.toString().contains('technician')) {
          rethrow;
        }
        throw Exception('Unable to find technicians. Please check database setup.');
      }

      // Get or create a service ID
      String serviceId;
      try {
        // First, try to find an existing service for this technician
        var serviceResponse = await supabase
            .from('services')
            .select('id, technician_id, service_name')
            .eq('technician_id', technicianId)
            .limit(1)
            .maybeSingle();
        
        // If no service for this technician, try to find any service
        if (serviceResponse == null) {
          print('No service found for technician $technicianId, checking for any service...');
          serviceResponse = await supabase
              .from('services')
              .select('id, technician_id, service_name')
              .limit(1)
              .maybeSingle();
        }
        
        if (serviceResponse != null) {
          serviceId = serviceResponse['id'] as String;
          print('✅ Using existing service: ${serviceResponse['service_name']} (ID: $serviceId)');
        } else {
          // No service exists at all - this needs manual creation due to RLS
          print('❌ No services found in database');
          throw Exception(
            'No services available. Please create a service for Ethan Estino first.\n\n'
            'Run this SQL in Supabase:\n'
            'INSERT INTO public.services (technician_id, service_name, description, category, estimated_duration, is_active)\n'
            'VALUES (\'$technicianId\', \'General Repair\', \'Device repair service\', \'Repair\', 60, true);'
          );
        }
      } catch (e) {
        print('❌ Error with service: $e');
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Unable to access services. Please check database setup.');
      }

      // Create booking in Supabase using BookingService
      final bookingService = ref.read(bookingServiceProvider);
      
      final createdBooking = await bookingService.createBooking(
        customerId: user.id,
        technicianId: technicianId,
        serviceId: serviceId,
        scheduledDate: scheduledDateTime,
        customerAddress: _addressController.text.trim(),
        customerLatitude: null, // TODO: Get from address geocoding
        customerLongitude: null,
        estimatedCost: finalPrice,
      );

      // Update diagnostic notes with booking details
      await bookingService.updateDiagnosticNotes(
        bookingId: createdBooking.id,
        notes: bookingDetails,
        finalCost: finalPrice,
      );

      // Mark voucher as used if one was applied
      if (_appliedVoucher != null) {
        final voucherService = ref.read(redeemedVoucherServiceProvider);
        await voucherService.markVoucherAsUsed(
          voucherId: _appliedVoucher!.id,
          bookingId: createdBooking.id,
        );
        // Refresh voucher providers
        ref.invalidate(redeemedVouchersProvider);
        ref.invalidate(unusedVouchersProvider);
      }

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
                context.push('/bookings'); // Go to bookings screen
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

      // Show user-friendly error message
      String errorMessage = 'Error creating booking';
      if (e.toString().contains('technician')) {
        errorMessage = 'No technicians available. Please contact support.';
      } else if (e.toString().contains('service')) {
        errorMessage = 'Service setup incomplete. Please contact support.';
      } else if (e.toString().contains('PostgrestException')) {
        errorMessage = 'Database error. Please ensure all setup is complete.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
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
                controller: _scrollController,
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
                        _scrollController.jumpTo(0);
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
                          _scrollController.jumpTo(0);
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

  void _showDeviceModelPicker() {
    if (_selectedDeviceType == null || _selectedBrand == null) return;
    final devices = _brandDevices[_selectedDeviceType]?[_selectedBrand] ?? [];

    // If brand is "Other" or no devices, let user type manually
    if (_selectedBrand == 'Other' || devices.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select $_selectedBrand Device',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: devices.length + 1, // +1 for "Other" option
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      if (index == devices.length) {
                        // "Other" option at the end
                        return ListTile(
                          leading: const Icon(Icons.edit, color: AppTheme.deepBlue),
                          title: const Text(
                            'Other (type manually)',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedModel = null;
                              _modelController.clear();
                            });
                          },
                        );
                      }
                      final device = devices[index];
                      final isSelected = _selectedModel == device;
                      return ListTile(
                        leading: Icon(
                          _selectedDeviceType == 'Laptop' ? Icons.laptop : Icons.phone_android,
                          color: isSelected ? AppTheme.deepBlue : Colors.grey.shade600,
                        ),
                        title: Text(
                          device,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppTheme.deepBlue : AppTheme.textPrimaryColor,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppTheme.deepBlue)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedModel = device;
                            _modelController.text = device;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeviceStep() {
    final servicePrice = _getServicePrice();
    final brands = _selectedDeviceType != null
        ? (_brandDevices[_selectedDeviceType]?.keys.toList() ?? [])
        : <String>[];

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
        const SizedBox(height: 16),

        // Repair Type Toggle
        const Text(
          'Repair Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isEmergency = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: !_isEmergency ? AppTheme.deepBlue : Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    border: Border.all(
                      color: !_isEmergency ? AppTheme.deepBlue : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.build_outlined,
                        color: !_isEmergency ? Colors.white : Colors.grey.shade600,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Regular Repair',
                        style: TextStyle(
                          color: !_isEmergency ? Colors.white : AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isEmergency = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isEmergency ? Colors.orange.shade700 : Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    border: Border.all(
                      color: _isEmergency ? Colors.orange.shade700 : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: _isEmergency ? Colors.white : Colors.grey.shade600,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Emergency',
                        style: TextStyle(
                          color: _isEmergency ? Colors.white : AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isEmergency) ...[
          const SizedBox(height: 6),
          Text(
            'Emergency repairs have a 10% surcharge for priority service',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
                  _selectedBrand = null;
                  _selectedModel = null;
                  _modelController.clear();
                  _selectedProblem = null;
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      device == 'Mobile Phone' ? Icons.phone_android : Icons.laptop,
                      color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Brand Selection
        if (_selectedDeviceType != null) ...[
          const Text(
            'Brand',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: brands.map((brand) {
              final isSelected = _selectedBrand == brand;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBrand = brand;
                    _selectedModel = null;
                    _modelController.clear();
                  });
                  // Show device picker popup for brands with devices
                  if (brand != 'Other') {
                    Future.delayed(const Duration(milliseconds: 150), () {
                      _showDeviceModelPicker();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    brand,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Device Model (shows selected model or allows manual input)
        if (_selectedBrand != null) ...[
          const Text(
            'Device Model',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedBrand == 'Other' || _selectedModel == null)
            TextField(
              controller: _modelController,
              decoration: InputDecoration(
                hintText: 'Enter your device model',
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
            )
          else
            InkWell(
              onTap: _showDeviceModelPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.deepBlue, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedDeviceType == 'Laptop' ? Icons.laptop : Icons.phone_android,
                      color: AppTheme.deepBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedModel!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    const Icon(Icons.swap_horiz, color: AppTheme.deepBlue, size: 20),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],

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
            _buildReviewItem('Repair Type', _isEmergency ? 'Emergency (+10%)' : 'Regular'),
            _buildReviewItem('Device', _selectedDeviceType ?? ''),
            _buildReviewItem('Brand', _selectedBrand ?? ''),
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
                              _appliedVoucher = null;
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
                Expanded(
                  child: Text(
                    'Promo code "$_appliedPromoCode" applied',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        // My Vouchers section
        if (_appliedPromoCode == null && _availableVouchers.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Or use a voucher',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availableVouchers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final voucher = _availableVouchers[index];
                return GestureDetector(
                  onTap: () => _applyVoucherDirectly(voucher),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.deepBlue.withValues(alpha: 0.08),
                          AppTheme.primaryCyan.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          voucher.voucherTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.deepBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher.discountType == 'percentage'
                              ? '${voucher.discountAmount.toStringAsFixed(0)}% off'
                              : '₱${voucher.discountAmount.toStringAsFixed(0)} off',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to apply',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
