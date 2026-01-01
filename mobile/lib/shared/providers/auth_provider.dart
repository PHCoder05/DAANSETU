import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../core/utils/logger.dart';
import '../models/user.dart';
import '../../core/api/api_client.dart';

// Create FlutterSecureStorage with web options for proper web platform support
FlutterSecureStorage _createSecureStorage() {
  if (kIsWeb) {
    return const FlutterSecureStorage(
      webOptions: WebOptions(
        dbName: 'daansetu_db',
        publicKey: 'daansetu_public_key',
      ),
    );
  }
  return const FlutterSecureStorage();
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return _createSecureStorage();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });
  
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final FlutterSecureStorage _storage = _createSecureStorage();
  
  AuthNotifier(this._ref) : super(const AuthState());
  
  Future<void> checkAuthStatus() async {
    debugPrint('AuthNotifier: checkAuthStatus started');
    state = state.copyWith(isLoading: true);
    
    try {
      debugPrint('AuthNotifier: Reading accessToken from storage...');
      String? accessToken;
      try {
        accessToken = await _storage.read(key: AppConstants.accessTokenKey)
            .timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint('AuthNotifier: accessToken read timed out');
          return null;
        });
        debugPrint('AuthNotifier: accessToken read completed: ${accessToken != null ? "found" : "not found"}');
      } catch (e) {
        debugPrint('AuthNotifier: accessToken read failed: $e');
      }
      
      debugPrint('AuthNotifier: Reading userJson from storage...');
      String? userJson;
      try {
        userJson = await _storage.read(key: AppConstants.userKey)
            .timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint('AuthNotifier: userJson read timed out');
          return null;
        });
        debugPrint('AuthNotifier: userJson read completed: ${userJson != null ? "found" : "not found"}');
      } catch (e) {
        debugPrint('AuthNotifier: userJson read failed: $e');
      }
      
      if (accessToken != null && userJson != null) {
        debugPrint('AuthNotifier: Parsing user data...');
        final user = User.fromJson(jsonDecode(userJson));
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        debugPrint('AuthNotifier: User authenticated successfully');
      } else {
        debugPrint('AuthNotifier: No valid auth data found');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      debugPrint('AuthNotifier: checkAuthStatus error: $e');
      state = state.copyWith(isLoading: false, error: e.toString(), isAuthenticated: false);
    }
    debugPrint('AuthNotifier: checkAuthStatus completed');
  }
  
  /// Check if email exists - for unified auth flow
  Future<bool> checkEmailExists(String email) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.checkEmail(email);
      
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return data['exists'] == true;
      }
    } catch (e) {
      debugPrint('Check email error: $e');
    }
    // Default to false (new user) on error
    return false;
  }
  
  Future<bool> login(String email, String password) async {
    AppLogger.auth('Login attempt', email: email);
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.login(email, password);
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        // API response structure: {success, message, data: {user, accessToken, refreshToken}}
        final data = responseData['data'] ?? responseData;
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final userData = data['user'];
        
        // Save tokens (wrapped in try-catch for web compatibility)
        try {
          await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
          await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
          AppLogger.debug('Tokens saved to storage', 'AUTH');
        } catch (e) {
          AppLogger.warn('Storage write failed (web): $e', 'AUTH');
        }
        
        final user = User.fromJson(userData);
        AppLogger.auth('Login successful', email: email, role: user.role, success: true);
        
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        
        return true;
      } else {
        // Non-200 response handling
        final errorMessage = response.data?['message'] ?? 'Login failed';
        AppLogger.auth('Login failed: $errorMessage', email: email, success: false);
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
    } on DioException catch (e) {
      // Extract error message from API response
      String errorMessage = 'Login failed. Please try again.';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timed out. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server. Please try again.';
      }
      
      AppLogger.error('Login error: $errorMessage', 'AUTH', e);
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      AppLogger.error('Unexpected login error', 'AUTH', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
    
    return false;
  }
  
  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.register(data);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        // API response structure: {success, message, data: {user, accessToken, refreshToken}}
        final respData = responseData['data'] ?? responseData;
        final accessToken = respData['accessToken'];
        final refreshToken = respData['refreshToken'];
        final userData = respData['user'];
        
        // Save tokens (wrapped in try-catch for web compatibility)
        try {
          await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
          await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
          await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
        } catch (e) {
          debugPrint('Storage write failed (web): $e');
        }
        
        final user = User.fromJson(userData);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        
        debugPrint('Registration successful, isAuthenticated: true');
        
        return true;
      } else {
        // Non-success response handling
        final errorMessage = response.data?['message'] ?? 'Registration failed';
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
    } on DioException catch (e) {
      // Extract error message from API response
      String errorMessage = 'Registration failed. Please try again.';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timed out. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Unable to connect to server. Please try again.';
      }
      
      debugPrint('Registration error: $e');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      debugPrint('Registration error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
    
    return false;
  }
  
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        final apiClient = _ref.read(apiClientProvider);
        await apiClient.logout(refreshToken);
      }
    } catch (e) {
      // Ignore logout API errors
    } finally {
      // Clear local storage
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.userKey);
      
      state = const AuthState();
    }
  }
  
  Future<void> refreshProfile() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getProfile();
      
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
        final user = User.fromJson(userData);
        state = state.copyWith(user: user);
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
    // Persist to storage
    _storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
  }
}
