import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  
  // Static constant for SharedPreferences key
  static const String hasSeenOnboardingKey = 'hasSeenOnboarding';
  
  /// Static method to mark onboarding as complete (call from OnboardingScreen)
  static Future<void> markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(hasSeenOnboardingKey, true);
      debugPrint('SplashScreen: Onboarding marked as complete');
    } catch (e) {
      debugPrint('SplashScreen: Error marking onboarding complete: $e');
    }
  }

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  
  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }
  
  Future<void> _checkAuthAndNavigate() async {
    debugPrint('SplashScreen: Starting auth check...');
    
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) {
      debugPrint('SplashScreen: Not mounted after delay');
      return;
    }
    
    // Check current in-memory auth state first (works for both web and mobile)
    final currentAuthState = ref.read(authStateProvider);
    debugPrint('SplashScreen: Current in-memory auth state: ${currentAuthState.isAuthenticated}');
    
    // If already authenticated in-memory (e.g., just logged in/registered), go to appropriate screen
    if (currentAuthState.isAuthenticated) {
      final user = currentAuthState.user;
      if (user?.isAdmin == true) {
        debugPrint('SplashScreen: Already authenticated as admin, navigating to admin dashboard');
        if (mounted) context.go(AppRoutes.adminDashboard);
      } else {
        debugPrint('SplashScreen: Already authenticated, navigating to home');
        if (mounted) context.go(AppRoutes.home);
      }
      return;
    }
    
    // On web, FlutterSecureStorage has issues, so skip persistent storage check
    if (kIsWeb) {
      debugPrint('SplashScreen: Web platform, navigating to login');
      if (mounted) context.go(AppRoutes.login);
      return;
    }
    
    // For mobile platforms, check persistent auth status from storage with timeout
    debugPrint('SplashScreen: Checking persistent auth status...');
    bool authCheckCompleted = false;
    
    try {
      await ref.read(authStateProvider.notifier).checkAuthStatus()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('SplashScreen: Auth check timed out after 5 seconds');
        authCheckCompleted = true;
      });
      authCheckCompleted = true;
      debugPrint('SplashScreen: Auth check completed successfully');
    } catch (e) {
      debugPrint('SplashScreen: Auth check failed with error: $e');
      authCheckCompleted = true;
    }
    
    if (!mounted) {
      debugPrint('SplashScreen: Not mounted after auth check');
      return;
    }
    
    final authState = ref.read(authStateProvider);
    debugPrint('SplashScreen: Final auth state - isAuthenticated=${authState.isAuthenticated}, isLoading=${authState.isLoading}');
    
    // Navigate based on auth state
    if (authState.isAuthenticated) {
      final user = authState.user;
      if (user?.isAdmin == true) {
        debugPrint('SplashScreen: Navigating to admin dashboard');
        context.go(AppRoutes.adminDashboard);
      } else {
        debugPrint('SplashScreen: Navigating to home');
        context.go(AppRoutes.home);
      }
    } else {
      // Check if user has seen onboarding before
      final hasSeenOnboarding = await _checkOnboardingStatus();
      
      if (hasSeenOnboarding) {
        // Returning user - skip onboarding, go to login
        debugPrint('SplashScreen: Returning user, navigating to login');
        if (mounted) context.go(AppRoutes.login);
      } else {
        // First-time user - show onboarding
        debugPrint('SplashScreen: First-time user, navigating to onboarding');
        if (mounted) context.go(AppRoutes.onboarding);
      }
    }
  }
  
  /// Check if user has completed onboarding before
  Future<bool> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(SplashScreen.hasSeenOnboardingKey) ?? false;
    } catch (e) {
      debugPrint('SplashScreen: Error checking onboarding status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                size: 50,
                color: AppTheme.primaryRed,
              ),
            )
                .animate()
                .scale(
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .fade(duration: 400.ms),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              'DAANSETU',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppTheme.white,
                letterSpacing: 4,
                fontSize: 36,
              ),
            )
                .animate(delay: 300.ms)
                .slideY(begin: 0.3, end: 0)
                .fade(),
            
            const SizedBox(height: 8),
            
            Text(
              'Bridge of Giving',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.white.withOpacity(0.9),
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            )
                .animate(delay: 500.ms)
                .fade(),
            
            const SizedBox(height: 60),
            
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.white.withOpacity(0.9),
              ),
            )
                .animate(delay: 700.ms)
                .fade()
                .scale(),
          ],
        ),
      ),
    );
  }
}
