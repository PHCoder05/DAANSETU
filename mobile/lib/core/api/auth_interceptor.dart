import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

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

class AuthInterceptor extends Interceptor {

  final FlutterSecureStorage _storage = _createSecureStorage();
  
  AuthInterceptor();
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for public endpoints
    final publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/password-reset/request',
      '/password-reset/verify',
      '/password-reset/reset',
      '/setup/check',
    ];
    
    final isPublic = publicEndpoints.any((e) => options.path.contains(e));
    
    if (!isPublic) {
      debugPrint('AuthInterceptor: Checking token for ${options.path}');
      final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
      debugPrint('AuthInterceptor: Token found? ${accessToken != null}');
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      } else {
        debugPrint('AuthInterceptor: WARNING - No access token found for authenticated endpoint');
      }
    } else {
      debugPrint('AuthInterceptor: Skipping auth for public endpoint ${options.path}');
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('🔴 API Error: ${err.requestOptions.path} - ${err.message}');
    if (err.response != null) {
      debugPrint('Response: ${err.response?.data}');
    }

    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      
      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
          final response = await dio.post('/auth/refresh', data: {
            'refreshToken': refreshToken,
          },);
          
          if (response.statusCode == 200) {
            final newAccessToken = response.data['accessToken'];
            final newRefreshToken = response.data['refreshToken'];
            
            // Save new tokens
            await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
            await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);
            
            // Retry original request
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          // Refresh failed, clear tokens and redirect to login
          await _storage.delete(key: AppConstants.accessTokenKey);
          await _storage.delete(key: AppConstants.refreshTokenKey);
          await _storage.delete(key: AppConstants.userKey);
        }
      }
    }
    
    handler.next(err);
  }
}
