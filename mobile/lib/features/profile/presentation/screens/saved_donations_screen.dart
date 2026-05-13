import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/donation.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../donations/presentation/widgets/donation_card.dart';

final savedDonationsProvider = FutureProvider.autoDispose<List<Donation>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authStateProvider);
  
  if (!authState.isAuthenticated) return [];
  
  final response = await apiClient.getDonations(saved: true);
  
  if (response.statusCode == 200) {
    final data = response.data;
    final donationsList = data['data'] != null ? data['data']['data'] as List : data['donations'] as List;
    
    return donationsList
        .map((d) => Donation.fromJson(d))
        .toList();
  }
  
  return [];
});

class SavedDonationsScreen extends ConsumerWidget {
  const SavedDonationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(savedDonationsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('Saved Donations'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.black),
          onPressed: () => context.pop(),
        ),
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
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              Text('Failed to load saved donations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(savedDonationsProvider),
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
                    child: const Icon(Icons.bookmark_border_rounded, size: 56, color: AppTheme.gray),
                  ),
                  const SizedBox(height: 20),
                  Text('No saved donations yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Save donations to view them here later',
                    style: TextStyle(color: AppTheme.gray),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Browse Donations'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            color: AppTheme.primaryRed,
            onRefresh: () async => ref.refresh(savedDonationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: donations.length,
              itemBuilder: (context, index) {
                final donation = donations[index];
                return DonationCard(
                  donation: donation,
                  onTap: () => context.push('${AppRoutes.donations}/${donation.id}'),
                ).animate(delay: Duration(milliseconds: index * 80)).fade().slideY(begin: 0.1, end: 0);
              },
            ),
          );
        },
      ),
    );
  }
}
