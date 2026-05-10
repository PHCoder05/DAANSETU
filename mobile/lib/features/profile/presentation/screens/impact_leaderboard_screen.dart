import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';

class ImpactLeaderboardScreen extends ConsumerStatefulWidget {
  const ImpactLeaderboardScreen({super.key});

  @override
  ConsumerState<ImpactLeaderboardScreen> createState() => _ImpactLeaderboardScreenState();
}

class _ImpactLeaderboardScreenState extends ConsumerState<ImpactLeaderboardScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Donors', 'NGOs', 'Volunteers'];
  
  Map<String, List<Map<String, dynamic>>> _leaderboardData = {
    'Donors': [],
    'NGOs': [],
    'Volunteers': [],
  };
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadLeaderboard(_tabs[_tabController.index].toLowerCase());
      }
    });
    _loadLeaderboard('donors');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard(String type) async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiClientProvider).getLeaderboard(type: type);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['leaderboard'];
        final tabName = _tabs.firstWhere((t) => t.toLowerCase() == type);
        
        setState(() {
          _leaderboardData[tabName] = data.map((item) {
            return {
              'name': item['name'] ?? 'Anonymous',
              'value': item['impactScore'] ?? item['donationCount'] ?? item['deliveredCount'] ?? item['points'] ?? 0,
              'subtitle': _getSubtitle(item, type),
              'image': item['profileImage'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getSubtitle(Map<String, dynamic> item, String type) {
    if (type == 'donors') return '${item['donationCount'] ?? 0} Donations';
    if (type == 'ngos') return '${item['deliveredCount'] ?? 0} Delivered';
    if (type == 'volunteers') return '${item['deliveries'] ?? 0} Pickups';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        slivers: [
          // ═══════════════════════════════════════════════════════════
          // PREMIUM STICKY HEADER
          // ═══════════════════════════════════════════════════════════
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.black, size: 20),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: AppTheme.black),
                onPressed: () {
                   HapticFeedback.lightImpact();
                   Share.share('Check out the DaanSetu Leaderboard! Together we are making a difference. #DaanSetu #Impact');
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Wall of Fame',
                style: TextStyle(
                  color: AppTheme.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(color: AppTheme.white),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.offWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppTheme.primaryRed,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.gray,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // PODIUM SECTION (TOP 3)
          // ═══════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: _isLoading 
              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)))
              : _buildPodium(_leaderboardData[_tabs[_tabController.index]]!),
          ),

          // ═══════════════════════════════════════════════════════════
          // LIST SECTION (RANK 4+)
          // ═══════════════════════════════════════════════════════════
          _isLoading 
            ? const SliverToBoxAdapter(child: SizedBox.shrink())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listData = _leaderboardData[_tabs[_tabController.index]]!;
                      if (listData.length <= 3) return null;
                      if (index + 3 >= listData.length) return null;
                      
                      final item = listData[index + 3];
                      final rank = index + 4;
                      
                      return _buildLeaderboardTile(item, rank);
                    },
                    childCount: math.max(0, _leaderboardData[_tabs[_tabController.index]]!.length - 3),
                  ),
                ),
              ),
        ],
      ),
      bottomNavigationBar: _buildMyRankCard(user, _leaderboardData[_tabs[_tabController.index]]!),
    );
  }

  Widget _buildMyRankCard(user, List<Map<String, dynamic>> listData) {
    if (user == null || listData.isEmpty) return const SizedBox.shrink();
    
    final myIndex = listData.indexWhere((item) => item['name'] == user.name);
    if (myIndex == -1) return const SizedBox.shrink();
    
    final myItem = listData[myIndex];
    final rank = myIndex + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Rank #$rank',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your Position',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Text(
            '${myItem['value']}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryRed),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topList) {
    if (topList.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('No data yet')));
    
    // Top 3 positions
    final first = topList.isNotEmpty ? topList[0] : null;
    final second = topList.length > 1 ? topList[1] : null;
    final third = topList.length > 2 ? topList[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd Place
          if (second != null) _buildPodiumItem(second, 2, 120),
          const SizedBox(width: 12),
          // 1st Place
          if (first != null) _buildPodiumItem(first, 1, 160),
          const SizedBox(width: 12),
          // 3rd Place
          if (third != null) _buildPodiumItem(third, 3, 100),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPodiumItem(Map<String, dynamic> item, int rank, double height) {
    Color podiumColor;
    String trophy;
    switch (rank) {
      case 1: 
        podiumColor = const Color(0xFFFFD700); 
        trophy = '👑';
        break;
      case 2: 
        podiumColor = const Color(0xFFC0C0C0); 
        trophy = '🥈';
        break;
      default: 
        podiumColor = const Color(0xFFCD7F32); 
        trophy = '🥉';
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: rank == 1 ? 80 : 65,
                height: rank == 1 ? 80 : 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: podiumColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: podiumColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: item['image'] != null
                    ? Image.network(item['image'], fit: BoxFit.cover)
                    : Container(
                        color: podiumColor.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            item['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: podiumColor,
                              fontWeight: FontWeight.bold,
                              fontSize: rank == 1 ? 24 : 20,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: podiumColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trophy,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${item['value']}',
            style: TextStyle(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.w900,
              fontSize: rank == 1 ? 16 : 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  podiumColor.withOpacity(0.8),
                  podiumColor.withOpacity(0.2),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> item, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
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
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            child: Text(
              item['name'][0].toUpperCase(),
              style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  item['subtitle'],
                  style: TextStyle(color: AppTheme.gray, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item['value']}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.charcoal),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (rank * 50).ms).slideX(begin: 0.05, end: 0);
  }
}
