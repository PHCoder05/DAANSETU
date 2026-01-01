import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../config/routes.dart';
import '../../../../shared/widgets/smart_donation_image.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/donation.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class DonationDetailScreen extends ConsumerStatefulWidget {
  final String donationId;
  
  const DonationDetailScreen({super.key, required this.donationId});

  @override
  ConsumerState<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends ConsumerState<DonationDetailScreen> {
  Donation? _donation;
  bool _isLoading = true;
  bool _isClaiming = false;

  
  // Action Handlers
  Future<void> _launchCaller() async {
     if (_donation?.donor?.phone == null) {
       CustomSnackBar.info(context, 'Donor contact not available');
       return;
     }
     final url = Uri.parse('tel:${_donation!.donor!.phone}');
     if (await canLaunchUrl(url)) {
       await launchUrl(url);
     } else {
       if (mounted) CustomSnackBar.error(context, 'Could not launch dialer');
     }
  }

  Future<void> _launchMaps() async {
    final location = _donation?.pickupLocation;
    if (location == null) return;
    
    // Use geo query if lat/lng available, otherwise address
    final query = location.lat != 0 && location.lng != 0
        ? '${location.lat},${location.lng}'
        : location.address ?? '';
        
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
       if (mounted) CustomSnackBar.error(context, 'Could not launch maps');
    }
  }
  
  void _shareDonation() {
    if (_donation == null) return;
    Share.share('Check out this donation on Daansetu: ${_donation!.title}. Help connect donors with those in need!');
  }
  
  Future<void> _toggleBookmark() async {
    final user = ref.read(authStateProvider).user;
    if (user == null) {
      if (mounted) CustomSnackBar.error(context, 'Please login to bookmark');
      return;
    }

    final isBookmarked = user.bookmarks.contains(widget.donationId);
    HapticFeedback.lightImpact();

    // Optimistic Update
    final newBookmarks = List<String>.from(user.bookmarks);
    if (!isBookmarked) {
      if (!newBookmarks.contains(widget.donationId)) newBookmarks.add(widget.donationId);
      if (mounted) CustomSnackBar.success(context, 'Donation saved');
    } else {
      newBookmarks.remove(widget.donationId);
      if (mounted) CustomSnackBar.info(context, 'Removed from saved');
    }
    
    // Update local user state immediately
    ref.read(authStateProvider.notifier).updateUser(user.copyWith(bookmarks: newBookmarks));

    try {
      await ref.read(apiClientProvider).toggleBookmark(widget.donationId);
    } catch (e) {
      // Revert if failed
      ref.read(authStateProvider.notifier).updateUser(user);
      if (mounted) CustomSnackBar.error(context, 'Failed to update bookmark');
    }
  }
  
  @override
  void initState() {
    super.initState();
    _loadDonation();
  }
  
  Future<void> _loadDonation() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getDonation(widget.donationId);
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        // Handle different response structures
        Map<String, dynamic>? donationData;
        
        if (responseData['data'] != null && responseData['data']['donation'] != null) {
          donationData = responseData['data']['donation'];
        } else if (responseData['donation'] != null) {
          donationData = responseData['donation'];
        } else if (responseData['data'] != null && responseData['data'] is Map) {
          donationData = responseData['data'];
        }
        
        if (donationData != null) {
          setState(() {
            _donation = Donation.fromJson(donationData!);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Load donation error: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _claimDonation() async {
    setState(() => _isClaiming = true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.claimDonation(widget.donationId);
      
      if (response.statusCode == 200) {
        if (mounted) {
          CustomSnackBar.success(context, 'Donation claimed successfully!');
          _loadDonation();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to claim donation');
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not found or loading, show basic states
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      );
    }

    if (_donation == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.white, elevation: 0),
        body: const Center(child: Text('Donation not found')),
      );
    }

    final donation = _donation!;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final isBookmarked = user?.bookmarks.contains(widget.donationId) ?? false;
    final canClaim = user?.isVerifiedNgo == true && donation.isAvailable;
    
    // Determine status color/text
    final isUrgent = donation.isUrgent;

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          // 1. Zomato-style Hero Image Header
          SliverAppBar(
            backgroundColor: AppTheme.white,
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: AppTheme.black, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
               IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                    color: isBookmarked ? AppTheme.primaryRed : AppTheme.black, 
                    size: 20
                  ),
                ),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: AppTheme.black, size: 20),
                ),
                onPressed: _shareDonation,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   // Smart Image with Fallback using Category
                   SmartDonationImage(
                     imageUrl: donation.images.isNotEmpty ? donation.images.first : null,
                     category: donation.category,
                     fit: BoxFit.cover,
                   ),
                  // Gradient Overlay for text readability if title was here, but we moved title successfully below
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Rating/Grade
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          donation.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.black,
                            fontSize: 26,
                            height: 1.1,
                          ),
                        ),
                      ),
                      // Rating-style box for Condition
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Text(
                              donation.condition.toUpperCase().substring(0, 1) + donation.condition.substring(1).toLowerCase(),
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Text(
                              'COND',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    '${donation.category} • ${donation.quantity ?? 1} ${donation.unit ?? 'Items'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray,
                    ),
                  ),
                  
                  if (isUrgent) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.timer_outlined, size: 14, color: AppTheme.error),
                           SizedBox(width: 4),
                           Text('Urgent Priority', style: TextStyle(
                             color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold
                           )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  
                  // Action Buttons (Call, Directions, Review style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Message',
                        onTap: () {
                           if (_donation?.donor != null) {
                             context.push('/chat/${_donation!.donor!.id}', extra: {'name': _donation!.donor!.name});
                           } else {
                             CustomSnackBar.info(context, 'Donor info unavailable');
                           }
                        },
                      ),
                      _ActionButton(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        onTap: _launchCaller,
                      ),
                      _ActionButton(
                        icon: Icons.directions_outlined,
                        label: 'Direction',
                        onTap: _launchMaps,
                      ),
                      _ActionButton(
                        icon: Icons.ios_share_rounded,
                        label: 'Share',
                        onTap: _shareDonation,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  // Track Order Button (Zomato Style)
                  if (!canClaim && donation.status != 'available' && donation.status != 'cancelled')
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.trackDonation.replaceFirst(':id', donation.id));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delivery_dining_rounded, color: Colors.white),
                        label: const Text('Track Live Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  const Divider(thickness: 8, color: AppTheme.offWhite), // Zomato style thick divider
                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    'About this donation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    donation.description,
                    style: TextStyle(
                      color: AppTheme.charcoal.withOpacity(0.8),
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                   // Info Grid
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       border: Border.all(color: AppTheme.lightGray),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: IntrinsicHeight(
                       child: Row(
                         children: [
                           Expanded(
                             child: _InfoColumn(
                               label: 'Expiry',
                               value: donation.expiryDate != null 
                                   ? '${donation.expiryDate!.day}/${donation.expiryDate!.month}' 
                                   : 'N/A',
                               icon: Icons.calendar_today_rounded,
                             ),
                           ),
                           const VerticalDivider(),
                           Expanded(
                             child: _InfoColumn(
                               label: 'Status',
                               value: donation.statusDisplay,
                               icon: Icons.info_outline_rounded,
                               valueColor: donation.status == 'available' ? AppTheme.success : AppTheme.warning,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),

                  const SizedBox(height: 24),
                  
                  // Pickup Location
                  Text(
                    'Pickup Location',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.offWhite,
                      borderRadius: BorderRadius.circular(12),
                      // Google Maps Placeholder
                      border: Border.all(color: AppTheme.gray.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on, color: AppTheme.primaryRed),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donation.pickupLocation.address ?? 'Location coordinates provided',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (donation.pickupInstructions != null)
                                  Text(
                                    donation.pickupInstructions!,
                                    style: TextStyle(color: AppTheme.gray, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Donor Info
                  if (donation.donor != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryRed,
                        child: Text(donation.donor!.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.white)),
                      ),
                      title: Text('Hosted by ${donation.donor!.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Verified Donor'),
                      trailing: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryRed,
                          side: const BorderSide(color: AppTheme.primaryRed),
                        ),
                        child: const Text('Profile'),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 100), // Space for fab/bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: (user?.isNgo == true && donation.isAvailable) ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${donation.quantity ?? 1} ${donation.unit ?? 'Items'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Free Pickup',
                      style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: (canClaim && !_isClaiming) ? _claimDonation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: AppTheme.white,
                  disabledBackgroundColor: AppTheme.lightGray,
                  disabledForegroundColor: AppTheme.gray,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isClaiming 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2))
                    : Text(
                        canClaim ? 'Claim Donation' : 'Verification Required',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              )
            ],
          ),
        ),
      ) : null,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.lightGray),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.white,
            ),
            child: Icon(icon, color: AppTheme.primaryRed, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoColumn({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.gray),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppTheme.gray, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? AppTheme.charcoal)),
      ],
    );
  }
}
