import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../booking/widgets/booking_dialog.dart';

class ServicesListScreen extends ConsumerWidget {
  const ServicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCyan,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'All Services',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mobile Repairs Section
              const Text(
                'Mobile Repairs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.phone_android,
                iconColor: const Color(0xFF4FC3F7),
                title: 'Screen Replacement',
                description: 'Cracked or damaged screen repair',
                price: '₱1,200 - ₱3,500',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.battery_charging_full,
                iconColor: Colors.green,
                title: 'Battery Replacement',
                description: 'Poor battery life or not charging',
                price: '₱500 - ₱1,500',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.camera_alt,
                iconColor: Colors.purple,
                title: 'Camera Repair',
                description: 'Blurry or not working camera',
                price: '₱800 - ₱2,000',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.water_drop,
                iconColor: const Color(0xFF4FC3F7),
                title: 'Water Damage Repair',
                description: 'Device exposed to liquid',
                price: '₱1,000 - ₱2,500',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 24),

              // Laptop Repairs Section
              const Text(
                'Laptop Repairs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.laptop,
                iconColor: Colors.orange,
                title: 'Screen Replacement',
                description: 'LCD or LED screen repair',
                price: '₱2,500 - ₱6,000',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.keyboard,
                iconColor: const Color(0xFF66BB6A),
                title: 'Keyboard Repair',
                description: 'Stuck or broken keys',
                price: '₱1,200 - ₱2,500',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.memory,
                iconColor: Colors.red,
                title: 'RAM Upgrade',
                description: 'Improve performance',
                price: '₱1,500 - ₱4,000',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.storage,
                iconColor: const Color(0xFFFFB300),
                title: 'SSD/HDD Upgrade',
                description: 'Increase storage capacity',
                price: '₱2,000 - ₱5,500',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 24),

              // Tablet Repairs Section
              const Text(
                'Tablet Repairs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.tablet,
                iconColor: Colors.pink,
                title: 'Screen Replacement',
                description: 'Touchscreen or LCD repair',
                price: '₱1,500 - ₱4,000',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.power,
                iconColor: const Color(0xFF66BB6A),
                title: 'Charging Port Repair',
                description: 'Not charging or loose port',
                price: '₱500 - ₱1,200',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 24),

              // Other Services Section
              const Text(
                'Other Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.bug_report,
                iconColor: Colors.red,
                title: 'Virus Removal',
                description: 'Malware and virus cleanup',
                price: '₱300 - ₱800',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.settings,
                iconColor: Colors.grey,
                title: 'Software Installation',
                description: 'OS and software setup',
                price: '₱300 - ₱600',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.backup,
                iconColor: const Color(0xFF4FC3F7),
                title: 'Data Recovery',
                description: 'Recover lost or deleted files',
                price: '₱1,000 - ₱3,000',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 12),
              _ServiceCard(
                icon: Icons.speed,
                iconColor: const Color(0xFFFFB300),
                title: 'Performance Tune-up',
                description: 'Speed optimization',
                price: '₱350 - ₱700',
                onTap: () => _showBookingDialog(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BookingDialog(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String price;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
