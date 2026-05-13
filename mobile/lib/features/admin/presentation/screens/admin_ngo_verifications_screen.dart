import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/app_loader.dart';
import 'admin_dashboard_screen.dart';

final allPendingNgosProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.getPendingNgos();
    if (response.statusCode == 200) {
      return response.data['data'] as List? ?? [];
    }
  } catch (_) {}
  return [];
});

class AdminNgoVerificationsScreen extends ConsumerWidget {
  const AdminNgoVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingNgosAsync = ref.watch(allPendingNgosProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('NGO Verifications', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.black,
      ),
      body: Column(
        children: [
          // 2-Step Legend Bar
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightGray),
            ),
            child: const Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _StepChip(number: '1', label: 'Govt API Check', color: Colors.blue),
                Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.gray),
                _StepChip(number: '2', label: 'Admin Review', color: AppTheme.primaryRed),
                Text(
                  'YOU ARE HERE',
                  style: TextStyle(
                    fontSize: 8, fontWeight: FontWeight.w900,
                    color: AppTheme.primaryRed, letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(allPendingNgosProvider),
              child: pendingNgosAsync.when(
                loading: () => const AppLoader(message: 'Fetching pending requests...'),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.error),
                      ),
                      const SizedBox(height: 16),
                      const Text('Failed to load verifications', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(allPendingNgosProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (ngos) {
                  if (ngos.isEmpty) {
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
                            child: Icon(Icons.verified_user_rounded, size: 48, color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'All caught up!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No pending verifications',
                            style: TextStyle(fontSize: 14, color: AppTheme.gray),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: ngos.length,
                    itemBuilder: (context, index) =>
                        _NgoVerificationDetailCard(ngo: ngos[index])
                            .animate()
                            .fade(delay: (index * 100).ms)
                            .slideY(begin: 0.1, delay: (index * 100).ms),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Chip ───
class _StepChip extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  const _StepChip({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.darkGray, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

// ─── Verification Detail Card ───
class _NgoVerificationDetailCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> ngo;
  const _NgoVerificationDetailCard({required this.ngo});

  @override
  ConsumerState<_NgoVerificationDetailCard> createState() => _NgoVerificationDetailCardState();
}

class _NgoVerificationDetailCardState extends ConsumerState<_NgoVerificationDetailCard> {
  bool _isProcessing = false;
  bool _isExpanded = false;

  Map<String, dynamic> get _apiVerification {
    final details = widget.ngo['ngoDetails'] as Map<String, dynamic>? ?? {};
    return details['govVerificationData'] as Map<String, dynamic>? ?? {};
  }

  String get _apiStatus {
    final details = widget.ngo['ngoDetails'] as Map<String, dynamic>? ?? {};
    return details['govVerificationStatus']?.toString() ?? 'pending';
  }
  
  String get _apiScore => _apiVerification['matchScore']?.toString() ?? '0%';

  Future<void> _handleAction(String status) async {
    setState(() => _isProcessing = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.verifyNgo(widget.ngo['_id'], status);
      
      if (mounted) {
        CustomSnackBar.success(context, 'NGO ${status == 'verified' ? 'Approved' : 'Rejected'}');
        ref.invalidate(allPendingNgosProvider);
        ref.invalidate(adminStatsProvider);
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to process request');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleGovCheck() async {
    setState(() => _isProcessing = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.verifyNgoGovApi(widget.ngo['_id']);
      
      if (mounted) {
        CustomSnackBar.success(context, 'Government API check completed');
        ref.invalidate(allPendingNgosProvider);
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to run Gov API check');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.ngo['ngoDetails'] ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                  child: const Icon(Icons.business_rounded, color: AppTheme.primaryRed),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.ngo['name'] ?? 'NGO', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(widget.ngo['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Step 1: Government API Status Card ───
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _apiStatus == 'passed'
                    ? const Color(0xFFF0FDF4)
                    : _apiStatus == 'failed'
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _apiStatus == 'passed'
                      ? Colors.green.shade200
                      : _apiStatus == 'failed'
                          ? Colors.red.shade200
                          : AppTheme.lightGray,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dns_rounded, size: 18, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STEP 1: GOVT API CHECK',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.darkGray),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _apiStatus == 'verified'
                                  ? 'Verified via NGO Darpan'
                                  : _apiStatus == 'failed'
                                      ? 'Government API could not verify'
                                      : 'Not yet checked',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _apiStatus == 'verified' ? Colors.green.shade700 : 
                                       _apiStatus == 'failed' ? Colors.red.shade700 : AppTheme.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Score badge
                      if (_apiScore != '0%')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _apiStatus == 'verified' ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _apiScore,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w900,
                              color: _apiStatus == 'verified' ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: AppTheme.gray, size: 20,
                      ),
                    ],
                  ),

                  // Expandable detail
                  if (_isExpanded) ...[
                    const Divider(height: 24),
                    // Check Gov API Button
                    if (_apiStatus == 'pending')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _handleGovCheck,
                          icon: const Icon(Icons.api_rounded, size: 18),
                          label: const Text('Run Darpan API Check'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            side: BorderSide(color: Colors.blue.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    
                    if (_apiStatus != 'pending') ...[
                      // Darpan verification Details
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _apiStatus == 'verified' ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _apiStatus == 'verified' ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 16,
                              color: _apiStatus == 'verified' ? Colors.green.shade600 : Colors.red.shade400,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'NGO Darpan',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                              ),
                            ),
                            Icon(
                              _apiStatus == 'verified' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 18,
                              color: _apiStatus == 'verified' ? Colors.green : Colors.red.shade300,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 32, indent: 20, endIndent: 20),

          // ─── Registration Details ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Reg Number', value: details['registrationNumber'] ?? 'N/A'),
                if (details['darpanId'] != null)
                  _DetailRow(label: 'Darpan ID', value: details['darpanId'].toString()),
                _DetailRow(label: 'Est. Year', value: details['establishedYear']?.toString() ?? 'N/A'),
                _DetailRow(label: 'Categories', value: (details['categories'] as List?)?.join(', ') ?? 'N/A'),
                const SizedBox(height: 8),
                const Text('Description:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.gray)),
                const SizedBox(height: 4),
                Text(
                  details['description'] ?? 'No description provided.',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Step 2: Admin Actions ───
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppTheme.primaryRed),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'STEP 2: ADMIN REVIEW',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.darkGray),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleAction('rejected'),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleAction('verified'),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
