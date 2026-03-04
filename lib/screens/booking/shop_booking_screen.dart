import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/redeemed_voucher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/rewards_provider.dart';

// ─────────────────────────────────────────────
// Data class passed from home screen → router
// ─────────────────────────────────────────────
class ShopInfo {
  final String shopName;
  final String ownerName;
  final double rating;
  final int reviewCount;
  final List<String> services;
  final String openTime;
  final bool isOpen;
  final List<Color> gradientColors;
  final String shopAddress;
  // The shop's dedicated technician ID (nullable — if null we pick any available)
  final String? technicianId;

  const ShopInfo({
    required this.shopName,
    required this.ownerName,
    required this.rating,
    required this.reviewCount,
    required this.services,
    required this.openTime,
    required this.isOpen,
    required this.gradientColors,
    required this.shopAddress,
    this.technicianId,
  });
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
class ShopBookingScreen extends ConsumerStatefulWidget {
  final ShopInfo shop;

  const ShopBookingScreen({super.key, required this.shop});

  @override
  ConsumerState<ShopBookingScreen> createState() => _ShopBookingScreenState();
}

class _ShopBookingScreenState extends ConsumerState<ShopBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // Step 1 — Device
  bool _isEmergency = false;
  String? _selectedDeviceType;
  String? _selectedBrand;
  final TextEditingController _modelController = TextEditingController();
  Set<String> _selectedProblems = {};
  final TextEditingController _detailsController = TextEditingController();

  // Step 2 — Drop-off schedule
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();

  // Step 3 — Promo / voucher
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  double _discountAmount = 0;
  String _discountType = 'none';
  RedeemedVoucher? _appliedVoucher;
  List<RedeemedVoucher> _availableVouchers = [];

  // Resolved technician ID (fetched from DB if shop doesn't provide one)
  String? _resolvedTechId;
  String? _resolvedTechName;

