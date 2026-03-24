import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_request_provider.dart';

class PostProblemScreen extends ConsumerStatefulWidget {
  const PostProblemScreen({super.key});

  @override
  ConsumerState<PostProblemScreen> createState() => _PostProblemScreenState();
}

class _PostProblemScreenState extends ConsumerState<PostProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _mapController = MapController();

  // Location
  double? _lat;
  double? _lng;
  String _address = '';
  bool _locating = false;
  bool _reverseGeocoding = false;
  String? _locationError;

  // Device
  String? _deviceType; // 'Mobile' or 'Laptop'
  String? _brand;
  String? _model;
  final Set<String> _selectedProblems = {};

  static const Map<String, List<String>> _brands = {
    'Mobile': ['Apple', 'Samsung', 'Xiaomi', 'Oppo', 'Vivo', 'Realme', 'Huawei', 'Other'],
    'Laptop': ['Apple', 'Lenovo', 'HP', 'Acer', 'Asus', 'Dell', 'Other'],
  };

  static const Map<String, Map<String, List<String>>> _models = {
    'Mobile': {
      'Apple': ['iPhone 16 Pro Max', 'iPhone 16 Pro', 'iPhone 16', 'iPhone 15 Pro Max', 'iPhone 15 Pro', 'iPhone 15', 'iPhone 14 Pro Max', 'iPhone 14', 'iPhone 13', 'iPhone 12', 'iPhone SE'],
      'Samsung': ['Galaxy S24 Ultra', 'Galaxy S24+', 'Galaxy S24', 'Galaxy S23 Ultra', 'Galaxy S23', 'Galaxy Z Fold 5', 'Galaxy Z Flip 5', 'Galaxy A54', 'Galaxy A34', 'Galaxy A14'],
      'Xiaomi': ['Xiaomi 14 Ultra', 'Xiaomi 14', 'Xiaomi 13T Pro', 'Redmi Note 13 Pro+', 'Redmi Note 13', 'Redmi 13C', 'POCO X6 Pro', 'POCO X6', 'POCO M6 Pro'],
      'Oppo': ['Oppo Find X7 Ultra', 'Oppo Reno 11 Pro', 'Oppo Reno 11', 'Oppo A98', 'Oppo A78', 'Oppo A58', 'Oppo A38'],
      'Vivo': ['Vivo X100 Pro', 'Vivo X100', 'Vivo V30 Pro', 'Vivo V30', 'Vivo Y100', 'Vivo Y36'],
      'Realme': ['Realme GT 5 Pro', 'Realme 12 Pro+', 'Realme 12 Pro', 'Realme C67', 'Realme C55'],
      'Huawei': ['Huawei P60 Pro', 'Huawei Nova 12', 'Huawei Nova 11', 'Huawei Y90'],
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

  static const List<String> _problems = [
    'Screen Cracked',
    'Battery Drains',
    "Won't Power On",
    'Overheating',
    'Water Damage',
    'Software Bug',
    'Charging Issue',
    'Speaker / Mic',
    'Camera Issue',
  ];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Reverse geocode via Nominatim (web + mobile compatible) ─────────────
  Future<String> _reverseGeocodeCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'FixIT Flutter App',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final parts = <String>[
            if (addr['road'] != null) addr['road'] as String,
            if (addr['suburb'] != null)
              addr['suburb'] as String
            else if (addr['neighbourhood'] != null)
              addr['neighbourhood'] as String,
            if (addr['city'] != null)
              addr['city'] as String
            else if (addr['town'] != null)
              addr['town'] as String
            else if (addr['village'] != null)
              addr['village'] as String,
            if (addr['state'] != null) addr['state'] as String,
          ].where((s) => s.isNotEmpty).toList();
          if (parts.isNotEmpty) return parts.join(', ');
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) return displayName;
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  Future<void> _getLocation() async {
    setState(() { _locating = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationError = 'Location services are disabled.'; _locating = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationError = 'Location permission denied.'; _locating = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _locationError = 'Location permanently denied. Enable in settings.'; _locating = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final addr = await _reverseGeocodeCoords(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() { _lat = pos.latitude; _lng = pos.longitude; _address = addr; _locating = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _locationError = 'Failed to get location.'; _locating = false; });
    }
  }

  Future<void> _onMapTap(TapPosition _, LatLng point) async {
    setState(() {
      _lat = point.latitude;
      _lng = point.longitude;
      _address = '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      _reverseGeocoding = true;
      _locationError = null;
    });
    final addr = await _reverseGeocodeCoords(point.latitude, point.longitude);
    if (mounted) setState(() { _address = addr; _reverseGeocoding = false; });
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_deviceType == null) {
      _showError('Please select a device type.');
      return;
    }
    if (_brand == null) {
      _showError('Please select a brand.');
      return;
    }
    if (_selectedProblems.isEmpty) {
      _showError('Please select at least one problem.');
      return;
    }
    if (_lat == null || _lng == null) {
      _showError('Please wait for your location or tap the map to pin it.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Not logged in');

      // Encode structured info into problemDescription
      final modelLine = (_model != null && _model!.isNotEmpty) ? 'Model: $_model\n' : '';
      final description = [
        'Brand: $_brand',
        modelLine.trim(),
        'Issues: ${_selectedProblems.join(', ')}',
        if (_detailsController.text.trim().isNotEmpty)
          '---\n${_detailsController.text.trim()}',
      ].where((s) => s.isNotEmpty).join('\n');

      final request = await ref.read(jobRequestServiceProvider).createRequest(
            customerId: user.id,
            deviceType: _deviceType!,
            problemDescription: description,
            latitude: _lat!,
            longitude: _lng!,
            address: _address,
          );

      // Notify all technicians — fire-and-forget, doesn't block the UI
      ref.read(jobRequestServiceProvider).notifyAllTechnicians(
        deviceType: _deviceType!,
        address: _address,
        requestId: request.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem posted! A nearby technician will respond.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.orange.shade700),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildDeviceTypeSection(),
                  if (_deviceType != null) ...[
                    const SizedBox(height: 16),
                    _buildBrandSection(),
                  ],
                  if (_brand != null && _models[_deviceType]?[_brand]?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildModelSection(),
                  ],
                  const SizedBox(height: 16),
                  _buildProblemsSection(),
                  const SizedBox(height: 16),
                  _buildDetailsSection(),
                  const SizedBox(height: 16),
                  _buildLocationSection(),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.deepBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.primaryCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Post a Problem',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell us what\'s wrong and a technician will find you',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section helpers ──────────────────────────────────────────────────────
  Widget _sectionLabel(String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.deepBlue),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Device Type ──────────────────────────────────────────────────────────
  Widget _buildDeviceTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Device Type', icon: Icons.devices_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _deviceTypeCard('Mobile', Icons.smartphone_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _deviceTypeCard('Laptop', Icons.laptop_rounded)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deviceTypeCard(String type, IconData icon) {
    final selected = _deviceType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _deviceType = type;
        _brand = null;
        _model = null;
        _selectedProblems.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppTheme.deepBlue, AppTheme.primaryCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.deepBlue.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: selected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: selected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Brand ────────────────────────────────────────────────────────────────
  Widget _buildBrandSection() {
    final brands = _brands[_deviceType] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Brand', icon: Icons.business_rounded),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: brands.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final b = brands[i];
              final selected = _brand == b;
              return GestureDetector(
                onTap: () => setState(() { _brand = b; _model = null; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.deepBlue : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected ? AppTheme.deepBlue : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: AppTheme.deepBlue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(
                    b,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Model ────────────────────────────────────────────────────────────────
  Widget _buildModelSection() {
    final models = _models[_deviceType]?[_brand] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Model', icon: Icons.perm_device_information_rounded),
        _card(
          child: DropdownButtonFormField<String>(
            initialValue: _model,
            decoration: _inputDeco('Select your model'),
            isExpanded: true,
            items: models
                .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14))))
                .toList(),
            onChanged: (v) => setState(() => _model = v),
          ),
        ),
      ],
    );
  }

  // ── Problems ─────────────────────────────────────────────────────────────
  Widget _buildProblemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("What's Wrong?", icon: Icons.build_circle_rounded),
        _card(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _problems.map((p) {
              final selected = _selectedProblems.contains(p);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) { _selectedProblems.remove(p); } else { _selectedProblems.add(p); }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.deepBlue : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.deepBlue : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        p,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Additional Details ───────────────────────────────────────────────────
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Additional Details', icon: Icons.notes_rounded),
        _card(
          child: TextFormField(
            controller: _detailsController,
            maxLines: 4,
            decoration: _inputDeco('Describe the problem in more detail (optional)...'),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ── Location ─────────────────────────────────────────────────────────────
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Your Location', icon: Icons.location_on_rounded),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Map
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 200,
                  child: _locating
                      ? Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(child: CircularProgressIndicator()),
                        )
                      : _locationError != null
                          ? Container(
                              color: const Color(0xFFF3F4F6),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_off_rounded, color: Colors.red.shade400, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      _locationError!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _getLocation,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: LatLng(_lat!, _lng!),
                                    initialZoom: 16,
                                    onTap: _onMapTap,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.fixit.app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(_lat!, _lng!),
                                          width: 44,
                                          height: 44,
                                          child: Stack(
                                            alignment: Alignment.topCenter,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.deepBlue,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppTheme.deepBlue.withValues(alpha: 0.4),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Hint banner
                                Positioned(
                                  top: 8,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                                          SizedBox(width: 5),
                                          Text(
                                            'Tap map to pin your exact location',
                                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_reverseGeocoding)
                                  const Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                ),
              ),

              // Address row
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.deepBlue, AppTheme.primaryCyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pinned Location',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _locating
                                ? 'Detecting location...'
                                : _reverseGeocoding
                                    ? 'Getting address...'
                                    : _locationError != null
                                        ? 'Location unavailable'
                                        : _address.isNotEmpty
                                            ? _address
                                            : 'Tap the map to pin your location',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!_locating && !_reverseGeocoding)
                      IconButton(
                        icon: const Icon(Icons.my_location_rounded, size: 20, color: AppTheme.deepBlue),
                        tooltip: 'Refresh GPS',
                        onPressed: _getLocation,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Submit Button ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _submitting ? null : _submit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: _submitting
                ? null
                : const LinearGradient(
                    colors: [AppTheme.deepBlue, AppTheme.primaryCyan],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: _submitting ? const Color(0xFFD1D5DB) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _submitting
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.deepBlue.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Center(
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Post Problem',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Input decoration ─────────────────────────────────────────────────────
  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.deepBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
