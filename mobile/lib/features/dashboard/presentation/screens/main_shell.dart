import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  // Navigation items for each role
  List<_NavItem> _getNavItemsForRole(String? role) {
    switch (role) {
      case 'admin':
        return [
          _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', path: AppRoutes.adminDashboard),
          _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Donations', path: AppRoutes.donations),
          _NavItem(icon: Icons.business_outlined, activeIcon: Icons.business_rounded, label: 'NGOs', path: AppRoutes.ngos),
          _NavItem(icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user_rounded, label: 'Verify', path: AppRoutes.adminVerify),
          _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat', path: '/chat'),
          _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', path: AppRoutes.profile),
        ];
      case 'ngo':
        return [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: AppRoutes.home),
          _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Donations', path: AppRoutes.donations),
          _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Claims', path: AppRoutes.ngoClaims),
          _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts', path: AppRoutes.notifications),
          _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat', path: '/chat'),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', path: AppRoutes.profile),
        ];
      case 'donor':
      default:
        return [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: AppRoutes.home),
          _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Donations', path: AppRoutes.donations),
          _NavItem(icon: Icons.business_outlined, activeIcon: Icons.business_rounded, label: 'NGOs', path: AppRoutes.ngos),
          _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts', path: AppRoutes.notifications),
          _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat', path: '/chat'),
          _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile', path: AppRoutes.profile),
        ];
    }
  }
  
  /// Handle back button press with exit confirmation (only called at root)
  Future<void> _onWillPop() async {
    final now = DateTime.now();
    
    // Double-press to exit confirmation
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      HapticFeedback.mediumImpact();
      
      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text('Press back again to exit'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.darkGray,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
    // User pressed back twice within 2 seconds - exit app
    HapticFeedback.heavyImpact();
    SystemNavigator.pop();
  }

  void _onItemTapped(int index, List<_NavItem> navItems) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
      });
      context.go(navItems[index].path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    // Get role-specific nav items
    final navItems = _getNavItemsForRole(user?.role);
    
    // Update current index based on current location
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
    
    // Determine FAB visibility based on role and current screen
    // Only show FAB for donors on Home and Donations screens
    final shouldShowFabOnScreen = location == AppRoutes.home || 
                                   location == AppRoutes.donations ||
                                   location.startsWith(AppRoutes.donations);
    final showFab = user?.isDonor == true && shouldShowFabOnScreen;

    // Check if we can actually pop (have navigation history)
    final canPopRouter = GoRouter.of(context).canPop();
    
    return PopScope(
      // Allow pop if router has history, block if at root
      canPop: canPopRouter,
      onPopInvokedWithResult: (didPop, result) async {
        // If didPop is true, the navigation already happened, nothing to do
        if (didPop) return;
        
        // We're at root, show exit confirmation
        await _onWillPop();
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: widget.child,
          ),
        ),
        // Global FAB removed to prevent overlap.
        // Specific screens (Home/Donations) handle their own FABs.
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = _currentIndex == index;
                  
                  return _NavBarItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                       // Add Heavy Impact for selection
                       if (!isSelected) HapticFeedback.heavyImpact();
                       _onItemTapped(index, navItems);
                    },
                    accentColor: user?.isAdmin == true ? const Color(0xFF667eea) : AppTheme.primaryRed,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  
  _NavItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  
  const _NavBarItem({
    required this.item, 
    required this.isSelected, 
    required this.onTap,
    this.accentColor = AppTheme.primaryRed, // Use Theme variable
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? accentColor : AppTheme.gray,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 11.5 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? accentColor : AppTheme.gray,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
