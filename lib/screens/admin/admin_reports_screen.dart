import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import 'widgets/admin_notifications_dialog.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedView = 'dashboard'; // dashboard, device, areas, team
  String _selectedPeriod = 'Month'; // Month or Week

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCyan,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppLogo(size: 48),
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications, size: 28, color: Colors.black),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AdminNotificationsDialog(),
                              );
                            },
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, size: 24, color: Colors.black),
                        onPressed: () {
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Export Report Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exporting report...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Export Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Reports Dashboard Header with Dropdown (only show on dashboard view)
            if (_selectedView == 'dashboard')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reports Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PeriodOption(
                                    label: 'Month',
                                    isSelected: _selectedPeriod == 'Month',
                                    onTap: () {
                                      setState(() => _selectedPeriod = 'Month');
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _PeriodOption(
                                    label: 'Week',
                                    isSelected: _selectedPeriod == 'Week',
                                    onTap: () {
                                      setState(() => _selectedPeriod = 'Week');
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedPeriod,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_selectedView == 'dashboard') const SizedBox(height: 16),
            // Content based on selected view
            Expanded(
              child: _selectedView == 'dashboard'
                  ? _buildDashboardView()
                  : _selectedView == 'device'
                      ? _buildDeviceBreakdownView()
                      : _selectedView == 'areas'
                          ? _buildPopularAreasView()
                          : _buildTeamPerformanceView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      child: Container(
        color: AppTheme.primaryCyan,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.35,
              children: [
                _StatCard(
                  icon: Icons.calendar_today,
                  iconColor: AppTheme.lightBlue,
                  iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.2),
                  value: _selectedPeriod == 'Month' ? '1245' : '321',
                  label: 'Total Bookings',
                  percentage: '+8%',
                  isPositive: true,
                ),
                _StatCard(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFFFF6B6B),
                  iconBgColor: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  value: _selectedPeriod == 'Month' ? '18 mins' : '16 mins',
                  label: 'Average Response Time',
                  percentage: '+23%',
                  isPositive: true,
                ),
                _StatCard(
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  iconBgColor: Colors.green.withValues(alpha: 0.2),
                  value: _selectedPeriod == 'Month' ? '₱789,415' : '₱193,130',
                  label: 'Total Revenue',
                  percentage: '+12%',
                  isPositive: true,
                ),
                _StatCard(
                  icon: Icons.people,
                  iconColor: Colors.purple,
                  iconBgColor: Colors.purple.withValues(alpha: 0.2),
                  value: _selectedPeriod == 'Month' ? '892' : '176',
                  label: 'Total Customers',
                  percentage: '+15%',
                  isPositive: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ReportOption(
                    title: 'Device Breakdown',
                    onTap: () => setState(() => _selectedView = 'device'),
                  ),
                  const Divider(height: 1),
                  _ReportOption(
                    title: 'Popular Areas',
                    onTap: () => setState(() => _selectedView = 'areas'),
                  ),
                  const Divider(height: 1),
                  _ReportOption(
                    title: 'Team Performance',
                    onTap: () => setState(() => _selectedView = 'team'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceBreakdownView() {
    return Container(
      color: AppTheme.primaryCyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _DeviceBreakdownCard(
                    icon: Icons.phone_android,
                    deviceName: 'Iphone',
                    percentage: '832(41.6%)',
                    progress: 0.416,
                    revenue: '₱832,000',
                  ),
                  const SizedBox(height: 12),
                  _DeviceBreakdownCard(
                    icon: Icons.phone_android,
                    deviceName: 'Samsung',
                    percentage: '660(33%)',
                    progress: 0.33,
                    revenue: '₱660,000',
                  ),
                  const SizedBox(height: 12),
                  _DeviceBreakdownCard(
                    icon: Icons.laptop_mac,
                    deviceName: 'Macbook',
                    percentage: '332(16.6%)',
                    progress: 0.166,
                    revenue: '₱332,000',
                  ),
                  const SizedBox(height: 12),
                  _DeviceBreakdownCard(
                    icon: Icons.laptop,
                    deviceName: 'Vivobook',
                    percentage: '166(8.3%)',
                    progress: 0.083,
                    revenue: '₱166,000',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _ReportOption(
                          title: 'Reports Dashboard',
                          onTap: () => setState(() => _selectedView = 'dashboard'),
                        ),
                        const Divider(height: 1),
                        _ReportOption(
                          title: 'Popular Areas',
                          onTap: () => setState(() => _selectedView = 'areas'),
                        ),
                        const Divider(height: 1),
                        _ReportOption(
                          title: 'Team Performance',
                          onTap: () => setState(() => _selectedView = 'team'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularAreasView() {
    return Container(
      color: AppTheme.primaryCyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Areas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _AreaCard(
                    areaName: 'Barangay 1, SFADS',
                    count: '1820',
                    revenue: '₱1.8M',
                  ),
                  const SizedBox(height: 12),
                  _AreaCard(
                    areaName: 'Barangay 3, SFADS',
                    count: '1132',
                    revenue: '₱1.1M',
                  ),
                  const SizedBox(height: 12),
                  _AreaCard(
                    areaName: 'Barangay 2, SFADS',
                    count: '786',
                    revenue: '₱786,000',
                  ),
                  const SizedBox(height: 12),
                  _AreaCard(
                    areaName: 'Barangay 7, SFADS',
                    count: '401',
                    revenue: '₱401,000',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _ReportOption(
                          title: 'Reports Dashboard',
                          onTap: () => setState(() => _selectedView = 'dashboard'),
                        ),
                        const Divider(height: 1),
                        _ReportOption(
                          title: 'Device Breakdown',
                          onTap: () => setState(() => _selectedView = 'device'),
                        ),
                        const Divider(height: 1),
                        _ReportOption(
                          title: 'Team Performance',
                          onTap: () => setState(() => _selectedView = 'team'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPerformanceView() {
    return Container(
      color: AppTheme.primaryCyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _TechnicianPerformanceCard(
                    initials: 'SS',
                    name: 'Shen Sarsale',
                    rating: 4.7,
                    jobs: '123 jobs',
                    revenue: '₱123,000',
                  ),
                  const SizedBox(height: 12),
                  _TechnicianPerformanceCard(
                    initials: 'EE',
                    name: 'Ethanjames Estino',
                    rating: 4.6,
                    jobs: '110 jobs',
                    revenue: '₱110,000',
                  ),
                  const SizedBox(height: 12),
                  _TechnicianPerformanceCard(
                    initials: 'MC',
                    name: 'Mark Cole',
                    rating: 4.0,
                    jobs: '87 jobs',
                    revenue: '₱87,000',
                  ),
                  const SizedBox(height: 12),
                  _TechnicianPerformanceCard(
                    initials: 'BY',
                    name: 'Bai Yag',
                    rating: 4.0,
                    jobs: '65 jobs',
                    revenue: '₱65,000',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _ReportOption(
                          title: 'Reports Dashboard',
                          onTap: () => setState(() => _selectedView = 'dashboard'),
                        ),
                        const Divider(height: 1),
                        _ReportOption(
                          title: 'Device Breakdown',
                          onTap: () => setState(() => _selectedView = 'device'),
                        ),
                        const Divider(height: 1),
                        _ReportOption(
                          title: 'Popular Areas',
                          onTap: () => setState(() => _selectedView = 'areas'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String value;
  final String label;
  final String percentage;
  final bool isPositive;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.value,
    required this.label,
    required this.percentage,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPositive ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ReportOption({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

class _DeviceBreakdownCard extends StatelessWidget {
  final IconData icon;
  final String deviceName;
  final String percentage;
  final double progress;
  final String revenue;

  const _DeviceBreakdownCard({
    required this.icon,
    required this.deviceName,
    required this.percentage,
    required this.progress,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      percentage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                revenue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.lightBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final String areaName;
  final String count;
  final String revenue;

  const _AreaCard({
    required this.areaName,
    required this.count,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 24, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  areaName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianPerformanceCard extends StatelessWidget {
  final String initials;
  final String name;
  final double rating;
  final String jobs;
  final String revenue;

  const _TechnicianPerformanceCard({
    required this.initials,
    required this.name,
    required this.rating,
    required this.jobs,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  jobs,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}


class _PeriodOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.deepBlue : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.deepBlue : Colors.black,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_box,
                color: AppTheme.deepBlue,
                size: 20,
              )
            else
              Icon(
                Icons.check_box_outline_blank,
                color: Colors.grey.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
