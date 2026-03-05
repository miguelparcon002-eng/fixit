import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TechnicianMapSheet extends StatefulWidget {
  final List<Map<String, dynamic>> technicians;
  final String? selectedTechnicianId;
  final ValueChanged<String> onTechnicianSelected;

  const TechnicianMapSheet({
    super.key,
    required this.technicians,
    required this.selectedTechnicianId,
    required this.onTechnicianSelected,
  });

  @override
  State<TechnicianMapSheet> createState() => _TechnicianMapSheetState();
}

class _TechnicianMapSheetState extends State<TechnicianMapSheet> {
  // San Francisco, Agusan del Sur, Philippines
  static const LatLng _sfCenter = LatLng(8.5048, 125.9676);

  late final MapController _mapController;
  late final Map<String, LatLng> _techLocations;
  String? _focusedTechId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _focusedTechId = widget.selectedTechnicianId;
    _techLocations = _generateLocations();
  }

  Map<String, LatLng> _generateLocations() {
    final Map<String, LatLng> locations = {};
    for (final tech in widget.technicians) {
      final id = tech['id'] as String;
      final lat = (tech['latitude'] as num?)?.toDouble();
      final lng = (tech['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        locations[id] = LatLng(lat, lng);
      }
      // Technicians without a saved location are omitted from the map
    }
    return locations;
  }

  void _selectTech(String techId) {
    if (_focusedTechId == techId) return;
    setState(() => _focusedTechId = techId);
    final loc = _techLocations[techId];
    if (loc != null) {
      _mapController.move(loc, 14.5);
    }
  }

  List<Marker> _buildMarkers() {
    return widget.technicians.map((tech) {
      final id = tech['id'] as String;
      final loc = _techLocations[id];
      if (loc == null) return null;
      final isSelected = id == _focusedTechId;
      return Marker(
        point: loc,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _selectTech(id),
          child: Icon(
            Icons.location_pin,
            size: 40,
            color: isSelected ? const Color(0xFF4A5FE0) : Colors.redAccent,
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final focusedTech = _focusedTechId != null
        ? widget.technicians.where((t) => t['id'] == _focusedTechId).firstOrNull
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
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
                const Icon(Icons.map_outlined, color: Color(0xFF4A5FE0)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Technicians Near You',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('San Francisco, Agusan del Sur',
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
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _sfCenter,
                initialZoom: 13.0,
                minZoom: 10.0,
                maxZoom: 17.0,
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
                  maxZoom: 17,
                  tileBuilder: (context, widget, tile) => widget,
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                  rotate: false,
                ),
              ],
            ),
          ),

          // Bottom card
          _BottomCard(
            tech: focusedTech,
            onSelect: () {
              widget.onTechnicianSelected(_focusedTechId!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _BottomCard extends StatelessWidget {
  final Map<String, dynamic>? tech;
  final VoidCallback onSelect;

  const _BottomCard({required this.tech, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: tech != null
          ? _buildTechRow(tech!)
          : const Center(
              child: Text(
                'Tap a marker on the map to select a technician',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
    );
  }

  Widget _buildTechRow(Map<String, dynamic> tech) {
    final name = tech['name'] as String? ?? 'Technician';
    final rating = (tech['rating'] as num?)?.toDouble() ?? 0.0;
    final specialties = (tech['specialties'] as List<String>?) ?? [];
    final distanceKm = (tech['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final profilePic = tech['profilePicture'] as String?;
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF4A5FE0),
          backgroundImage: (profilePic != null && profilePic.isNotEmpty)
              ? NetworkImage(profilePic)
              : null,
          child: (profilePic == null || profilePic.isEmpty)
              ? Text(initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Flexible(
                  child: Text(name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
                if (tech['verified'] == true) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Color(0xFF4A5FE0), size: 15),
                ],
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.star, size: 13, color: Colors.amber),
                const SizedBox(width: 3),
                Text(rating > 0 ? rating.toStringAsFixed(1) : 'New',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 2),
                Text('${distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              if (specialties.isNotEmpty)
                Text(specialties.take(2).join(' • '),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onSelect,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A5FE0),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Select', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
