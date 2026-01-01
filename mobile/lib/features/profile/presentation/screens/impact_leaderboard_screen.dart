import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/api/api_client.dart';
import 'package:share_plus/share_plus.dart';

class ImpactLeaderboardScreen extends ConsumerStatefulWidget {
  const ImpactLeaderboardScreen({super.key});

  @override
  ConsumerState<ImpactLeaderboardScreen> createState() => _ImpactLeaderboardScreenState();
}

class _ImpactLeaderboardScreenState extends ConsumerState<ImpactLeaderboardScreen> {
  List<Map<String, dynamic>> _topDonors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final response = await ref.read(apiClientProvider).getLeaderboard();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['leaderboard'];
        setState(() {
          _topDonors = data.map((item) {
            final score = (item['impactScore'] ?? 0) as int;
            return {
              'name': item['name'] ?? 'Anonymous',
              'impact': score,
              'role': _getImpactLevel(score),
              'bg': _getRoleColor(score),
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  // Get color based on score (visual variety)
  Color _getRoleColor(int score) {
      if (score > 1000) return AppTheme.primaryRed;
      if (score > 500) return AppTheme.accentOrange;
      if (score > 100) return AppTheme.warning;
      if (score > 50) return AppTheme.success;
      return AppTheme.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    // Calculate real impact score if user exists
    final donations = user?.donorStats?.totalDonations ?? 0;
    final active = user?.donorStats?.activeDonations ?? 0;
    final completed = user?.donorStats?.completedDonations ?? 0;
    
    // Use real impact score if available, otherwise fallback to formula
    final impactScore = user?.impactScore ?? ((donations * 10) + (completed * 5));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Impact Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.black),
            onPressed: () {
               Share.share('I am making a real difference on DAANSETU with an Impact Score of $impactScore! Join our community and help those in need. #DAANSETU #Impact');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. My Impact Summary Card (REAL DATA)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR IMPACT SCORE',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$impactScore',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                  ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getImpactLevel(impactScore), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImpactStat('$donations', 'Donations'),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _buildImpactStat('$active', 'Active'),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _buildImpactStat('$completed', 'Completed'),
                    ],
                  )
                ],
              ),
            ).animate().slideY(begin: 0.2, end: 0).fade(),

            const SizedBox(height: 32),
            
            // 2. Wall of Fame Header
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.warning, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Wall of Fame',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('View All'))
              ],
            ),
            const SizedBox(height: 16),

            // 3. List
            if (_isLoading)
               const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryRed)))
            else if (_topDonors.isEmpty)
               const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No donors yet. Be the first!", style: TextStyle(color: AppTheme.gray))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topDonors.length,
                itemBuilder: (context, index) {
                  final donor = _topDonors[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          // Rank Text
                          SizedBox(
                            width: 30,
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: index < 3 ? AppTheme.black : AppTheme.gray,
                              ),
                            ),
                          ),
                          // Avatar
                          CircleAvatar(
                            backgroundColor: (donor['bg'] as Color).withOpacity(0.1),
                            child: Text(
                              (donor['name'] as String)[0].toUpperCase(),
                              style: TextStyle(color: donor['bg'] as Color, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donor['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                donor['role'] as String,
                                style: TextStyle(color: AppTheme.gray, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.offWhite,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppTheme.warning),
                              const SizedBox(width: 4),
                              Text(
                                '${donor['impact']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (100 * index).ms).slideX(begin: 0.1, end: 0).fade();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
  
  String _getImpactLevel(int score) {
    if (score > 1000) return 'Top 1% Donor';
    if (score > 500) return 'Top 5% Donor';
    if (score > 100) return 'Top 10% Donor';
    if (score > 50) return 'Top 20% Donor';
    return 'Rising Star';
  }
}
