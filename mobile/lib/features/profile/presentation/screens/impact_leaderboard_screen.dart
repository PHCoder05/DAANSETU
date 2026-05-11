import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';

class ImpactLeaderboardScreen extends ConsumerStatefulWidget {
  const ImpactLeaderboardScreen({super.key});

  @override
  ConsumerState<ImpactLeaderboardScreen> createState() => _ImpactLeaderboardScreenState();
}

class _ImpactLeaderboardScreenState extends ConsumerState<ImpactLeaderboardScreen> {
  bool _isLoading = true;
  List<dynamic> _leaderboard = [];
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final lbResponse = await apiClient.getLeaderboard();
      final statsResponse = await apiClient.getGamificationStats();

      if (mounted) {
        setState(() {
          _leaderboard = lbResponse.data['data']['leaderboard'] ?? [];
          _userStats = statsResponse.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
            )
          else if (_leaderboard.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No champions yet. Be the first!')),
            )
          else
            _buildLeaderboardList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryRed,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE53935), Color(0xFFC62828)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 60)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .shimmer(delay: 1.seconds),
              const SizedBox(height: 12),
              const Text(
                'Impact Champions',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Making the world better, one donation at a time',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (_userStats != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Your Rank: #${_userStats!['rank']}  •  ${_userStats!['impactScore']} Pts',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _buildPodium(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Skip first 3 as they are in podium
                final actualIndex = index + 3;
                if (actualIndex >= _leaderboard.length) return null;
                
                final user = _leaderboard[actualIndex];
                final rank = actualIndex + 1;
                return _buildLeaderboardItem(user, rank);
              },
              childCount: _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    if (_leaderboard.isEmpty) return const SizedBox.shrink();
    
    final top3 = _leaderboard.take(3).toList();
    
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 2nd Place
          if (top3.length > 1) 
            _buildPodiumSpot(top3[1], 2, 160, const Color(0xFFC0C0C0)),
          
          // 1st Place
          if (top3.isNotEmpty)
            _buildPodiumSpot(top3[0], 1, 200, const Color(0xFFFFD700)),
            
          // 3rd Place
          if (top3.length > 2)
            _buildPodiumSpot(top3[2], 3, 140, const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot(dynamic user, int rank, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
                ],
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 40 : 30,
                backgroundColor: AppTheme.offWhite,
                backgroundImage: user['profileImage'] != null ? NetworkImage(user['profileImage']) : null,
                child: user['profileImage'] == null ? const Icon(Icons.person, color: AppTheme.gray) : null,
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  '$rank',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user['name']?.split(' ')[0] ?? 'User',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          '${user['impactScore'] ?? 0} pts',
          style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height - 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.8), color.withOpacity(0.2)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: rank == 1 ? const Icon(Icons.workspace_premium_rounded, color: Colors.white30, size: 32) : null,
        ),
      ],
    ).animate().fadeIn(delay: (rank * 200).ms).slideY(begin: 0.2);
  }

  Widget _buildLeaderboardItem(dynamic user, int rank) {
    final isTop3 = rank <= 3;
    final rankColor = rank == 1 
        ? const Color(0xFFFFD700) // Gold
        : rank == 2 
            ? const Color(0xFFC0C0C0) // Silver
            : rank == 3 
                ? const Color(0xFFCD7F32) // Bronze
                : AppTheme.gray;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            alignment: Alignment.center,
            child: isTop3 
                ? Icon(Icons.workspace_premium_rounded, color: rankColor, size: 28)
                : Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gray)),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.offWhite,
            backgroundImage: user['profileImage'] != null ? NetworkImage(user['profileImage']) : null,
            child: user['profileImage'] == null ? const Icon(Icons.person, color: AppTheme.gray) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Anonymous',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${user['donorStats']?['completedDonations'] ?? 0} Donations',
                  style: const TextStyle(color: AppTheme.gray, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['impactScore'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryRed),
              ),
              const Text('Impact Pts', style: TextStyle(fontSize: 10, color: AppTheme.gray)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (rank * 50).ms).slideX(begin: 0.1);
  }
}
