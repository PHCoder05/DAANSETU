import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  List<_NavItem> _getNavItemsForRole(String? role) {
    switch (role) {
      case 'admin':
        // Admin ONLY sees admin operations
        return [
          _NavItem(icon: Icons.space_dashboard_outlined, activeIcon: Icons.space_dashboard_rounded, label: 'Overview', path: AppRoutes.adminDashboard),
          _NavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Users', path: AppRoutes.adminUsers),
          _NavItem(icon: Icons.verified_outlined, activeIcon: Icons.verified_rounded, label: 'Verify', path: AppRoutes.adminNgoVerifications),
          _NavItem(icon: Icons.support_agent_outlined, activeIcon: Icons.support_agent_rounded, label: 'Support', path: AppRoutes.adminSupportRequests),
          _NavItem(icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts_rounded, label: 'Account', path: AppRoutes.profile),
        ];
      case 'ngo':
        return [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: AppRoutes.dashboard),
          _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Donations', path: AppRoutes.donations),
          _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Claims', path: AppRoutes.ngoClaims),
          _NavItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Stories', path: AppRoutes.impactStories),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', path: AppRoutes.profile),
        ];
      case 'volunteer':
        return [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: AppRoutes.dashboard),
          _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Donations', path: AppRoutes.donations),
          _NavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded, label: 'Rank', path: AppRoutes.leaderboard),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', path: AppRoutes.profile),
        ];
      case 'donor':
      default:
        return [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: AppRoutes.dashboard),
          _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Donations', path: AppRoutes.donations),
          _NavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded, label: 'Rank', path: AppRoutes.leaderboard),
          _NavItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Stories', path: AppRoutes.impactStories),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', path: AppRoutes.profile),
        ];
    }
  }

  Future<void> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.exit_to_app, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Press back again to exit', style: TextStyle(fontSize: 14)),
          ]),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.charcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    SystemNavigator.pop();
  }

  void _onItemTapped(int index, List<_NavItem> navItems) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
      context.go(navItems[index].path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final navItems = _getNavItemsForRole(user?.role);
    final isAdmin = user?.isAdmin == true;
    final Color accentColor = isAdmin ? const Color(0xFF6C5CE7) : AppTheme.primaryRed;

    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < navItems.length; i++) {
      if (location.startsWith(navItems[i].path)) {
        if (_currentIndex != i) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = i);
          });
        }
        break;
      }
    }

    final canPopRouter = GoRouter.of(context).canPop();

    return PopScope(
      canPop: canPopRouter,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey<int>(_currentIndex), child: widget.child),
        ),
        bottomNavigationBar: _ProfessionalNavBar(
          navItems: navItems,
          currentIndex: _currentIndex,
          accentColor: accentColor,
          onTap: (i) => _onItemTapped(i, navItems),
        ),
      ),
    );
  }
}

// ─── PROFESSIONAL NAV BAR ───
class _ProfessionalNavBar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int currentIndex;
  final Color accentColor;
  final void Function(int) onTap;

  const _ProfessionalNavBar({
    required this.navItems,
    required this.currentIndex,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.lightGray.withValues(alpha: 0.8), width: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: navItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Expanded(
                child: _NavBarItem(
                  item: item,
                  isSelected: currentIndex == i,
                  accentColor: accentColor,
                  onTap: () => onTap(i),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── DATA CLASS ───
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  _NavItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}

// ─── NAV BAR ITEM ───
class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? accentColor : AppTheme.gray,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? accentColor : AppTheme.gray,
              letterSpacing: isSelected ? 0.1 : 0,
            ),
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
