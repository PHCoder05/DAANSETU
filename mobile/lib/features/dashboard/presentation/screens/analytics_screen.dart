import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'dashboard_screen.dart'; // To access dashboardProvider

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = ref.watch(authStateProvider).user;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text('Impact Analytics', style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.black),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
        error: (err, stack) => Center(child: Text('Error loading analytics: $err')),
        data: (data) {
          if (user?.role == 'ngo') {
            return _buildNgoAnalytics(context, data);
          } else if (user?.role == 'volunteer') {
            return _buildVolunteerAnalytics(context, data, user);
          } else {
            return _buildDonorAnalytics(context, data, user);
          }
        },
      ),
    );
  }

  Widget _buildDonorAnalytics(BuildContext context, Map<String, dynamic> data, dynamic user) {
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final donations = stats['donations'] as Map<String, dynamic>? ?? {};
    
    final total = stats['totalDonations'] ?? 0;
    final completed = donations['delivered'] ?? 0;
    final active = (donations['claimed'] ?? 0) + (donations['in-transit'] ?? 0);
    final impactScore = user?.impactScore ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, total, completed, impactScore).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 24),
          _buildTierCard(context, impactScore).animate().fadeIn(delay: 150.ms).scale(),
          const SizedBox(height: 32),
          Text('Your Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          _buildAchievements().animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 32),
          Text('Donation Status Breakdown', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildPieChart(active, completed, total).animate().fadeIn(delay: 300.ms).scale(),
          const SizedBox(height: 32),
          Text('Impact Over Time', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildBarChart(AppTheme.primaryRed).animate().fadeIn(delay: 500.ms).slideX(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNgoAnalytics(BuildContext context, Map<String, dynamic> data) {
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final inventory = stats['inventory'] as Map<String, dynamic>? ?? {};
    
    final claimed = stats['claimed'] ?? 0;
    final delivered = stats['delivered'] ?? 0;
    final totalStock = inventory['totalStock'] ?? 0;
    final totalDistributed = inventory['totalDistributed'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid([
            _StatItem('Claimed', '$claimed', Icons.handshake_rounded, AppTheme.primaryRed),
            _StatItem('Delivered', '$delivered', Icons.check_circle_rounded, AppTheme.success),
            _StatItem('In Stock', '$totalStock', Icons.inventory_2_rounded, AppTheme.info),
            _StatItem('Distributed', '$totalDistributed', Icons.volunteer_activism_rounded, AppTheme.accentOrange),
          ]).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 32),
          Text('Inventory Utilization', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInventoryChart(totalStock, totalDistributed).animate().fadeIn(delay: 200.ms).scale(),
          const SizedBox(height: 32),
          Text('Monthly Collection Trend', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildBarChart(AppTheme.info).animate().fadeIn(delay: 400.ms).slideX(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildVolunteerAnalytics(BuildContext context, Map<String, dynamic> data, dynamic user) {
    final stats = user?.volunteerStats;
    final deliveries = stats?.totalDeliveries ?? 0;
    final points = stats?.totalPoints ?? 0;
    final reliability = stats?.reliabilityScore ?? 100;
    final rating = stats?.rating ?? 5.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid([
            _StatItem('Deliveries', '$deliveries', Icons.local_shipping_rounded, Colors.blue),
            _StatItem('Points', '$points', Icons.monetization_on_rounded, Colors.green),
            _StatItem('Trust', '$reliability%', Icons.verified_user_rounded, AppTheme.primaryRed),
            _StatItem('Rating', rating.toStringAsFixed(1), Icons.star_rounded, AppTheme.accentOrange),
          ]).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 32),
          _buildReliabilityCard(reliability).animate().fadeIn(delay: 200.ms).scale(),
          const SizedBox(height: 32),
          Text('Delivery Performance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildBarChart(Colors.blue).animate().fadeIn(delay: 400.ms).slideX(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color.withOpacity(0.8), size: 24),
              const SizedBox(height: 8),
              Text(item.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryChart(int stock, int distributed) {
    final total = stock + distributed;
    if (total == 0) return _buildEmptyState('No inventory data');

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.cardShadow,
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(color: AppTheme.info, value: stock.toDouble(), title: 'Stock', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            PieChartSectionData(color: AppTheme.accentOrange, value: distributed.toDouble(), title: 'Used', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildReliabilityCard(int score) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const Text('Reliability Index', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text('$score%', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            color: Colors.white,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            score > 90 ? 'Excellent Trust Score!' : 'Keep delivering to improve!',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Center(child: Text(message, style: const TextStyle(color: AppTheme.gray))),
    );
  }

  // --- Reused components from original ---

  Widget _buildSummaryCard(BuildContext context, int total, int completed, int impactScore) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusLarge,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Impact Score', style: TextStyle(color: AppTheme.white.withOpacity(0.8), fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('$impactScore', style: const TextStyle(color: AppTheme.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.workspace_premium_rounded, color: AppTheme.white, size: 48),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Total Items', '$total', Icons.inventory_2_outlined)),
              Container(width: 1, height: 40, color: AppTheme.white.withOpacity(0.2)),
              Expanded(child: _buildMiniStat('Lives Helped', '${completed * 3}', Icons.favorite_border_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, int score) {
    String tier = 'Bronze Giver';
    double progress = (score % 500) / 500;
    if (score >= 1000) tier = 'Gold Guardian';
    else if (score >= 500) tier = 'Silver Donor';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.primaryRed, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tier, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, backgroundColor: AppTheme.lightGray, color: AppTheme.primaryRed, minHeight: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [{'icon': '🎁', 'label': 'First Giver'}, {'icon': '🏡', 'label': 'Community Hero'}, {'icon': '📦', 'label': 'Bulk Provider'}];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, index) => Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.lightGray)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(achievements[index]['icon']!, style: const TextStyle(fontSize: 24)), Text(achievements[index]['label']!, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)]),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(children: [Icon(icon, color: AppTheme.white, size: 20), Text(value, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: AppTheme.white, fontSize: 10))]);
  }

  Widget _buildPieChart(int active, int completed, int total) {
    if (total == 0) return _buildEmptyState('No donation data');
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.borderRadiusLarge, boxShadow: AppTheme.cardShadow),
      child: PieChart(PieChartData(sections: [
        PieChartSectionData(color: AppTheme.success, value: completed.toDouble(), title: 'Delivered', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        PieChartSectionData(color: AppTheme.warning, value: active.toDouble(), title: 'Active', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ])),
    );
  }

  Widget _buildBarChart(Color color) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.borderRadiusLarge, boxShadow: AppTheme.cardShadow),
      child: BarChart(BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: color, width: 16)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: color, width: 16)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 15, color: color, width: 16)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 10, color: color, width: 16)]),
        ],
      )),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}
