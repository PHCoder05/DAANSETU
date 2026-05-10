class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? address;
  final Location? location;
  final String? profileImage;
  final bool verified;
  final bool active;
  final NgoDetails? ngoDetails;
  final DonorStats? donorStats;
  final VolunteerStats? volunteerStats;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isAvailable; // For volunteers to toggle online/offline
  final int impactScore;
  final List<Badge> badges;
  final List<String> bookmarks;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.address,
    this.location,
    this.profileImage,
    this.verified = false,
    this.active = true,
    this.ngoDetails,
    this.donorStats,
    this.volunteerStats,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable,
    this.impactScore = 0,
    this.badges = const [],
    this.bookmarks = const [],
  });
  
  bool get isDonor => role == 'donor';
  bool get isNgo => role == 'ngo';
  bool get isAdmin => role == 'admin';
  bool get isVolunteer => role == 'volunteer';
  bool get isVerifiedNgo => isNgo && (ngoDetails?.verificationStatus == 'verified');
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'donor',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      location: json['location'] != null && json['location'] is Map ? Location.fromJson(json['location']) : null,
      profileImage: json['profileImage']?.toString(),
      verified: json['verified'] == true || json['verified'] == 'true',
      active: json['active'] == true || json['active'] == 'true' || json['active'] == null,
      ngoDetails: json['ngoDetails'] != null && json['ngoDetails'] is Map ? NgoDetails.fromJson(json['ngoDetails']) : null,
      donorStats: json['donorStats'] != null && json['donorStats'] is Map ? DonorStats.fromJson(json['donorStats']) : null,
      volunteerStats: json['volunteerStats'] != null && json['volunteerStats'] is Map ? VolunteerStats.fromJson(json['volunteerStats']) : null,
      createdAt: json['createdAt'] != null ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      isAvailable: json['isAvailable'] == true || json['isAvailable'] == 'true',
      impactScore: (json['impactScore'] is int) ? json['impactScore'] : ((json['impactScore'] is double) ? (json['impactScore'] as double).toInt() : 0),
      badges: (json['badges'] != null && json['badges'] is List) ? (json['badges'] as List).map((x) => Badge.fromJson(x as Map<String, dynamic>)).toList() : [],
      bookmarks: (json['bookmarks'] != null && json['bookmarks'] is List) ? (json['bookmarks'] as List).map((e) => e.toString()).toList() : [],
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? address,
    Location? location,
    String? profileImage,
    bool? verified,
    bool? active,
    NgoDetails? ngoDetails,
    DonorStats? donorStats,
    VolunteerStats? volunteerStats,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? impactScore,
    List<Badge>? badges,
    List<String>? bookmarks,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      verified: verified ?? this.verified,
      active: active ?? this.active,
      ngoDetails: ngoDetails ?? this.ngoDetails,
      donorStats: donorStats ?? this.donorStats,
      volunteerStats: volunteerStats ?? this.volunteerStats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      impactScore: impactScore ?? this.impactScore,
      badges: badges ?? this.badges,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'address': address,
      'location': location?.toJson(),
      'profileImage': profileImage,
      'verified': verified,
      'active': active,
      'ngoDetails': ngoDetails?.toJson(),
      'donorStats': donorStats?.toJson(),
      'volunteerStats': volunteerStats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isAvailable': isAvailable,
      'impactScore': impactScore,
      'badges': badges.map((e) => e.toJson()).toList(),
      'bookmarks': bookmarks,
    };
  }
}

class Location {
  final double lat;
  final double lng;
  final String? address;
  
  Location({
    required this.lat,
    required this.lng,
    this.address,
  });
  
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      address: json['address'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}

class NgoDetails {
  final String? registrationNumber;
  final String? description;
  final String? website;
  final List<String> documents;
  final String verificationStatus;
  final List<String> categories;
  final int? establishedYear;
  
  NgoDetails({
    this.registrationNumber,
    this.description,
    this.website,
    this.documents = const [],
    this.verificationStatus = 'pending',
    this.categories = const [],
    this.establishedYear,
  });
  
  factory NgoDetails.fromJson(Map<String, dynamic> json) {
    int? parseIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }
    
    return NgoDetails(
      registrationNumber: json['registrationNumber']?.toString(),
      description: json['description']?.toString(),
      website: json['website']?.toString(),
      documents: List<String>.from((json['documents'] ?? []).map((e) => e.toString())),
      verificationStatus: json['verificationStatus']?.toString() ?? 'pending',
      categories: List<String>.from((json['categories'] ?? []).map((e) => e.toString())),
      establishedYear: parseIntSafe(json['establishedYear']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'registrationNumber': registrationNumber,
      'description': description,
      'website': website,
      'documents': documents,
      'verificationStatus': verificationStatus,
      'categories': categories,
      'establishedYear': establishedYear,
    };
  }
}

class DonorStats {
  final int totalDonations;
  final int activeDonations;
  final int completedDonations;
  
  DonorStats({
    this.totalDonations = 0,
    this.activeDonations = 0,
    this.completedDonations = 0,
  });
  
  factory DonorStats.fromJson(Map<String, dynamic> json) {
    int parseIntSafe(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      if (value is Map) {
        final incValue = value[r'$inc'] ?? value['\$inc'];
        if (incValue != null) {
          if (incValue is int) return incValue;
          if (incValue is String) return int.tryParse(incValue) ?? defaultValue;
          if (incValue is double) return incValue.toInt();
        }
        return defaultValue;
      }
      return defaultValue;
    }
    
    return DonorStats(
      totalDonations: parseIntSafe(json['totalDonations']),
      activeDonations: parseIntSafe(json['activeDonations']),
      completedDonations: parseIntSafe(json['completedDonations']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'totalDonations': totalDonations,
      'activeDonations': activeDonations,
      'completedDonations': completedDonations,
    };
  }
}

class VolunteerStats {
  final int totalDeliveries;
  final int totalPoints;
  final double rating;
  final int reliabilityScore;

  VolunteerStats({
    this.totalDeliveries = 0,
    this.totalPoints = 0,
    this.rating = 0.0,
    this.reliabilityScore = 100,
  });

  factory VolunteerStats.fromJson(Map<String, dynamic> json) {
    return VolunteerStats(
      totalDeliveries: json['pickupsCompleted'] ?? json['totalDeliveries'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reliabilityScore: json['reliabilityScore'] ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDeliveries': totalDeliveries,
      'totalPoints': totalPoints,
      'rating': rating,
      'reliabilityScore': reliabilityScore,
    };
  }
}

class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final DateTime awardedAt;

  Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.awardedAt
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      awardedAt: json['awardedAt'] != null ? DateTime.tryParse(json['awardedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'awardedAt': awardedAt.toIso8601String(),
    };
  }
}
