import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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
import '../widgets/volunteer_dashboard_view.dart';
import '../widgets/ngo_inventory_view.dart';
import '../../../../core/providers/tracking_provider.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/providers/location_provider.dart';
import '../widgets/voice_search_modal.dart';

/// Custom exception class for API errors with user-friendly messages
class DonationException implements Exception {
  final String message;
  final String? details;
  
  DonationException(this.message, [this.details]);
  
  @override
  String toString() => message;
}

final myDonationsFilterProvider = StateProvider.autoDispose<bool>((ref) => false);
final radiusFilterProvider = StateProvider.autoDispose<double?>((ref) => 50.0); // Default 50km

final donationsProvider = FutureProvider.autoDispose<List<Donation>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final myDonations = ref.watch(myDonationsFilterProvider);
  final location = ref.watch(userLocationProvider);
  final radius = ref.watch(radiusFilterProvider);
  
  try {
    final response = await apiClient.getDonations(
      myDonations: myDonations,
      lat: location.position?.latitude,
      lng: location.position?.longitude,
      radius: radius,
    );
    
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
  String _selectedLocation = 'current';
  String _sortBy = 'newest';
  bool _isNgoInventoryMode = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // No coachmarks keys needed
  
  // Use centralized category config from constants
  List<DonationCategory> get _categories => AppConstants.categories;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userLocationProvider.notifier).updateLocation();
    });
  }

  Future<void> _toggleAvailability(bool value) async {
    try {
      HapticFeedback.mediumImpact();
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.updateProfile({'isAvailable': value});
      
      if (response.statusCode == 200) {
        // Update local state via auth provider
        await ref.read(authStateProvider.notifier).refreshProfile();
        
        // Handle background tracking via global provider
        await ref.read(trackingProvider.notifier).toggleGlobalOnline(value);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? 'You are now Online' : 'You are now Offline'),
              backgroundColor: value ? AppTheme.success : AppTheme.charcoal,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppTheme.primaryRed),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Coachmark logic removed to prevent Duplicate GlobalKey exceptions during navigation and sliver transitions

  @override
  Widget build(BuildContext context) {
    final donationsAsync = ref.watch(donationsProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      drawer: _buildDrawer(context, user),
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
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppTheme.black),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: Consumer(
                  builder: (context, ref, _) {
                    final locationState = ref.watch(userLocationProvider);
                    String displayLocation = locationState.address ?? '';
                    
                    if (displayLocation.isEmpty) {
                      switch (_selectedLocation) {
                        case 'current': displayLocation = 'Current Location'; break;
                        case 'home': displayLocation = 'Home'; break;
                        case 'work': displayLocation = 'Work'; break;
                        case 'custom': displayLocation = 'Custom Address'; break;
                        default: displayLocation = 'Set Location';
                      }
                    }
                    
                    return GestureDetector(
                      onTap: () => _showLocationSelector(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryRed, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayLocation,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.black),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.charcoal, size: 20),
                                  ],
                                ),
                                Text(
                                  locationState.address != null ? 'Tap to change' : 'Tap to set location',
                                  style: const TextStyle(color: AppTheme.gray, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                actions: [
                  if (user?.isVolunteer == true)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          Text(
                            user?.isAvailable == true ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: user?.isAvailable == true ? AppTheme.success : AppTheme.gray,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch.adaptive(
                              value: user?.isAvailable ?? false,
                              onChanged: (val) => _toggleAvailability(val),
                              activeTrackColor: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
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

              // 0. Urgent Needs Banner (Zomato-style Highlight)
              _buildUrgentBanner(donationsAsync),
              
              // 1. Verification Banner for NGOs
              if (user?.isNgo == true && user?.isVerifiedNgo == false)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.2),
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
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius:  BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppTheme.lightGray),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search "food" or "books"...',
                        hintStyle: const TextStyle(color: AppTheme.gray),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryRed),
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
                              decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: AppTheme.lightGray)),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.mic_none_rounded, color: AppTheme.primaryRed),
                                onPressed: _showVoiceSearch,
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
                                      color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.1) : AppTheme.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryRed : AppTheme.lightGray.withValues(alpha: 0.5),
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

              // 5. Feed Title / NGO Toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        _isNgoInventoryMode 
                          ? 'My Inventory' 
                          : 'Within ${ref.watch(radiusFilterProvider)?.toInt() ?? 50} km',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      if (user?.role == AppConstants.roleNgo)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.offWhite,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildToggleOption(
                                'EXPLORE', 
                                !_isNgoInventoryMode, 
                                () => setState(() => _isNgoInventoryMode = false),
                              ),
                              _buildToggleOption(
                                'INVENTORY', 
                                _isNgoInventoryMode, 
                                () => setState(() => _isNgoInventoryMode = true),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 6. Content List
              user?.role == AppConstants.roleVolunteer 
                ? SliverFillRemaining(
                    child: VolunteerDashboardView(
                      donations: donationsAsync.value ?? [],
                      onRefresh: () => ref.invalidate(donationsProvider),
                    ),
                  )
                : (user?.role == AppConstants.roleNgo && _isNgoInventoryMode)
                    ? SliverFillRemaining(
                        child: NgoInventoryView(
                          inventory: (donationsAsync.value ?? []).where((d) => 
                            d.status == 'delivered' && d.ngo?.id == user?.id,
                          ).toList(),
                          onRefresh: () => ref.invalidate(donationsProvider),
                          onAction: (item, action) async {
                            try {
                              HapticFeedback.mediumImpact();
                              final apiClient = ref.read(apiClientProvider);
                              // Map actions to API statuses
                              final apiStatus = action == 'used' ? 'distributed' : 'disposed';
                              
                              await apiClient.updateInventoryStatus(item.id, apiStatus);
                              ref.invalidate(donationsProvider);
                              if (context.mounted) {
                                CustomSnackBar.success(context, "Item marked as ${action == 'used' ? 'distributed' : 'removed'}.");
                              }
                            } catch (e) {
                              if (context.mounted) {
                                CustomSnackBar.error(context, 'Failed to update inventory: $e');
                              }
                            }
                          },
                        ),
                      )
                    : donationsAsync.when(
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
                              return Slidable(
                                key: ValueKey(donation.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) => _toggleBookmark(donation.id),
                                      backgroundColor: AppTheme.accentOrange,
                                      foregroundColor: Colors.white,
                                      icon: Icons.bookmark_border_rounded,
                                      label: 'Save',
                                    ),
                                    SlidableAction(
                                      onPressed: (context) => SharePlus.instance.share(ShareParams(text: 'Check out this donation on Daansetu: ${donation.title}')),
                                      backgroundColor: AppTheme.info,
                                      foregroundColor: Colors.white,
                                      icon: Icons.share_rounded,
                                      label: 'Share',
                                    ),
                                  ],
                                ),
                                child: DonationCard(
                                  donation: donation,
                                  onTap: () => context.go('${AppRoutes.donations}/${donation.id}'),
                                ),
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
          color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.1) : Colors.transparent,
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
  
  Widget _buildUrgentBanner(AsyncValue<List<Donation>> donationsAsync) {
    return donationsAsync.when(
      data: (donations) {
        final urgentDonations = donations.where((d) => d.priority == 'urgent' && d.status == 'available').toList();
        if (urgentDonations.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppTheme.primaryRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Urgent Needs Nearby',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: urgentDonations.length,
                  itemBuilder: (context, index) {
                    final donation = urgentDonations[index];
                    return GestureDetector(
                      onTap: () => context.go('${AppRoutes.donations}/${donation.id}'),
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              child: Container(
                                width: 100,
                                height: double.infinity,
                                color: AppTheme.primaryRed.withValues(alpha: 0.1),
                                child: donation.images.isNotEmpty 
                                  ? Image.network(donation.images.first, fit: BoxFit.cover)
                                  : const Icon(Icons.emergency_rounded, color: AppTheme.primaryRed, size: 32),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      donation.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      donation.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.gray, fontSize: 11),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 10, color: AppTheme.gray),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            donation.pickupLocation.address ?? 'Nearby',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppTheme.gray, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slideX(begin: 0.2, end: 0, delay: Duration(milliseconds: index * 100)).fadeIn();
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
  
  /// Premium location selector bottom sheet
  void _showLocationSelector(BuildContext context) {
    HapticFeedback.lightImpact();
    final addressController = TextEditingController();
    bool isDetecting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentRadius = ref.watch(radiusFilterProvider) ?? 50.0;

          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Choose Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.black)),
                            Text('Set your delivery area', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                          ]),
                        ),
                        GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.offWhite, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 18, color: AppTheme.charcoal),
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // GPS Button
                    GestureDetector(
                      onTap: () async {
                        setModalState(() => isDetecting = true);
                        HapticFeedback.mediumImpact();
                        await ref.read(userLocationProvider.notifier).updateLocation();
                        setState(() => _selectedLocation = 'current');
                        setModalState(() => isDetecting = false);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primaryRed, AppTheme.primaryRed.withValues(alpha: 0.85)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isDetecting)
                              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                            else
                              const Icon(Icons.my_location_rounded, color: AppTheme.white, size: 20),
                            const SizedBox(width: 10),
                            Text(isDetecting ? 'Detecting...' : 'Use Current Location', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search bar for custom address
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.lightGray),
                      ),
                      child: TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          hintText: 'Search for area, street name...',
                          hintStyle: const TextStyle(color: AppTheme.gray, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.gray, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryRed, size: 20),
                            onPressed: () {
                              if (addressController.text.isNotEmpty) {
                                setState(() => _selectedLocation = 'custom');
                                ref.read(userLocationProvider.notifier).setAddress(addressController.text);
                                Navigator.pop(ctx);
                              }
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (val) {
                          if (val.isNotEmpty) {
                            setState(() => _selectedLocation = 'custom');
                            ref.read(userLocationProvider.notifier).setAddress(val);
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Saved Places
                    const Text('SAVED PLACES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.gray, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _LocationOption(
                      icon: Icons.home_rounded, label: 'Home', isSelected: _selectedLocation == 'home',
                      onTap: () { _promptSavedPlace(ctx, 'Home', 'home'); },
                    ),
                    _LocationOption(
                      icon: Icons.work_rounded, label: 'Work', isSelected: _selectedLocation == 'work',
                      onTap: () { _promptSavedPlace(ctx, 'Work', 'work'); },
                    ),

                    const SizedBox(height: 20),
                    // Radius
                    Row(
                      children: [
                        const Text('SEARCH RADIUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.gray, letterSpacing: 1)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text('${currentRadius.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primaryRed,
                        inactiveTrackColor: AppTheme.lightGray,
                        thumbColor: AppTheme.primaryRed,
                        overlayColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: currentRadius, min: 5, max: 200, divisions: 39,
                        onChanged: (v) => setModalState(() => ref.read(radiusFilterProvider.notifier).state = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5 km', style: TextStyle(fontSize: 10, color: AppTheme.gray)),
                        Text('200 km', style: TextStyle(fontSize: 10, color: AppTheme.gray)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _promptSavedPlace(BuildContext parentCtx, String label, String id) {
    Navigator.pop(parentCtx);
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Set $label Address', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Enter the address for your $label to see nearby donations.', style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Koramangala, Bangalore',
                prefixIcon: Icon(id == 'home' ? Icons.home_rounded : Icons.work_rounded, color: AppTheme.primaryRed),
                filled: true,
                fillColor: AppTheme.offWhite,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() => _selectedLocation = id);
                    ref.read(userLocationProvider.notifier).setAddress(controller.text);
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _toggleBookmark(String donationId) async {
    final user = ref.read(authStateProvider).user;
    if (user == null) {
      if (mounted) CustomSnackBar.error(context, 'Please login to bookmark');
      return;
    }

    final isBookmarked = user.bookmarks.contains(donationId);
    HapticFeedback.lightImpact();

    // Optimistic update
    final newBookmarks = List<String>.from(user.bookmarks);
    if (!isBookmarked) {
      newBookmarks.add(donationId);
      if (mounted) CustomSnackBar.success(context, 'Donation saved');
    } else {
      newBookmarks.remove(donationId);
      if (mounted) CustomSnackBar.info(context, 'Removed from saved');
    }
    
    ref.read(authStateProvider.notifier).updateUser(user.copyWith(bookmarks: newBookmarks));

    try {
      await ref.read(apiClientProvider).toggleBookmark(donationId);
    } catch (e) {
      // Revert on failure
      ref.read(authStateProvider.notifier).updateUser(user);
      if (mounted) CustomSnackBar.error(context, 'Failed to update bookmark');
    }
  }

  void _showVoiceSearch() async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceSearchModal(),
    );

    if (result != null && mounted) {
      if (result is Map<String, dynamic>) {
        // AI returned filters
        setState(() {
          if (result['category'] != null) {
            _selectedCategory = result['category'].toString().toLowerCase();
          }
          if (result['searchTerm'] != null) {
            _searchQuery = result['searchTerm'].toString().toLowerCase();
            _searchController.text = result['searchTerm'].toString();
          }
        });
        
        CustomSnackBar.success(context, 'Filters applied from voice search');
      } else if (result == 'keyboard') {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    }
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
                selectedColor: AppTheme.primaryRed.withValues(alpha: 0.2),
              ),).toList(),
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
            ),),
          ],
        ),
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
                  AppTheme.primaryRed.withValues(alpha: 0.05),
                  AppTheme.accentOrange.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: AppTheme.primaryRed.withValues(alpha: 0.4),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  quote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                        color: AppTheme.primaryRed.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
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
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
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
  
  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      backgroundColor: AppTheme.white,
      child: Column(
        children: [
          // Header with profile info
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE23744), Color(0xFFFF4E50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppTheme.white,
              child: Text(
                user?.name?[0].toUpperCase() ?? 'U',
                style: const TextStyle(color: AppTheme.primaryRed, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            accountName: Text(user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? 'user@example.com'),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', () {
                  Navigator.pop(context);
                  context.go(AppRoutes.dashboard);
                }),
                _buildDrawerItem(Icons.history_rounded, 'My Donations', () {
                  Navigator.pop(context);
                  context.go(AppRoutes.myDonations);
                }),
                _buildDrawerItem(Icons.emoji_events_outlined, 'Leaderboard', () {
                  Navigator.pop(context);
                  context.go(AppRoutes.leaderboard);
                }),
                _buildDrawerItem(Icons.auto_awesome_rounded, 'Impact Stories', () {
                  Navigator.pop(context);
                  context.go(AppRoutes.impactStories);
                }),
                const Divider(),
                _buildDrawerItem(Icons.settings_outlined, 'Settings', () {
                  Navigator.pop(context);
                  // context.go(AppRoutes.settings);
                }),
                _buildDrawerItem(Icons.help_outline_rounded, 'Help & Support', () {
                  Navigator.pop(context);
                }),
                const Divider(),
                _buildDrawerItem(Icons.logout_rounded, 'Logout', () {
                  Navigator.pop(context);
                  ref.read(authStateProvider.notifier).logout();
                  context.go(AppRoutes.login);
                }, color: AppTheme.primaryRed,),
              ],
            ),
          ),
          
          // Version info at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0.0 (Premium)',
              style: TextStyle(color: AppTheme.gray.withValues(alpha: 0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.charcoal),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppTheme.charcoal,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      visualDensity: VisualDensity.compact,
    );
  }

  Widget colEmpty() {
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 64, color: AppTheme.gray.withValues(alpha: 0.5)),
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
                  color: const Color(0xFFE23744).withValues(alpha: 0.4),
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
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      
                      // Animated text reveal
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        width: _isExpanded ? 110 : 0,
                        child: const SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 10),
                              Text(
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

class _LocationOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationOption({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.05) : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.3) : AppTheme.lightGray),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.1) : AppTheme.offWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? AppTheme.primaryRed : AppTheme.gray, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: AppTheme.charcoal, fontSize: 14))),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
              color: isSelected ? AppTheme.primaryRed : AppTheme.lightGray,
              size: isSelected ? 20 : 14,
            ),
          ],
        ),
      ),
    );
  }
}
