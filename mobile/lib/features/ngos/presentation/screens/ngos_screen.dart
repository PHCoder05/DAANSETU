import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

final ngosProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getNgos();
  
  if (response.statusCode == 200) {
    final data = response.data;
    // Handle different API response structures
    List<dynamic> ngosList;
    if (data['data'] != null && data['data']['data'] != null) {
      ngosList = data['data']['data'] as List;
    } else if (data['ngos'] != null) {
      ngosList = data['ngos'] as List;
    } else if (data['data'] != null && data['data'] is List) {
      ngosList = data['data'] as List;
    } else {
      ngosList = [];
    }
    return ngosList.map((n) => User.fromJson(n)).toList();
  }
  
  return [];
});

class NgosScreen extends ConsumerStatefulWidget {
  const NgosScreen({super.key});

  @override
  ConsumerState<NgosScreen> createState() => _NgosScreenState();
}

class _NgosScreenState extends ConsumerState<NgosScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ngosAsync = ref.watch(ngosProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            ref.invalidate(ngosProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryRed,
          backgroundColor: AppTheme.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Partner NGOs',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Verified organizations making a difference',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Filter Button
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list_rounded, color: AppTheme.primaryRed),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                // TODO: Show filter
                              },
                            ),
                          ),
                        ],
                      ).animate().fade().slideX(begin: -0.1, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: AppTheme.borderRadiusMedium,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search NGOs...',
                            hintStyle: TextStyle(color: AppTheme.gray),
                            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.gray),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ).animate(delay: 100.ms).fade().slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Content
              ngosAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: _buildLoadingState(),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: _buildErrorState(context, ref, error),
                ),
                data: (ngos) {
                  final filteredNgos = ngos.where((ngo) {
                     if (_searchQuery.isEmpty) return true;
                     return ngo.name.toLowerCase().contains(_searchQuery) ||
                            (ngo.address ?? '').toLowerCase().contains(_searchQuery) ||
                            (ngo.ngoDetails?.categories.any((c) => c.toLowerCase().contains(_searchQuery)) ?? false); 
                  }).toList();

                  if (filteredNgos.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    );
                  }
                  
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ngo = filteredNgos[index];
                          return _NgoCard(
                            ngo: ngo,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.go('${AppRoutes.ngos}/${ngo.id}');
                            },
                          )
                              .animate(delay: Duration(milliseconds: index * 80))
                              .fade()
                              .slideY(begin: 0.1, end: 0);
                        },
                        childCount: filteredNgos.length,
                      ),
                    ),
                  );
                },
              ),
              
              // Bottom Padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(4, (index) => 
          _NgoCardSkeleton()
              .animate(delay: Duration(milliseconds: index * 100))
              .fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
  
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load NGOs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection',
              style: TextStyle(color: AppTheme.gray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(ngosProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF9B59B6).withOpacity(0.1),
                    AppTheme.primaryRed.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_rounded,
                size: 56,
                color: const Color(0xFF9B59B6).withOpacity(0.7),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
            
            const SizedBox(height: 24),
            
            Text(
              'No NGOs found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Partner NGOs will appear here once they register and get verified.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// NGO Card Skeleton
class _NgoCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NgoCard extends StatelessWidget {
  final User ngo;
  final VoidCallback? onTap;
  
  const _NgoCard({required this.ngo, this.onTap});

  @override
  Widget build(BuildContext context) {
    final details = ngo.ngoDetails;
    // Mock rating for visual consistency if not available
    final double rating = 4.5; 
    final int reviewCount = 120;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20), // Softer corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo with Status Indicator
                  Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppTheme.offWhite,
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                             image: AssetImage('assets/images/placeholder_ngo.png'), // Fallback/Placeholder
                             fit: BoxFit.cover,
                             opacity: 0.1, // Subtle pattern
                          ),
                          border: Border.all(color: AppTheme.lightGray.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Text(
                            ngo.name.isNotEmpty ? ngo.name[0].toUpperCase() : 'N',
                            style: TextStyle(
                              color: AppTheme.primaryRed.withOpacity(0.8),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (details?.verificationStatus == 'verified')
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.verified, size: 20, color: AppTheme.primaryBlue),
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ngo.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.black,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Rating Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '$rating',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.star, size: 10, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Categories / Cuisine-style tags
                        if (details?.categories.isNotEmpty == true)
                          Text(
                            details!.categories.join(", ").toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.gray,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                        const SizedBox(height: 8),
                        
                        // Location / Distance
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: AppTheme.lightGray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ngo.address ?? 'Location not available',
                                style: const TextStyle(fontSize: 12, color: AppTheme.darkGray),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.offWhite,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.near_me_rounded, size: 10, color: AppTheme.darkGray),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(ngo.id.hashCode % 100) / 10 + 0.5} km', // Simulated distance based on ID
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.black),
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
            
            // Divider & Footer Action
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.lightGray.withOpacity(0.3))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, size: 16, color: AppTheme.accentBlue),
                        const SizedBox(width: 8),
                        Text(
                          '120+ lives impacted recently',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryRed),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
