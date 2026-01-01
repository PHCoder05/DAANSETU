import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Structured logger for DAANSETU app - similar to backend Winston logger
class AppLogger {
  static const String _appName = 'DAANSETU';
  
  // Log levels
  static const String _info = '🟢 INFO';
  static const String _warn = '🟡 WARN';
  static const String _error = '🔴 ERROR';
  static const String _debug = '🔵 DEBUG';
  static const String _success = '✅ SUCCESS';
  static const String _api = '🌐 API';
  static const String _nav = '🧭 NAV';
  static const String _auth = '🔐 AUTH';
  
  static String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
  
  static void _log(String level, String message, [String? tag, Map<String, dynamic>? data]) {
    final timestamp = _timestamp();
    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '$timestamp $level $tagStr $message';
    
    if (kDebugMode) {
      debugPrint(logMessage);
      if (data != null && data.isNotEmpty) {
        data.forEach((key, value) {
          debugPrint('    $key: $value');
        });
      }
    }
    
    // Also log to developer console for better DevTools integration
    developer.log(message, name: '$_appName${tag != null ? '.$tag' : ''}');
  }
  
  // ========== Standard Logs ==========
  
  static void info(String message, [String? tag]) {
    _log(_info, message, tag);
  }
  
  static void warn(String message, [String? tag]) {
    _log(_warn, message, tag);
  }
  
  static void error(String message, [String? tag, dynamic error, StackTrace? stackTrace]) {
    _log(_error, message, tag);
    if (error != null && kDebugMode) {
      debugPrint('    Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('    Stack: ${stackTrace.toString().split('\n').take(5).join('\n    ')}');
    }
  }
  
  static void debug(String message, [String? tag, Map<String, dynamic>? data]) {
    if (kDebugMode) {
      _log(_debug, message, tag, data);
    }
  }
  
  static void success(String message, [String? tag]) {
    _log(_success, message, tag);
  }
  
  // ========== Specialized Logs ==========
  
  /// Log API requests/responses
  static void api(String method, String url, {int? statusCode, String? response, bool isError = false}) {
    final status = statusCode != null ? '[$statusCode]' : '';
    final level = isError ? _error : (statusCode != null && statusCode >= 200 && statusCode < 300 ? _success : _api);
    _log(level, '$method $url $status', 'API');
    if (response != null && kDebugMode) {
      // Truncate long responses
      final truncated = response.length > 200 ? '${response.substring(0, 200)}...' : response;
      debugPrint('    Response: $truncated');
    }
  }
  
  /// Log navigation events
  static void nav(String action, String route, [String? from]) {
    final fromStr = from != null ? 'from $from' : '';
    _log(_nav, '$action → $route $fromStr', 'NAV');
  }
  
  /// Log authentication events
  static void auth(String action, {String? email, String? role, bool success = true}) {
    final level = success ? _success : _error;
    final details = <String>[];
    if (email != null) details.add('email: $email');
    if (role != null) details.add('role: $role');
    final detailsStr = details.isNotEmpty ? '(${details.join(', ')})' : '';
    _log(level, '$action $detailsStr', 'AUTH');
  }
  
  /// Log user actions
  static void action(String action, [Map<String, dynamic>? data]) {
    _log(_info, action, 'ACTION', data);
  }
  
  /// Log state changes
  static void state(String stateName, String oldValue, String newValue) {
    _log(_debug, '$stateName: $oldValue → $newValue', 'STATE');
  }
  
  /// Log performance metrics
  static void perf(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    final level = ms > 1000 ? _warn : _info;
    _log(level, '$operation completed in ${ms}ms', 'PERF');
  }
}

/// Extension to easily log from any class
extension LoggerExtension on Object {
  void logInfo(String message) => AppLogger.info(message, runtimeType.toString());
  void logWarn(String message) => AppLogger.warn(message, runtimeType.toString());
  void logError(String message, [dynamic error]) => AppLogger.error(message, runtimeType.toString(), error);
  void logDebug(String message, [Map<String, dynamic>? data]) => AppLogger.debug(message, runtimeType.toString(), data);
}
