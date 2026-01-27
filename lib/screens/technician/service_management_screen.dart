import 'package:flutter/material.dart';

class ServiceManagementScreen extends StatelessWidget {
  const ServiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services')),
      body: const Center(child: Text('Add and edit your services')),
    );
  }
}
