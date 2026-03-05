import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../providers/admin_reports_provider.dart';
import '../../services/admin_reports_service.dart';
import 'widgets/admin_notifications_dialog.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _selectedView = 'dashboard'; // dashboard, device, areas, team
  DeviceBreakdownItem? _selectedDevice; // for drill-down into models

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final period = ref.watch(adminReportsPeriodProvider);
    final reportsAsync = ref.watch(adminReportsProvider);

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
                        ? 'Device Breakdown'
                        : _selectedView == 'areas'
                            ? 'Popular Areas'
                            : 'Team Performance',
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
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AdminNotificationsDialog(),
            ),
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
          final maxWidth =
              constraints.maxWidth >= 900 ? 820.0 : double.infinity;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Period selector ──────────────────────────────────────
                    _SectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showPeriodPicker(context, ref, period),
                              icon: const Icon(Icons.date_range_outlined),
                              label: Text('Period: $period'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimaryColor,
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: implement print/export
                              },
                              icon: const Icon(Icons.print_rounded),
                              label: const Text('Print Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.deepBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Body ─────────────────────────────────────────────────
                    reportsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => _ErrorCard(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(adminReportsProvider),
                      ),
                      data: (data) => _buildViewBody(data, period),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPeriodPicker(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Period',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                      )),
              const SizedBox(height: 12),
              _PeriodOption(
                label: 'All',
                isSelected: current == 'All',
                onTap: () {
                  ref.read(adminReportsPeriodProvider.notifier).state = 'All';
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _PeriodOption(
                label: 'Day',
                isSelected: current == 'Day',
                onTap: () {
                  ref.read(adminReportsPeriodProvider.notifier).state = 'Day';
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _PeriodOption(
                label: 'Week',
                isSelected: current == 'Week',
                onTap: () {
                  ref.read(adminReportsPeriodProvider.notifier).state = 'Week';
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _PeriodOption(
                label: 'Month',
                isSelected: current == 'Month',
                onTap: () {
                  ref.read(adminReportsPeriodProvider.notifier).state = 'Month';
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewBody(AdminReportsData data, String period) {
    switch (_selectedView) {
      case 'device':
        return _buildDeviceView(data);
      case 'areas':
        return _buildAreasView(data);
      case 'team':
        return _buildTeamView(data, period);
      case 'dashboard':
      default:
        return _buildDashboard(data, period);
    }
  }

  // ── DASHBOARD ──────────────────────────────────────────────────────────────

  Widget _buildDashboard(AdminReportsData data, String period) {
    final bookings = period == 'Day'
        ? data.dayBookings
        : period == 'Week'
            ? data.weekBookings
            : period == 'Month'
                ? data.monthBookings
                : data.totalBookings;
    final revenue = period == 'Day'
        ? data.dayRevenue
        : period == 'Week'
            ? data.weekRevenue
            : period == 'Month'
                ? data.monthRevenue
                : data.totalRevenue;
    final newCustomers = period == 'Day'
        ? data.dayCustomers
        : period == 'Week'
            ? data.weekCustomers
            : period == 'Month'
                ? data.monthCustomers
                : data.totalCustomers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Overview · $period',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
              ),
        ),
        const SizedBox(height: 12),

        // ── 4 stat cards ─────────────────────────────────────────────────────
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width >= 620 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              icon: Icons.receipt_long_rounded,
              iconColor: AppTheme.lightBlue,
              iconBgColor: AppTheme.lightBlue.withValues(alpha: 0.18),
              value: _fmt(bookings.toDouble(), isCount: true),
              label: 'Bookings',
              sub: '${_fmt(data.totalBookings.toDouble(), isCount: true)} total',
            ),
            _StatCard(
              icon: Icons.payments_rounded,
              iconColor: AppTheme.successColor,
              iconBgColor: AppTheme.successColor.withValues(alpha: 0.18),
              value: _fmtCurrency(revenue),
              label: 'Revenue',
              sub: '${_fmtCurrency(data.totalRevenue)} total',
            ),
            _StatCard(
              icon: Icons.people_rounded,
              iconColor: AppTheme.accentPurple,
              iconBgColor: AppTheme.accentPurple.withValues(alpha: 0.18),
              value: '+${_fmt(newCustomers.toDouble(), isCount: true)}',
              label: 'New Customers',
              sub: '${_fmt(data.totalCustomers.toDouble(), isCount: true)} total',
            ),
            _StatCard(
              icon: Icons.check_circle_rounded,
              iconColor: Colors.green,
              iconBgColor: Colors.green.withValues(alpha: 0.18),
              value: _fmt(
                (period == 'Day'
                        ? data.dayCompletedBookings
                        : period == 'Week'
                            ? data.weekCompletedBookings
                            : period == 'Month'
                                ? data.monthCompletedBookings
                                : data.completedBookings)
                    .toDouble(),
                isCount: true,
              ),
              label: 'Completed',
              sub: '${_fmt(data.completedBookings.toDouble(), isCount: true)} total',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Booking status breakdown ─────────────────────────────────────────
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
              ),
              const SizedBox(height: 14),
              _StatusRow(
                label: 'Completed',
                count: data.completedBookings,
                total: data.totalBookings,
                color: AppTheme.successColor,
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(height: 10),
              _StatusRow(
                label: 'Pending / In Progress',
                count: data.pendingBookings,
                total: data.totalBookings,
                color: Colors.orange,
                icon: Icons.pending_rounded,
              ),
              const SizedBox(height: 10),
              _StatusRow(
                label: 'Cancelled',
                count: data.cancelledBookings,
                total: data.totalBookings,
                color: AppTheme.errorColor,
                icon: Icons.cancel_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Drill-down options ───────────────────────────────────────────────
        _SectionCard(
          child: Column(
            children: [
              _ReportOption(
                title: 'Device Breakdown',
                subtitle:
                    '${data.deviceBreakdown.length} device types · most common: ${data.deviceBreakdown.isNotEmpty ? data.deviceBreakdown.first.deviceName : '—'}',
                icon: Icons.devices_other_outlined,
                onTap: () => setState(() => _selectedView = 'device'),
              ),
              const Divider(height: 1),
              _ReportOption(
                title: 'Popular Areas',
                subtitle:
                    '${data.popularAreas.length} areas · top: ${data.popularAreas.isNotEmpty ? data.popularAreas.first.areaName : '—'}',
                icon: Icons.map_outlined,
                onTap: () => setState(() => _selectedView = 'areas'),
              ),
              const Divider(height: 1),
              _ReportOption(
                title: 'Team Performance',
                subtitle:
                    '${data.teamPerformance.length} technicians · top: ${data.teamPerformance.isNotEmpty ? data.teamPerformance.first.name : '—'}',
                icon: Icons.groups_2_outlined,
                onTap: () => setState(() => _selectedView = 'team'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── DEVICE BREAKDOWN ──────────────────────────────────────────────────────

  Widget _buildDeviceView(AdminReportsData data) {
    // Drill-down: show models for a selected category
    if (_selectedDevice != null) {
      final device = _selectedDevice!;
      final sorted = device.models.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SubViewHeader(
            title: '${device.deviceName} Models',
            description: 'Individual models fixed under ${device.deviceName}.',
            onBack: () => setState(() => _selectedDevice = null),
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            const _EmptyCard(message: 'No model details available.')
          else
            ...sorted.asMap().entries.map((e) {
              final rank = e.key + 1;
              final model = e.value.key;
              final count = e.value.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SectionCard(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.deepBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          model,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.deepBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count booking${count == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.deepBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      );
    }

    final items = data.deviceBreakdown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Device Breakdown',
          description: 'Tap a category to see individual models.',
          onBack: () => setState(() { _selectedView = 'dashboard'; _selectedDevice = null; }),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _EmptyCard(message: 'No device data yet.\nDevice info is pulled from booking notes.')
        else
          ...items.asMap().entries.map((e) {
            final rank = e.key + 1;
            final item = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DeviceBreakdownCard(
                rank: rank,
                deviceName: item.deviceName,
                count: item.count,
                percentage: item.percentage,
                revenue: item.revenue,
                onTap: item.models.isNotEmpty
                    ? () => setState(() => _selectedDevice = item)
                    : null,
              ),
            );
          }),
        const SizedBox(height: 12),
        _OtherReportsCard(
          exclude: 'device',
          onAreas: () => setState(() => _selectedView = 'areas'),
          onTeam: () => setState(() => _selectedView = 'team'),
          onDevice: () {},
        ),
      ],
    );
  }

  // ── POPULAR AREAS ─────────────────────────────────────────────────────────

  Widget _buildAreasView(AdminReportsData data) {
    final items = data.popularAreas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Popular Areas',
          description: 'Booking distribution by customer address.',
          onBack: () => setState(() => _selectedView = 'dashboard'),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _EmptyCard(message: 'No area data yet.\nArea info is pulled from customer addresses.')
        else
          ...items.asMap().entries.map((e) {
            final rank = e.key + 1;
            final item = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AreaCard(
                rank: rank,
                areaName: item.areaName,
                count: item.count,
                revenue: item.revenue,
              ),
            );
          }),
        const SizedBox(height: 12),
        _OtherReportsCard(
          exclude: 'areas',
          onAreas: () {},
          onTeam: () => setState(() => _selectedView = 'team'),
          onDevice: () => setState(() => _selectedView = 'device'),
        ),
      ],
    );
  }

  // ── TEAM PERFORMANCE ──────────────────────────────────────────────────────

  Widget _buildTeamView(AdminReportsData data, String period) {
    final items = data.teamPerformance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Team Performance',
          description: 'Technicians ranked by completed jobs.',
          onBack: () => setState(() => _selectedView = 'dashboard'),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _EmptyCard(message: 'No technician data yet.')
        else
          ...items.asMap().entries.map((e) {
            final rank = e.key + 1;
            final item = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TechnicianCard(
                rank: rank,
                name: item.name,
                profileImageUrl: item.profileImageUrl,
                completedJobs: item.completedJobs,
                revenue: item.revenue,
                averageRating: item.averageRating,
              ),
            );
          }),
        const SizedBox(height: 12),
        _OtherReportsCard(
          exclude: 'team',
          onAreas: () => setState(() => _selectedView = 'areas'),
          onTeam: () {},
          onDevice: () => setState(() => _selectedView = 'device'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER FORMATTERS
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(double v, {bool isCount = false}) {
  if (isCount) {
    final n = v.toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
  return v.toStringAsFixed(0);
}

String _fmtCurrency(double v) {
  if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(2)}M';
  if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}K';
  return '₱${v.toStringAsFixed(0)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AppTheme.errorColor),
          const SizedBox(height: 10),
          Text('Failed to load reports',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  )),
          const SizedBox(height: 4),
          Text(message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
  final String sub;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.value,
    required this.label,
    required this.sub,
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
              offset: Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textSecondaryColor)),
            Text(sub,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      )),
            ),
            Text('$count',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    )),
            const SizedBox(width: 6),
            Text('(${(pct * 100).toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _DeviceBreakdownCard extends StatelessWidget {
  final int rank;
  final String deviceName;
  final int count;
  final double percentage;
  final double revenue;
  final VoidCallback? onTap;

  const _DeviceBreakdownCard({
    required this.rank,
    required this.deviceName,
    required this.count,
    required this.percentage,
    required this.revenue,
    this.onTap,
  });

  static const _rankColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  IconData get _icon {
    final lower = deviceName.toLowerCase();
    if (lower.contains('iphone')) return Icons.phone_iphone;
    if (lower.contains('samsung') || lower.contains('android')) return Icons.phone_android;
    if (lower.contains('macbook')) return Icons.laptop_mac;
    if (lower.contains('laptop') || lower.contains('notebook') || lower.contains('vivobook') || lower.contains('asus') || lower.contains('hp') || lower.contains('dell') || lower.contains('lenovo')) return Icons.laptop;
    if (lower.contains('tablet') || lower.contains('ipad')) return Icons.tablet_rounded;
    if (lower.contains('desktop') || lower.contains('pc')) return Icons.desktop_windows_rounded;
    return Icons.devices_other_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColor = rank <= 3 ? _rankColors[rank - 1] : AppTheme.deepBlue;

    return _SectionCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rankColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppTheme.deepBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, size: 20, color: AppTheme.deepBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryColor)),
                    const SizedBox(height: 2),
                    Text(
                        '$count booking${count == 1 ? '' : 's'} · ${(percentage * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              Text(_fmtCurrency(revenue),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                  rank == 1 ? AppTheme.primaryCyan : AppTheme.lightBlue),
              minHeight: 8,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final int rank;
  final String areaName;
  final int count;
  final double revenue;

  const _AreaCard({
    required this.rank,
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('#$rank',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryCyan)),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 20, color: AppTheme.primaryCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(areaName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 2),
                Text('$count booking${count == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
          Text(_fmtCurrency(revenue),
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final int rank;
  final String name;
  final String? profileImageUrl;
  final int completedJobs;
  final double revenue;
  final double? averageRating;

  const _TechnicianCard({
    required this.rank,
    required this.name,
    this.profileImageUrl,
    required this.completedJobs,
    required this.revenue,
    this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.deepBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('#$rank',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.deepBlue)),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.deepBlue.withValues(alpha: 0.10),
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : null,
            child: profileImageUrl == null
                ? Text(initials,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.deepBlue))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (averageRating != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(averageRating!.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimaryColor)),
                        ],
                      ),
                    Text('$completedJobs job${completedJobs == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ],
            ),
          ),
          Text(_fmtCurrency(revenue),
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }
}

class _OtherReportsCard extends StatelessWidget {
  final String exclude;
  final VoidCallback onDevice;
  final VoidCallback onAreas;
  final VoidCallback onTeam;

  const _OtherReportsCard({
    required this.exclude,
    required this.onDevice,
    required this.onAreas,
    required this.onTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Other Reports',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor,
                )),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            children: [
              if (exclude != 'device') ...[
                _ReportOption(
                    title: 'Device Breakdown',
                    icon: Icons.devices_other_outlined,
                    onTap: onDevice),
                if (exclude != 'areas' || exclude != 'team')
                  const Divider(height: 1),
              ],
              if (exclude != 'areas') ...[
                _ReportOption(
                    title: 'Popular Areas',
                    icon: Icons.map_outlined,
                    onTap: onAreas),
                if (exclude != 'team') const Divider(height: 1),
              ],
              if (exclude != 'team')
                _ReportOption(
                    title: 'Team Performance',
                    icon: Icons.groups_2_outlined,
                    onTap: onTeam),
            ],
          ),
        ),
      ],
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
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 18, color: AppTheme.deepBlue),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor, height: 1.3)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textSecondaryColor),
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
              offset: Offset(0, 6)),
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
    required this.onBack,
  });

  final String title;
  final String description;
  final VoidCallback onBack;

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
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 6),
                Text(description,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor, height: 1.25)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Dashboard'),
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

  const _PeriodOption(
      {required this.label, required this.isSelected, required this.onTap});

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
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.deepBlue : Colors.black)),
            Icon(
              isSelected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: isSelected
                  ? AppTheme.deepBlue
                  : Colors.grey.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
