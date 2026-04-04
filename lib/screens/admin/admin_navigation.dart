import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
class AdminNavigation extends StatefulWidget {
  final Widget child;
  const AdminNavigation({super.key, required this.child});
  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}
class _AdminNavigationState extends State<AdminNavigation> {
  int _indexFromRoute(String location) {
    if (location.startsWith('/admin-home')) return 0;
    if (location.startsWith('/admin-appointments')) return 1;
    if (location.startsWith('/admin-users') ||
        location.startsWith('/admin-customers') ||
        location.startsWith('/admin-technicians')) { return 2; }
    if (location.startsWith('/admin-reports')) return 3;
    return 0;
  }
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromRoute(location);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/admin-home'),
              ),
              _NavItem(
                icon: Icons.calendar_today,
                label: 'Appointment',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/admin-appointments'),
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Users',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/admin-users'),
              ),
              _NavItem(
                icon: Icons.bar_chart,
                label: 'Report',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/admin-reports'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.deepBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.deepBlue
                  : AppTheme.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.deepBlue
                    : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}