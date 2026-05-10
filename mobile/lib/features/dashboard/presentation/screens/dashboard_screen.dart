import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getDashboard();
  
  if (response.statusCode == 200) {
    return response.data;
  }
  
  return {};
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(color: AppTheme.white.withOpacity(0.8), fontSize: 14),
                            ),
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.go(AppRoutes.notifications),
                        icon: const Icon(Icons.notifications_outlined, color: AppTheme.white),
                      ),
                    ],
                  ),
                ].animate().fade().slideY(begin: 0.1, end: 0),
              ),
            ),
          ),
          
          // Stats
          SliverToBoxAdapter(
            child: dashboardAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Shimmer stats row
                    Row(
                      children: List.generate(2, (i) => Expanded(
                        child: Container(
                          height: 100,
                          margin: EdgeInsets.only(right: i == 0 ? 12 : 0),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppTheme.white.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(2, (i) => Expanded(
                        child: Container(
                          height: 100,
                          margin: EdgeInsets.only(right: i == 0 ? 12 : 0),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: 200.ms, color: AppTheme.white.withOpacity(0.5)),
                    const SizedBox(height: 20),
                    // Shimmer action bar
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: 400.ms, color: AppTheme.white.withOpacity(0.5)),
                    const SizedBox(height: 20),
                    // Shimmer list items
                    ...List.generate(3, (i) => Container(
                      height: 72,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, delay: 600.ms, color: AppTheme.white.withOpacity(0.5)),
                  ],
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.lightGray),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.error),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We couldn\'t load your dashboard. Check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppTheme.darkGray, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => ref.invalidate(dashboardProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().scale(begin: const Offset(0.95, 0.95)),
              ),
              data: (data) {
                final stats = data['stats'] as Map<String, dynamic>? ?? {};
                final recentDonations = data['recentDonations'] as List? ?? [];
                
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      if (user?.isDonor == true) ...[
                        _buildDonorStats(context, stats),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.analytics),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)],
                              ),
                              borderRadius: AppTheme.borderRadiusLarge,
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.analytics_rounded, color: AppTheme.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Impact Analytics', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('See how your donations are helping lives', style: TextStyle(color: AppTheme.white.withOpacity(0.9), fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.white, size: 16),
                              ],
                            ),
                          ),
                        ).animate().fade().slideY(begin: 0.1),
                      ] else if (user?.isNgo == true) ...[
                        _buildNgoStats(context, stats),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.ngoInventory),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.info, AppTheme.info.withOpacity(0.8)],
                              ),
                              borderRadius: AppTheme.borderRadiusLarge,
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: AppTheme.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Manage Inventory', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Distribute items to beneficiaries', style: TextStyle(color: AppTheme.white.withOpacity(0.9), fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.white, size: 16),
                              ],
                            ),
                          ),
                        ).animate().fade().slideY(begin: 0.1),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          if (user?.isDonor == true)
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.add_circle_outline,
                                title: 'Create Donation',
                                color: AppTheme.primaryRed,
                                onTap: () => context.go('${AppRoutes.donations}/create'),
                              ),
                            ),
                          if (user?.isDonor == true) const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.search_rounded,
                              title: 'Browse Donations',
                              color: AppTheme.success,
                              onTap: () => context.go(AppRoutes.donations),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.business_rounded,
                              title: 'View NGOs',
                              color: AppTheme.info,
                              onTap: () => context.go(AppRoutes.ngos),
                            ),
                          ),
                        ],
                      ).animate().fade().slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Activity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.donations),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      
                      if (recentDonations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: AppTheme.offWhite,
                            borderRadius: AppTheme.borderRadiusMedium,
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_rounded, size: 48, color: AppTheme.gray),
                              const SizedBox(height: 12),
                              Text('No recent activity', style: TextStyle(color: AppTheme.gray)),
                            ],
                          ),
                        )
                      else
                        ...recentDonations.take(5).map((donation) => _RecentDonationCard(
                          title: donation['title'] ?? 'Donation',
                          status: donation['status'] ?? 'available',
                          category: donation['category'] ?? 'other',
                          date: donation['createdAt'] != null 
                              ? DateTime.parse(donation['createdAt']) 
                              : DateTime.now(),
                        )).toList(),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDonorStats(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${stats['totalDonations'] ?? 0}',
            label: 'Total',
            icon: Icons.volunteer_activism_rounded,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${stats['activeDonations'] ?? 0}',
            label: 'Active',
            icon: Icons.hourglass_top_rounded,
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${stats['completedDonations'] ?? 0}',
            label: 'Completed',
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildNgoStats(BuildContext context, Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${stats['claimedDonations'] ?? 0}',
            label: 'Claimed',
            icon: Icons.handshake_rounded,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${stats['inTransit'] ?? 0}',
            label: 'In Transit',
            icon: Icons.local_shipping_rounded,
            color: AppTheme.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${stats['delivered'] ?? 0}',
            label: 'Delivered',
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.gray)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDonationCard extends StatelessWidget {
  final String title;
  final String status;
  final String category;
  final DateTime date;
  
  const _RecentDonationCard({
    required this.title,
    required this.status,
    required this.category,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.categoryColors[category] ?? AppTheme.gray;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getCategoryIcon(category), color: categoryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 12, color: AppTheme.gray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(status),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food': return Icons.restaurant_rounded;
      case 'clothes': return Icons.checkroom_rounded;
      case 'books': return Icons.menu_book_rounded;
      case 'medical': return Icons.medical_services_rounded;
      case 'electronics': return Icons.devices_rounded;
      case 'furniture': return Icons.chair_rounded;
      default: return Icons.inventory_2_rounded;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return AppTheme.success;
      case 'claimed': return AppTheme.warning;
      case 'in-transit': return AppTheme.info;
      case 'delivered': return const Color(0xFF9B59B6);
      default: return AppTheme.gray;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
