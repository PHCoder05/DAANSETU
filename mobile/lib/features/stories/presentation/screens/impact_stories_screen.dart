import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ImpactStory {
  final String id;
  final String title;
  final String story;
  final List<String> photos;
  final String category;
  final int beneficiariesCount;
  final Map<String, dynamic>? ngo;
  final Map<String, dynamic>? donation;
  final int likesCount;
  final bool isLikedByMe;
  final List<dynamic> comments;
  final DateTime createdAt;
  final Map<String, dynamic>? location;

  const ImpactStory({
    required this.id,
    required this.title,
    required this.story,
    required this.photos,
    required this.category,
    required this.beneficiariesCount,
    this.ngo,
    this.donation,
    required this.likesCount,
    required this.isLikedByMe,
    required this.comments,
    required this.createdAt,
    this.location,
  });

  factory ImpactStory.fromJson(Map<String, dynamic> json) {
    return ImpactStory(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      story: json['story'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      category: json['category'] ?? 'general',
      beneficiariesCount: json['beneficiariesCount'] ?? 0,
      ngo: json['ngo'] as Map<String, dynamic>?,
      donation: json['donation'] as Map<String, dynamic>?,
      likesCount: json['likesCount'] ?? 0,
      isLikedByMe: json['isLikedByMe'] ?? false,
      comments: json['comments'] ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      location: json['location'] as Map<String, dynamic>?,
    );
  }

  ImpactStory copyWith({bool? isLikedByMe, int? likesCount}) {
    return ImpactStory(
      id: id, title: title, story: story, photos: photos, category: category,
      beneficiariesCount: beneficiariesCount, ngo: ngo, donation: donation,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      comments: comments, createdAt: createdAt, location: location,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final impactStoriesProvider = FutureProvider.autoDispose<List<ImpactStory>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.getImpactStories();
  if (response.statusCode == 200) {
    final List data = response.data['data'] ?? [];
    return data.map((e) => ImpactStory.fromJson(e)).toList();
  }
  return [];
});

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ImpactStoriesScreen extends ConsumerStatefulWidget {
  const ImpactStoriesScreen({super.key});

  @override
  ConsumerState<ImpactStoriesScreen> createState() => _ImpactStoriesScreenState();
}

class _ImpactStoriesScreenState extends ConsumerState<ImpactStoriesScreen> {
  // Local optimistic state for likes
  final Map<String, bool> _likedMap = {};
  final Map<String, int> _likesCountMap = {};

  static const Map<String, Color> _categoryColors = {
    'food': Color(0xFFFF6B35),
    'clothes': Color(0xFF6C5CE7),
    'books': Color(0xFF00B894),
    'medical': Color(0xFFE17055),
    'electronics': Color(0xFF0984E3),
    'furniture': Color(0xFFBD9B27),
    'general': Color(0xFFD63031),
  };

  static const Map<String, IconData> _categoryIcons = {
    'food': Icons.restaurant_rounded,
    'clothes': Icons.checkroom_rounded,
    'books': Icons.menu_book_rounded,
    'medical': Icons.local_hospital_rounded,
    'electronics': Icons.devices_rounded,
    'furniture': Icons.chair_rounded,
    'general': Icons.volunteer_activism_rounded,
  };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  Future<void> _toggleLike(ImpactStory story) async {
    HapticFeedback.lightImpact();
    final wasLiked = _likedMap[story.id] ?? story.isLikedByMe;
    final prevCount = _likesCountMap[story.id] ?? story.likesCount;

    // Optimistic update
    setState(() {
      _likedMap[story.id] = !wasLiked;
      _likesCountMap[story.id] = wasLiked ? prevCount - 1 : prevCount + 1;
    });

    try {
      await ref.read(apiClientProvider).toggleStoryLike(story.id);
    } catch (_) {
      // Revert on error
      setState(() {
        _likedMap[story.id] = wasLiked;
        _likesCountMap[story.id] = prevCount;
      });
    }
  }

    final authState = ref.watch(authStateProvider);
    final isNgo = authState.user?.isNgo == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      floatingActionButton: isNgo ? FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createStory),
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text('Share Impact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms) : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            ref.invalidate(impactStoriesProvider);
          },
          color: AppTheme.primaryRed,
          backgroundColor: const Color(0xFF1A1A2E),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),

              // Impact Metrics
              SliverToBoxAdapter(
                child: _buildImpactDashboard(context),
              ),

              // Stories
              storiesAsync.when(
                loading: () => SliverToBoxAdapter(child: _buildLoading()),
                error: (e, _) => SliverToBoxAdapter(child: _buildEmpty()),
                data: (stories) {
                  if (stories.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmpty());
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildStoryCard(context, stories[index], index);
                      },
                      childCount: stories.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Impact Stories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Real change, real stories',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD63031), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Live Feed', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.08)),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildImpactDashboard(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildImpactMetric(
            context,
            '12.4K+',
            'Beneficiaries',
            Icons.people_alt_rounded,
            const Color(0xFF6C5CE7),
          ),
          _buildImpactMetric(
            context,
            '850',
            'NGOs Active',
            Icons.corporate_fare_rounded,
            const Color(0xFF00B894),
          ),
          _buildImpactMetric(
            context,
            '98%',
            'Success Rate',
            Icons.verified_rounded,
            const Color(0xFFFAB1A0),
          ),
          _buildImpactMetric(
            context,
            '250K',
            'Items Shared',
            Icons.inventory_2_rounded,
            const Color(0xFF0984E3),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetric(BuildContext context, String value, String label, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Icon(Icons.north_east_rounded, color: Colors.white.withOpacity(0.2), size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStoryCard(BuildContext context, ImpactStory story, int index) {
    final catColor = _categoryColors[story.category] ?? const Color(0xFFD63031);
    final catIcon = _categoryIcons[story.category] ?? Icons.volunteer_activism_rounded;
    final isLiked = _likedMap[story.id] ?? story.isLikedByMe;
    final likesCount = _likesCountMap[story.id] ?? story.likesCount;
    final ngoName = story.ngo?['name'] ?? 'Anonymous NGO';
    final ngoAvatar = story.ngo?['profileImage'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NGO Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // NGO avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: catColor.withOpacity(0.15),
                  backgroundImage: ngoAvatar != null ? NetworkImage(ngoAvatar) : null,
                  child: ngoAvatar == null
                      ? Icon(catIcon, color: catColor, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngoName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _timeAgo(story.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: catColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(catIcon, color: catColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        story.category.toUpperCase(),
                        style: TextStyle(
                          color: catColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Story Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              story.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Story Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              story.story,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13.5,
                height: 1.6,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          // Photo Gallery
          if (story.photos.isNotEmpty) _buildPhotoGallery(story.photos, catColor),

          // Beneficiaries Stats
          if (story.beneficiariesCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor.withOpacity(0.12), catColor.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: catColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_rounded, color: catColor, size: 18),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${story.beneficiariesCount}',
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          TextSpan(
                            text: ' lives impacted by this donation',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Verified Donation Link
          if (story.donation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InkWell(
                onTap: () => context.push('${AppRoutes.donations}/${story.donation?['_id']}'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF00B894), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Donation: ${story.donation?['title'] ?? 'Donation'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 10),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Divider
          Divider(color: Colors.white.withOpacity(0.06), height: 1),

          // Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Like button
                _buildActionButton(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: likesCount > 0 ? '$likesCount' : 'Like',
                  color: isLiked ? const Color(0xFFFF6B6B) : Colors.white.withOpacity(0.5),
                  onTap: () => _toggleLike(story),
                ),
                // Comments
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: story.comments.isNotEmpty ? '${story.comments.length}' : 'Comment',
                  color: Colors.white.withOpacity(0.5),
                  onTap: () => _showCommentsSheet(context, story),
                ),
                const Spacer(),
                // Location chip
                if (story.location != null)
                  Row(
                    children: [
                      Icon(Icons.place_rounded, color: Colors.white.withOpacity(0.3), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        story.location!['city']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 80)).fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> photos, Color catColor) {
    if (photos.length == 1) {
      return _buildSinglePhoto(photos[0], catColor);
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 160,
            child: _photoWidget(photos[i], catColor),
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePhoto(String url, Color catColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _photoWidget(url, catColor),
        ),
      ),
    );
  }

  Widget _photoWidget(String url, Color catColor) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoPlaceholder(catColor),
      );
    }
    return _photoPlaceholder(catColor);
  }

  Widget _photoPlaceholder(Color catColor) {
    return Container(
      color: catColor.withOpacity(0.1),
      child: Center(
        child: Icon(Icons.image_rounded, color: catColor.withOpacity(0.4), size: 40),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, ImpactStory story) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Comments (${story.comments.length})',
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                ),
              ),
            ),
            if (story.comments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Be the first to comment! ✨',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                ),
              ),
            // Comment input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (controller.text.trim().isEmpty) return;
                      try {
                        await ref.read(apiClientProvider).addStoryComment(story.id, controller.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.invalidate(impactStoriesProvider);
                      } catch (_) {}
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFD63031), Color(0xFFFF6B6B)]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFFD63031)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_rounded, color: Colors.white24, size: 60),
          const SizedBox(height: 16),
          const Text(
            'No stories yet',
            style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'NGOs will share their impact stories here soon!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
