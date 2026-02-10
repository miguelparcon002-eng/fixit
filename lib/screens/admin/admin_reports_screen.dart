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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedView != 'dashboard') {
              setState(() => _selectedView = 'dashboard');
              return;
            }
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin-home');
            }
          },
        ),
        title: Row(
          children: [
            const AppLogo(
              size: 28,
              showText: false,
              assetPath: 'assets/images/logo_square.png',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedView == 'dashboard'
                    ? 'Reports'
                    : _selectedView == 'device'
                    ? 'Device breakdown'
                    : _selectedView == 'areas'
                    ? 'Popular areas'
                    : 'Team performance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AdminNotificationsDialog(),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 900
              ? 820.0
              : double.infinity;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export & period',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _PeriodOption(
                                                label: 'Month',
                                                isSelected:
                                                    _selectedPeriod == 'Month',
                                                onTap: () {
                                                  setState(
                                                    () => _selectedPeriod =
                                                        'Month',
                                                  );
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              const SizedBox(height: 8),
                                              _PeriodOption(
                                                label: 'Week',
                                                isSelected:
                                                    _selectedPeriod == 'Week',
                                                onTap: () {
                                                  setState(
                                                    () => _selectedPeriod =
                                                        'Week',
                                                  );
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.date_range_outlined),
                                  label: Text('Period: $_selectedPeriod'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.textPrimaryColor,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Exporting report…'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.file_download_outlined,
                                  ),
                                  label: const Text('Export'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.deepBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildViewBody(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewBody() {
    switch (_selectedView) {
      case 'device':
        return _buildDeviceBreakdownView();
      case 'areas':
        return _buildPopularAreasView();
      case 'team':
        return _buildTeamPerformanceView();
      case 'dashboard':
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width >= 620 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _StatCard(
              icon: Icons.calendar_today,
              iconColor: AppTheme.lightBlue,
              iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.18),
              value: _selectedPeriod == 'Month' ? '1245' : '321',
              label: 'Total bookings',
              percentage: '+8%',
              isPositive: true,
            ),
            _StatCard(
              icon: Icons.access_time,
              iconColor: const Color(0xFFFF6B6B),
              iconBgColor: const Color(0xFFFF6B6B).withValues(alpha: 0.18),
              value: _selectedPeriod == 'Month' ? '18 mins' : '16 mins',
              label: 'Avg response',
              percentage: '+23%',
              isPositive: true,
            ),
            _StatCard(
              icon: Icons.attach_money,
              iconColor: AppTheme.successColor,
              iconBgColor: AppTheme.successColor.withValues(alpha: 0.18),
              value: _selectedPeriod == 'Month' ? '₱789,415' : '₱193,130',
              label: 'Revenue',
              percentage: '+12%',
              isPositive: true,
            ),
            _StatCard(
              icon: Icons.people,
              iconColor: AppTheme.accentPurple,
              iconBgColor: AppTheme.accentPurple.withValues(alpha: 0.18),
              value: _selectedPeriod == 'Month' ? '892' : '176',
              label: 'Customers',
              percentage: '+15%',
              isPositive: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          child: Column(
            children: [
              _ReportOption(
                title: 'Device breakdown',
                subtitle: 'See the most common device types for this period.',
                icon: Icons.devices_other_outlined,
                onTap: () => setState(() => _selectedView = 'device'),
              ),
              const Divider(height: 1),
              _ReportOption(
                title: 'Popular areas',
                subtitle: 'Bookings distribution by location.',
                icon: Icons.map_outlined,
                onTap: () => setState(() => _selectedView = 'areas'),
              ),
              const Divider(height: 1),
              _ReportOption(
                title: 'Team performance',
                subtitle: 'Top technicians by jobs, ratings and revenue.',
                icon: Icons.groups_2_outlined,
                onTap: () => setState(() => _selectedView = 'team'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceBreakdownView() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Device breakdown',
          description: 'Most common device categories for the selected period.',
          onBackToDashboard: () => setState(() => _selectedView = 'dashboard'),
        ),
        const SizedBox(height: 12),
        _DeviceBreakdownCard(
          icon: Icons.phone_iphone,
          deviceName: 'iPhone',
          percentage: '832 (41.6%)',
          progress: 0.416,
          revenue: '₱832,000',
        ),
        const SizedBox(height: 12),
        _DeviceBreakdownCard(
          icon: Icons.phone_android,
          deviceName: 'Samsung',
          percentage: '660 (33%)',
          progress: 0.33,
          revenue: '₱660,000',
        ),
        const SizedBox(height: 12),
        _DeviceBreakdownCard(
          icon: Icons.laptop_mac,
          deviceName: 'MacBook',
          percentage: '332 (16.6%)',
          progress: 0.166,
          revenue: '₱332,000',
        ),
        const SizedBox(height: 12),
        _DeviceBreakdownCard(
          icon: Icons.laptop,
          deviceName: 'Vivobook',
          percentage: '166 (8.3%)',
          progress: 0.083,
          revenue: '₱166,000',
        ),
        const SizedBox(height: 16),
        Text(
          'Other reports',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            children: [
              _ReportOption(
                title: 'Popular areas',
                icon: Icons.map_outlined,
                onTap: () => setState(() => _selectedView = 'areas'),
              ),
              const Divider(height: 1),
              _ReportOption(
                title: 'Team performance',
                icon: Icons.groups_2_outlined,
                onTap: () => setState(() => _selectedView = 'team'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopularAreasView() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Popular areas',
          description: 'Where most bookings come from in this period.',
          onBackToDashboard: () => setState(() => _selectedView = 'dashboard'),
        ),
        const SizedBox(height: 12),
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
        Text(
          'Other reports',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            children: [
              _ReportOption(
                title: 'Device breakdown',
                icon: Icons.devices_other_outlined,
                onTap: () => setState(() => _selectedView = 'device'),
              ),
              const Divider(height: 1),
              _ReportOption(
                title: 'Team performance',
                icon: Icons.groups_2_outlined,
                onTap: () => setState(() => _selectedView = 'team'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamPerformanceView() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Team performance',
          description: 'A quick look at technician output and ratings.',
          onBackToDashboard: () => setState(() => _selectedView = 'dashboard'),
        ),
        const SizedBox(height: 12),
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
        Text(
          'Other reports',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            children: [
              _ReportOption(
                title: 'Device breakdown',
                icon: Icons.devices_other_outlined,
                onTap: () => setState(() => _selectedView = 'device'),
              ),
              const Divider(height: 1),
              _ReportOption(
                title: 'Popular areas',
                icon: Icons.map_outlined,
                onTap: () => setState(() => _selectedView = 'areas'),
              ),
            ],
          ),
        ),
      ],
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
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isPositive
                                ? AppTheme.successColor
                                : AppTheme.errorColor)
                            .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color:
                          (isPositive
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor)
                              .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    percentage,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isPositive
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  const _ReportOption({
    required this.title,
    this.subtitle,
    this.icon,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppTheme.deepBlue),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SubViewHeader extends StatelessWidget {
  const _SubViewHeader({
    required this.title,
    required this.description,
    required this.onBackToDashboard,
  });

  final String title;
  final String description;
  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onBackToDashboard,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Dashboard'),
          ),
        ],
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
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: AppTheme.deepBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      percentage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                revenue,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.lightBlue,
              ),
              minHeight: 10,
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
    final theme = Theme.of(context);

    return _SectionCard(
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 22,
              color: AppTheme.primaryCyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  areaName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count bookings',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimaryColor,
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
    final theme = Theme.of(context);

    return _SectionCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.deepBlue.withValues(alpha: 0.10),
            child: Text(
              initials,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.deepBlue,
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
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      jobs,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimaryColor,
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
            color: isSelected
                ? AppTheme.deepBlue
                : Colors.grey.withValues(alpha: 0.3),
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
              const Icon(Icons.check_box, color: AppTheme.deepBlue, size: 20)
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
