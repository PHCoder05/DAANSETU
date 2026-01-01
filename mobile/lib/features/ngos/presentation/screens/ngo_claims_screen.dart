import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class NgoClaimsScreen extends ConsumerStatefulWidget {
  const NgoClaimsScreen({super.key});

  @override
  ConsumerState<NgoClaimsScreen> createState() => _NgoClaimsScreenState();
}

class _NgoClaimsScreenState extends ConsumerState<NgoClaimsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getRequests();
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Adjust based on actual API response structure
        if (data['data'] != null && data['data']['requests'] != null) {
           _requests = List<Map<String, dynamic>>.from(data['data']['requests']);
        } else if (data['requests'] != null) {
           _requests = List<Map<String, dynamic>>.from(data['requests']);
        }
      }
    } catch (e) {
      CustomSnackBar.error(context, 'Failed to load claims');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    // Implement cancel logic if API supports it
    CustomSnackBar.info(context, 'Cancelling request...');
    // Mock success for UI feedback
     setState(() {
       _requests.removeWhere((r) => r['_id'] == requestId || r['id'] == requestId);
     });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text('My Claims', style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : _requests.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    return _buildClaimCard(request).animate(delay: (50 * index).ms).slideY(begin: 0.1);
                  },
                ),
    );
  }

  Widget _buildClaimCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final donation = request['donationId'] is Map ? request['donationId'] : null;
    final title = donation?['title'] ?? 'Donation Request';
    final date = request['createdAt'] != null ? DateTime.tryParse(request['createdAt']) : DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donation Image or Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(12),
                    image: donation?['images'] != null && (donation['images'] as List).isNotEmpty
                        ? DecorationImage(image: NetworkImage(donation['images'][0]), fit: BoxFit.cover)
                        : null,
                  ),
                  child: donation?['images'] == null || (donation['images'] as List).isEmpty
                      ? const Icon(Icons.volunteer_activism, color: AppTheme.primaryRed)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'Requested on ${_formatDate(date)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                      ),
                      const SizedBox(height: 8),
                      // Message
                      if (request['message'] != null)
                        Text(
                          '"${request['message']}"',
                          style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.darkGray, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          if (status == 'pending')
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.offWhite)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _cancelRequest(request['_id'] ?? request['id']),
                      icon: const Icon(Icons.close, size: 16, color: AppTheme.gray),
                      label: const Text('Cancel Request', style: TextStyle(color: AppTheme.gray)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppTheme.success;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        color = AppTheme.error;
        icon = Icons.error_outline;
        break;
      default:
        color = AppTheme.accentOrange;
        icon = Icons.access_time;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: AppTheme.gray.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No claims found', style: TextStyle(fontSize: 16, color: AppTheme.gray)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.donations),
            child: const Text('Browse Donations'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat.yMMMd().format(date);
  }
}
