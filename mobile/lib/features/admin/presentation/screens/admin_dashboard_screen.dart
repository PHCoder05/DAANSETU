import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'admin_volunteer_verifications_screen.dart';
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
      final data = response.data['data'];
      
      final users = data['users'] ?? {};
      final donations = data['donations'] ?? {};
      
      // Fetch support counts
      int supportRequests = 0;
      try {
        final supportRes = await apiClient.getAllSupportRequests();
        if (supportRes.statusCode == 200) {
          final list = supportRes.data['data'] as List? ?? [];
          supportRequests = list.where((r) => r['status'] == 'pending').length;
        }
      } catch (_) {}

      // Fetch fraud counts
      int fraudAlerts = 0;
      try {
        final fraudRes = await apiClient.getFraudAlerts(status: 'open');
        if (fraudRes.statusCode == 200) {
          final list = fraudRes.data['data'] as List? ?? [];
          fraudAlerts = list.length;
        }
      } catch (_) {}
      
      return {
        'totalDonations': donations['total'] ?? 0,
        'totalNgos': users['ngos'] ?? 0,
        'pendingVerifications': (users['pendingNGOs'] ?? 0) + (users['pendingVolunteers'] ?? 0),
        'pendingNgos': users['pendingNGOs'] ?? 0,
        'pendingVolunteers': users['pendingVolunteers'] ?? 0,
        'totalUsers': users['total'] ?? 0,
        'pendingSupport': supportRequests,
        'openFraudAlerts': fraudAlerts,
        
        // Distribution Data
        'activeDonations': (donations['available'] ?? 0) as int, 
        'claimedDonations': (donations['claimed'] ?? 0) as int,
        'deliveredDonations': (donations['delivered'] ?? 0) as int,
      };
    }
  } catch (e) {
    debugPrint('Error fetching admin stats: $e');
  }
  
  return {
    'totalDonations': 0, 'totalNgos': 0, 'pendingVerifications': 0, 'totalUsers': 0,
    'pendingSupport': 0, 'activeDonations': 0, 'claimedDonations': 0, 'deliveredDonations': 0,
  };
});

