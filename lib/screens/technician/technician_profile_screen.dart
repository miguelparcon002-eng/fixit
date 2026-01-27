import 'package:flutter/material.dart';

class TechnicianProfileScreen extends StatelessWidget {
  final String technicianId;
  const TechnicianProfileScreen({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technician Profile')),
      body: Center(child: Text('Technician: $technicianId')),
    );
  }
}
