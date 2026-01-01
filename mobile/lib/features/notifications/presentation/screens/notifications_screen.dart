import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;
  
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });
  
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      read: json['read'] == true || json['read'] == 'true',
      createdAt: json['createdAt'] != null 
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()) 
          : DateTime.now(),
    );
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.getNotifications();
    
    if (response.statusCode == 200) {
      final data = response.data;
      List<dynamic>? notificationsList;
      
      if (data['data'] != null && data['data']['notifications'] != null) {
        notificationsList = data['data']['notifications'] as List;
      } else if (data['notifications'] != null) {
        notificationsList = data['notifications'] as List;
      } else if (data['data'] != null && data['data'] is List) {
        notificationsList = data['data'] as List;
      }
      
      if (notificationsList != null) {
        final notifications = notificationsList
            .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
            .toList();
        // Sort by date desc
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      }
    }
  } catch (e) {
    debugPrint('Error loading notifications: $e');
  }
  
  return [];
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              // Mark all read logic
              HapticFeedback.lightImpact();
              final apiClient = ref.read(apiClientProvider);
              await apiClient.markAllAsRead();
              ref.refresh(notificationsProvider);
            },
            icon: const Icon(Icons.done_all_rounded, color: AppTheme.primaryRed),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryRed),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text('Failed to load notifications'),
              TextButton(
                onPressed: () => ref.refresh(notificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }
          
          final grouped = _groupNotifications(notifications);
          
          return RefreshIndicator(
            color: AppTheme.primaryRed,
            onRefresh: () async => ref.refresh(notificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final groupName = grouped.keys.elementAt(index);
                final groupItems = grouped[groupName]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        groupName.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.gray,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...groupItems.map((notification) => _NotificationTile(
                      notification: notification,
                      onTap: () async {
                         if (!notification.read) {
                            final apiClient = ref.read(apiClientProvider);
                            await apiClient.markAsRead(notification.id);
                            ref.refresh(notificationsProvider);
                         }
                      },
                    )),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.gray.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll let you know when there's\nan update on your donations.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gray, height: 1.5),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Map<String, List<AppNotification>> _groupNotifications(List<AppNotification> notifications) {
    final Map<String, List<AppNotification>> grouped = {};
    final now = DateTime.now();
    
    for (var notification in notifications) {
      final date = notification.createdAt;
      String key;
      
      final diff = now.difference(date);
      
      if (diff.inDays == 0 && date.day == now.day) {
        key = 'Today';
      } else if (diff.inDays <= 1 && date.day == now.day - 1) {
        key = 'Yesterday';
      } else {
        key = 'Earlier';
      }
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(notification);
    }
    return grouped;
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.read ? AppTheme.white : AppTheme.primaryRed.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.read ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          color: AppTheme.gray,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'donation': return Icons.volunteer_activism_rounded;
      case 'request': return Icons.mail_rounded;
      case 'claim': return Icons.handshake_rounded;
      case 'delivery': return Icons.local_shipping_rounded;
      case 'verification': return Icons.verified_rounded;
      default: return Icons.notifications_rounded;
    }
  }
  
  Color _getTypeColor(String type) {
    switch (type) {
      case 'donation': return AppTheme.primaryRed;
      case 'verification': return AppTheme.success;
      case 'delivery': return AppTheme.info;
      default: return AppTheme.accentOrange;
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat.jm().format(date); // Requires intl package, or write helper
  }
}
