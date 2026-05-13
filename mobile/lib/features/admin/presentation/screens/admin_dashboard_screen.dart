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

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final statsAsync = ref.watch(adminStatsProvider);
    final pendingNgosAsync = ref.watch(pendingNgosProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: RefreshIndicator(
        color: const Color(0xFF6C5CE7),
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(adminStatsProvider);
          ref.invalidate(pendingNgosProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, user, ref),
              ),

              // Divider space
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              
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
                                    backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.1),
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
            ],
          ),
        ),
      );
  }

  Widget _buildHeader(BuildContext context, dynamic user, WidgetRef ref) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B69), Color(0xFF6C5CE7)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting,', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                    Text(user?.name ?? 'Admin', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    final items = [
      {'title': 'Pending Approvals', 'value': stats['pendingVerifications'].toString(), 'icon': Icons.verified_user_rounded, 'color': const Color(0xFFF39C12)},
      {'title': 'Fraud Alerts', 'value': stats['openFraudAlerts'].toString(), 'icon': Icons.security_rounded, 'color': const Color(0xFFE74C3C)},
      {'title': 'Total Users', 'value': stats['totalUsers'].toString(), 'icon': Icons.people_rounded, 'color': const Color(0xFF3498DB)},
      {'title': 'Total Donations', 'value': stats['totalDonations'].toString(), 'icon': Icons.volunteer_activism_rounded, 'color': const Color(0xFF1BAC4B)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final color = item['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(item['icon'] as IconData, color: color, size: 20),
              ),
              const Expanded(child: SizedBox(height: 4)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(item['value'] as String, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.black, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 2),
              Text(item['title'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ).animate(delay: Duration(milliseconds: i * 80)).fade().scale(begin: const Offset(0.95, 0.95));
      },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Donation Ecosystem',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (_touchedIndex != -1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _touchedIndex == 0 ? '${active.toInt()} Available' : 
                    _touchedIndex == 1 ? '${claimed.toInt()} Claimed' : 
                    '${delivered.toInt()} Delivered',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6C5CE7)),
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  _buildPieSection(0, active, total, AppTheme.accentOrange, 'Available'),
                  _buildPieSection(1, claimed, total, AppTheme.primaryBlue, 'Claimed'),
                  _buildPieSection(2, delivered, total, AppTheme.success, 'Delivered'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _ChartLegend(color: AppTheme.accentOrange, label: 'Available'),
              _ChartLegend(color: AppTheme.primaryBlue, label: 'Claimed'),
              _ChartLegend(color: AppTheme.success, label: 'Delivered'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  PieChartSectionData _buildPieSection(int index, double value, double total, Color color, String label) {
    final isTouched = index == _touchedIndex;
    final fontSize = isTouched ? 16.0 : 10.0;
    final radius = isTouched ? 55.0 : 45.0;
    final widgetSize = isTouched ? 55.0 : 40.0;
    final double opacity = isTouched ? 1.0 : 0.85;

    return PieChartSectionData(
      color: color.withValues(alpha: opacity),
      value: value,
      title: '${(value / total * 100).toStringAsFixed(0)}%',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
      ),
      badgeWidget: isTouched ? _Badge(color, label) : null,
      badgePositionPercentageOffset: .98,
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.gray.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppTheme.gray)),
        ],
      ),
    );
  }

  Future<void> _verifyNgo(BuildContext context, WidgetRef ref, String ngoId) async {
    HapticFeedback.mediumImpact();
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.verifyNgo(ngoId, 'verified');
      if (!context.mounted) return;
      CustomSnackBar.success(context, 'NGO verified and activated!');
      ref.invalidate(pendingNgosProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      if (!context.mounted) return;
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
        if (!context.mounted) return;
        CustomSnackBar.warning(context, 'NGO registration rejected');
        ref.invalidate(pendingNgosProvider);
        ref.invalidate(adminStatsProvider);
      } catch (_) {}
    }
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
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
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
              CircleAvatar(backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.1), child: const Icon(Icons.business_rounded, color: AppTheme.accentBlue)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ngo['name'] ?? 'NGO', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(ngo['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
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
          
          final volunteers = (snapshot.data?.data['data']['volunteers'] as List?) ?? [];
          
          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(19.0760, 72.8777), // Default to Mumbai
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
                        color: AppTheme.primaryRed.withValues(alpha: 0.2),
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
class _Badge extends StatelessWidget {
  final Color color;
  final String label;
  const _Badge(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
      ),
      child: Icon(
        label == 'Available' ? Icons.inventory_2_rounded : 
        label == 'Claimed' ? Icons.assignment_turned_in_rounded : 
        Icons.check_circle_rounded,
        size: 16,
        color: color,
      ),
    );
  }
}
