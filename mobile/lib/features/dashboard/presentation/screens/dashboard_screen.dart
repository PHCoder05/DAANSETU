import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../widgets/gemini_assistant_modal.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getDashboard();
  if (response.statusCode == 200) return response.data;
  return {};
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showGeminiAssistant(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GeminiAssistantModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final locationState = ref.watch(userLocationProvider);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF333333)]),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton(
          onPressed: () => _showGeminiAssistant(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryRed, size: 26),
        ),
      ).animate().scale(delay: 800.ms, duration: 400.ms, curve: Curves.easeOutBack),
      body: RefreshIndicator(
        color: AppTheme.primaryRed,
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ─── HEADER ───
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
                decoration: const BoxDecoration(color: AppTheme.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar: avatar + greeting + notifications
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primaryRed, Color(0xFFFF6B6B)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(greeting, style: TextStyle(color: AppTheme.gray, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                user?.name ?? 'User',
                                style: const TextStyle(color: AppTheme.black, fontSize: 20, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        _HeaderIconButton(icon: Icons.notifications_outlined, onTap: () => context.go(AppRoutes.notifications)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Location row
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.donations),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.offWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.lightGray.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppTheme.primaryRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationState.address ?? 'Detecting your location...',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.charcoal),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.gray, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(duration: 300.ms),
              ),
            ),

            // ─── VERIFICATION PENDING BANNER ───
            if (user?.role == 'ngo' && user?.verified == false)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.pending_actions_rounded, color: Colors.amber.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Verification Pending', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                            const SizedBox(height: 4),
                            Text(
                              'Your application is under review. We are currently cross-checking your registration with Government databases. This process usually takes 1-2 business days.',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── BODY ───
            SliverToBoxAdapter(
              child: dashboardAsync.when(
                loading: () => _buildShimmer(),
                error: (e, _) => _buildError(ref),
                data: (data) {
                  final stats = data['stats'] as Map<String, dynamic>? ?? {};
                  final recentDonations = data['recentDonations'] as List? ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // ── Impact Summary Card ──
                      _buildImpactCard(context, user, stats),
                      // ── Quick Actions Grid ──
                      _sectionTitle(context, 'Quick Actions'),
                      _buildQuickActions(context, user),
                      // ── Explore Section ──
                      _sectionTitle(context, 'Explore'),
                      _buildExploreCards(context),
                      // ── Recent Activity ──
                      _buildRecentSection(context, recentDonations),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  Widget _sectionTitle(BuildContext context, String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          if (onViewAll != null) GestureDetector(onTap: onViewAll, child: const Text('View all', style: TextStyle(fontSize: 13, color: AppTheme.primaryRed, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ─── IMPACT CARD ───
  Widget _buildImpactCard(BuildContext context, dynamic user, Map<String, dynamic> stats) {
    final int total = stats['totalDonations'] ?? stats['claimedDonations'] ?? stats['activeTasks'] ?? 0;
    final int active = stats['activeDonations'] ?? stats['inTransit'] ?? stats['completedDeliveries'] ?? 0;
    final int done = stats['completedDonations'] ?? stats['delivered'] ?? stats['totalPoints'] ?? 0;

    String roleLabel = 'Donor';
    String roleEmoji = '❤️';
    if (user?.isNgo == true) { roleLabel = 'NGO Partner'; roleEmoji = '🏢'; }
    else if (user?.role == 'volunteer') { roleLabel = 'Volunteer'; roleEmoji = '🤝'; }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF1A1A2E).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryRed.withValues(alpha: 0.1)))),
            Positioned(right: 20, bottom: -30, child: Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.white.withValues(alpha: 0.05)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('$roleEmoji $roleLabel', style: const TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.analytics),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppTheme.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.analytics_rounded, color: AppTheme.white, size: 14),
                            SizedBox(width: 4),
                            Text('Analytics', style: TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Your Impact', style: TextStyle(color: AppTheme.white.withValues(alpha: 0.7), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$total Contributions', style: const TextStyle(color: AppTheme.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _ImpactMini(label: 'Active', value: '$active', color: AppTheme.warning),
                      const SizedBox(width: 24),
                      _ImpactMini(label: 'Completed', value: '$done', color: AppTheme.success),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 400.ms).slideY(begin: 0.08, end: 0),
    );
  }

  // ─── QUICK ACTIONS ───
  Widget _buildQuickActions(BuildContext context, dynamic user) {
    final actions = <Map<String, dynamic>>[
      if (user?.isDonor == true) {'icon': Icons.add_circle_rounded, 'label': 'Donate', 'color': const Color(0xFFE23744), 'route': '${AppRoutes.donations}/create'},
      {'icon': Icons.search_rounded, 'label': 'Browse', 'color': const Color(0xFF1BAC4B), 'route': AppRoutes.donations},
      {'icon': Icons.emoji_events_rounded, 'label': 'Leaderboard', 'color': const Color(0xFFF39C12), 'route': AppRoutes.leaderboard},
      {'icon': Icons.auto_stories_rounded, 'label': 'Stories', 'color': const Color(0xFF9B59B6), 'route': AppRoutes.impactStories},
      if (user?.isNgo == true) {'icon': Icons.inventory_2_rounded, 'label': 'Inventory', 'color': const Color(0xFF3498DB), 'route': AppRoutes.ngoInventory},
      if (user?.isNgo == true) {'icon': Icons.assignment_rounded, 'label': 'Claims', 'color': const Color(0xFF1ABC9C), 'route': AppRoutes.ngoClaims},
      {'icon': Icons.business_rounded, 'label': 'NGOs', 'color': const Color(0xFF3498DB), 'route': AppRoutes.ngos},
      {'icon': Icons.chat_bubble_rounded, 'label': 'Chat', 'color': const Color(0xFF6C5CE7), 'route': '/chat'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); context.go(a['route']); },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: (a['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(a['label'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.charcoal), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 50)).fade().scale(begin: const Offset(0.9, 0.9));
        },
      ),
    );
  }

  // ─── EXPLORE CARDS ───
  Widget _buildExploreCards(BuildContext context) {
    final cards = [
      {'title': 'Donate Food', 'sub': 'Help fight hunger today', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFE23744), 'bg': const Color(0xFFFFF0F0)},
      {'title': 'Donate Clothes', 'sub': 'Warmth for everyone', 'icon': Icons.checkroom_rounded, 'color': const Color(0xFF9B59B6), 'bg': const Color(0xFFF5F0FF)},
      {'title': 'Donate Books', 'sub': 'Spread knowledge', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF3498DB), 'bg': const Color(0xFFEFF6FF)},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        itemBuilder: (context, i) {
          final c = cards[i];
          return GestureDetector(
            onTap: () => context.go(AppRoutes.donations),
            child: Container(
              width: 200, margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c['bg'] as Color, borderRadius: BorderRadius.circular(16), border: Border.all(color: (c['color'] as Color).withValues(alpha: 0.15))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(c['icon'] as IconData, color: c['color'] as Color, size: 28),
                  const SizedBox(height: 10),
                  Text(c['title'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c['color'] as Color)),
                  const SizedBox(height: 2),
                  Text(c['sub'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: i * 80)).fade().slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  // ─── RECENT ACTIVITY ───
  Widget _buildRecentSection(BuildContext context, List recentDonations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Recent Activity', onViewAll: () => context.go(AppRoutes.donations)),
        if (recentDonations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.lightGray)),
              child: Column(children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.offWhite, shape: BoxShape.circle), child: const Icon(Icons.inbox_rounded, size: 36, color: AppTheme.gray)),
                const SizedBox(height: 12),
                const Text('No activity yet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
                const SizedBox(height: 4),
                const Text('Your donations will appear here', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
              ]),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: recentDonations.take(5).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                return _RecentCard(
                  title: d['title'] ?? 'Donation',
                  status: d['status'] ?? 'available',
                  category: d['category'] ?? 'other',
                  date: d['createdAt'] != null ? DateTime.parse(d['createdAt']) : DateTime.now(),
                ).animate(delay: Duration(milliseconds: i * 60)).fade().slideY(begin: 0.05, end: 0);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(height: 180, decoration: BoxDecoration(color: AppTheme.lightGray.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 20),
        Row(children: List.generate(4, (i) => Expanded(child: Container(height: 80, margin: EdgeInsets.only(right: i < 3 ? 12 : 0), decoration: BoxDecoration(color: AppTheme.lightGray.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)))))),
        const SizedBox(height: 20),
        ...List.generate(3, (_) => Container(height: 72, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: AppTheme.lightGray.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)))),
      ]).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: AppTheme.white.withValues(alpha: 0.5)),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.lightGray)),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.error)),
          const SizedBox(height: 20),
          const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Pull down to retry', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
        ]),
      ),
    );
  }
}

