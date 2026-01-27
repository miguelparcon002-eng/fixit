import 'package:flutter/material.dart';

class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technician Dashboard')),
      body: const Center(child: Text('Manage your services and bookings')),
    );
  }
}
