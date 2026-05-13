import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/fraud_alert.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/app_loader.dart';

final fraudAlertsProvider = FutureProvider.autoDispose<List<FraudAlert>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getFraudAlerts(status: 'open');
  
  if (response.statusCode == 200) {
    final List<dynamic> data = response.data['data'];
    return data.map((json) => FraudAlert.fromJson(json)).toList();
  }
  return [];
});

class AdminFraudAlertsScreen extends ConsumerWidget {
  const AdminFraudAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(fraudAlertsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Fraud Alerts'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(fraudAlertsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const AppLoader(message: 'Scanning for threats...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 80, color: AppTheme.success.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text('System Secure', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('No active fraud alerts detected', style: TextStyle(color: AppTheme.gray)),
                ],
              ).animate().fadeIn().scale(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _FraudAlertCard(alert: alert).animate(delay: Duration(milliseconds: index * 100)).fadeIn().slideX(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}

class _FraudAlertCard extends ConsumerWidget {
  final FraudAlert alert;
  const _FraudAlertCard({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: alert.severity.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Severity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: alert.severity.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: alert.severity.color),
                const SizedBox(width: 8),
                Text(
                  alert.severity.name.toUpperCase(),
                  style: TextStyle(
                    color: alert.severity.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, HH:mm').format(alert.createdAt),
                  style: const TextStyle(fontSize: 10, color: AppTheme.gray),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.typeDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'User: ${alert.userName ?? "Unknown"}',
                            style: const TextStyle(color: AppTheme.gray, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    _buildIcon(alert.type),
                  ],
                ),
                const Divider(height: 24),
                
                // Details based on type
                if (alert.type == 'location_mismatch')
                  _buildLocationDetails(alert.details)
                else if (alert.type == 'suspicious_login')
                  _buildLoginDetails(alert.details)
                else
                  Text(
                    alert.details.toString(),
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                  ),

                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showResolveDialog(context, ref, true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.gray,
                          side: const BorderSide(color: AppTheme.gray),
                        ),
                        child: const Text('False Positive'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showResolveDialog(context, ref, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Resolve'),
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

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'location_mismatch':
        icon = Icons.location_off_rounded;
        color = AppTheme.primaryRed;
        break;
      case 'suspicious_login':
        icon = Icons.no_accounts_rounded;
        color = AppTheme.accentOrange;
        break;
      case 'rapid_claims':
        icon = Icons.speed_rounded;
        color = AppTheme.accentBlue;
        break;
      default:
        icon = Icons.gpp_maybe_rounded;
        color = AppTheme.gray;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildLocationDetails(Map<String, dynamic> details) {
    final distance = (details['distance'] as num?)?.toStringAsFixed(2) ?? 'N/A';
    final action = details['action'] ?? 'unknown';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Action', value: action.toUpperCase()),
        _DetailRow(label: 'Deviation', value: '$distance km'),
        const SizedBox(height: 8),
        const Text(
          'Volunteer was far from the pickup/delivery point during the scan.',
          style: TextStyle(fontSize: 12, color: AppTheme.gray, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildLoginDetails(Map<String, dynamic> details) {
    final attempts = details['failedAttempts'] ?? 'N/A';
    final ip = details['ip'] ?? 'Unknown';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Attempts', value: attempts.toString()),
        _DetailRow(label: 'IP Address', value: ip),
      ],
    );
  }

  Future<void> _showResolveDialog(BuildContext context, WidgetRef ref, bool isFalsePositive) async {
    final controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFalsePositive ? 'Mark as False Positive' : 'Resolve Alert'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter resolution notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isEmpty) {
                CustomSnackBar.error(context, 'Please enter resolution notes');
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFalsePositive ? AppTheme.gray : AppTheme.primaryRed,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.resolveFraudAlert(
          alert.id, 
          resolution: controller.text,
          isFalsePositive: isFalsePositive,
        );
        
        if (context.mounted) {
          CustomSnackBar.success(context, 'Alert resolved');
          ref.invalidate(fraudAlertsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          CustomSnackBar.error(context, 'Failed to resolve alert');
        }
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
        ],
      ),
    );
  }
}
