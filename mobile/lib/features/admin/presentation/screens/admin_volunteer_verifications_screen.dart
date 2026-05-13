import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/app_loader.dart';
import 'admin_dashboard_screen.dart';

final allPendingVolunteersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    // Assuming this endpoint exists or will be added to backend
    final response = await apiClient.getPendingVolunteers();
    if (response.statusCode == 200) {
      return response.data['data'] as List? ?? [];
    }
  } catch (_) {}
  return [];
});

class AdminVolunteerVerificationsScreen extends ConsumerWidget {
  const AdminVolunteerVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingVolunteersAsync = ref.watch(allPendingVolunteersProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Volunteer Approvals', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allPendingVolunteersProvider),
        child: pendingVolunteersAsync.when(
          loading: () => const AppLoader(message: 'Fetching volunteers...'),
          error: (e, _) => _buildErrorState(ref),
          data: (volunteers) {
            if (volunteers.isEmpty) return _buildEmptyState();
            
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: volunteers.length,
              itemBuilder: (context, index) =>
                  _VolunteerVerificationCard(volunteer: volunteers[index])
                      .animate()
                      .fade(delay: (index * 100).ms)
                      .slideY(begin: 0.1, delay: (index * 100).ms),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded, size: 48, color: AppTheme.success.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          const Text('Clear Queue!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('No volunteers waiting for approval', style: TextStyle(color: AppTheme.gray)),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          const Text('Something went wrong'),
          TextButton(
            onPressed: () => ref.invalidate(allPendingVolunteersProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _VolunteerVerificationCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> volunteer;
  const _VolunteerVerificationCard({required this.volunteer});

  @override
  ConsumerState<_VolunteerVerificationCard> createState() => _VolunteerVerificationCardState();
}

class _VolunteerVerificationCardState extends ConsumerState<_VolunteerVerificationCard> {
  bool _isProcessing = false;

  Future<void> _handleAction(String status) async {
    setState(() => _isProcessing = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      // Backend should handle volunteer verification
      await apiClient.verifyVolunteer(widget.volunteer['_id'], status);
      
      if (mounted) {
        CustomSnackBar.success(context, 'Volunteer ${status == 'verified' ? 'Approved' : 'Rejected'}');
        ref.invalidate(allPendingVolunteersProvider);
        ref.invalidate(adminStatsProvider);
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to update status');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.volunteer;
    final idProof = v['id_proof'] ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.offWhite,
                backgroundImage: v['profileImage'] != null ? NetworkImage(v['profileImage']) : null,
                child: v['profileImage'] == null ? const Icon(Icons.person, color: AppTheme.gray) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(v['email'] ?? '', style: const TextStyle(color: AppTheme.gray, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('PENDING', style: TextStyle(color: AppTheme.accentOrange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('IDENTITY PROOF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.gray, letterSpacing: 1)),
          const SizedBox(height: 12),
          
          // ID Proof Placeholder/Image
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightGray),
            ),
            child: idProof['url'] != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(idProof['url'], fit: BoxFit.cover),
                )
              : const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_rounded, color: AppTheme.gray),
                    SizedBox(height: 8),
                    Text('No ID document found', style: TextStyle(color: AppTheme.gray, fontSize: 12)),
                  ],
                ),),
          ),
          
          const SizedBox(height: 24),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction('verified'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
