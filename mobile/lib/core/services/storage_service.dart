import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local storage service for caching and offline support
class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ═══════════════════════════════════════════════════════════════════
  // String operations
  // ═══════════════════════════════════════════════════════════════════
  
  static Future<bool> setString(String key, String value) async {
    return _instance.setString(key, value);
  }

  static String? getString(String key) {
    return _instance.getString(key);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Bool operations
  // ═══════════════════════════════════════════════════════════════════
  
  static Future<bool> setBool(String key, bool value) async {
    return _instance.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _instance.getBool(key);
  }

  // ═══════════════════════════════════════════════════════════════════
  // JSON operations
  // ═══════════════════════════════════════════════════════════════════
  
  static Future<bool> setJson(String key, Map<String, dynamic> json) async {
    return _instance.setString(key, jsonEncode(json));
  }

  static Map<String, dynamic>? getJson(String key) {
    final str = _instance.getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // List operations
  // ═══════════════════════════════════════════════════════════════════
  
  static Future<bool> setStringList(String key, List<String> list) async {
    return _instance.setStringList(key, list);
  }

  static List<String>? getStringList(String key) {
    return _instance.getStringList(key);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Delete operations
  // ═══════════════════════════════════════════════════════════════════
  
  static Future<bool> remove(String key) async {
    return _instance.remove(key);
  }

  static Future<bool> clear() async {
    return _instance.clear();
  }

  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }
}

/// Storage keys for consistency
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String user = 'user_data';
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode';
  static const String recentSearches = 'recent_searches';
  static const String cachedDonations = 'cached_donations';
  static const String lastSync = 'last_sync';
}

/// Recent searches manager
class RecentSearchesManager {
  static const int maxRecentSearches = 10;

  static List<String> getRecentSearches() {
    return StorageService.getStringList(StorageKeys.recentSearches) ?? [];
  }

  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final searches = getRecentSearches();
    searches.remove(query); // Remove if exists
    searches.insert(0, query); // Add to front
    
    // Keep only last N searches
    final trimmed = searches.take(maxRecentSearches).toList();
    await StorageService.setStringList(StorageKeys.recentSearches, trimmed);
  }

  static Future<void> removeSearch(String query) async {
    final searches = getRecentSearches();
    searches.remove(query);
    await StorageService.setStringList(StorageKeys.recentSearches, searches);
  }

  static Future<void> clearSearches() async {
    await StorageService.remove(StorageKeys.recentSearches);
  }
}
