import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'core/api/api_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found: $e');
  }

  // Initialize Firebase & Notifications
  try {
    await Firebase.initializeApp();
    
    // Create a temporary ProviderContainer to initialize the NotificationService
    // with the ApiClient before the app starts.
    final container = ProviderContainer();
    final apiClient = container.read(apiClientProvider);
    await NotificationService().initialize(apiClient);
  } catch (e) {
    debugPrint('Firebase/Notification initialization skipped: $e');
  }
  
  runApp(
    const ProviderScope(
      child: DaansetuApp(),
    ),
  );
}
