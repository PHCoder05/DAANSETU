
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/unified_auth_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/dashboard/presentation/screens/main_shell.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/analytics_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/donations/presentation/screens/donations_screen.dart';
import '../features/donations/presentation/screens/donation_detail_screen.dart';
import '../features/donations/presentation/screens/create_donation_screen.dart';
import '../features/donations/presentation/screens/donation_tracking_screen.dart';
import '../features/donations/presentation/screens/my_donations_screen.dart';
import '../shared/models/donation.dart';
import '../features/ngos/presentation/screens/ngos_screen.dart';
import '../features/ngos/presentation/screens/ngos_screen.dart';
import '../features/ngos/presentation/screens/ngo_detail_screen.dart';
import '../features/ngos/presentation/screens/ngo_claims_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/change_password_screen.dart';
import '../features/profile/presentation/screens/activity_screen.dart';
import '../features/profile/presentation/screens/about_screen.dart';
import '../features/profile/presentation/screens/help_support_screen.dart';
import '../features/profile/presentation/screens/legal_screen.dart';
import '../features/profile/presentation/screens/impact_leaderboard_screen.dart';
import '../features/profile/presentation/screens/saved_donations_screen.dart';
import '../features/reviews/presentation/screens/create_review_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_users_screen.dart';
import '../features/admin/presentation/screens/admin_support_requests_screen.dart';
import '../features/admin/presentation/screens/admin_ngo_verifications_screen.dart';
import '../features/admin/presentation/screens/admin_volunteer_verifications_screen.dart';
import '../features/admin/presentation/screens/admin_fraud_alerts_screen.dart';
import '../features/profile/presentation/screens/contact_support_screen.dart';
import '../features/profile/presentation/screens/volunteer_id_screen.dart';
import '../features/profile/presentation/screens/milestones_screen.dart';
import '../shared/providers/auth_provider.dart';

// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';  // Now points to unified auth
  static const String register = '/register'; // Also points to unified auth
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';
  static const String donations = '/donations';
  static const String donationDetail = '/donations/:id';
  static const String createDonation = '/donations/create';
  static const String trackDonation = '/donations/track/:id';
  static const String myDonations = '/my-donations';
  static const String ngos = '/ngos';
  static const String ngoDetail = '/ngos/:id';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String activity = '/profile/activity';
  static const String about = '/profile/about';
  static const String helpSupport = '/profile/help-support';
  static const String savedDonations = '/profile/saved';
  static const String verification = '/profile/verification';
  static const String volunteerId = '/profile/volunteer-id';
  static const String milestones = '/profile/milestones';
  static const String leaderboard = '/leaderboard';
  static const String createReview = '/review/create';
  static const String onboarding = '/onboarding';
  
  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminVerify = '/admin/verify';
  static const String adminUsers = '/admin/users';
  static const String adminNgoVerifications = '/admin/ngos/pending';
  static const String adminVolunteerVerifications = '/admin/volunteers/pending';
  static const String adminSupportRequests = '/admin/support';
  static const String adminFraudAlerts = '/admin/fraud';
  
  static const String privacy = '/profile/privacy';
  static const String terms = '/profile/terms';
  
  // NGO routes
  static const String ngoClaims = '/ngo/claims';
  static const String ngoInventory = '/ngo/inventory';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Use ref.read instead of ref.watch to prevent router rebuilds
  // that cause the app to restart when auth state changes
  
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Read auth state inside redirect so it gets fresh value each time
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isRegistering = state.matchedLocation == AppRoutes.register;
      final isForgotPassword = state.matchedLocation == AppRoutes.forgotPassword;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      
      // Allow splash screen to handle initial navigation
      if (isSplash) return null;
      
      // If not logged in and not on auth pages/onboarding, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isRegistering && !isForgotPassword && !isOnboarding) {
        return AppRoutes.login;
      }
      
      // If logged in and on auth pages/onboarding, redirect based on role
      if (isLoggedIn && (isLoggingIn || isRegistering || isForgotPassword || isOnboarding)) {
        final user = authState.user;
        if (user?.isAdmin == true) {
          return AppRoutes.adminDashboard;
        }
        return AppRoutes.home;
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Unified Auth Screen (handles both login and registration)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const UnifiedAuthScreen(),
      ),
      // Register route also uses unified auth (for backwards compatibility)
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const UnifiedAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const DonationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          // Admin routes
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminVerify,
            builder: (context, state) => const AdminDashboardScreen(), // Uses same screen for now
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminSupportRequests,
            builder: (context, state) => const AdminSupportRequestsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminNgoVerifications,
            builder: (context, state) => const AdminNgoVerificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminVolunteerVerifications,
            builder: (context, state) => const AdminVolunteerVerificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminFraudAlerts,
            builder: (context, state) => const AdminFraudAlertsScreen(),
          ),
          // NGO claims route
          GoRoute(
            path: AppRoutes.ngoClaims,
            builder: (context, state) => const NgoClaimsScreen(), 
          ),
          // NGO Inventory Route
          GoRoute(
            path: AppRoutes.ngoInventory,
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.donations,
            builder: (context, state) => const DonationsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final initialData = state.extra as Donation?;
                  return CreateDonationScreen(initialData: initialData);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DonationDetailScreen(donationId: id);
                },
              ),
              GoRoute(
                path: 'track/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return DonationTrackingScreen(donationId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/chat/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatScreen(
                recipientId: userId,
                recipientName: extra?['name'] ?? 'User',
                donationId: extra?['donationId'],
              );
            },
          ),
          GoRoute(
            path: AppRoutes.myDonations,
            builder: (context, state) => const MyDonationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.ngos,
            builder: (context, state) => const NgosScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return NgoDetailScreen(ngoId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'change-password',
                builder: (context, state) => const ChangePasswordScreen(),
              ),
              GoRoute(
                path: 'activity',
                builder: (context, state) => const ActivityScreen(),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutScreen(),
              ),
              GoRoute(
                path: 'help-support',
                builder: (context, state) => const HelpSupportScreen(),
                routes: [
                  GoRoute(
                    path: 'contact',
                    builder: (context, state) => const ContactSupportScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacyPolicyScreen(),
              ),
              GoRoute(
                path: 'terms',
                builder: (context, state) => const TermsScreen(),
              ),
              GoRoute(
                path: 'saved',
                builder: (context, state) => const SavedDonationsScreen(),
              ),
              GoRoute(
                path: 'volunteer-id',
                builder: (context, state) => const VolunteerIdScreen(),
              ),
              GoRoute(
                path: 'milestones',
                builder: (context, state) => const MilestonesScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.createReview,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return CreateReviewScreen(
                donationId: extra['donationId'] ?? '',
                ngoId: extra['ngoId'] ?? '',
                ngoName: extra['ngoName'] ?? 'NGO',
              );
            },
          ),
          GoRoute(
            path: AppRoutes.leaderboard,
            builder: (context, state) => const ImpactLeaderboardScreen(),
          ),
        ],
      ),
    ],
  );
});
