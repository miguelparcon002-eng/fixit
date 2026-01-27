import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class TechNavigation extends StatefulWidget {
  final Widget child;

  const TechNavigation({super.key, required this.child});

  @override
  State<TechNavigation> createState() => _TechNavigationState();
}

class _TechNavigationState extends State<TechNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () {
                    setState(() => _currentIndex = 0);
                    context.go('/tech-home');
                  },
                ),
                _NavItem(
                  icon: Icons.work_outline,
                  label: 'Jobs',
                  isSelected: _currentIndex == 1,
                  onTap: () {
                    setState(() => _currentIndex = 1);
                    context.go('/tech-jobs');
                  },
                ),
                _NavItem(
                  icon: Icons.attach_money,
                  label: 'Earnings',
                  isSelected: _currentIndex == 2,
                  onTap: () {
                    setState(() => _currentIndex = 2);
                    context.go('/tech-earnings');
                  },
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: _currentIndex == 3,
                  onTap: () {
                    setState(() => _currentIndex = 3);
                    context.go('/tech-profile');
                  },
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
          color: isSelected ? AppTheme.primaryCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
