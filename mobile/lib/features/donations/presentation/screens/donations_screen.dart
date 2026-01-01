import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../config/constants.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/donation.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../widgets/donation_card.dart';

/// Custom exception class for API errors with user-friendly messages
class DonationException implements Exception {
  final String message;
  final String? details;
  
  DonationException(this.message, [this.details]);
  
  @override
  String toString() => message;
}

final myDonationsFilterProvider = StateProvider.autoDispose<bool>((ref) => false);

final donationsProvider = FutureProvider.autoDispose<List<Donation>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final myDonations = ref.watch(myDonationsFilterProvider);
  
  try {
    final response = await apiClient.getDonations(myDonations: myDonations);
    
    if (response.statusCode == 200) {
      final data = response.data;
      
      // Check if data structure is valid
      if (data == null) {
        throw DonationException(
          'Server returned empty response',
          'The server returned no data. Please try again later.',
        );
      }
      
      List<dynamic> donationsList;
      
      if (data['data'] != null && data['data']['data'] != null) {
        donationsList = data['data']['data'] as List;
      } else if (data['donations'] != null) {
        donationsList = data['donations'] as List;
      } else if (data['data'] != null && data['data']['donations'] != null) {
        donationsList = data['data']['donations'] as List;
      } else if (data['data'] != null && data['data'] is List) {
        donationsList = data['data'] as List;
      } else if (data is List) {
        donationsList = data;
      } else {
        throw DonationException(
          'Invalid data format',
          'Expected donations list but received unexpected structure.',
        );
      }
      
      final donations = donationsList
          .map((d) => Donation.fromJson(d))
          .toList();
      return donations;
    } else {
      throw DonationException(
        'Failed to load donations',
        'Server returned status ${response.statusCode}',
      );
    }
  } catch (e) {
    if (e is DonationException) rethrow;
    throw DonationException(
      'Unexpected error',
      e.toString(),
    );
  }
});

class DonationsScreen extends ConsumerStatefulWidget {
  const DonationsScreen({super.key});

  @override
  ConsumerState<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends ConsumerState<DonationsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _selectedLocation = 'Current Location';
  String _sortBy = 'newest';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // GlobalKeys for coachmarks
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  TutorialCoachMark? _tutorialCoachMark;
  
