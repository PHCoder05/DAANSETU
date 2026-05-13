import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';

class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final user = ref.watch(authStateProvider).user;
    
    // Mock milestones for demonstration
    final milestones = [
      _Milestone(
        title: 'First Step',
        description: 'Complete your first donation or delivery',
        icon: Icons.star_rounded,
        color: const Color(0xFFF1C40F),
        isUnlocked: true,
        progress: 1.0,
      ),
      _Milestone(
        title: 'Community Hero',
        description: 'Impact 10 lives through donations',
        icon: Icons.favorite_rounded,
        color: AppTheme.primaryRed,
        isUnlocked: true,
        progress: 1.0,
      ),
      _Milestone(
        title: 'Guardian Angel',
        description: 'Help 50 people in one month',
        icon: Icons.shield_rounded,
        color: const Color(0xFF3498DB),
        isUnlocked: false,
        progress: 0.65,
        target: '50',
        current: '32',
      ),
      _Milestone(
        title: 'Eco Warrior',
        description: 'Prevent 100kg of food waste',
        icon: Icons.eco_rounded,
        color: AppTheme.primaryGreen,
        isUnlocked: false,
        progress: 0.3,
        target: '100kg',
        current: '30kg',
      ),
      _Milestone(
        title: 'Night Owl',
        description: 'Complete 5 late-night deliveries',
        icon: Icons.nights_stay_rounded,
        color: const Color(0xFF2C3E50),
        isUnlocked: false,
        progress: 0.8,
        target: '5',
        current: '4',
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('My Milestones', style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryRed, Color(0xFFC0392B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        '${milestones.where((m) => m.isUnlocked).length}/${milestones.length} Unlocked',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final milestone = milestones[index];
                  return _buildMilestoneCard(context, milestone, index);
                },
                childCount: milestones.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(BuildContext context, _Milestone milestone, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: milestone.isUnlocked ? milestone.color.withValues(alpha: 0.1) : AppTheme.offWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(
              milestone.icon, 
              color: milestone.isUnlocked ? milestone.color : AppTheme.gray,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      milestone.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: milestone.isUnlocked ? AppTheme.black : AppTheme.gray,
                      ),
                    ),
                    if (milestone.isUnlocked)
                      const Icon(Icons.verified_rounded, color: AppTheme.success, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.description,
                  style: const TextStyle(color: AppTheme.gray, fontSize: 12),
                ),
                const SizedBox(height: 12),
                
                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: milestone.progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: milestone.isUnlocked ? milestone.color : AppTheme.gray.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!milestone.isUnlocked) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${milestone.current}/${milestone.target}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.gray),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}

class _Milestone {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress;
  final String? target;
  final String? current;

  _Milestone({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
    this.target,
    this.current,
  });
}
