import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../booking/widgets/booking_dialog.dart';

class MoreServicesScreen extends StatelessWidget {
  const MoreServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Services'),
        backgroundColor: AppTheme.deepBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select from our comprehensive range of repair and maintenance services',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Services Section
            _buildSectionHeader('Quick Services'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _ServiceCard(
                  icon: Icons.search,
                  title: 'Diagnostics',
                  subtitle: '₱300-800',
                  color: const Color(0xFF9C27B0),
                  onTap: () => _showBookingDialog(context, 'Diagnostics'),
                ),
                _ServiceCard(
                  icon: Icons.tune,
                  title: 'Performance Tune-up',
                  subtitle: '₱350-700',
                  color: const Color(0xFF2196F3),
                  onTap: () => _showBookingDialog(context, 'Performance Tune-up'),
                ),
                _ServiceCard(
                  icon: Icons.bug_report,
                  title: 'Virus Removal',
                  subtitle: '₱300-800',
                  color: const Color(0xFFFF5722),
                  onTap: () => _showBookingDialog(context, 'Virus Removal'),
                ),
                _ServiceCard(
                  icon: Icons.apps,
                  title: 'Software Install',
                  subtitle: '₱300-600',
                  color: const Color(0xFF00BCD4),
                  onTap: () => _showBookingDialog(context, 'Software Installation'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Hardware Services Section
            _buildSectionHeader('Hardware Services'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _ServiceCard(
                  icon: Icons.memory,
                  title: 'RAM Upgrade',
                  subtitle: '₱1,500-4,000',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _showBookingDialog(context, 'RAM Upgrade'),
                ),
                _ServiceCard(
                  icon: Icons.storage,
                  title: 'SSD/HDD Upgrade',
                  subtitle: '₱2,000-5,500',
                  color: const Color(0xFF3F51B5),
                  onTap: () => _showBookingDialog(context, 'Storage Upgrade'),
                ),
                _ServiceCard(
                  icon: Icons.settings_backup_restore,
                  title: 'Data Recovery',
                  subtitle: '₱1,000-3,000',
                  color: const Color(0xFFE91E63),
                  onTap: () => _showBookingDialog(context, 'Data Recovery'),
                ),
                _ServiceCard(
                  icon: Icons.headphones,
                  title: 'Accessories',
                  subtitle: 'Installation',
                  color: const Color(0xFF795548),
                  onTap: () => _showBookingDialog(context, 'Accessory Installation'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Premium Services Section
            _buildSectionHeader('Premium Services'),
            const SizedBox(height: 12),
            _PremiumServiceCard(
              icon: Icons.verified_user,
              title: 'Extended Warranty',
              subtitle: 'Protect your device with extended coverage',
              price: 'Starting ₱500/month',
              color: const Color(0xFFFFB300),
              onTap: () => _showBookingDialog(context, 'Extended Warranty'),
            ),
            const SizedBox(height: 12),
            _PremiumServiceCard(
              icon: Icons.location_on,
              title: 'On-Site Repair',
              subtitle: 'We come to your location for repairs',
              price: '+₱200 service fee',
              color: const Color(0xFF00897B),
              onTap: () => _showBookingDialog(context, 'On-Site Repair'),
            ),
            const SizedBox(height: 12),
            _PremiumServiceCard(
              icon: Icons.business,
              title: 'Corporate Services',
              subtitle: 'Bulk repair services for businesses',
              price: 'Custom pricing',
              color: const Color(0xFF5E35B1),
              onTap: () => _showBookingDialog(context, 'Corporate Services'),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String serviceType) {
    showDialog(
      context: context,
      builder: (context) => const BookingDialog(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final Color color;
  final VoidCallback onTap;

  const _PremiumServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
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
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
