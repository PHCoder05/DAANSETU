import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Donation Category with all associated metadata
class DonationCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  
  const DonationCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Application-wide constants
class AppConstants {
  // API Configuration
  // API Version - update when migrating to new API versions
  static const String apiVersion = 'v1';
  
  // Base server URL from environment
  static String get _baseServerUrl {
    // For web, use relative path or env variable
    // For mobile, always use env variable
    return dotenv.env['API_BASE_URL'] ?? 
           dotenv.env['API_URL']?.replaceAll('/api', '') ?? 
           (kIsWeb ? '' : 'https://api-daansetu.onrender.com');
  }
  
  // API URL with version
  static String get apiBaseUrl => '$_baseServerUrl/api/$apiVersion';
  
  // Socket URL (same as base server)
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? _baseServerUrl;
  
  // Health check URL
  static String get healthUrl => '$_baseServerUrl/health/ready';
  
  // Token Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  
  // ========== DONATION CATEGORIES ==========
  // Single source of truth for all category data
  static const List<DonationCategory> categories = [
    DonationCategory(
      id: 'all',
      label: 'All',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFE23744), // primaryRed
    ),
    DonationCategory(
      id: 'food',
      label: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE23744),
    ),
    DonationCategory(
      id: 'clothes',
      label: 'Clothes',
      icon: Icons.checkroom_rounded,
      color: Color(0xFF9B59B6),
    ),
    DonationCategory(
      id: 'books',
      label: 'Books',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF3498DB),
    ),
    DonationCategory(
      id: 'medical',
      label: 'Medical',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF1ABC9C),
    ),
    DonationCategory(
      id: 'electronics',
      label: 'Electronics',
      icon: Icons.devices_rounded,
      color: Color(0xFFE67E22),
    ),
    DonationCategory(
      id: 'furniture',
      label: 'Furniture',
      icon: Icons.chair_rounded,
      color: Color(0xFF795548),
    ),
    DonationCategory(
      id: 'other',
      label: 'Other',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF607D8B),
    ),
  ];
  
  // Helper: Get category IDs only (for dropdowns, validation)
  static List<String> get donationCategories => 
      categories.where((c) => c.id != 'all').map((c) => c.id).toList();
  
  // Helper: Get category by ID
  static DonationCategory? getCategoryById(String id) =>
      categories.where((c) => c.id == id).firstOrNull;
  
  // Helper: Get color by category ID
  static Color getCategoryColor(String id) =>
      getCategoryById(id)?.color ?? const Color(0xFF607D8B);
  
  // Helper: Get icon by category ID
  static IconData getCategoryIcon(String id) =>
      getCategoryById(id)?.icon ?? Icons.inventory_2_rounded;
  
  // Donation Conditions
  static const List<String> donationConditions = [
    'new',
    'good',
    'fair',
    'used',
  ];
  
  // Priority Levels
  static const List<String> priorityLevels = [
    'low',
    'normal',
    'high',
    'urgent',
  ];
  
  // Donation Status
  static const List<String> donationStatuses = [
    'available',
    'claimed',
    'in-transit',
    'delivered',
    'cancelled',
  ];
  
  // User Roles
  static const String roleDonor = 'donor';
  static const String roleNgo = 'ngo';
  static const String roleVolunteer = 'volunteer';
  static const String roleAdmin = 'admin';
  
  // ========== LOADING QUOTES (Zomato-style) ==========
  static const List<String> loadingQuotes = [
    '"No one has ever become poor by giving." – Anne Frank',
    '"The meaning of life is to find your gift. The purpose of life is to give it away."',
    '"We make a living by what we get, but we make a life by what we give."',
    '"Giving is not just about making a donation. It\'s about making a difference."',
    '"The best way to find yourself is to lose yourself in the service of others." – Gandhi',
    '"A single act of kindness throws out roots in all directions."',
    '"Generosity is the most natural outward expression of an inner attitude of compassion."',
    '"The simplest acts of kindness are by far more powerful than a thousand heads bowing in prayer."',
    '"Remember that the happiest people are not those getting more, but those giving more."',
    '"We rise by lifting others." – Robert Ingersoll',
  ];
  
  // Helper: Get random quote
  static String getRandomQuote() {
    final index = (DateTime.now().millisecondsSinceEpoch ~/ 3000) % loadingQuotes.length;
    return loadingQuotes[index];
  }
}
