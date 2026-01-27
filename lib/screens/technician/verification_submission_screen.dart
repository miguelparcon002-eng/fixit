import 'package:flutter/material.dart';

class VerificationSubmissionScreen extends StatelessWidget {
  const VerificationSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Verification')),
      body: const Center(child: Text('Upload verification documents')),
    );
  }
}
