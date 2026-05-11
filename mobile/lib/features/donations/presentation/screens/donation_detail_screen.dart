import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:confetti/confetti.dart';
import '../../../../config/routes.dart';
import '../../../../shared/widgets/smart_donation_image.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../widgets/review_ngo_modal.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/donation.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/live_tracking_map.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../shared/widgets/impact_share_card.dart';
import '../widgets/verification_qr_modal.dart';
import '../widgets/volunteer_review_modal.dart';
import '../screens/qr_scanner_screen.dart';
import '../../../../core/providers/tracking_provider.dart';


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
  bool _isUpdatingStatus = false;
  bool _isBroadcasting = false;
  bool _isDownloadingReceipt = false;
  Map<String, dynamic>? _tracking;
  bool _isFetchingTracking = false;
  late ConfettiController _confettiController;

  Future<void> _toggleBroadcasting() async {
    if (_donation == null) return;
    
    final trackingState = ref.read(trackingProvider);
    final isCurrentlyBroadcasting = trackingState.isBroadcasting && trackingState.activeDonationId == widget.donationId;

    if (isCurrentlyBroadcasting) {
      ref.read(trackingProvider.notifier).stopDonationTracking();
      CustomSnackBar.info(context, 'Live broadcasting stopped.');
    } else {
      final success = await ref.read(trackingProvider.notifier).startDonationTracking(widget.donationId);
      if (success) {
        if (mounted) CustomSnackBar.success(context, 'Live broadcasting started. It will continue in the background.');
      } else {
        if (mounted) CustomSnackBar.error(context, 'Location permission is required to broadcast.');
      }
    }
    setState(() {}); // Refresh UI
  }
  
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

    final newBookmarks = List<String>.from(user.bookmarks);
    if (!isBookmarked) {
      if (!newBookmarks.contains(widget.donationId)) newBookmarks.add(widget.donationId);
      if (mounted) CustomSnackBar.success(context, 'Donation saved');
    } else {
      newBookmarks.remove(widget.donationId);
      if (mounted) CustomSnackBar.info(context, 'Removed from saved');
    }
    
    ref.read(authStateProvider.notifier).updateUser(user.copyWith(bookmarks: newBookmarks));

    try {
      await ref.read(apiClientProvider).toggleBookmark(widget.donationId);
    } catch (e) {
      ref.read(authStateProvider.notifier).updateUser(user);
      if (mounted) CustomSnackBar.error(context, 'Failed to update bookmark');
    }
  }

  Future<void> _downloadReceipt() async {
    if (_donation == null) return;
    
    setState(() => _isDownloadingReceipt = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/receipt_${_donation!.id}.pdf';
      
      final apiClient = ref.read(apiClientProvider);
      await apiClient.downloadDonationReceipt(_donation!.id, savePath);
      
      if (mounted) {
        CustomSnackBar.success(context, 'Receipt downloaded successfully!');
        OpenFilePlus.open(savePath);
      }
    } catch (e) {
      debugPrint('Download receipt error: $e');
      if (mounted) CustomSnackBar.error(context, 'Failed to download receipt');
    } finally {
      if (mounted) setState(() => _isDownloadingReceipt = false);
    }
  }
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadDonation().then((_) => _loadTracking());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDonation() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getDonation(widget.donationId);
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic>? donationData;
        
        if (responseData['data'] != null && responseData['data']['donation'] != null) {
          donationData = responseData['data']['donation'];
        } else if (responseData['donation'] != null) {
          donationData = responseData['donation'];
        } else if (responseData['data'] != null && responseData['data'] is Map) {
          donationData = responseData['data'];
        }
        
        if (donationData != null) {
          final donation = Donation.fromJson(donationData);
          setState(() {
            _donation = donation;
            _isLoading = false;
          });
          
          if (donation.status == 'delivered' || donation.status == 'distributed') {
            _confettiController.play();
          }
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

  Future<void> _loadTracking() async {
    if (_donation == null) return;
    setState(() => _isFetchingTracking = true);
    try {
      final response = await ref.read(apiClientProvider).getDeliveryTracking(widget.donationId);
      if (response.statusCode == 200) {
        setState(() => _tracking = response.data['data']['tracking']);
      }
    } catch (e) {
      debugPrint('Load tracking error: $e');
    } finally {
      setState(() => _isFetchingTracking = false);
    }
  }

  Future<void> _handleQrVerification(String type) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen(title: 'Scan $type QR')),
    );

    if (result != null) {
      if (type == 'pickup') {
        await _confirmPickupWithQr(result);
      } else {
        await _confirmDeliveryWithQr(result);
      }
    }
  }

  Future<void> _confirmPickupWithQr(String qrCode) async {
    setState(() => _isUpdatingStatus = true);
    try {
      // Get current location for fraud protection verification
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      Map<String, double>? locationData;
      if (position != null) {
        locationData = {
          'lat': position.latitude,
          'lng': position.longitude,
        };
      }

      final response = await ref.read(apiClientProvider).markPickedUp(
        widget.donationId, 
        qrCode: qrCode,
        location: locationData,
      );
      if (response.statusCode == 200) {
        CustomSnackBar.success(context, 'Pickup verified!');
        _loadDonation();
        _loadTracking();
      }
    } catch (e) {
      CustomSnackBar.error(context, 'Invalid QR Code for pickup');
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _confirmDeliveryWithQr(String qrCode) async {
    setState(() => _isUpdatingStatus = true);
    try {
      // Get current location for fraud protection verification
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      Map<String, double>? locationData;
      if (position != null) {
        locationData = {
          'lat': position.latitude,
          'lng': position.longitude,
        };
      }

      final response = await ref.read(apiClientProvider).markDelivered(
        widget.donationId, 
        qrCode: qrCode,
        location: locationData,
      );
      if (response.statusCode == 200) {
        CustomSnackBar.success(context, 'Delivery verified!');
        _loadDonation();
        _loadTracking();
      }
    } catch (e) {
      CustomSnackBar.error(context, 'Invalid QR Code for delivery');
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  void _showQrCode(String type, String qrCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VerificationQrModal(
        qrCode: qrCode,
        type: type,
        donationTitle: _donation?.title ?? 'Donation',
      ),
    );
  }
  
  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.updateDonationStatus(widget.donationId, newStatus);
      
      if (response.statusCode == 200) {
        if (mounted) {
          CustomSnackBar.success(context, 'Status updated to $newStatus');
          _loadDonation();
        }
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to update status');
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
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
    final canClaim = (user?.isVerifiedNgo == true || user?.role == 'volunteer') && donation.isAvailable;
    
    final isUrgent = donation.isUrgent;

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.white,
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppTheme.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: AppTheme.black, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
               IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppTheme.white, shape: BoxShape.circle),
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
                  decoration: const BoxDecoration(color: AppTheme.white, shape: BoxShape.circle),
                  child: const Icon(Icons.share_rounded, color: AppTheme.black, size: 20),
                ),
                onPressed: _shareDonation,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'donation_image_${donation.id}',
                child: SmartDonationImage(
                  imageUrl: donation.images.isNotEmpty ? donation.images.first : null,
                  category: donation.category,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          children: [
                            Text(
                              donation.condition.toUpperCase(),
                              style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const Text('COND', style: TextStyle(color: AppTheme.white, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 8),
                  Text(
                    '${donation.category} • ${donation.quantity ?? 1} ${donation.unit ?? 'Items'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.gray),
                  ),
                  
                  if (isUrgent) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.timer_outlined, size: 14, color: AppTheme.error),
                           SizedBox(width: 4),
                           Text('Urgent Priority', style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(icon: Icons.chat_bubble_outline_rounded, label: 'Message', onTap: () {
                         if (_donation?.donor != null) context.push('/chat/${_donation!.donor!.id}', extra: {'name': _donation!.donor!.name});
                      }),
                      _ActionButton(icon: Icons.call_outlined, label: 'Call', onTap: _launchCaller),
                      _ActionButton(icon: Icons.directions_outlined, label: 'Direction', onTap: _launchMaps),
                      _ActionButton(icon: Icons.ios_share_rounded, label: 'Share', onTap: _shareDonation),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  if (!canClaim && donation.status != 'available' && donation.status != 'cancelled')
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.trackDonation.replaceFirst(':id', donation.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delivery_dining_rounded, color: Colors.white),
                        label: const Text('Track Live Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  const Divider(thickness: 8, color: AppTheme.offWhite),
                  const SizedBox(height: 24),

                  Text('About this donation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(donation.description, style: TextStyle(color: AppTheme.charcoal.withOpacity(0.8), height: 1.5, fontSize: 15)),
                  
                  const SizedBox(height: 24),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(border: Border.all(color: AppTheme.lightGray), borderRadius: BorderRadius.circular(12)),
                     child: IntrinsicHeight(
                       child: Row(
                         children: [
                           Expanded(child: _InfoColumn(label: 'Expiry', value: donation.expiryDate != null ? '${donation.expiryDate!.day}/${donation.expiryDate!.month}' : 'N/A', icon: Icons.calendar_today_rounded)),
                           const VerticalDivider(),
                           Expanded(child: _InfoColumn(label: 'Status', value: donation.statusDisplay, icon: Icons.info_outline_rounded, valueColor: donation.status == 'available' ? AppTheme.success : AppTheme.warning)),
                         ],
                       ),
                     ),
                   ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(donation.status == 'in-transit' ? 'Live Tracking' : 'Pickup Location', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (donation.status == 'in-transit' && ref.watch(trackingProvider).isBroadcasting && ref.watch(trackingProvider).activeDonationId == widget.donationId)
                        const Row(children: [Icon(Icons.circle, color: Colors.red, size: 12), SizedBox(width: 4), Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))]).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 500.ms),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (donation.status == 'in-transit')
                    LiveTrackingMap(
                      donationId: donation.id,
                      initialLocation: donation.currentLocation != null ? LocationData(lat: donation.currentLocation!.lat, lng: donation.currentLocation!.lng) : null,
                      pickupLocation: LocationData(lat: donation.pickupLocation.lat, lng: donation.pickupLocation.lng),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.gray.withOpacity(0.2))),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.white, shape: BoxShape.circle), child: const Icon(Icons.location_on, color: AppTheme.primaryRed)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(donation.pickupLocation.address ?? 'Location coordinates provided', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (donation.pickupInstructions != null) Text(donation.pickupInstructions!, style: TextStyle(color: AppTheme.gray, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  if (donation.status == 'in-transit' && user?.id == donation.claimedBy)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      width: double.infinity,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final trackingState = ref.watch(trackingProvider);
                          final isBroadcastingThis = trackingState.isBroadcasting && trackingState.activeDonationId == widget.donationId;
                          
                          return ElevatedButton.icon(
                            onPressed: _toggleBroadcasting,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBroadcastingThis ? Colors.red : Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(isBroadcastingThis ? Icons.stop_circle_rounded : Icons.my_location_rounded, color: Colors.white),
                            label: Text(isBroadcastingThis ? 'Stop Broadcasting' : 'Broadcast Live Location', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          );
                        }
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  if (donation.donor != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: AppTheme.primaryRed, child: Text(donation.donor!.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.white))),
                      title: Text('Hosted by ${donation.donor!.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Verified Donor'),
                    ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primaryRed,
                AppTheme.accentOrange,
                Colors.amber,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheet(user, donation, canClaim),
    );
  }

  Widget? _buildBottomSheet(user, donation, bool canClaim) {
    final bool isVolunteer = user?.role == 'volunteer';
    
    if (isVolunteer) {
      if (donation.status == 'available') {
        return _buildActionBottomBar(title: "Claim for Pickup", subtitle: "Earn 15 impact points", buttonLabel: "Accept Task", onPressed: _claimDonation, isLoading: _isClaiming);
      } else if (donation.claimedBy == user?.id) {
        if (donation.status == 'claimed') {
          return _buildActionBottomBar(title: "Arrived at Pickup", subtitle: "Scan Donor's QR to verify", buttonLabel: "Scan Pickup QR", onPressed: () => _handleQrVerification('pickup'), isLoading: _isUpdatingStatus);
        } else if (donation.status == 'in-transit') {
          return _buildActionBottomBar(title: "Out for Delivery", subtitle: "Scan NGO's QR to complete", buttonLabel: "Scan Delivery QR", onPressed: () => _handleQrVerification('delivery'), isLoading: _isUpdatingStatus, color: AppTheme.success);
        }
      }
    }

    if (user?.id == donation.donorId) {
      if (donation.status == 'claimed') {
        final pickupQr = _tracking?['pickupQrCode'];
        if (pickupQr != null) {
          return _buildActionBottomBar(title: "Volunteer is Coming", subtitle: "Show this QR to the volunteer", buttonLabel: "Show Pickup QR", onPressed: () => _showQrCode('pickup', pickupQr), color: AppTheme.accentOrange);
        }
      } else if (donation.status == 'delivered' || donation.status == 'distributed') {
         return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (donation.claimedBy != null)
                  _buildSecondaryActionButton(label: 'Rate NGO Performance', icon: Icons.star_rounded, onPressed: () => _showReviewModal(donation), color: AppTheme.black),
                if (donation.volunteerId != null) ...[
                  const SizedBox(height: 12),
                  _buildSecondaryActionButton(label: 'Rate Volunteer Performance', icon: Icons.star_border_rounded, onPressed: () => _showVolunteerReviewModal(donation), color: Colors.amber[800]!),
                ],
                const SizedBox(height: 12),
                _buildSecondaryActionButton(label: 'Download 80G Tax Receipt', icon: Icons.description_rounded, onPressed: _isDownloadingReceipt ? null : _downloadReceipt, isLoading: _isDownloadingReceipt),
                const SizedBox(height: 12),
                _buildSecondaryActionButton(label: 'Share My Impact Card', icon: Icons.auto_awesome_rounded, onPressed: () => _showImpactShareDialog(donation, user.name), color: AppTheme.accentOrange),
              ],
            ),
          ),
        );
      }
    }

    if (user?.role == 'ngo' && donation.claimedBy == user?.id) {
        if (donation.status == 'in-transit') {
          final deliveryQr = _tracking?['deliveryQrCode'];
          if (deliveryQr != null) {
            return _buildActionBottomBar(title: "Volunteer Arriving", subtitle: "Show this QR to receive donation", buttonLabel: "Show Delivery QR", onPressed: () => _showQrCode('delivery', deliveryQr), color: AppTheme.success);
          }
        } else if (donation.status == 'delivered' || donation.status == 'distributed') {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSecondaryActionButton(
                    label: 'Post Impact Story', 
                    icon: Icons.auto_stories_rounded, 
                    onPressed: () => context.push(AppRoutes.createStory, extra: {'donationId': donation.id, 'category': donation.category}),
                    color: AppTheme.primaryRed
                  ),
                  const SizedBox(height: 12),
                  _buildSecondaryActionButton(
                    label: 'Mark as Distributed', 
                    icon: Icons.check_circle_outline_rounded, 
                    onPressed: donation.status == 'distributed' ? null : () => _updateStatus('distributed'),
                    color: AppTheme.success
                  ),
                ],
              ),
            ),
          );
        }
    }

    if (user?.isNgo == true && donation.isAvailable) {
      return _buildActionBottomBar(title: '${donation.quantity ?? 1} ${donation.unit ?? 'Items'}', subtitle: "Free Pickup", buttonLabel: canClaim ? 'Claim Donation' : 'Verification Required', onPressed: canClaim ? _claimDonation : null, isLoading: _isClaiming);
    }
    return null;
  }

  Widget _buildActionBottomBar({required String title, required String subtitle, required String buttonLabel, required VoidCallback? onPressed, bool isLoading = false, Color color = AppTheme.primaryRed}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold))])),
            ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: AppTheme.white, disabledBackgroundColor: AppTheme.lightGray, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.white, strokeWidth: 2)) : Text(buttonLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton({required String label, required IconData icon, required VoidCallback? onPressed, bool isLoading = false, Color color = AppTheme.primaryRed}) {
    return SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: AppTheme.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon), label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
  }

  void _showReviewModal(Donation donation) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => ReviewNgoModal(ngoId: donation.claimedBy!, donationId: donation.id, ngoName: donation.ngo?.name ?? 'the NGO'));
  }

  void _showImpactShareDialog(Donation donation, String donorName) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(10), child: ImpactShareCard(donation: donation, donorName: donorName)));
  }

  void _showVolunteerReviewModal(Donation donation) {
    if (donation.volunteerId == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VolunteerReviewModal(
        donation: donation,
        volunteerId: donation.volunteerId!,
        volunteerName: donation.volunteer?.name ?? 'the volunteer',
      ),
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
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Column(children: [Icon(icon, color: AppTheme.primaryRed), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))])));
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
    return Column(children: [Icon(icon, size: 20, color: AppTheme.gray), const SizedBox(height: 8), Text(label, style: TextStyle(color: AppTheme.gray, fontSize: 12)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor))]);
  }
}