// ─── SUB WIDGETS ───

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.lightGray)),
        child: Icon(icon, color: AppTheme.charcoal, size: 22),
      ),
    );
  }
}

class _ImpactMini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ImpactMini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$value ', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: TextStyle(color: AppTheme.white.withValues(alpha: 0.6), fontSize: 12)),
    ]);
  }
}

class _RecentCard extends StatelessWidget {
  final String title, status, category;
  final DateTime date;
  const _RecentCard({required this.title, required this.status, required this.category, required this.date});

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.categoryColors[category] ?? AppTheme.gray;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(_catIcon(category), color: catColor, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(_fmt(date), style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _statusColor(status), letterSpacing: 0.5)),
        ),
      ]),
    );
  }

  IconData _catIcon(String c) => switch (c) { 'food' => Icons.restaurant_rounded, 'clothes' => Icons.checkroom_rounded, 'books' => Icons.menu_book_rounded, 'medical' => Icons.medical_services_rounded, 'electronics' => Icons.devices_rounded, 'furniture' => Icons.chair_rounded, _ => Icons.inventory_2_rounded };
  Color _statusColor(String s) => switch (s) { 'available' => AppTheme.success, 'claimed' => AppTheme.warning, 'in-transit' => AppTheme.info, 'delivered' => const Color(0xFF9B59B6), _ => AppTheme.gray };
  String _fmt(DateTime d) { final diff = DateTime.now().difference(d); if (diff.inMinutes < 60) return '${diff.inMinutes}m ago'; if (diff.inHours < 24) return '${diff.inHours}h ago'; if (diff.inDays < 7) return '${diff.inDays}d ago'; return '${d.day}/${d.month}/${d.year}'; }
}
