import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';

// Model for Activity
class Activity {
  final String type;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic> data;

  Activity({
    required this.type,
    required this.timestamp,
    required this.description,
    required this.data,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      type: json['type'] ?? 'unknown',
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      description: json['description'] ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

final activityProvider = FutureProvider.autoDispose<List<Activity>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.getActivity();
    
    if (response.statusCode == 200) {
      final data = response.data;
      final activitiesList = data['data'] != null ? data['data']['activities'] as List : data['activities'] as List;
      
      return activitiesList
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    debugPrint('Error loading activity: $e');
  }
  
  return [];
});

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: AppTheme.white,
      ),
      body: activityAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Failed to load activity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(activityProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (activities) {
          if (activities.isEmpty) {
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
                    child: const Icon(Icons.history_rounded, size: 56, color: AppTheme.gray),
                  ),
                  const SizedBox(height: 20),
                  Text('No activity yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Your recent actions will appear here',
                    style: TextStyle(color: AppTheme.gray),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            color: AppTheme.primaryRed,
            onRefresh: () async => ref.refresh(activityProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _ActivityCard(
                  activity: activity,
                  isLast: index == activities.length - 1,
                ).animate(delay: Duration(milliseconds: index * 50)).fade().slideX(begin: 0.05, end: 0);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isLast;
  
  const _ActivityCard({
    required this.activity,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _getTypeColor().withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _getTypeColor().withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(_getTypeIcon(), size: 18, color: _getTypeColor()),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getTypeColor().withOpacity(0.5),
                            AppTheme.lightGray.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: AppTheme.lightGray.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            activity.description,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Text(
                          _formatTime(activity.timestamp),
                          style: const TextStyle(color: AppTheme.gray, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Optional: Add specific details based on activity type if available in 'data'
                    if (activity.data.isNotEmpty && activity.data['amount'] != null)
                       Container(
                         margin: const EdgeInsets.only(top: 8),
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(
                           color: AppTheme.scaffoldLight,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           'Detail: ${activity.data['amount']}', // Example placeholder
                           style: const TextStyle(fontSize: 12, color: AppTheme.charcoal),
                         ),
                       ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getTypeIcon() {
    switch (activity.type) {
      case 'donation_created': return Icons.volunteer_activism_rounded;
      case 'request_created': return Icons.campaign_rounded;
      case 'donation_claimed': return Icons.handshake_rounded;
      default: return Icons.local_activity_rounded;
    }
  }
  
  Color _getTypeColor() {
    switch (activity.type) {
      case 'donation_created': return AppTheme.primaryRed;
      case 'request_created': return AppTheme.accentOrange;
      case 'donation_claimed': return AppTheme.success;
      default: return AppTheme.accentBlue;
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}';
  }
}
