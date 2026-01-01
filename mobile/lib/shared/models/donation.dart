import 'user.dart';

class Donation {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final String category;
  final int? quantity;
  final String? unit;
  final List<String> images;
  final String condition;
  final DateTime? expiryDate;
  final Location pickupLocation;
  final String? pickupInstructions;
  final String status;
  final String? claimedBy;
  final DateTime? claimedAt;
  final String? deliveryStatus;
  final DateTime? deliveryDate;
  final String? deliveryNotes;
  final List<String> deliveryImages;
  final String priority;
  final List<String> tags;
  final bool active;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related data from aggregation
  final User? donor;
  final User? ngo;
  
  Donation({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.category,
    this.quantity,
    this.unit,
    this.images = const [],
    this.condition = 'good',
    this.expiryDate,
    required this.pickupLocation,
    this.pickupInstructions,
    this.status = 'available',
    this.claimedBy,
    this.claimedAt,
    this.deliveryStatus,
    this.deliveryDate,
    this.deliveryNotes,
    this.deliveryImages = const [],
    this.priority = 'normal',
    this.tags = const [],
    this.active = true,
    this.views = 0,
    required this.createdAt,
    required this.updatedAt,
    this.donor,
    this.ngo,
  });
  
  bool get isAvailable => status == 'available';
  bool get isClaimed => status == 'claimed';
  bool get isInTransit => status == 'in-transit';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high' || priority == 'urgent';
  
  String get statusDisplay {
    switch (status) {
      case 'available':
        return 'Available';
      case 'claimed':
        return 'Claimed';
      case 'in-transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
  
  String get priorityDisplay {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High';
      case 'urgent':
        return '🔥 Urgent';
      default:
        return priority;
    }
  }
  
  factory Donation.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int values
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }
    
    return Donation(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      donorId: json['donorId'] is Map ? (json['donorId']['_id']?.toString() ?? '') : (json['donorId']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      quantity: parseIntSafe(json['quantity']),
      unit: json['unit']?.toString(),
      images: List<String>.from((json['images'] ?? []).map((e) => e.toString())),
      condition: json['condition']?.toString() ?? 'good',
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null,
      pickupLocation: json['pickupLocation'] != null 
          ? Location.fromJson(json['pickupLocation']) 
          : Location(lat: 0, lng: 0),
      pickupInstructions: json['pickupInstructions']?.toString(),
      status: json['status']?.toString() ?? 'available',
      claimedBy: json['claimedBy'] is Map ? json['claimedBy']['_id']?.toString() : json['claimedBy']?.toString(),
      claimedAt: json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'].toString()) : null,
      deliveryStatus: json['deliveryStatus']?.toString(),
      deliveryDate: json['deliveryDate'] != null ? DateTime.tryParse(json['deliveryDate'].toString()) : null,
      deliveryNotes: json['deliveryNotes']?.toString(),
      deliveryImages: List<String>.from((json['deliveryImages'] ?? []).map((e) => e.toString())),
      priority: json['priority']?.toString() ?? 'normal',
      tags: List<String>.from((json['tags'] ?? []).map((e) => e.toString())),
      active: json['active'] == true || json['active'] == 'true',
      views: parseIntSafe(json['views']) ?? 0,
      createdAt: json['createdAt'] != null ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      donor: json['donor'] != null && json['donor'] is Map ? User.fromJson(json['donor']) : null,
      ngo: json['ngo'] != null && json['ngo'] is Map ? User.fromJson(json['ngo']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'images': images,
      'condition': condition,
      'expiryDate': expiryDate?.toIso8601String(),
      'pickupLocation': pickupLocation.toJson(),
      'pickupInstructions': pickupInstructions,
      'priority': priority,
      'tags': tags,
    };
  }
}
