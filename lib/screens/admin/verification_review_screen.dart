import 'package:flutter/material.dart';

class VerificationReviewScreen extends StatelessWidget {
  const VerificationReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Verifications')),
      body: const Center(child: Text('Approve or reject technicians')),
    );
  }
}
