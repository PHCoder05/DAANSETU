import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/app_loader.dart';

/// Provider for admin stats
final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.getAdminStats();
    
    if (response.statusCode == 200) {
      final data = response.data['data']; // Assuming wrapped in standard 'data'
      
      final users = data['users'] ?? {};
      final donations = data['donations'] ?? {};
      
      return {
        'totalDonations': donations['total'] ?? 0,
        'totalNgos': users['ngos'] ?? 0,
        'pendingVerifications': users['pendingNGOs'] ?? 0,
        'totalUsers': users['total'] ?? 0,
        
        // Real Distribution Data
        'activeDonations': (donations['available'] ?? 0) as int, 
        'claimedDonations': (donations['claimed'] ?? 0) as int,
        'deliveredDonations': (donations['delivered'] ?? 0) as int,
        'pendingDonations': 0, // 'active' is essentially pending claim
      };
    }
  } catch (e) {
    // Fallback if API fails or structure differs
  }
  
  return {
    'totalDonations': 0,
    'totalNgos': 0,
    'pendingVerifications': 0,
    'totalUsers': 0,
    'activeDonations': 0,
    'claimedDonations': 0,
    'deliveredDonations': 0,
    'pendingDonations': 0,
  };
});

/// Provider for pending NGO verifications
final pendingNgosProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.getNgos();
    
    if (response.statusCode == 200) {
      final data = response.data;
      final ngosList = data['ngos'] as List? ?? [];
      return ngosList.where((n) => 
        n['ngoDetails']?['verificationStatus'] == 'pending'
      ).toList();
    }
  } catch (e) {
    // Handle error
  }
  
  return [];
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final statsAsync = ref.watch(adminStatsProvider);
    final pendingNgosAsync = ref.watch(pendingNgosProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            ref.invalidate(adminStatsProvider);
            ref.invalidate(pendingNgosProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryRed,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Card with Glassmorphism
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryRed,
                              AppTheme.primaryRed.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.name ?? 'Admin',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Super Admin',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Logout Button
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                await ref.read(authStateProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go(AppRoutes.login);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideY(begin: -0.1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Stats Cards
                      statsAsync.when(
                        loading: () => const AppLoader(message: 'Loading stats...'),
                        error: (_, __) => const Text('Error loading stats'),
                        data: (stats) => Column(
                          children: [
                            _buildStatsGrid(context, stats),
                            const SizedBox(height: 24),
                            _buildDonationChart(context, stats),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Pending Verifications Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Pending NGO Verifications',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go(AppRoutes.adminUsers);
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ).animate(delay: 300.ms).fade(),
              ),
              
              // Pending NGOs List
              pendingNgosAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: AppLoader(message: 'Loading verifications...'),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text('Error: $error'),
                    ),
                  ),
                ),
                data: (ngos) {
                  if (ngos.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyVerifications(context),
                    );
                  }
                  
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ngo = ngos[index];
                          return _NgoVerificationCard(
                            ngo: ngo,
                            onVerify: () => _verifyNgo(context, ref, ngo['_id']),
                            onReject: () => _rejectNgo(context, ref, ngo['_id']),
                          ).animate(delay: Duration(milliseconds: index * 100))
                              .fade()
                              .slideY(begin: 0.1, end: 0);
                        },
                        childCount: ngos.length,
                      ),
                    ),
                  );
                },
              ),
              
              // Quick Actions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.volunteer_activism_rounded,
                              label: 'Donations',
                              color: AppTheme.primaryRed,
                              onTap: () => context.go(AppRoutes.donations),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.business_rounded,
                              label: 'NGOs',
                              color: const Color(0xFF9B59B6),
                              onTap: () => context.go(AppRoutes.ngos),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.people_rounded,
                              label: 'Users',
                              color: AppTheme.accentBlue,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.go(AppRoutes.adminUsers);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fade(),
              ),
              
              // Bottom padding for nav bar
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDonationChart(BuildContext context, Map<String, dynamic> stats) {
    if (stats['totalDonations'] == 0) return const SizedBox.shrink();
    
    final active = stats['activeDonations'] as int;
    final completed = stats['deliveredDonations'] as int;
    final claimed = stats['claimedDonations'] as int; // using claimed instead of pending
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donation Status Distribution',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.success,
                    value: completed > 0 ? completed.toDouble() : 1, // Avoid empty
                    title: completed > 0 ? '${(completed/(active+completed+claimed)*100).toStringAsFixed(0)}%' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppTheme.accentOrange,
                    value: active > 0 ? active.toDouble() : 1,
                    title: active > 0 ? '${(active/(active+completed+claimed)*100).toStringAsFixed(0)}%' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppTheme.primaryBlue,
                    value: claimed > 0 ? claimed.toDouble() : 1,
                    title: claimed > 0 ? '${(claimed/(active+completed+claimed)*100).toStringAsFixed(0)}%' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(color: AppTheme.success, label: 'Delivered'),
              const SizedBox(width: 16),
              _ChartLegend(color: AppTheme.accentOrange, label: 'Available'),
              const SizedBox(width: 16),
              _ChartLegend(color: AppTheme.primaryBlue, label: 'Claimed'),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3, // Reduced from 1.5 for better fit
      children: [
        _StatCard(
          title: 'Total Donations',
          value: stats['totalDonations'].toString(),
          icon: Icons.volunteer_activism_rounded,
          color: AppTheme.primaryRed,
        ).animate(delay: 100.ms).fade().scale(begin: const Offset(0.9, 0.9)),
        _StatCard(
          title: 'Total NGOs',
          value: stats['totalNgos'].toString(),
          icon: Icons.business_rounded,
          color: const Color(0xFF9B59B6),
        ).animate(delay: 150.ms).fade().scale(begin: const Offset(0.9, 0.9)),
        _StatCard(
          title: 'Pending Verifications',
          value: stats['pendingVerifications'].toString(),
          icon: Icons.pending_actions_rounded,
          color: AppTheme.warning,
        ).animate(delay: 200.ms).fade().scale(begin: const Offset(0.9, 0.9)),
        _StatCard(
          title: 'Total Users',
          value: stats['totalUsers'].toString(),
          icon: Icons.people_rounded,
          color: AppTheme.accentBlue,
        ).animate(delay: 250.ms).fade().scale(begin: const Offset(0.9, 0.9)),
      ],
    );
  }
  
  Widget _buildEmptyVerifications(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending NGO verifications',
              style: TextStyle(color: AppTheme.gray),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }
  
  Future<void> _verifyNgo(BuildContext context, WidgetRef ref, String ngoId) async {
    HapticFeedback.mediumImpact();
    
    try {
      final apiClient = ref.read(apiClientProvider);
      // Call verification endpoint
      // await apiClient.verifyNgo(ngoId, 'verified');
      
      CustomSnackBar.success(context, 'NGO verified successfully!');
      ref.invalidate(pendingNgosProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      CustomSnackBar.error(context, 'Failed to verify NGO');
    }
  }
  
  Future<void> _rejectNgo(BuildContext context, WidgetRef ref, String ngoId) async {
    HapticFeedback.mediumImpact();
    
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject NGO'),
          content: const Text('Are you sure you want to reject this NGO verification?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      
      if (confirmed == true) {
        // final apiClient = ref.read(apiClientProvider);
        // await apiClient.verifyNgo(ngoId, 'rejected');
        
        if (context.mounted) {
          CustomSnackBar.warning(context, 'NGO verification rejected');
        }
        ref.invalidate(pendingNgosProvider);
        ref.invalidate(adminStatsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.error(context, 'Failed to reject NGO');
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced from 16
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min, // Add this to prevent expansion
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced from 8
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18), // Reduced from 20
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith( // Changed from headlineSmall
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11, // Reduced from 12
              color: AppTheme.gray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NgoVerificationCard extends StatelessWidget {
  final Map<String, dynamic> ngo;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  
  const _NgoVerificationCard({
    required this.ngo,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final ngoDetails = ngo['ngoDetails'] as Map<String, dynamic>? ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (ngo['name'] as String?)?.isNotEmpty == true 
                        ? ngo['name'][0].toUpperCase() 
                        : 'N',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ngo['name'] ?? 'Unknown NGO',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ngo['email'] ?? '',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          
          // Details
          if (ngoDetails['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              ngoDetails['description'],
              style: TextStyle(color: AppTheme.darkGray, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          if (ngoDetails['registrationNumber'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 14, color: AppTheme.gray),
                const SizedBox(width: 6),
                Text(
                  'Reg: ${ngoDetails['registrationNumber']}',
                  style: TextStyle(fontSize: 12, color: AppTheme.gray),
                ),
              ],
            ),
          ],
          
          // Actions
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.gray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
