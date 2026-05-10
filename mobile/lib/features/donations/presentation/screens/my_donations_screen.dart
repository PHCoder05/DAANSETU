import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../shared/models/donation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/impact_share_card.dart';
import '../widgets/volunteer_review_modal.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

final myDonationsProvider = FutureProvider.autoDispose<List<Donation>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authStateProvider);
  
  if (!authState.isAuthenticated) return [];
  
  final response = await apiClient.getDonations(myDonations: true);
  
  if (response.statusCode == 200) {
    final data = response.data;
    // Check if the data has 'data' field (from pagination response wrapper)
    final donationsList = data['data'] != null ? data['data']['data'] as List : data['donations'] as List;
    
    final donations = donationsList
        .map((d) => Donation.fromJson(d))
        .toList();
    return donations;
  }
  
  return [];
});

class MyDonationsScreen extends ConsumerWidget {
  const MyDonationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(myDonationsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('My Donations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('${AppRoutes.donations}/create'),
          ),
        ],
      ),
      body: donationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              Text('Failed to load donations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(myDonationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (donations) {
          if (donations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppTheme.offWhite,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, size: 56, color: AppTheme.gray),
                  ),
                  const SizedBox(height: 20),
                  Text("You haven't created any donations yet", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Start making a difference today!',
                    style: TextStyle(color: AppTheme.gray),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('${AppRoutes.donations}/create'),
                    icon: const Icon(Icons.add, color: AppTheme.white),
                    label: const Text('Create Donation'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            color: AppTheme.primaryRed,
            onRefresh: () async => ref.refresh(myDonationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: donations.length,
              itemBuilder: (context, index) {
                final donation = donations[index];
                return _MyDonationCard(
                  donation: donation,
                  onTap: () => context.go('${AppRoutes.donations}/${donation.id}'),
                  onEdit: () => _showEditOptions(context, ref, donation),
                ).animate(delay: Duration(milliseconds: index * 80)).fade().slideY(begin: 0.1, end: 0);
              },
            ),
          );
        },
      ),
    );
  }
}

  
  void _showImpactShareModal(BuildContext context, WidgetRef ref, Donation donation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Your Impact', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ImpactShareCard(
                  donation: donation,
                  donorName: ref.read(authStateProvider).user?.name ?? 'Community Hero',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVolunteerReviewModal(BuildContext context, Donation donation) {
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

  void _showEditOptions(BuildContext context, WidgetRef ref, Donation donation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              donation.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // View Details
            _ActionTile(
              icon: Icons.visibility_outlined,
              title: 'View Details',
              color: AppTheme.info,
              onTap: () {
                Navigator.pop(context);
                context.go('${AppRoutes.donations}/${donation.id}');
              },
            ),
            
            // Share Impact
            if (donation.isDelivered) ...[
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.share_rounded,
                title: 'Share Impact',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  _showImpactShareModal(context, ref, donation);
                },
              ),
              if (donation.volunteerId != null) ...[
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.star_border_rounded,
                  title: 'Rate Volunteer',
                  color: Colors.amber[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    _showVolunteerReviewModal(context, donation);
                  },
                ),
              ],
            ],
            
            // Edit Donation
            if (donation.isAvailable) ...[
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.edit_rounded,
                title: 'Edit Donation',
                color: AppTheme.primaryRed,
                onTap: () {
                  Navigator.pop(context);
                  context.go('${AppRoutes.donations}/create', extra: donation);
                },
              ),
            ],
            
            // Update Status
            if (donation.isAvailable || donation.isClaimed) ...[
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.update_rounded,
                title: 'Update Status',
                color: AppTheme.warning,
                onTap: () {
                  Navigator.pop(context);
                  _showStatusDialog(context, ref, donation);
                },
              ),
            ],
            
            // Delete
            if (donation.isAvailable) ...[
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Donation',
                color: AppTheme.error,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, donation);
                },
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  void _showStatusDialog(BuildContext context, WidgetRef ref, Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (donation.isClaimed) ...[
              _StatusOption(
                label: 'In Transit',
                icon: Icons.local_shipping_rounded,
                color: AppTheme.info,
                onTap: () => _updateStatus(context, ref, donation.id, 'in-transit'),
              ),
              const SizedBox(height: 8),
              _StatusOption(
                label: 'Delivered',
                icon: Icons.check_circle_rounded,
                color: AppTheme.success,
                onTap: () => _updateStatus(context, ref, donation.id, 'delivered'),
              ),
            ],
            const SizedBox(height: 8),
            _StatusOption(
              label: 'Cancel Donation',
              icon: Icons.cancel_rounded,
              color: AppTheme.error,
              onTap: () => _updateStatus(context, ref, donation.id, 'cancelled'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String id, String status) async {
    Navigator.pop(context);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.updateDonationStatus(id, status);
      ref.invalidate(myDonationsProvider);
      
      if (context.mounted) {
        CustomSnackBar.success(context, 'Status updated!');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.error(context, 'Failed to update status');
      }
    }
  }
  
  void _confirmDelete(BuildContext context, WidgetRef ref, Donation donation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Donation?'),
        content: Text('Are you sure you want to delete "${donation.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteDonation(context, ref, donation.id),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteDonation(BuildContext context, WidgetRef ref, String id) async {
    Navigator.pop(context);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteDonation(id);
      ref.invalidate(myDonationsProvider);
      
      if (context.mounted) {
        CustomSnackBar.success(context, 'Donation deleted');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.error(context, 'Failed to delete donation');
      }
    }
  }

class _MyDonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  
  const _MyDonationCard({
    required this.donation,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.categoryColors[donation.category] ?? AppTheme.gray;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(donation.category),
                  color: categoryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(donation.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            donation.statusDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(donation.status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.visibility_outlined, size: 12, color: AppTheme.gray),
                        const SizedBox(width: 2),
                        Text(
                          '${donation.views}',
                          style: TextStyle(fontSize: 11, color: AppTheme.gray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.more_vert_rounded),
                color: AppTheme.gray,
              ),
            ],
          ),
        ),
      ),
    );
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
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return AppTheme.success;
      case 'claimed': return AppTheme.warning;
      case 'in-transit': return AppTheme.info;
      case 'delivered': return const Color(0xFF9B59B6);
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.gray;
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  
  const _StatusOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
