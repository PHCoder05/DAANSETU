import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _token;

  Future<void> initialize(ApiClient apiClient) async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted notification permission');
      }

      // 2. Get Token
      _token = await _fcm.getToken();
      if (_token != null) {
        if (kDebugMode) {
          print('FCM Token: $_token');
        }
        
        // 3. Register Token with Backend
        try {
          await apiClient.registerFcmToken(_token!);
        } catch (e) {
          if (kDebugMode) {
            print('Error registering FCM token: $e');
          }
        }
      }

      // 4. Handle Token Refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        _token = newToken;
        try {
          await apiClient.registerFcmToken(newToken);
        } catch (e) {
          if (kDebugMode) {
            print('Error updating FCM token: $e');
          }
        }
      });

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Foreground message received: ${message.notification?.title}');
        }
        // You can show a local notification here using flutter_local_notifications if needed
      });

      // 6. Handle Interaction
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Message opened app: ${message.data}');
        }
        // Navigate to specific screen based on message data
      });
    }
  }

  String? get token => _token;
}
