import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 30, showText: false, assetPath: 'assets/images/logo_square.png'),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Platform management',
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
      ),
    );
  }
}