  // ── Pricing ──────────────────────────────────────────────
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
    'Screen Cracked', 'Battery Drains', 'Won\'t power on',
    'Overheating', 'Water damage', 'Software Bug',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVouchers();
      _resolveTechnician();
    });
  }

  Future<void> _loadVouchers() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final voucherService = ref.read(redeemedVoucherServiceProvider);
    final vouchers = await voucherService.getUnusedVouchers(user.id);
    if (mounted) setState(() => _availableVouchers = vouchers);
  }

  Future<void> _resolveTechnician() async {
    if (widget.shop.technicianId != null) {
      // Shop provides a specific technician
      final row = await SupabaseConfig.client
          .from('users')
          .select('id, full_name')
          .eq('id', widget.shop.technicianId!)
          .maybeSingle();
      if (mounted && row != null) {
        setState(() {
          _resolvedTechId = row['id'] as String;
          _resolvedTechName = row['full_name'] as String? ?? widget.shop.ownerName;
        });
      }
    } else {
      // No specific technician — pick the first available verified technician
      final rows = await SupabaseConfig.client
          .from('users')
          .select('id, full_name')
          .eq('role', 'technician')
          .eq('verified', true)
          .limit(1);
      if (mounted && rows.isNotEmpty) {
        setState(() {
          _resolvedTechId = rows.first['id'] as String;
          _resolvedTechName = rows.first['full_name'] as String? ?? 'Shop Technician';
        });
      }
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    _promoCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Pricing helpers ───────────────────────────────────────

  double _getServicePrice() {
    if (_selectedDeviceType == null || _selectedProblems.isEmpty) return 0.0;
    double base = 0.0;
    for (final p in _selectedProblems) {
      base += _pricing[_selectedDeviceType]?[p] ?? 0.0;
    }
    return _isEmergency ? base * 1.10 : base;
  }

  double _calculateFinalPrice() {
    final base = _getServicePrice();
    if (_discountType == 'percentage') return base - (base * _discountAmount / 100);
    if (_discountType == 'fixed') return base - _discountAmount;
    return base;
  }

  // ── Promo code ────────────────────────────────────────────

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();
    const promoCodes = {
      'WELCOME10': {'type': 'percentage', 'amount': 10.0},
      'FIRST20':   {'type': 'percentage', 'amount': 20.0},
      'SAVE500':   {'type': 'fixed',      'amount': 500.0},
      'FIRSTTIME': {'type': 'percentage', 'amount': 15.0},
    };
    if (promoCodes.containsKey(code)) {
      setState(() {
        _appliedPromoCode = code;
        _discountType = promoCodes[code]!['type'] as String;
        _discountAmount = promoCodes[code]!['amount'] as double;
        _appliedVoucher = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code applied!'), backgroundColor: Colors.green),
      );
      return;
    }
    final matching = _availableVouchers.where((v) =>
        'VOUCHER${v.voucherId}'.toUpperCase() == code).toList();
    if (matching.isNotEmpty) {
      final v = matching.first;
      setState(() {
        _appliedPromoCode = code;
        _discountType = v.discountType;
        _discountAmount = v.discountAmount;
        _appliedVoucher = v;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher "${v.voucherTitle}" applied!'), backgroundColor: Colors.green),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid promo code'), backgroundColor: Colors.red),
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
  }

  // ── Date / time pickers ───────────────────────────────────

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.deepBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.deepBlue,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Validation ────────────────────────────────────────────

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_selectedDeviceType == null) {
          _snack('Please select a device type');
          return false;
        }
        if (_selectedBrand == null) {
          _snack('Please select a brand');
          return false;
        }
        if (_modelController.text.trim().isEmpty) {
          _snack('Please select or enter a device model');
          return false;
        }
        if (_selectedProblems.isEmpty) {
          _snack('Please select at least one problem');
          return false;
        }
        return true;
      case 1:
        if (_selectedDate == null) {
          _snack('Please select a drop-off date');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Confirm booking ───────────────────────────────────────

  Future<void> _confirmBooking() async {
    if (!_validateStep(_currentStep)) return;
    if (_resolvedTechId == null) {
      _snack('No technician available for this shop right now');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('User not logged in');

      final finalPrice = _calculateFinalPrice();
      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final bookingDetails = [
        'Booking Type: SHOP',
        'Shop: ${widget.shop.shopName}',
        'Shop Address: ${widget.shop.shopAddress}',
        'Repair Type: ${_isEmergency ? "Emergency" : "Regular"}',
        'Device: $_selectedDeviceType',
        'Brand: $_selectedBrand',
        'Model: ${_modelController.text.trim()}',
        'Problem: ${_selectedProblems.join(', ')}',
        'Technician: ${_resolvedTechName ?? widget.shop.ownerName}',
        if (_detailsController.text.trim().isNotEmpty)
          'Details: ${_detailsController.text.trim()}',
        if (_notesController.text.trim().isNotEmpty)
          'Customer Notes: ${_notesController.text.trim()}',
        if (_appliedPromoCode != null) 'Promo Code: $_appliedPromoCode',
        if (_appliedVoucher != null) 'Redeemed Voucher ID: ${_appliedVoucher!.id}',
      ].join('\n');

      final supabase = SupabaseConfig.client;

      // Get or create a service ID
      String serviceId;
      var svcRes = await supabase
          .from('services')
          .select('id')
          .eq('technician_id', _resolvedTechId!)
          .limit(1)
          .maybeSingle();
      svcRes ??= await supabase.from('services').select('id').limit(1).maybeSingle();
      if (svcRes == null) throw Exception('No services available. Please contact support.');
      serviceId = svcRes['id'] as String;

      final bookingService = ref.read(bookingServiceProvider);
      final booking = await bookingService.createBooking(
        customerId: user.id,
        technicianId: _resolvedTechId!,
        serviceId: serviceId,
        scheduledDate: scheduledDateTime,
        customerAddress: widget.shop.shopAddress,
        estimatedCost: finalPrice,
      );

      await bookingService.updateDiagnosticNotes(
        bookingId: booking.id,
        notes: bookingDetails,
        finalCost: finalPrice,
      );

      ref.invalidate(customerBookingsProvider);
      ref.invalidate(technicianBookingsProvider);

      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Booking Confirmed!'),
            ],
          ),
          content: Text(
            'Your drop-off booking at ${widget.shop.shopName} has been submitted. '
            'The shop will confirm your appointment shortly.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/bookings');
              },
              child: const Text('View Bookings'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.deepBlue),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final steps = ['Device', 'Drop-off Schedule', 'Review'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        title: const Text(
          'Book at Shop',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Column(
        children: [
          // ── Shop banner ──────────────────────────────────
          _ShopBanner(shop: widget.shop),

          // ── Step indicators ──────────────────────────────
          _StepIndicator(steps: steps, currentStep: _currentStep),

          // ── Step content ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStep(_currentStep),
                ),
              ),
            ),
          ),

          // ── Bottom navigation bar ────────────────────────
          _BottomNav(
            currentStep: _currentStep,
            totalSteps: steps.length,
            isLoading: _isLoading,
            onBack: () => setState(() => _currentStep--),
            onNext: () {
              if (_validateStep(_currentStep)) {
                if (_currentStep < steps.length - 1) {
                  setState(() => _currentStep++);
                } else {
                  _confirmBooking();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildDeviceStep();
      case 1:
        return _buildScheduleStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════
  // STEP 1 — DEVICE INFO
  // ══════════════════════════════════════════

  Widget _buildDeviceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Device Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        const SizedBox(height: 20),

        // Emergency toggle
        _buildSectionCard(
          title: 'Repair Type',
          child: Row(
            children: [
              _buildTypeButton('Regular', !_isEmergency, () => setState(() => _isEmergency = false)),
              const SizedBox(width: 12),
              _buildTypeButton('Emergency (+10%)', _isEmergency, () => setState(() => _isEmergency = true),
                  color: Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Device type
        _buildSectionCard(
          title: 'Device Type',
          child: Row(
            children: ['Mobile Phone', 'Laptop'].map((type) {
              final selected = _selectedDeviceType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDeviceType = type;
                    _selectedBrand = null;
                    _modelController.clear();
                    _selectedProblems = {};
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.deepBlue : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.deepBlue : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type == 'Mobile Phone' ? Icons.smartphone : Icons.laptop,
                          color: selected ? Colors.white : AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(height: 6),
                        Text(type,
                            style: TextStyle(
                              color: selected ? Colors.white : AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        if (_selectedDeviceType != null) ...[
          // Brand
          _buildSectionCard(
            title: 'Brand',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_brandDevices[_selectedDeviceType]?.keys.toList() ?? []).map((brand) {
                final selected = _selectedBrand == brand;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedBrand = brand;
                    _modelController.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.deepBlue : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppTheme.deepBlue : Colors.grey.shade300),
                    ),
                    child: Text(brand,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_selectedBrand != null) ...[
          // Model
          _buildSectionCard(
            title: 'Device Model',
            child: _buildModelField(),
          ),
          const SizedBox(height: 16),
        ],

        if (_selectedDeviceType != null) ...[
          // Problems
          _buildSectionCard(
            title: 'Problem(s)',
            subtitle: 'Select all that apply',
            child: Column(
              children: _problems.map((p) {
                final selected = _selectedProblems.contains(p);
                final price = _pricing[_selectedDeviceType]?[p] ?? 0.0;
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedProblems.add(p);
                    } else {
                      _selectedProblems.remove(p);
                    }
                  }),
                  title: Text(p, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('₱${price.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.deepBlue, fontWeight: FontWeight.w600)),
                  activeColor: AppTheme.deepBlue,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Additional details
        _buildSectionCard(
          title: 'Additional Details',
          subtitle: 'Optional — describe the issue in more detail',
          child: TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'E.g. "Screen cracked on bottom left corner"',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),

        if (_selectedProblems.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPricePreview(),
        ],
      ],
    );
  }

  Widget _buildModelField() {
    final models = _brandDevices[_selectedDeviceType]?[_selectedBrand] ?? [];
    if (models.isEmpty) {
      return TextField(
        controller: _modelController,
        decoration: const InputDecoration(
          hintText: 'Enter device model',
          border: InputBorder.none,
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showModelPicker(models),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _modelController.text.isEmpty ? 'Select model' : _modelController.text,
                style: TextStyle(
                  color: _modelController.text.isEmpty
                      ? Colors.grey.shade400
                      : AppTheme.textPrimaryColor,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(List<String> models) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: models.map((m) => ListTile(
                title: Text(m),
                onTap: () {
                  setState(() {
                    _modelController.text = m;
                  });
                  Navigator.pop(ctx);
                },
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPricePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: widget.shop.gradientColors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estimated Service Price',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('₱${_getServicePrice().toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.storefront, color: Colors.white54, size: 20),
          const SizedBox(width: 4),
          const Text('Shop\nVisit', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, bool selected, VoidCallback onTap,
      {Color color = AppTheme.deepBlue}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.grey.shade300),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // STEP 2 — DROP-OFF SCHEDULE
  // ══════════════════════════════════════════

  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Drop-off Schedule',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        const SizedBox(height: 8),
        Text('Choose when to drop off your device at ${widget.shop.shopName}',
            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14)),
        const SizedBox(height: 24),

        // Shop info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.shop.gradientColors),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.shop.shopName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(widget.shop.shopAddress,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.shop.isOpen ? Colors.green.shade400 : Colors.red.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.shop.isOpen ? 'Open Now' : 'Closed',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(widget.shop.openTime,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Date picker
        _buildSectionCard(
          title: 'Drop-off Date',
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.deepBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Select date'
                        : DateFormat('EEE, MMM dd, yyyy').format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null ? Colors.grey.shade400 : AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Time picker
        _buildSectionCard(
          title: 'Drop-off Time',
          child: GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppTheme.deepBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Additional notes
        _buildSectionCard(
          title: 'Notes for the Shop',
          subtitle: 'Optional — any special requests',
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'E.g. "Please call before starting repairs"',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Assigned technician info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primaryCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.build_circle, color: AppTheme.deepBlue, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shop Technician',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor, fontSize: 13)),
                    Text(
                      _resolvedTechName ?? 'Loading technician...',
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_resolvedTechId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Assigned',
                      style: TextStyle(
                          color: AppTheme.successColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // STEP 3 — REVIEW
  // ══════════════════════════════════════════

  Widget _buildReviewStep() {
    final servicePrice = _getServicePrice();
    final finalPrice = _calculateFinalPrice();
    final discount = servicePrice - finalPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Booking',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        const SizedBox(height: 20),

        // Shop info
        _buildReviewSection('Shop Information', [
          _buildReviewItem('Shop Name', widget.shop.shopName),
          _buildReviewItem('Address', widget.shop.shopAddress),
          _buildReviewItem('Hours', widget.shop.openTime),
          _buildReviewItem('Assigned Technician', _resolvedTechName ?? 'Shop Technician'),
        ]),
        const SizedBox(height: 16),

        // Device
        _buildReviewSection('Device Information', [
          _buildReviewItem('Repair Type', _isEmergency ? 'Emergency (+10%)' : 'Regular'),
          _buildReviewItem('Device', _selectedDeviceType ?? ''),
          _buildReviewItem('Brand', _selectedBrand ?? ''),
          _buildReviewItem('Model', _modelController.text),
          _buildReviewItem('Problem(s)', _selectedProblems.join(', ')),
          if (_detailsController.text.isNotEmpty)
            _buildReviewItem('Details', _detailsController.text),
        ]),
        const SizedBox(height: 16),

        // Schedule
        _buildReviewSection('Drop-off Schedule', [
          _buildReviewItem(
            'Date & Time',
            _selectedDate == null
                ? 'Not set'
                : '${DateFormat('MMM dd, yyyy').format(_selectedDate!)} at ${_selectedTime.format(context)}',
          ),
          if (_notesController.text.isNotEmpty)
            _buildReviewItem('Notes', _notesController.text),
        ]),
        const SizedBox(height: 20),

        // Promo code
        const Text('Promo Code (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
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
                          onPressed: () => setState(() {
                            _appliedPromoCode = null;
                            _discountAmount = 0;
                            _discountType = 'none';
                            _appliedVoucher = null;
                            _promoCodeController.clear();
                          }),
                        )
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_appliedPromoCode == null)
              ElevatedButton(
                onPressed: _applyPromoCode,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                child: const Text('Apply', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        if (_appliedPromoCode != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text('Promo code "$_appliedPromoCode" applied',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],

        // Vouchers
        if (_appliedPromoCode == null && _availableVouchers.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Or use a voucher',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availableVouchers.length,
              separatorBuilder: (_, i) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final v = _availableVouchers[i];
                return GestureDetector(
                  onTap: () => _applyVoucherDirectly(v),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.deepBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.voucherTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deepBlue,
                                fontSize: 12)),
                        const Spacer(),
                        Text(
                          v.discountType == 'percentage'
                              ? '${v.discountAmount.toInt()}% OFF'
                              : '₱${v.discountAmount.toInt()} OFF',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: AppTheme.deepBlue, fontSize: 16),
                        ),
                        const Text('Tap to apply',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Price summary
        _buildReviewSection('Price Summary', [
          _buildReviewItem('Service Fee', '₱${servicePrice.toStringAsFixed(2)}'),
          _buildReviewItem('Distance Fee', 'FREE (Shop Visit)'),
          if (discount > 0) _buildReviewItem('Discount', '-₱${discount.toStringAsFixed(2)}',
              valueColor: Colors.green),
          const Divider(),
          _buildReviewItem('Total', '₱${finalPrice.toStringAsFixed(2)}',
              bold: true, valueColor: AppTheme.deepBlue),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warningColor, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No distance fee — you are bringing your device to the shop.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Reusable section helpers ──────────────────────────────

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
          const Divider(height: 20),
          ...items,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shop banner shown at the top of every step
// ─────────────────────────────────────────────
class _ShopBanner extends StatelessWidget {
  final ShopInfo shop;

  const _ShopBanner({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: shop.gradientColors),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.shopName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text('${shop.rating} (${shop.reviewCount} reviews)',
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: shop.isOpen ? Colors.green.shade400 : Colors.red.shade400,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shop.isOpen ? 'Open' : 'Closed',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step indicator
// ─────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const _StepIndicator({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep ? AppTheme.deepBlue : Colors.grey.shade300,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppTheme.deepBlue
                      : isCurrent
                          ? AppTheme.primaryCyan
                          : Colors.grey.shade200,
                  border: Border.all(
                    color: isCurrent ? AppTheme.deepBlue : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text('${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? AppTheme.deepBlue : Colors.grey,
                          )),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? AppTheme.deepBlue : AppTheme.textSecondaryColor,
                  )),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomNav({
    required this.currentStep,
    required this.totalSteps,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppTheme.textSecondaryColor,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onNext,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(isLast ? Icons.check_circle : Icons.arrow_forward),
              label: Text(isLast ? 'Confirm Booking' : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
