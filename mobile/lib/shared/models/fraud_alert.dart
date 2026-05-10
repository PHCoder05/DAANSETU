import 'package:flutter/material.dart';

enum FraudAlertSeverity {
  low,
  medium,
  high,
  critical;

  Color get color {
    switch (this) {
      case FraudAlertSeverity.low:
        return Colors.blue;
      case FraudAlertSeverity.medium:
        return Colors.orange;
      case FraudAlertSeverity.high:
        return Colors.red;
      case FraudAlertSeverity.critical:
        return Colors.purple;
    }
  }
}

class FraudAlert {
  final String id;
  final String? userId;
  final String? userName;
  final String type; // suspicious_login, location_mismatch, rapid_claims, etc.
  final FraudAlertSeverity severity;
  final Map<String, dynamic> details;
  final String? resourceType;
  final String? resourceId;
  final String status; // open, resolved, false_positive
  final DateTime createdAt;

  FraudAlert({
    required this.id,
    this.userId,
    this.userName,
    required this.type,
    required this.severity,
    required this.details,
    this.resourceType,
    this.resourceId,
    required this.status,
    required this.createdAt,
  });

  factory FraudAlert.fromJson(Map<String, dynamic> json) {
    return FraudAlert(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? (json['user'] != null ? json['user']['_id'] : null),
      userName: json['user'] != null ? json['user']['name'] : null,
      type: json['type'] ?? 'unusual_activity',
      severity: _parseSeverity(json['severity']),
      details: json['details'] ?? {},
      resourceType: json['resourceType'],
      resourceId: json['resourceId'],
      status: json['status'] ?? 'open',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  static FraudAlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'low':
        return FraudAlertSeverity.low;
      case 'high':
        return FraudAlertSeverity.high;
      case 'critical':
        return FraudAlertSeverity.critical;
      case 'medium':
      default:
        return FraudAlertSeverity.medium;
    }
  }

  String get typeDisplay {
    return type.replaceAll('_', ' ').toUpperCase();
  }
}