/// Provider for pending NGO verifications
final pendingNgosProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getPendingNgos();
    if (response.statusCode == 200) {
      return response.data['data'] as List? ?? [];
    }
  } catch (_) {}
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
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildHeader(context, user, ref),
                ),
              ),
              
              // Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: statsAsync.when(
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
                ),
              ),
              
              pendingNgosAsync.when(
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
                data: (ngos) {
                  if (ngos.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _NgoVerificationCard(
                          ngo: ngos[index],
                          onVerify: () => _verifyNgo(context, ref, ngos[index]['_id']),
                          onReject: () => _rejectNgo(context, ref, ngos[index]['_id']),
                        ).animate(delay: Duration(milliseconds: index * 100)).fade().slideY(begin: 0.1, end: 0),
                        childCount: ngos.length > 2 ? 2 : ngos.length,
                      ),
                    ),
                  );
                },
              ),

              // Volunteer Verifications Entry
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text('Volunteer Approvals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(onPressed: () => context.go(AppRoutes.adminVolunteerVerifications), child: const Text('View All')),
                    ],
                  ),
                ),
              ),
              
              // Small card for volunteers
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final volunteersAsync = ref.watch(allPendingVolunteersProvider);
                    return volunteersAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (volunteers) {
                        if (volunteers.isEmpty) return _buildEmptyState('No pending volunteers', Icons.person_add_rounded);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: InkWell(
                            onTap: () => context.go(AppRoutes.adminVolunteerVerifications),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
                                    child: const Icon(Icons.group_add_rounded, color: AppTheme.accentOrange),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${volunteers.length} Pending Volunteers', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const Text('Verify IDs to activate accounts', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppTheme.gray),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Field Operations Map
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Field Operations', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const _FieldOperationsMap(),
                    ],
                  ),
                ),
              ),
              
              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Management Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _QuickActionCard(icon: Icons.support_agent_rounded, label: 'Support', color: AppTheme.primaryRed, onTap: () => context.go(AppRoutes.adminSupportRequests))),
                          const SizedBox(width: 12),
                          Expanded(child: _QuickActionCard(icon: Icons.shield_rounded, label: 'Security', color: AppTheme.accentOrange, onTap: () => context.go(AppRoutes.adminFraudAlerts))),
                          const SizedBox(width: 12),
                          Expanded(child: _QuickActionCard(icon: Icons.people_rounded, label: 'Users', color: AppTheme.accentBlue, onTap: () => context.go(AppRoutes.adminUsers))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Dashboard', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                Text(user?.name ?? 'Super Admin', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(title: 'Pending Approvals', value: stats['pendingVerifications'].toString(), icon: Icons.verified_user_rounded, color: AppTheme.warning),
        _StatCard(title: 'Fraud Alerts', value: stats['openFraudAlerts'].toString(), icon: Icons.security_rounded, color: AppTheme.primaryRed),
        _StatCard(title: 'Active Users', value: stats['totalUsers'].toString(), icon: Icons.people_rounded, color: AppTheme.accentBlue),
        _StatCard(title: 'Total Donations', value: stats['totalDonations'].toString(), icon: Icons.volunteer_activism_rounded, color: AppTheme.success),
      ],
    );
  }

  Widget _buildDonationChart(BuildContext context, Map<String, dynamic> stats) {
    final active = (stats['activeDonations'] as int).toDouble();
    final claimed = (stats['claimedDonations'] as int).toDouble();
    final delivered = (stats['deliveredDonations'] as int).toDouble();
    final total = active + claimed + delivered;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Donation Ecosystem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: AppTheme.accentOrange, value: active, title: '${(active/total*100).toStringAsFixed(0)}%', radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(color: AppTheme.primaryBlue, value: claimed, title: '${(claimed/total*100).toStringAsFixed(0)}%', radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  PieChartSectionData(color: AppTheme.success, value: delivered, title: '${(delivered/total*100).toStringAsFixed(0)}%', radius: 45, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(color: AppTheme.accentOrange, label: 'Available'),
              const SizedBox(width: 16),
              _ChartLegend(color: AppTheme.primaryBlue, label: 'Claimed'),
              const SizedBox(width: 16),
              _ChartLegend(color: AppTheme.success, label: 'Delivered'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.gray.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: AppTheme.gray)),
        ],
      ),
    );
  }

  Future<void> _verifyNgo(BuildContext context, WidgetRef ref, String ngoId) async {
    HapticFeedback.mediumImpact();
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.verifyNgo(ngoId, 'verified');
      CustomSnackBar.success(context, 'NGO verified and activated!');
      ref.invalidate(pendingNgosProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      CustomSnackBar.error(context, 'Verification failed');
    }
  }

  Future<void> _rejectNgo(BuildContext context, WidgetRef ref, String ngoId) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject NGO?'),
        content: const Text('This will decline their registration request.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppTheme.error), child: const Text('Reject')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.verifyNgo(ngoId, 'rejected');
        CustomSnackBar.warning(context, 'NGO registration rejected');
        ref.invalidate(pendingNgosProvider);
        ref.invalidate(adminStatsProvider);
      } catch (_) {}
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 11, color: AppTheme.gray), maxLines: 1, overflow: TextOverflow.ellipsis),
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
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
  const _NgoVerificationCard({required this.ngo, required this.onVerify, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadow),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppTheme.accentBlue.withOpacity(0.1), child: const Icon(Icons.business_rounded, color: AppTheme.accentBlue)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ngo['name'] ?? 'NGO', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(ngo['email'] ?? '', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onReject, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error)), child: const Text('Reject'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: onVerify, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white), child: const Text('Verify'))),
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
  const _ChartLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.gray))]);
  }
}

class _FieldOperationsMap extends ConsumerWidget {
  const _FieldOperationsMap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder(
        future: ref.read(apiClientProvider).getActiveVolunteers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final volunteers = (snapshot.data?.data['data'] as List?) ?? [];
          
          return FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(19.0760, 72.8777), // Default to Mumbai
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.daansetu.app',
              ),
              MarkerLayer(
                markers: volunteers.map((v) {
                  final loc = v['location'];
                  if (loc == null || loc['coordinates'] == null) return null;
                  return Marker(
                    point: LatLng(loc['coordinates'][1], loc['coordinates'][0]),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryRed, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.delivery_dining_rounded, color: AppTheme.primaryRed, size: 18),
                      ),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
