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
    
    // For mobile platforms, check persistent auth status from storage
    debugPrint('SplashScreen: Checking persistent auth status...');
    
    try {
      await ref.read(authStateProvider.notifier).checkAuthStatus();
    } catch (e) {
      debugPrint('SplashScreen: Auth check failed with error: $e');
    }
    
    if (!mounted) {
      debugPrint('SplashScreen: Not mounted after auth check');
      return;
    }
    
    final authState = ref.read(authStateProvider);
    debugPrint('SplashScreen: Final auth state - isAuthenticated=${authState.isAuthenticated}');
    
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE23744),
              Color(0xFFD42E3F),
              Color(0xFFBD1F30),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative circles
            Positioned(
              top: -size.width * 0.25,
              left: -size.width * 0.15,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ).animate().scale(duration: 1200.ms, curve: Curves.easeOut),
            ),
            Positioned(
              bottom: -size.width * 0.2,
              right: -size.width * 0.1,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ).animate().scale(duration: 1000.ms, delay: 200.ms, curve: Curves.easeOut),
            ),
            Positioned(
              top: size.height * 0.15,
              right: size.width * 0.1,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ).animate().scale(duration: 800.ms, delay: 400.ms, curve: Curves.easeOutBack),
            ),

            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing ring behind logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 2000.ms),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        size: 54,
                        color: AppTheme.primaryRed,
                      ),
                    )
                        .animate()
                        .scale(duration: 700.ms, curve: Curves.easeOutBack)
                        .fade(duration: 400.ms),
                  ],
                ),

                const SizedBox(height: 36),

                // App Name
                Text(
                  'DAANSETU',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.white,
                    letterSpacing: 6,
                    fontSize: 36,
                  ),
                )
                    .animate(delay: 300.ms)
                    .slideY(begin: 0.3, end: 0)
                    .fade(),

                const SizedBox(height: 10),

                // Tagline with decorative line
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 24, height: 1, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 12),
                    Text(
                      'Bridge of Giving',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.white.withValues(alpha: 0.9),
                        letterSpacing: 3,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 24, height: 1, color: Colors.white.withValues(alpha: 0.4)),
                  ],
                )
                    .animate(delay: 500.ms)
                    .fade()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 64),

                // Loading indicator
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.white.withValues(alpha: 0.8),
                  ),
                )
                    .animate(delay: 700.ms)
                    .fade()
                    .scale(),
              ],
            ),

            // Bottom branding
            Positioned(
              bottom: 40,
              child: Text(
                'Trusted by 500+ NGOs across India',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ).animate(delay: 800.ms).fade(),
            ),
          ],
        ),
      ),
    );
  }
}
