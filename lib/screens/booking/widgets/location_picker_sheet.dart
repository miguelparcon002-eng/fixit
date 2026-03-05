import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Result returned when customer confirms their pinned location.
class PickedLocation {
  final LatLng latLng;
  final String label; // displayed address string

  const PickedLocation({required this.latLng, required this.label});
}

/// Bottom sheet where the customer taps the map to pin their exact location.
/// Centered on San Francisco, Agusan del Sur by default.
class LocationPickerSheet extends StatefulWidget {
  /// Pre-fill with an existing pin if the customer already set one.
  final LatLng? initialLocation;

  const LocationPickerSheet({super.key, this.initialLocation});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  static const LatLng _sfCenter = LatLng(8.5048, 125.9676);

  late final MapController _mapController;
  late final TextEditingController _addressController;
  LatLng? _pickedLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pickedLocation = widget.initialLocation;
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _formatLatLng(LatLng loc) =>
      '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF4A5FE0)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pin Your Location',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('Tap anywhere on the map to set your exact address',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pickedLocation ?? _sfCenter,
                    initialZoom: 14.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                    onTap: (_, latLng) {
                      setState(() => _pickedLocation = latLng);
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fixit',
                      maxZoom: 18,
                    ),
                    if (_pickedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedLocation!,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_pin,
                              size: 48,
                              color: Color(0xFF4A5FE0),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Center crosshair hint when nothing is pinned yet
                if (_pickedLocation == null)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 48, color: Colors.black38),
                        SizedBox(height: 8),
                        Text('Tap to pin your location',
                            style: TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom confirm area
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pickedLocation != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Color(0xFF4A5FE0), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Pinned: ${_formatLatLng(_pickedLocation!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A5FE0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address label (optional)',
                      hintText: 'e.g. Brgy. San Francisco, Agusan del Sur',
                      prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const Text(
                    'Tap on the map to pin your exact location.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickedLocation == null
                        ? null
                        : () {
                            final label = _addressController.text.trim().isNotEmpty
                                ? _addressController.text.trim()
                                : _formatLatLng(_pickedLocation!);
                            Navigator.pop(
                              context,
                              PickedLocation(latLng: _pickedLocation!, label: label),
                            );
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Location',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5FE0),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
