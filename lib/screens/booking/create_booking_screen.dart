import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/supabase_config.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/notification_service.dart';
import '../../services/ratings_service.dart';
import '../../services/technician_specialty_service.dart';
import '../../services/distance_fee_service.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/technician_map_sheet.dart';
import 'widgets/location_picker_sheet.dart';
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

  // Distance fee rate (₱ per 100m) — loaded from Supabase
  double _distanceFeeRate = 5.0;

  // Step 1: Device selection
  String? _selectedDeviceType;
  String? _selectedBrand;
  String? _selectedModel;
  final TextEditingController _modelController = TextEditingController();
  final Set<String> _selectedProblems = {};
  final TextEditingController _detailsController = TextEditingController();

  // Step 2: Time and location
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _selectedDate;
  final TextEditingController _addressController = TextEditingController();
  LatLng? _pickedLatLng; // exact pinned location from map
  String? _selectedTechnicianId;
  List<Map<String, dynamic>> _techniciansFromDb = [];
  bool _isTechniciansLoading = false;

  final String _selectedPaymentMethod = 'gcash'; // App only accepts GCash

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

  // Maps each problem to the technician specialties that cover it
  static const Map<String, List<String>> _problemToSpecialties = {
    'Screen Cracked':  ['Screen Repair', 'Display Replacement', 'iPhone Repair', 'Android Repair', 'Samsung Repair', 'Laptop Repair', 'MacBook Repair'],
    'Battery Drains':  ['Battery Replacement', 'iPhone Repair', 'Android Repair', 'Samsung Repair', 'Laptop Repair', 'MacBook Repair'],
    'Won\'t power on': ['Motherboard Repair', 'Power Button Repair', 'Charging Port Repair', 'Laptop Repair', 'MacBook Repair', 'iPhone Repair', 'Android Repair'],
    'Overheating':     ['Cooling System', 'Motherboard Repair', 'Hardware Upgrade', 'Laptop Repair', 'MacBook Repair'],
    'Water damage':    ['Water Damage Repair', 'Data Recovery', 'Motherboard Repair', 'iPhone Repair', 'Android Repair', 'Laptop Repair', 'MacBook Repair'],
    'Software Bug':    ['Software Issues', 'Virus Removal', 'Data Recovery', 'SSD/HDD Upgrade'],
  };

  /// Returns true if the technician has at least one specialty matching the selected problems.
  bool _isTechnicianRecommended(List<String> techSpecialties) {
    if (_selectedProblems.isEmpty || techSpecialties.isEmpty) return false;
    final relevant = _selectedProblems
        .expand((p) => _problemToSpecialties[p] ?? [])
        .toSet();
    return techSpecialties.any((s) => relevant.contains(s));
  }

  @override
  void initState() {
    super.initState();
    _isEmergency = widget.isEmergency;
    DistanceFeeService.getRate().then((rate) {
      if (mounted) setState(() => _distanceFeeRate = rate);
    });
    // Load default address, vouchers, and technicians
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGcashNotice();
      _loadTechnicians();
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
                if (defaultAddress.latitude != null && defaultAddress.longitude != null) {
                  _pickedLatLng = LatLng(defaultAddress.latitude!, defaultAddress.longitude!);
                }
              });
            }
          }
        });
      } catch (e) {
        // Address loading failed, user can enter manually
      }
    });
  }


  Future<void> _loadTechnicians() async {
    if (!mounted) return;
    setState(() => _isTechniciansLoading = true);

    try {
      final supabase = SupabaseConfig.client;
      final specialtyService = TechnicianSpecialtyService();

      // Fetch available technician profiles.
      // Also fetch schedule, busy status and accept-while-busy preference.
      final availableProfiles = await supabase
          .from('technician_profiles')
          .select('user_id, weekly_schedule, is_busy, accept_requests_while_busy')
          .eq('is_available', true);

      // Build lookup: userId → profile data
      final profileMap = <String, Map<String, dynamic>>{
        for (final p in (availableProfiles as List))
          p['user_id'] as String: Map<String, dynamic>.from(p as Map),
      };

      // Only keep technicians who pass the schedule check AND either
      // are not busy, or are busy but accept new requests.
      final availableIds = profileMap.entries
          .where((e) {
            if (!_techIsOnlineNow(e.value['weekly_schedule'])) return false;
            final isBusy = e.value['is_busy'] as bool? ?? false;
            final acceptWhileBusy = e.value['accept_requests_while_busy'] as bool? ?? false;
            return !isBusy || acceptWhileBusy;
          })
          .map((e) => e.key)
          .toSet();

      // Fetch all technician users then keep only available ones
      final allTechRows = await supabase
          .from('users')
          .select()
          .eq('role', 'technician');
      final techRows = (allTechRows as List)
          .where((row) => availableIds.contains(row['id'] as String))
          .toList();

      final List<Map<String, dynamic>> results = [];

      for (final row in techRows) {
        final techId = row['id'] as String;

        // Load specialties (safe - returns empty list on error)
        List<String> specialtyNames = [];
        try {
          final specialties = await specialtyService.getTechnicianSpecialties(techId);
          specialtyNames = specialties.map((s) => s.specialtyName).toList();
        } catch (_) {}

        // Load stats (rating, completed jobs, experience)
        double avgRating = 0.0;
        int completedJobs = 0;
        String experience = 'New';

        // Calculate live average — always combine UUID rows + legacy name-matched rows
        final techFullName = row['full_name'] as String? ?? '';
        try {
          final seenIds = <String>{};
          final vals = <int>[];

          // UUID rows
          try {
            final byId = await supabase
                .from('app_ratings')
                .select('id, rating')
                .eq('technician_id', techId);
            for (final r in (byId as List)) {
              final id = r['id'] as String? ?? '';
              if (seenIds.add(id)) vals.add((r['rating'] as num).toInt());
            }
          } catch (_) {}

          // Legacy rows (no technician_id) — always run
          final allRatings = await supabase
              .from('app_ratings')
              .select('id, rating, technician, technician_id');
          final myName = techFullName.toLowerCase().trim();
          final nameParts = techFullName.split(' ');
          final lastName = nameParts.length > 1 ? nameParts.last.toLowerCase() : null;
          for (final r in (allRatings as List)) {
            if (r['technician_id'] != null) continue;
            final id = r['id'] as String? ?? '';
            if (seenIds.contains(id)) continue;
            final stored = (r['technician'] as String? ?? '').toLowerCase().trim();
            final matches = stored == myName ||
                (myName.contains(stored) && stored.length > 2) ||
                (lastName != null && stored == lastName);
            if (matches && seenIds.add(id)) vals.add((r['rating'] as num).toInt());
          }

          if (vals.isNotEmpty) {
            avgRating = vals.reduce((a, b) => a + b) / vals.length;
          }
        } catch (_) {}

        // Load completed jobs and experience from cached stats
        try {
          final statsRow = await supabase
              .from('app_technician_stats')
              .select('completed_jobs, experience')
              .eq('technician_id', techId)
              .maybeSingle();
          if (statsRow != null) {
            completedJobs = (statsRow['completed_jobs'] as num?)?.toInt() ?? 0;
            experience = statsRow['experience'] as String? ?? 'New';
          }
        } catch (_) {}

        // Use technician's saved lat/lng if available
        final techLat = (row['latitude'] as num?)?.toDouble();
        final techLng = (row['longitude'] as num?)?.toDouble();

        // Calculate real distance if both have coordinates, else fallback to random
        double distanceKm;
        if (techLat != null && techLng != null && _pickedLatLng != null) {
          distanceKm = _haversineKm(
            techLat, techLng,
            _pickedLatLng!.latitude, _pickedLatLng!.longitude,
          );
        } else {
          final rawKm = 1.0 + Random().nextDouble();
          distanceKm = (rawKm * 10).round() / 10.0;
        }
        distanceKm = double.parse(distanceKm.toStringAsFixed(1));
        // fee rate loaded from admin settings (₱ per 100m)
        final distanceFee = (distanceKm * 10).round() * _distanceFeeRate;

        final techProfile = profileMap[techId];
        results.add({
          'id': techId,
          'name': row['full_name'] as String? ?? 'Technician',
          'profilePicture': row['profile_picture'] as String?,
          'bio': row['bio'] as String?,
          'verified': row['verified'] as bool? ?? false,
          'specialties': specialtyNames,
          'rating': avgRating,
          'completedJobs': completedJobs,
          'experience': experience,
          'distanceKm': distanceKm,
          'distanceFee': distanceFee,
          'latitude': techLat,
          'longitude': techLng,
          'isBusy': techProfile?['is_busy'] as bool? ?? false,
        });
      }

      if (mounted) {
        setState(() {
          _techniciansFromDb = results;
          _isTechniciansLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTechniciansLoading = false);
      }
    }
  }

  /// Equirectangular approximation — returns distance in km.
  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const toRad = pi / 180;
    final dlat = (lat2 - lat1) * 111.0;
    final dlng = (lng2 - lng1) * 111.0 * cos((lat1 + lat2) / 2 * toRad);
    return sqrt(dlat * dlat + dlng * dlng);
  }

  Map<String, dynamic>? get _selectedTechData {
    if (_selectedTechnicianId == null) return null;
    try {
      return _techniciansFromDb.firstWhere((t) => t['id'] == _selectedTechnicianId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _detailsController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _getServicePrice() {
    if (_selectedDeviceType == null || _selectedProblems.isEmpty) return 0.0;
    double base = 0.0;
    for (final problem in _selectedProblems) {
      base += _pricing[_selectedDeviceType]?[problem] ?? 0.0;
    }
    return _isEmergency ? base * 1.10 : base;
  }

  double _getDistanceFee() {
    final tech = _selectedTechData;
    if (tech == null) return 0.0;
    return (tech['distanceFee'] as num?)?.toDouble() ?? 0.0;
  }

  double _getSelectedDistanceKm() {
    final tech = _selectedTechData;
    if (tech == null) return 0.0;
    return (tech['distanceKm'] as num?)?.toDouble() ?? 0.0;
  }

  double _calculatePrice() {
    return _getServicePrice() + _getDistanceFee();
  }

  double _calculateFinalPrice() => _calculatePrice();

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
        if (_detailsController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please describe the problem')),
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
        if (_selectedTechnicianId == null) {
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
      final serviceFee = _getServicePrice();
      final distanceFee = _getDistanceFee();
      final bookingDetails = [
        'Repair Type: ${_isEmergency ? "Emergency" : "Regular"}',
        'Device: $_selectedDeviceType',
        'Brand: $_selectedBrand',
        'Model: ${_modelController.text.trim()}',
        'Problem: ${_detailsController.text.trim()}',
        'Technician: ${_selectedTechData?['name'] ?? 'N/A'}',
        'Payment Method: GCash',
        'Service Fee: ₱${serviceFee.toStringAsFixed(2)}',
        'Distance Fee: ₱${distanceFee.toStringAsFixed(2)}',
        'Convenience Fee Rate: 5',
      ].join('\n');

      // Use the selected technician directly
      final technicianId = _selectedTechnicianId!;
      final supabase = SupabaseConfig.client;

      // Get or create a service ID for this technician
      String serviceId;
      var serviceResponse = await supabase
          .from('services')
          .select('id')
          .eq('technician_id', technicianId)
          .limit(1)
          .maybeSingle();

      serviceResponse ??= await supabase
          .from('services')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (serviceResponse != null) {
        serviceId = serviceResponse['id'] as String;
      } else {
        throw Exception('No services available. Please contact support.');
      }

      // Create booking in Supabase using BookingService
      final bookingService = ref.read(bookingServiceProvider);

      final createdBooking = await bookingService.createBooking(
        customerId: user.id,
        technicianId: technicianId,
        serviceId: serviceId,
        scheduledDate: scheduledDateTime,
        customerAddress: _addressController.text.trim(),
        customerLatitude: _pickedLatLng?.latitude,
        customerLongitude: _pickedLatLng?.longitude,
        estimatedCost: finalPrice,
        paymentMethod: _selectedPaymentMethod,
      );

      // Update diagnostic notes with booking details
      await bookingService.updateDiagnosticNotes(
        bookingId: createdBooking.id,
        notes: bookingDetails,
        finalCost: finalPrice,
      );

      // Notify the technician of the new booking request
      final customerName = user.fullName;
      final problemList = _selectedProblems.join(', ');
      await NotificationService().sendNotification(
        userId: technicianId,
        type: 'booking_request',
        title: 'New Booking Request',
        message: '$customerName has requested a repair for: $problemList. Tap to view details.',
        data: {'booking_id': createdBooking.id, 'route': '/tech-jobs'},
      );

      // Also notify the customer that their booking was submitted
      await NotificationService().sendNotification(
        userId: user.id,
        type: 'booking_request',
        title: 'Booking Submitted',
        message: 'Your booking has been submitted. Please wait for the technician to accept your request.',
        data: {'booking_id': createdBooking.id, 'route': '/booking/${createdBooking.id}'},
      );

      // Force refresh bookings so the new booking appears immediately (no hot restart)
      ref.invalidate(customerBookingsProvider);
      ref.invalidate(technicianBookingsProvider);

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
                    onPressed: _isLoading ? null : () async {
                      if (_currentStep < 2) {
                        if (_validateStep(_currentStep)) {
                          // On step 0 (tech selection), warn if busy tech selected
                          if (_currentStep == 0) {
                            final tech = _selectedTechData;
                            final busy = tech?['isBusy'] as bool? ?? false;
                            if (busy) {
                              final proceed = await _showBusyWarning(
                                tech?['name'] as String? ?? 'This technician',
                              );
                              if (proceed != true) return;
                            }
                          }
                          setState(() { _currentStep++; });
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
                    separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
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
                onTap: () => setState(() {
                  _isEmergency = false;
                  _selectedDate = null;
                }),
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
                onTap: () => setState(() {
                  _isEmergency = true;
                  _selectedDate = DateTime.now();
                }),
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
                  _selectedProblems.clear();
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

        // What's the problem?
        const Text(
          'What\'s the Problem?',
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
            hintText: 'e.g. Screen is cracked, battery drains fast...',
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
            '* Distance fee ₱${_distanceFeeRate.toStringAsFixed(0)} per 100m varies per technician location',
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

  void _showTechnicianMap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TechnicianMapSheet(
        technicians: _techniciansFromDb,
        selectedTechnicianId: _selectedTechnicianId,
        onTechnicianSelected: (id) {
          setState(() => _selectedTechnicianId = id);
        },
      ),
    );
  }

  Future<void> _checkAndShowGcashNotice() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'gcash_notice_seen_${user.id}';
    if (prefs.getBool(key) == true) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payment_rounded, size: 36, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              'GCash Only',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              'FixIT currently accepts GCash as the only payment method. Please make sure your GCash account is ready before proceeding with a booking.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await prefs.setBool(key, true);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Got it', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showBusyWarning(String techName) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.engineering_rounded, size: 36, color: Colors.orange.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              '$techName is currently busy',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'This technician is currently working on another job. You can still send your request — they\'ll respond once they\'re free. This may take longer than usual.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Send Request Anyway', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Find Another Technician', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTechnicianDetails(Map<String, dynamic> tech) {
    final name = tech['name'] as String;
    final bio = tech['bio'] as String?;
    final rating = (tech['rating'] as num?)?.toDouble() ?? 0.0;
    final completedJobs = (tech['completedJobs'] as num?)?.toInt() ?? 0;
    final experience = tech['experience'] as String? ?? 'New';
    final specialties = (tech['specialties'] as List<String>?) ?? [];
    final verified = tech['verified'] as bool? ?? false;
    final profilePic = tech['profilePicture'] as String?;
    final initials = name.split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Profile header
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.deepBlue,
                    backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                        ? NetworkImage(profilePic)
                        : null,
                    child: (profilePic == null || profilePic.isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppTheme.deepBlue, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.deepBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      experience,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTechStat(Icons.star, Colors.amber, rating > 0 ? rating.toStringAsFixed(1) : 'N/A', 'Rating'),
                      const SizedBox(width: 24),
                      _buildTechStat(Icons.work, AppTheme.deepBlue, '$completedJobs', 'Jobs Done'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  if (bio != null && bio.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        bio,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimaryColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Specialties
                  if (specialties.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Specialties',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: specialties.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.deepBlue,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Customer Reviews
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Customer Reviews',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Rating>>(
                    future: RatingsService().getAllReviewsForTechnician(name, tech['id'] as String),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final reviews = snap.data ?? [];
                      if (reviews.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.rate_review_outlined, size: 20, color: Colors.grey[400]),
                              const SizedBox(width: 8),
                              Text('No reviews yet', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: reviews.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildReviewCard(r),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Select button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTechnicianId = tech['id'];
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedTechnicianId == tech['id'] ? 'Selected' : 'Select This Technician',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTechnicianReviews(String technicianName, String technicianId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Reviews for $technicianName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Rating>>(
                future: RatingsService().getAllReviewsForTechnician(technicianName, technicianId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final reviews = snap.data ?? [];
                  if (reviews.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No reviews yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (ctx, i) => _buildReviewCard(reviews[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Rating r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.deepBlue.withValues(alpha: 0.15),
              child: Text(
                r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.deepBlue),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(r.date, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            Row(
              children: List.generate(5, (i) => Icon(
                i < r.rating ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.amber,
              )),
            ),
          ],
        ),
        if (r.review.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.review, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor, height: 1.4)),
        ],
        if (r.service.isNotEmpty || r.device.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            [if (r.device.isNotEmpty) r.device, if (r.service.isNotEmpty) r.service].join(' · '),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  Widget _buildTechStat(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
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
          onTap: _isEmergency ? null : _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isEmergency ? Colors.orange.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isEmergency ? Colors.orange.shade300 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isEmergency ? Icons.lock : Icons.calendar_today,
                  color: _isEmergency ? Colors.orange.shade700 : AppTheme.deepBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEmergency
                        ? 'Today — ${DateFormat('MMM dd, yyyy').format(DateTime.now())} (locked)'
                        : (_selectedDate == null
                            ? 'Select Date'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!)),
                    style: TextStyle(
                      fontSize: 16,
                      color: _isEmergency
                          ? Colors.orange.shade700
                          : (_selectedDate == null ? Colors.grey.shade600 : AppTheme.textPrimaryColor),
                      fontWeight: _isEmergency || _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                    ),
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
        const SizedBox(height: 8),
        // Pin exact location on map
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<PickedLocation>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => LocationPickerSheet(
                initialLocation: _pickedLatLng,
              ),
            );
            if (result != null) {
              setState(() => _pickedLatLng = result.latLng);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _pickedLatLng != null
                  ? const Color(0xFF4A5FE0).withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _pickedLatLng != null
                    ? const Color(0xFF4A5FE0).withValues(alpha: 0.4)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _pickedLatLng != null ? Icons.location_pin : Icons.add_location_alt_outlined,
                  color: const Color(0xFF4A5FE0),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _pickedLatLng != null
                        ? 'Pinned: ${_pickedLatLng!.latitude.toStringAsFixed(5)}, ${_pickedLatLng!.longitude.toStringAsFixed(5)}'
                        : 'Pin exact location on map (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      color: _pickedLatLng != null
                          ? const Color(0xFF4A5FE0)
                          : Colors.grey.shade600,
                      fontWeight: _pickedLatLng != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Technician Selection
        Row(
          children: [
            const Expanded(
              child: Text(
                'Select Technician',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (_isTechniciansLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: _loadTechnicians,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh technicians',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppTheme.deepBlue,
              ),
            if (!_isTechniciansLoading && _techniciansFromDb.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showTechnicianMap(),
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('View on Map'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.deepBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a technician to see their details',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        if (_isTechniciansLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_techniciansFromDb.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No technicians available at the moment.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...(() {
            final sorted = [..._techniciansFromDb];
            sorted.sort((a, b) {
              final aRec = _isTechnicianRecommended((a['specialties'] as List<String>?) ?? []);
              final bRec = _isTechnicianRecommended((b['specialties'] as List<String>?) ?? []);
              if (aRec && !bRec) return -1;
              if (!aRec && bRec) return 1;
              return 0;
            });
            return sorted;
          }()).map((tech) {
            final isSelected = _selectedTechnicianId == tech['id'];
            final isBusy = tech['isBusy'] as bool? ?? false;
            final rating = (tech['rating'] as num?)?.toDouble() ?? 0.0;
            final specialties = (tech['specialties'] as List<String>?) ?? [];
            final isRecommended = _isTechnicianRecommended(specialties);
            final experience = tech['experience'] as String? ?? 'New';
            final distanceKm = (tech['distanceKm'] as num?)?.toDouble() ?? 0.0;
            final distanceFee = (tech['distanceFee'] as num?)?.toDouble() ?? 0.0;
            final profilePic = tech['profilePicture'] as String?;
            final name = tech['name'] as String;
            final initials = name.split(' ')
                .where((s) => s.isNotEmpty)
                .take(2)
                .map((s) => s[0].toUpperCase())
                .join();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTechnicianId = tech['id'];
                  });
                },
                onLongPress: () => _showTechnicianDetails(tech),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
                            backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                                ? NetworkImage(profilePic)
                                : null,
                            child: (profilePic == null || profilePic.isEmpty)
                                ? Text(
                                    initials,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (tech['verified'] == true) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: AppTheme.deepBlue, size: 16),
                                    ],
                                    if (isRecommended) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.recommend_rounded, color: Colors.white, size: 10),
                                            SizedBox(width: 3),
                                            Text(
                                              'Recommended',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (isBusy) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade600,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.engineering_rounded, color: Colors.white, size: 10),
                                            SizedBox(width: 3),
                                            Text(
                                              'Busy',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: rating > 0 ? () => _showTechnicianReviews(name, tech['id'] as String) : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: rating > 0 ? Colors.amber.withValues(alpha: 0.12) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star, size: 14, color: Colors.amber),
                                            const SizedBox(width: 3),
                                            Text(
                                              rating > 0 ? rating.toStringAsFixed(1) : 'New',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            if (rating > 0) ...[
                                              const SizedBox(width: 2),
                                              Icon(Icons.chevron_right, size: 12, color: Colors.grey[500]),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.work_outline, size: 13, color: Colors.grey[500]),
                                    const SizedBox(width: 3),
                                    Text(
                                      experience,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${distanceKm.toStringAsFixed(1)} km away',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(Icons.directions_car_outlined, size: 13, color: AppTheme.deepBlue),
                                    const SizedBox(width: 3),
                                    Text(
                                      '+₱${distanceFee.toStringAsFixed(0)} fee',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.deepBlue, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => _showTechnicianDetails(tech),
                                child: const Icon(Icons.info_outline, color: AppTheme.deepBlue, size: 20),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? AppTheme.deepBlue : Colors.grey.shade400,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Specialties chips
                      if (specialties.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: specialties.take(3).map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.lightBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.deepBlue,
                                ),
                              ),
                            )).toList()
                            ..addAll(specialties.length > 3 ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+${specialties.length - 3} more',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                              ),
                            ] : []),
                          ),
                        ),
                      ],
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
            _buildReviewItem('Problem', _detailsController.text),
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
            _buildReviewItem('Technician', _selectedTechData?['name'] ?? ''),
          ],
        ),
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
                  Text(
                    'Distance Fee (${_getSelectedDistanceKm().toStringAsFixed(1)} km)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
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

/// Returns true if the current day and time fall within the technician's
/// weekly schedule. If no schedule is stored, returns true (rely on
/// is_available flag which was already checked in the DB query).
bool _techIsOnlineNow(dynamic weeklyScheduleJson) {
  if (weeklyScheduleJson == null) return true;
  const days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  final now     = DateTime.now();
  final dayName = days[now.weekday - 1]; // weekday: 1=Mon … 7=Sun
  final schedule = weeklyScheduleJson as Map<String, dynamic>;
  final dayData  = schedule[dayName] as Map<String, dynamic>?;
  if (dayData == null || dayData['enabled'] != true) return false;
  final startStr = (dayData['start'] as String?) ?? '09:00';
  final endStr   = (dayData['end']   as String?) ?? '18:00';
  final sp = startStr.split(':');
  final ep = endStr.split(':');
  final startMin = int.parse(sp[0]) * 60 + int.parse(sp[1]);
  final endMin   = int.parse(ep[0]) * 60 + int.parse(ep[1]);
  final nowMin   = now.hour * 60 + now.minute;
  return nowMin >= startMin && nowMin < endMin;
}

