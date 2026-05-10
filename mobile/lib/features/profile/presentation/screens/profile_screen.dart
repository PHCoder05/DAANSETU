import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
      );
    }

    // Calculate level from impact score
    final level = _calculateLevel(user.impactScore);
    final xpInLevel = user.impactScore - level['minXP']!;
    final xpForNextLevel = level['maxXP']! - level['minXP']!;
    final progress = xpForNextLevel > 0 ? xpInLevel / xpForNextLevel : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════════════════════
          // PREMIUM ANIMATED HEADER WITH GLASSMORPHISM
          // ═══════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Animated Gradient Background
                AnimatedBuilder(
                  animation: _gradientController,
                  builder: (context, child) {
                    return Container(
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(
                              const Color(0xFFE23744),
                              const Color(0xFFFF6B6B),
                              _gradientController.value,
                            )!,
                            Color.lerp(
                              const Color(0xFFFF6B6B),
                              const Color(0xFFE23744),
                              _gradientController.value,
                            )!,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            top: -50 + (_scrollOffset * 0.3),
                            right: -30,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20 - (_scrollOffset * 0.2),
                            left: -60,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          // Header content
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'My Profile',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Manage your account',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                                      onPressed: () => context.go(AppRoutes.editProfile),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ═══════════════════════════════════════════════════════════
                // GLASSMORPHISM USER CARD
                // ═══════════════════════════════════════════════════════════
                Positioned(
                  top: 140,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE23744).withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar with glow effect
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE23744).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFE23744), Color(0xFFFF8A8A)],
                                  ),
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: user.profileImage != null
                                    ? ClipOval(
                                        child: Image.network(
                                          '${AppConstants.apiBaseUrl.replaceAll('/api', '')}${user.profileImage}',
                                          fit: BoxFit.cover,
                                          width: 85,
                                          height: 85,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _buildAvatarPlaceholder(user),
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return _buildAvatarPlaceholder(user, isLoading: true);
                                          },
                                        ),
                                      )
                                    : _buildAvatarPlaceholder(user),
                              ),
                            ).animate().scale(
                                  duration: 500.ms,
                                  curve: Curves.easeOutBack,
                                ),

                            const SizedBox(width: 18),

                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1BAC4B),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _buildRoleBadge(user.role),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Since Jan \'24',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0),
                ),
              ],
            ),
          ),

          // Spacer for overlapping card
          const SliverToBoxAdapter(child: SizedBox(height: 100)),

          // ═══════════════════════════════════════════════════════════
          // LEVEL PROGRESS SECTION
          // ═══════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE23744).withOpacity(0.08),
                      Colors.orange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE23744).withOpacity(0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE23744), Color(0xFFFF6B6B)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${level['level']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  '${user.impactScore} XP earned',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.leaderboard),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE23744),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Ranks',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                height: 10,
                                width: MediaQuery.of(context).size.width * 0.8 * progress.clamp(0.0, 1.0),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE23744), Color(0xFFFF8A8A)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$xpInLevel / $xpForNextLevel XP to ${level['nextTitle']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fade().slideX(begin: -0.1, end: 0),
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // ANIMATED STATS SECTION (For Donors & Volunteers)
          // ═══════════════════════════════════════════════════════════
          if (user.isDonor && user.donorStats != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedStatCard(
                        value: user.donorStats!.totalDonations,
                        label: 'Total Given',
                        icon: Icons.volunteer_activism_rounded,
                        color: const Color(0xFFE23744),
                        delay: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AnimatedStatCard(
                        value: user.donorStats!.activeDonations,
                        label: 'Active',
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFF39C12),
                        delay: 100,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AnimatedStatCard(
                        value: user.donorStats!.completedDonations,
                        label: 'Completed',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF1BAC4B),
                        delay: 200,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (user.isVolunteer && user.volunteerStats != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedStatCard(
                        value: user.volunteerStats!.totalDeliveries,
                        label: 'Deliveries',
                        icon: Icons.delivery_dining_rounded,
                        color: const Color(0xFFE23744),
                        delay: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AnimatedStatCard(
                        value: user.volunteerStats!.reliabilityScore,
                        label: 'Trust',
                        icon: Icons.verified_user_rounded,
                        color: const Color(0xFFF39C12),
                        delay: 100,
                        isPercentage: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AnimatedStatCard(
                        value: user.volunteerStats!.rating,
                        label: 'Rating',
                        icon: Icons.star_rounded,
                        color: const Color(0xFF1BAC4B),
                        delay: 200,
                        decimalPlaces: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ═══════════════════════════════════════════════════════════
          // BADGES CAROUSEL
          // ═══════════════════════════════════════════════════════════
          if (user.badges.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Badges',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            '${user.badges.length} earned',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: user.badges.length,
                        itemBuilder: (context, index) {
                          final badge = user.badges[index];
                          return Container(
                            width: 85,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE23744).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    badge.icon,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    badge.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: (index * 80).ms).scale(
                                begin: const Offset(0.8, 0.8),
                                curve: Curves.easeOutBack,
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ═══════════════════════════════════════════════════════════
          // MENU SECTIONS
          // ═══════════════════════════════════════════════════════════
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('Account'),
                _PremiumMenuContainer(
                  children: [
                    _PremiumMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your information',
                      color: const Color(0xFF3498DB),
                      onTap: () => context.go(AppRoutes.editProfile),
                    ),
                    _PremiumMenuItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Trust & Verification',
                      subtitle: 'Verify your identity & status',
                      color: const Color(0xFF1BAC4B),
                      onTap: () => context.go(AppRoutes.verification),
                    ),
                    if (user.isVolunteer || user.isNgo)
                      _PremiumMenuItem(
                        icon: Icons.badge_outlined,
                        title: 'Digital ID Card',
                        subtitle: 'Official field verification ID',
                        color: AppTheme.primaryRed,
                        onTap: () => context.go(AppRoutes.volunteerId),
                      ),
                    _PremiumMenuItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Keep your account secure',
                      color: const Color(0xFF9B59B6),
                      onTap: () => context.go(AppRoutes.changePassword),
                    ),
                    if (user.isDonor)
                      _PremiumMenuItem(
                        icon: Icons.history_edu_rounded,
                        title: 'My Donations',
                        subtitle: 'View your donation history',
                        color: const Color(0xFFE23744),
                        onTap: () => context.go(AppRoutes.myDonations),
                      ),
                    _PremiumMenuItem(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Saved Donations',
                      subtitle: 'Items you\'ve bookmarked',
                      color: const Color(0xFFF39C12),
                      onTap: () => context.go(AppRoutes.savedDonations),
                    ),
                    _PremiumMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your alerts',
                      color: const Color(0xFF1ABC9C),
                      onTap: () => context.go(AppRoutes.notifications),
                      badge: '3',
                    ),
                    _PremiumMenuItem(
                      icon: Icons.emoji_events_outlined,
                      title: 'Milestones & Badges',
                      subtitle: 'Track your achievements',
                      color: const Color(0xFFF1C40F),
                      onTap: () => context.go(AppRoutes.milestones),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('More'),
                _PremiumMenuContainer(
                  children: [
                    _PremiumMenuItem(
                      icon: Icons.history_rounded,
                      title: 'Activity History',
                      subtitle: 'Your recent actions',
                      color: const Color(0xFF607D8B),
                      onTap: () => context.go(AppRoutes.activity),
                    ),
                    _PremiumMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get assistance',
                      color: const Color(0xFF3498DB),
                      onTap: () => context.go(AppRoutes.helpSupport),
                    ),
                    _PremiumMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'How we protect your data',
                      color: const Color(0xFF1BAC4B),
                      onTap: () => context.go(AppRoutes.privacy),
                    ),
                    _PremiumMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'Our usage guidelines',
                      color: const Color(0xFF795548),
                      onTap: () => context.go(AppRoutes.terms),
                    ),
                    _PremiumMenuItem(
                      icon: Icons.share_rounded,
                      title: 'Share App',
                      subtitle: 'Invite friends to join',
                      color: const Color(0xFFE91E63),
                      onTap: () => Share.share(
                        'Join me on DAANSETU and start making a difference today! Download now. #DAANSETU',
                      ),
                    ),
                    _PremiumMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About DAANSETU',
                      subtitle: 'Learn about our mission',
                      color: const Color(0xFFE23744),
                      onTap: () => context.go(AppRoutes.about),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Logout Button
                _LogoutButton(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Delete Account
                Center(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Delete Account'),
                          content: const Text(
                            'Are you sure you want to delete your account? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => ctx.pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                ctx.pop();
                                await ref.read(authStateProvider.notifier).logout();
                                if (context.mounted) context.go(AppRoutes.login);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'DAANSETU',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    IconData icon;
    
    switch (role) {
      case 'donor':
        color = const Color(0xFFE23744);
        icon = Icons.volunteer_activism;
        break;
      case 'ngo':
        color = const Color(0xFF9B59B6);
        icon = Icons.business;
        break;
      case 'admin':
        color = const Color(0xFFF39C12);
        icon = Icons.admin_panel_settings;
        break;
      default:
        color = Colors.grey;
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateLevel(int score) {
    if (score >= 1000) {
      return {
        'level': 5,
        'title': 'Legend',
        'nextTitle': 'Max Level',
        'minXP': 1000,
        'maxXP': 1500,
      };
    } else if (score >= 500) {
      return {
        'level': 4,
        'title': 'Community Hero',
        'nextTitle': 'Legend',
        'minXP': 500,
        'maxXP': 1000,
      };
    } else if (score >= 200) {
      return {
        'level': 3,
        'title': 'Dedicated Helper',
        'nextTitle': 'Community Hero',
        'minXP': 200,
        'maxXP': 500,
      };
    } else if (score >= 50) {
      return {
        'level': 2,
        'title': 'Rising Star',
        'nextTitle': 'Dedicated Helper',
        'minXP': 50,
        'maxXP': 200,
      };
    } else {
      return {
        'level': 1,
        'title': 'Newcomer',
        'nextTitle': 'Rising Star',
        'minXP': 0,
        'maxXP': 50,
      };
    }
  }

  Widget _buildAvatarPlaceholder(dynamic user, {bool isLoading = false}) {
    return Center(
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedStatCard extends StatelessWidget {
  final num value;
  final String label;
  final IconData icon;
  final Color color;
  final int delay;
  final bool isPercentage;
  final int decimalPlaces;

  const _AnimatedStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.delay,
    this.isPercentage = false,
    this.decimalPlaces = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.toDouble()),
            duration: Duration(milliseconds: 800 + delay),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              String displayValue;
              if (decimalPlaces > 0) {
                displayValue = val.toStringAsFixed(decimalPlaces);
              } else {
                displayValue = val.toInt().toString();
              }
              
              if (isPercentage) displayValue += '%';
              
              return Text(
                displayValue,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fade().scale(begin: const Offset(0.9, 0.9));
  }
}

class _PremiumMenuContainer extends StatelessWidget {
  final List<Widget> children;

  const _PremiumMenuContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          return Column(
            children: [
              children[index],
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  color: Colors.grey[100],
                  indent: 72,
                  endIndent: 20,
                ),
            ],
          );
        }),
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _PremiumMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _PremiumMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  State<_PremiumMenuItem> createState() => _PremiumMenuItemState();
}

class _PremiumMenuItemState extends State<_PremiumMenuItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withOpacity(0.2),
                      widget.color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE23744),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.08),
                Colors.red.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 200.ms).fade();
  }
}