  // Use centralized category config from constants
  List<DonationCategory> get _categories => AppConstants.categories;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialIfNeeded());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Show coachmark tutorial for first-time users
  Future<void> _showTutorialIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenDonationsTutorial') ?? false;
    
    if (!hasSeenTutorial && mounted) {
      // Add small delay for UI to settle
      await Future.delayed(const Duration(milliseconds: 500));
      _showTutorial();
      await prefs.setBool('hasSeenDonationsTutorial', true);
    }
  }
  
  void _showTutorial() {
    _tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: AppTheme.primaryRed,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      hideSkip: false,
      onFinish: () {},
      onSkip: () => true,
    );
    _tutorialCoachMark!.show(context: context);
  }
  
  List<TargetFocus> _createTargets() {
    return [
      TargetFocus(
        identify: "location",
        keyTarget: _locationKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildCoachContent(
              icon: Icons.location_on_rounded,
              title: "📍 Set Your Location",
              description: "Tap here to change location and see donations near you",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      TargetFocus(
        identify: "search",
        keyTarget: _searchKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildCoachContent(
              icon: Icons.search_rounded,
              title: "🔍 Search Donations",
              description: "Type to find food, clothes, books or any donation",
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
      TargetFocus(
        identify: "filter",
        keyTarget: _filterKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildCoachContent(
              icon: Icons.tune_rounded,
              title: "⚙️ Filter & Sort",
              description: "Filter by category or sort by newest, oldest, or nearest",
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
      TargetFocus(
        identify: "fab",
        keyTarget: _fabKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildCoachContent(
              icon: Icons.add_rounded,
              title: "➕ Create Donation",
              description: "Tap the + button to donate items and help those in need!",
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    ];
  }
  
  Widget _buildCoachContent({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryRed, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(fontSize: 14, color: AppTheme.gray)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Tap anywhere to continue', style: TextStyle(fontSize: 12, color: AppTheme.primaryRed)),
              const SizedBox(width: 4),
              Icon(Icons.touch_app, size: 14, color: AppTheme.primaryRed),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationsAsync = ref.watch(donationsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            ref.invalidate(donationsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryRed,
          backgroundColor: AppTheme.white,
          displacement: 20,
          edgeOffset: 100,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Zomato-style Header with Location logic
              SliverAppBar(
                backgroundColor: AppTheme.white,
                elevation: 0,
                pinned: true,
                floating: true,
                toolbarHeight: 60,
                title: GestureDetector(
                  key: _locationKey,
                  onTap: () => _showLocationSelector(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.primaryRed, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _selectedLocation.length > 15 ? '${_selectedLocation.substring(0, 15)}...' : _selectedLocation,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.black,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.charcoal, size: 24),
                        ],
                      ),
                      Text(
                        'Tap to change location',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.offWhite,
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppTheme.primaryRed,
                        radius: 18,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // 1. Verification Banner for NGOs
              if (user?.isNgo == true && user?.isVerifiedNgo == false)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_outlined, color: AppTheme.warning, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verification Pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.warning,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'You cannot claim donations until an admin verifies your account.',
                                style: TextStyle(
                                  color: AppTheme.charcoal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: -0.1, end: 0),
                ),
              
              // 2. Search Bar (Sticky-ish feel by placing it here)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    key: _searchKey,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius:  BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: AppTheme.lightGray),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search "food" or "books"...',
                        hintStyle: TextStyle(color: AppTheme.gray),
                        prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryRed),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.gray, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: AppTheme.lightGray)),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.mic_none_rounded, color: AppTheme.primaryRed),
                                onPressed: () => _showVoiceSearchDialog(context),
                              ),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. "What's on your mind?" (Categories)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        "What's on your mind?",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 1,
                          color: AppTheme.charcoal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _categories.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category.id;
                          
                          // Circular Design like Zomato
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedCategory = category.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : AppTheme.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryRed : AppTheme.lightGray.withOpacity(0.5),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      category.icon,
                                      size: 30,
                                      color: isSelected ? AppTheme.primaryRed : category.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? AppTheme.primaryRed : AppTheme.charcoal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Sticky Filter Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverFilterHeaderDelegate(
                  maxHeight: 56, // Slightly taller for better touch targets
                  child: Container(
                    color: AppTheme.scaffoldLight,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjusted vertical padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Toggle: Explore vs My Activity
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.lightGray),
                          ),
                          child: Row(
                            children: [
                              _buildToggleOption(
                                'Explore', 
                                !ref.watch(myDonationsFilterProvider),
                                () => ref.read(myDonationsFilterProvider.notifier).state = false,
                              ),
                              _buildToggleOption(
                                user?.isDonor == true ? 'My Donations' : 'My Claims',
                                ref.watch(myDonationsFilterProvider),
                                () => ref.read(myDonationsFilterProvider.notifier).state = true,
                              ),
                            ],
                          ),
                        ),
                        
                        // Icon Filters (Compact)
                        Row(
                          key: _filterKey,
                          children: [
                            GestureDetector(
                              onTap: () => _showFilterSheet(context),
                              child: _buildFilterIcon(Icons.tune_rounded),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showSortSheet(context),
                              child: _buildFilterIcon(Icons.sort_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Feed Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    'All Donations around you',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              // 6. Content List
              donationsAsync.when(
                loading: () => SliverToBoxAdapter(child: _buildLoadingState()),
                error: (error, stack) => SliverToBoxAdapter(child: _buildErrorState(error)),
                data: (donations) {
                  final filteredDonations = donations.where((d) {
                    final matchesCategory = _selectedCategory == 'all' || d.category == _selectedCategory;
                    final matchesSearch = _searchQuery.isEmpty || 
                        d.title.toLowerCase().contains(_searchQuery) ||
                        d.description.toLowerCase().contains(_searchQuery) ||
                        d.category.toLowerCase().contains(_searchQuery);
                    
                    return matchesCategory && matchesSearch;
                  }).toList();
                  
                  if (filteredDonations.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final donation = filteredDonations[index];
                          return DonationCard(
                            donation: donation,
                            onTap: () => context.go('${AppRoutes.donations}/${donation.id}'),
                          ).animate(delay: Duration(milliseconds: index * 50)).fade().slideY(begin: 0.05, end: 0);
                        },
                        childCount: filteredDonations.length,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: user?.isDonor == true ? _ExpandableFab(
        key: _fabKey,
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go('${AppRoutes.donations}/create');
        },
      ) : null,
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryRed : AppTheme.gray,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Icon(icon, size: 16, color: AppTheme.charcoal),
    );
  }
  
  /// Show location selector bottom sheet
  void _showLocationSelector(BuildContext context) {
    HapticFeedback.lightImpact();
    final locations = ['Current Location', 'Home', 'Work', 'Custom Address'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            ...locations.map((loc) => ListTile(
              leading: Icon(
                loc == 'Current Location' ? Icons.my_location : Icons.location_on_outlined,
                color: _selectedLocation == loc ? AppTheme.primaryRed : AppTheme.gray,
              ),
              title: Text(loc),
              trailing: _selectedLocation == loc ? const Icon(Icons.check, color: AppTheme.primaryRed) : null,
              onTap: () {
                setState(() => _selectedLocation = loc);
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }
  
  /// Show voice search dialog (placeholder)
  void _showVoiceSearchDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 40, color: AppTheme.primaryRed),
            ),
            const SizedBox(height: 16),
            const Text('Listening...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Say "food" or "clothes" to search', style: TextStyle(color: AppTheme.gray)),
            const SizedBox(height: 16),
            const Text('(Voice search coming soon)', style: TextStyle(color: AppTheme.gray, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }
  
  /// Show filter sheet
  void _showFilterSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Donations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) => FilterChip(
                label: Text(cat.label),
                selected: _selectedCategory == cat.id,
                onSelected: (selected) {
                  setState(() => _selectedCategory = selected ? cat.id : 'all');
                  Navigator.pop(context);
                },
                selectedColor: AppTheme.primaryRed.withOpacity(0.2),
              )).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedCategory = 'all');
                  Navigator.pop(context);
                },
                child: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show sort sheet
  void _showSortSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final sortOptions = [
      {'id': 'newest', 'label': 'Newest First', 'icon': Icons.access_time},
      {'id': 'oldest', 'label': 'Oldest First', 'icon': Icons.history},
      {'id': 'nearest', 'label': 'Nearest First', 'icon': Icons.near_me},
    ];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sortOptions.map((opt) => ListTile(
              leading: Icon(opt['icon'] as IconData, color: _sortBy == opt['id'] ? AppTheme.primaryRed : AppTheme.gray),
              title: Text(opt['label'] as String),
              trailing: _sortBy == opt['id'] ? const Icon(Icons.check, color: AppTheme.primaryRed) : null,
              onTap: () {
                setState(() => _sortBy = opt['id'] as String);
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.charcoal),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.charcoal),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    // Get quote from centralized constants
    final quote = AppConstants.getRandomQuote();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Quote section - Zomato style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRed.withOpacity(0.05),
                  AppTheme.accentOrange.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryRed.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: AppTheme.primaryRed.withOpacity(0.4),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.charcoal,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryRed.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Finding donations near you...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          
          // Skeleton cards
          ...List.generate(3, (index) => 
            const DonationCardSkeleton()
                .animate(delay: Duration(milliseconds: index * 100))
                .fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => ref.refresh(donationsProvider),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: colEmpty(),
      ),
    );
  }
  
  Widget colEmpty() {
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 64, color: AppTheme.gray.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          'No donations found',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.gray),
        ),
      ],
    );
  }
}

class _SliverFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;

  _SliverFilterHeaderDelegate({required this.child, this.maxHeight = 54});

  @override
  double get minExtent => maxHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverFilterHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight || oldDelegate.child != child;
  }
}

/// Premium expandable FAB with + icon that expands to show "Donate Now"
class _ExpandableFab extends StatefulWidget {
  final VoidCallback onTap;
  
  const _ExpandableFab({super.key, required this.onTap});
  
  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    // Auto-expand after delay to show users they can tap
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isExpanded) {
        _toggleExpand();
        // Collapse after showing
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isExpanded) {
            _toggleExpand();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _toggleExpand() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isExpanded) {
          widget.onTap();
        } else {
          _toggleExpand();
        }
      },
      onLongPress: widget.onTap,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFE23744), Color(0xFFFF4E50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE23744).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isExpanded) {
                    widget.onTap();
                  } else {
                    _toggleExpand();
                  }
                },
                onLongPress: widget.onTap,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isExpanded ? 20 : 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // + icon (always shows +, no rotation)
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      
                      // Animated text reveal
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        width: _isExpanded ? 110 : 0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 10),
                              const Text(
                                'Donate Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate()
     .slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutBack)
     .fade(begin: 0, end: 1, duration: 300.ms);
  }
}
