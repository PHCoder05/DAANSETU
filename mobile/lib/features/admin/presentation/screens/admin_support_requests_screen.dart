import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/app_loader.dart';

final allSupportRequestsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getAllSupportRequests();
  if (response.statusCode == 200) {
    return response.data['data'] as List? ?? [];
  }
  return [];
});

class AdminSupportRequestsScreen extends ConsumerWidget {
  const AdminSupportRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(allSupportRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('User Support Requests'),
        backgroundColor: AppTheme.white,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No support requests found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _SupportRequestCard(request: request);
            },
          );
        },
        loading: () => const AppLoader(message: 'Loading requests...'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SupportRequestCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;
  const _SupportRequestCard({required this.request});

  @override
  ConsumerState<_SupportRequestCard> createState() => _SupportRequestCardState();
}

class _SupportRequestCardState extends ConsumerState<_SupportRequestCard> {
  final TextEditingController _responseController = TextEditingController();
  bool _isResponding = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final status = request['status'] ?? 'pending';
    final user = request['user'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  child: Text(
                    (user['name'] as String?)?.isNotEmpty == true ? user['name'][0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(user['email'] ?? '', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Issue: ${request['issue'] ?? 'General'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  request['message'] ?? 'No message provided',
                  style: const TextStyle(fontSize: 14, color: AppTheme.darkGray),
                ),
              ],
            ),
          ),

          if (status == 'pending') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _responseController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Enter your response...',
                      filled: true,
                      fillColor: AppTheme.scaffoldLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isResponding ? null : _respond,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isResponding 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Resolve & Respond', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (request['adminResponse'] != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.success, size: 14),
                        SizedBox(width: 6),
                        Text('Admin Response', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(request['adminResponse'], style: const TextStyle(fontSize: 13, color: AppTheme.darkGray)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'resolved' ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Future<void> _respond() async {
    if (_responseController.text.trim().isEmpty) {
      CustomSnackBar.warning(context, 'Please enter a response');
      return;
    }

    setState(() => _isResponding = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.respondToSupport(
        widget.request['_id'],
        _responseController.text.trim(),
        'resolved',
      );
      
      if (mounted) {
        CustomSnackBar.success(context, 'Response sent and ticket resolved');
        ref.invalidate(allSupportRequestsProvider);
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to send response');
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }
}
