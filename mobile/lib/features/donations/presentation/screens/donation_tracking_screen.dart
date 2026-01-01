import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../shared/models/donation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Provider to fetch single donation
final donationDetailProvider = FutureProvider.family<Donation, String>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getDonation(id);
  
  if (response.statusCode == 200 && response.data != null) {
    // Handle different response structures like in donations screen
    final data = response.data;
    if (data['data'] != null) {
      return Donation.fromJson(data['data']);
    } else if (data['donation'] != null) {
      return Donation.fromJson(data['donation']);
    } else {
      return Donation.fromJson(data);
    }
  }
  throw Exception('Failed to load donation');
});

class DonationTrackingScreen extends ConsumerStatefulWidget {
  final String donationId;

  const DonationTrackingScreen({super.key, required this.donationId});

  @override
  ConsumerState<DonationTrackingScreen> createState() => _DonationTrackingScreenState();
}

class _DonationTrackingScreenState extends ConsumerState<DonationTrackingScreen> {
  final List<String> _steps = [
    'Available',
    'Claimed',
    'In-Transit',
    'Delivered'
  ];
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final donationAsync = ref.watch(donationDetailProvider(widget.donationId));
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Track Donation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('ID: #${widget.donationId.substring(widget.donationId.length - 6)}', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryRed),
            onPressed: () {
               Share.share('I just donated to help someone in need via DAANSETU! Track my impact or join me in making a difference. #DAANSETU #Charity');
            },
          ),
          TextButton(
            onPressed: () {
               context.push('/chat');
            },
            child: const Text('Help', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Stack(
        children: [
          donationAsync.when(
            data: (donation) {
              final currentStepIndex = _getStepIndex(donation.status);
              
              // ══════════════════════════════════════════════════════════════
              // DATA ISOLATION: Check if user has permission to view tracking
              // Only donor or claiming NGO should see full tracking details
              // ══════════════════════════════════════════════════════════════
              final user = ref.watch(authStateProvider).user;
              final isDonor = donation.donor?.id == user?.id;
              final isClaimedNGO = donation.claimedBy == user?.id;
              
              // If not authorized and donation is claimed, show limited view
              if (!isDonor && !isClaimedNGO && donation.status != 'available') {
                return _buildAccessDenied();
              }
              
              // Trigger confetti if delivered
              if (donation.status == 'delivered') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                   _confettiController.play();
                });
              }
              
              return Column(
                children: [
                  // Status Map Header
            Container(
              height: 200,
              width: double.infinity,
              color: AppTheme.offWhite,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Real map using OpenStreetMap
                  (donation.pickupLocation.lat != 0 && donation.pickupLocation.lng != 0) 
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: latLng.LatLng(donation.pickupLocation.lat, donation.pickupLocation.lng),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.daansetu.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latLng.LatLng(donation.pickupLocation.lat, donation.pickupLocation.lng),
                              width: 80,
                              height: 80,
                              child: const Icon(Icons.location_on, color: AppTheme.primaryRed, size: 40),
                            ),
                          ],
                        ),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap contributors',
                              onTap: () {}, 
                            ),
                          ],
                        ),
                      ],
                    )
                  : donation.images.isNotEmpty 
                      ? Image.network(donation.images.first, fit: BoxFit.cover)
                      : Container(
                          color: _getCategoryColor(donation.category).withOpacity(0.1),
                          child: Icon(_getCategoryIcon(donation.category), size: 64, color: _getCategoryColor(donation.category).withOpacity(0.5)),
                        ),
                  Container(color: Colors.black.withOpacity(0.3)), // Overlay
                  // Navigate Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'navigate_fab',
                      backgroundColor: AppTheme.white,
                      child: const Icon(Icons.directions, color: AppTheme.primaryRed),
                      onPressed: () async {
                        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${donation.pickupLocation.lat},${donation.pickupLocation.lng}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          CustomSnackBar.error(context, 'Could not launch maps');
                        }
                      },
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(donation.status), 
                          color: Colors.white, 
                          size: 48
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Text(
                            donation.status.toUpperCase().replaceAll('-', ' '), 
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(donation.status)
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // QR Verification Button
            if (currentStepIndex >= 1 && currentStepIndex < 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     onPressed: () => _showQrCode(context, donation.id),
                     icon: const Icon(Icons.qr_code_rounded),
                     label: const Text('Show Pickup QR Code'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.black,
                       foregroundColor: AppTheme.white,
                       padding: const EdgeInsets.all(16),
                     ),
                   ),
                ),
              ).animate().fade().slideY(begin: 0.1, end: 0),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(donation.category).withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Icon(_getCategoryIcon(donation.category), color: _getCategoryColor(donation.category)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(donation.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                if (donation.donor != null)
                                  Text('Donor: ${donation.donor!.name}', style: const TextStyle(color: AppTheme.gray, fontSize: 13)),
                              ],
                            ),
                          ),
                          
                          // Call Button
                           Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightGray),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.call, color: AppTheme.primaryRed),
                              onPressed: () {
                                CustomSnackBar.info(context, 'Calling donor...');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // TIMELINE
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          final isCompleted = index <= currentStepIndex;
                          final isLast = index == _steps.length - 1;
                          final isCurrent = index == currentStepIndex;

                          return IntrinsicHeight(
                            child: Row(
                              children: [
                                // Timeline Line & Dot
                                SizedBox(
                                  width: 40,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: isCompleted ? AppTheme.primaryGreen : AppTheme.offWhite,
                                          border: Border.all(
                                            color: isCompleted ? AppTheme.primaryGreen : AppTheme.gray,
                                            width: 2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: index < currentStepIndex ? AppTheme.primaryGreen : AppTheme.lightGray,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 32),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _steps[index],
                                          style: TextStyle(
                                            color: isCompleted ? AppTheme.black : AppTheme.gray,
                                            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _getStatusDescription(donation.status),
                                            style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                          ).animate().fade(duration: 800.ms).then().fade(delay: 500.ms),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showQrCode(BuildContext context, String donationId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pickup Verification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show this QR code to the NGO volunteer to verify pickup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            QrImageView(
              data: 'DAAN-SETU-$donationId',
              version: QrVersions.auto,
              size: 200.0,
              foregroundColor: AppTheme.primaryRed,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.primaryRed,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ID: ${donationId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'available': return 0;
      case 'claimed': return 1;
      case 'in-transit': return 2;
      case 'delivered': return 3;
      default: return 0;
    }
  }
  
  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'available': return 'Waiting for an NGO to claim...';
      case 'claimed': return 'Volunteer assigned, preparing for pickup...';
      case 'in-transit': return 'On the way to destination...';
      case 'delivered': return 'Successfully delivered!';
      default: return 'Status updated';
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available': return Icons.inventory_2_outlined;
      case 'claimed': return Icons.volunteer_activism_outlined;
      case 'in-transit': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available': return AppTheme.success;
      case 'claimed': return AppTheme.warning;
      case 'in-transit': return AppTheme.info;
      case 'delivered': return const Color(0xFF9B59B6);
      default: return AppTheme.gray;
    }
  }

  Color _getCategoryColor(String category) {
    return AppTheme.categoryColors[category] ?? AppTheme.gray;
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food': return Icons.restaurant_rounded;
      case 'clothes': return Icons.checkroom_rounded;
      case 'books': return Icons.menu_book_rounded;
      case 'medical': return Icons.medical_services_rounded;
      case 'electronics': return Icons.devices_rounded;
      case 'furniture': return Icons.chair_rounded;
      default: return Icons.inventory_2_rounded;
    }
  }
  
  /// Build access denied view for data isolation
  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tracking Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This donation has been claimed by another organization. You can only view tracking for your own claims.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.gray,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    ).animate().fade();
  }
}
