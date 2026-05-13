import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/constants.dart';
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  
  // Add auth interceptor
  dio.interceptors.add(AuthInterceptor());
  
  // Add logging interceptor in debug mode
  dio.interceptors.add(LogInterceptor(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
  ),);
  
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class ApiClient {
  final Dio _dio;
  
  ApiClient(this._dio);
  
  // Auth endpoints
  
  /// Check if email exists - for unified auth flow
  Future<Response> checkEmail(String email) async {
    return _dio.get('/auth/check-email', queryParameters: {'email': email});
  }
  
  Future<Response> register(Map<String, dynamic> data) async {
    return _dio.post('/auth/register', data: data);
  }
  
  Future<Response> login(String email, String password) async {
    return _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    },);
  }
  
  Future<Response> refreshToken(String refreshToken) async {
    return _dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    },);
  }
  
  Future<Response> logout(String refreshToken) async {
    return _dio.post('/auth/logout', data: {
      'refreshToken': refreshToken,
    },);
  }
  
  Future<Response> getProfile() async {
    return _dio.get('/auth/profile');
  }
  
  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return _dio.put('/auth/profile', data: data);
  }
  
  Future<Response> changePassword(String currentPassword, String newPassword) async {
    return _dio.put('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },);
  }

  Future<Response> uploadProfileImage(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    
    return _dio.post('/auth/profile/image', data: formData);
  }
  
  // Password Reset
  Future<Response> requestPasswordReset(String email) async {
    return _dio.post('/password-reset/request', data: {'email': email});
  }
  
  Future<Response> resetPassword(String token, String password) async {
    return _dio.post('/password-reset/reset', data: {
      'token': token,
      'newPassword': password,
    },);
  }

  Future<Response> verifyResetToken(String token) async {
    return _dio.get('/password-reset/verify', queryParameters: {'token': token});
  }
  
  // Donations endpoints
  Future<Response> getDonations({
    int page = 1,
    int limit = 10,
    String? category,
    String? status,
    String? search,
    bool myDonations = false,
    bool saved = false,
    double? lat,
    double? lng,
    double? radius,
  }) async {
    return _dio.get('/donations', queryParameters: {
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (search != null) 'search': search,
      if (myDonations) 'myDonations': 'true',
      if (saved) 'saved': 'true',
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radius != null) 'radius': radius,
    },);
  }
  
  Future<Response> getNearbyDonations({
    required double lat,
    required double lng,
    double maxDistance = 50,
  }) async {
    return _dio.get('/donations/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'maxDistance': maxDistance,
    },);
  }
  
  Future<Response> getDonation(String id) async {
    return _dio.get('/donations/$id');
  }
  
  Future<Response> createDonation(Map<String, dynamic> data) async {
    return _dio.post('/donations', data: data);
  }
  
  Future<Response> updateDonation(String id, Map<String, dynamic> data) async {
    return _dio.put('/donations/$id', data: data);
  }
  
  Future<Response> deleteDonation(String id) async {
    return _dio.delete('/donations/$id');
  }
  
  Future<Response> claimDonation(String id) async {
    return _dio.post('/donations/$id/claim');
  }
  
  Future<Response> updateDonationStatus(String id, String status) async {
    return _dio.put('/donations/$id/status', data: {'status': status});
  }

  Future<Response> downloadDonationReceipt(String id, String savePath) async {
    return _dio.download('/donations/$id/receipt', savePath);
  }
  
  // Bookmark
  Future<Response> toggleBookmark(String donationId) async {
    return _dio.post('/auth/bookmark', data: {'donationId': donationId});
  }
  
  // Notifications
  Future<Response> registerFcmToken(String token) async {
    return _dio.post('/notifications/tokens', data: {'token': token});
  }

  Future<Response> unregisterFcmToken(String token) async {
    return _dio.delete('/notifications/tokens', data: {'token': token});
  }

  // NGO endpoints
  Future<Response> getNgos({int page = 1, int limit = 10}) async {
    return _dio.get('/ngos', queryParameters: {
      'page': page,
      'limit': limit,
    },);
  }
  
  Future<Response> getNgo(String id) async {
    return _dio.get('/ngos/$id');
  }
  
  Future<Response> getRequests({int page = 1, int limit = 10}) async {
    return _dio.get('/ngos/requests/list', queryParameters: {
      'page': page,
      'limit': limit,
    },);
  }
  
  Future<Response> createRequest(Map<String, dynamic> data) async {
    return _dio.post('/ngos/requests', data: data);
  }
  
  Future<Response> updateRequestStatus(String id, String status, {String? response}) async {
    return _dio.put('/ngos/requests/$id/status', data: {
      'status': status,
      if (response != null) 'response': response,
    },);
  }
  
  // Notifications endpoints
  Future<Response> getNotifications({int page = 1, int limit = 20}) async {
    return _dio.get('/notifications', queryParameters: {
      'page': page,
      'limit': limit,
    },);
  }
  
  Future<Response> getUnreadCount() async {
    return _dio.get('/notifications/unread-count');
  }
  
  Future<Response> markAsRead(String id) async {
    return _dio.put('/notifications/$id/read');
  }
  
  Future<Response> markAllAsRead() async {
    return _dio.put('/notifications/read-all');
  }
  
  // Reviews endpoints
  Future<Response> createReview(Map<String, dynamic> data) async {
    return _dio.post('/reviews', data: data);
  }
  
  Future<Response> getNgoReviews(String ngoId, {int page = 1, int limit = 10}) async {
    return _dio.get('/reviews/ngo/$ngoId', queryParameters: {
      'page': page,
      'limit': limit,
    },);
  }

  Future<Response> respondToReview(String reviewId, String response) async {
    return _dio.put('/reviews/$reviewId/respond', data: {'response': response});
  }

  Future<Response> createVolunteerReview(Map<String, dynamic> data) async {
    return _dio.post('/reviews/volunteer', data: data);
  }

  Future<Response> getVolunteerReviews(String volunteerId, {int page = 1, int limit = 10}) async {
    return _dio.get('/reviews/volunteer/$volunteerId', queryParameters: {
      'page': page,
      'limit': limit,
    },);
  }
  
  // Dashboard endpoints
  Future<Response> getDashboard() async {
    return _dio.get('/dashboard');
  }
  
  Future<Response> getActivity({int page = 1, int limit = 20}) async {
    return _dio.get('/dashboard/activity', queryParameters: {
      'page': page,
      'limit': limit,
    },);
  }
  
  Future<Response> getLeaderboard({String type = 'donors'}) async {
    return _dio.get('/dashboard/leaderboard', queryParameters: {'type': type});
  }
  
  // Search endpoints
  Future<Response> searchDonations(Map<String, dynamic> params) async {
    return _dio.get('/search/donations', queryParameters: params);
  }
  
  Future<Response> searchNgos(Map<String, dynamic> params) async {
    return _dio.get('/search/ngos', queryParameters: params);
  }
  
  Future<Response> getCategories() async {
    return _dio.get('/search/categories');
  }
  
  // Admin endpoints
  Future<Response> getAdminStats() async {
    return _dio.get('/admin/stats');
  }
  
  Future<Response> getUsers({int page = 1, int limit = 20}) async {
    return _dio.get('/admin/users', queryParameters: {
      'page': page,
      'limit': limit,
    },);
  }
  
  Future<Response> getPendingNgos() async {
    return _dio.get('/admin/ngos/pending');
  }
  
  Future<Response> verifyNgo(String userId, String status) async {
    return _dio.put('/admin/ngos/$userId/verify', data: {'status': status});
  }

  Future<Response> verifyNgoGovApi(String userId) async {
    return _dio.post('/admin/ngos/$userId/verify-gov');
  }

  Future<Response> getPendingVolunteers() async {
    return _dio.get('/admin/volunteers/pending');
  }
  
  Future<Response> verifyVolunteer(String userId, String status) async {
    return _dio.put('/admin/volunteers/$userId/verify', data: {'status': status});
  }
  
  Future<Response> toggleUserStatus(String userId) async {
    return _dio.put('/admin/users/$userId/toggle-status');
  }

  /// Get all support requests for admin
  Future<Response> getAllSupportRequests() async {
    return _dio.get('/verification/support/all');
  }

  /// Respond to support request as admin
  Future<Response> respondToSupport(String id, String response, String status) async {
    return _dio.post('/verification/support/$id/respond', data: {
      'response': response,
      'status': status,
    });
  }

  /// Get active volunteers for admin map
  Future<Response> getActiveVolunteers() async {
    return _dio.get('/admin/volunteers/active');
  }
  
  // Chat endpoints
  Future<Response> getChatHistory(String recipientId) async {
    return _dio.get('/chat/history/$recipientId');
  }
  
  Future<Response> getConversations() async {
    return _dio.get('/chat/conversations');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Health & Status endpoints
  // ═══════════════════════════════════════════════════════════════════
  
  /// Check API health status (liveness)
  Future<Response> checkHealth() async {
    return _dio.get('/health');
  }
  
  /// Deep health check (readiness with DB status)
  Future<Response> checkReadiness() async {
    return _dio.get('/health/ready');
  }
  
  /// Get API version info
  Future<Response> getApiInfo() async {
    // Use base URL without /v1 to get root info
    final baseUrl = _dio.options.baseUrl.replaceAll('/v1', '');
    return _dio.get('$baseUrl/');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Chat endpoints
  // ═══════════════════════════════════════════════════════════════════
  
  /// Mark chat messages from a user as read
  Future<Response> markChatAsRead(String recipientId, {String? donationId}) async {
    final queryParams = donationId != null ? {'donationId': donationId} : null;
    return _dio.put('/chat/read/$recipientId', queryParameters: queryParams);
  }
  
  /// Get chat history for a specific donation
  Future<Response> getChatByDonation(String donationId, String recipientId) async {
    return _dio.get('/chat/donation/$donationId/$recipientId');
  }
  
  /// Get conversations grouped by donation
  Future<Response> getConversationsByDonation() async {
    return _dio.get('/chat/conversations/by-donation');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Donation History endpoints
  // ═══════════════════════════════════════════════════════════════════
  
  /// Get my donations (as donor or NGO)
  Future<Response> getMyDonations({String type = 'all', String? role}) async {
    return _dio.get('/donations/my', queryParameters: {
      'type': type,
      if (role != null) 'role': role,
    },);
  }
  
  /// Get donation timeline (status history)
  Future<Response> getDonationTimeline(String donationId) async {
    return _dio.get('/donations/$donationId/timeline');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Delivery Tracking endpoints
  // ═══════════════════════════════════════════════════════════════════
  
  /// Get tracking status for a donation
  Future<Response> getDeliveryTracking(String donationId) async {
    return _dio.get('/delivery/$donationId');
  }
  
  /// Initialize delivery tracking (NGO)
  Future<Response> initializeTracking(String donationId, {DateTime? scheduledPickup}) async {
    return _dio.post('/delivery/$donationId/initialize', data: {
      if (scheduledPickup != null) 'scheduledPickupTime': scheduledPickup.toIso8601String(),
    },);
  }
  
  /// Mark donation as picked up
  Future<Response> markPickedUp(String donationId, {String? photo, String? signature, Map<String, double>? location, String? qrCode}) async {
    return _dio.post('/delivery/$donationId/pickup', data: {
      if (photo != null) 'photo': photo,
      if (signature != null) 'signature': signature,
      if (location != null) 'location': location,
      if (qrCode != null) 'qrCode': qrCode,
    },);
  }
  
  /// Update GPS location during transit
  Future<Response> updateDeliveryLocation(String donationId, double lat, double lng) async {
    return _dio.post('/delivery/$donationId/location', data: {'lat': lat, 'lng': lng});
  }
  
  /// Mark donation as delivered
  Future<Response> markDelivered(String donationId, {String? photo, String? signature, Map<String, double>? location, String? qrCode}) async {
    return _dio.post('/delivery/$donationId/deliver', data: {
      if (photo != null) 'photo': photo,
      if (signature != null) 'signature': signature,
      if (location != null) 'location': location,
      if (qrCode != null) 'qrCode': qrCode,
    },);
  }

  /// Report emergency (SOS)
  Future<Response> reportSOS(String donationId, {Map<String, double>? location, String? message}) async {
    return _dio.post('/delivery/$donationId/sos', data: {
      if (location != null) 'location': location,
      if (message != null) 'message': message,
    },);
  }
  
  /// Donor confirms delivery
  Future<Response> confirmDelivery(String donationId) async {
    return _dio.post('/delivery/$donationId/confirm');
  }
  
  /// Get active deliveries for NGO
  Future<Response> getActiveDeliveries() async {
    return _dio.get('/delivery/active/list');
  }
  
  /// Get location history for delivery
  Future<Response> getDeliveryLocationHistory(String donationId) async {
    return _dio.get('/delivery/$donationId/history');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Audit/Activity Log endpoints
  // ═══════════════════════════════════════════════════════════════════
  
  /// Get my activity log
  Future<Response> getMyActivityLog({int limit = 50, String? action, String? resource}) async {
    return _dio.get('/audit/my', queryParameters: {
      'limit': limit,
      if (action != null) 'action': action,
      if (resource != null) 'resource': resource,
    },);
  }
  
  /// Get activity summary for dashboard
  Future<Response> getActivitySummary() async {
    return _dio.get('/audit/summary');
  }
  
  /// Get audit trail for a donation
  Future<Response> getDonationAuditTrail(String donationId) async {
    return _dio.get('/audit/donation/$donationId');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Verification endpoints
  // ═══════════════════════════════════════════════════════════════════
  
  /// Request verification (auto-verifies NGO via govt APIs)
  Future<Response> requestVerification(String type, {
    List<String>? documents, 
    String? documentType, 
    String? documentNumber,
    String? darpanId,
    String? pan,
    String? cin,
  }) async {
    return _dio.post('/verification/request', data: {
      'type': type,
      if (documents != null) 'documents': documents,
      if (documentType != null) 'documentType': documentType,
      if (documentNumber != null) 'documentNumber': documentNumber,
      if (darpanId != null) 'darpanId': darpanId,
      if (pan != null) 'pan': pan,
      if (cin != null) 'cin': cin,
    },);
  }
  
  /// Auto-verify NGO using government databases
  Future<Response> autoVerifyNgo({String? darpanId, String? pan, String? cin, String? registrationNumber}) async {
    return _dio.post('/verification/ngo/auto-verify', data: {
      if (darpanId != null) 'darpanId': darpanId,
      if (pan != null) 'pan': pan,
      if (cin != null) 'cin': cin,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
    },);
  }
  
  /// Verify NGO using Darpan ID only
  Future<Response> verifyDarpanId(String darpanId) async {
    return _dio.post('/verification/ngo/darpan', data: {'darpanId': darpanId});
  }
  
  /// Verify 80G certificate using PAN
  Future<Response> verify80G(String pan) async {
    return _dio.post('/verification/ngo/80g', data: {'pan': pan});
  }
  
  /// Get verification steps progress (for NGO to see their verification journey)
  Future<Response> getVerificationSteps({String type = 'ngo_registration'}) async {
    return _dio.get('/verification/steps', queryParameters: {'type': type});
  }
  
  /// Get my verification status
  Future<Response> getVerificationStatus() async {
    return _dio.get('/verification/status');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Support Request endpoints (Contact Admin)
  // ═══════════════════════════════════════════════════════════════════
  
  /// Request support / contact admin for verification issues
  Future<Response> requestSupport({
    String? verificationId,
    required String issue,
    required String message,
    String? contactEmail,
    String? contactPhone,
  }) async {
    return _dio.post('/verification/support/request', data: {
      if (verificationId != null) 'verificationId': verificationId,
      'issue': issue,
      'message': message,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
    },);
  }
  
  /// Get my support requests
  Future<Response> getMySupportRequests() async {
    return _dio.get('/verification/support/my');
  }
  
  // ═══════════════════════════════════════════════════════════════════
  // Email Verification endpoints
  // ═══════════════════════════════════════════════════════════════════
  
  /// Send email verification link
  Future<Response> sendVerificationEmail() async {
    return _dio.post('/auth/send-verification');
  }
  
  /// Verify email with token
  Future<Response> verifyEmail(String token) async {
    return _dio.post('/auth/verify-email', data: {'token': token});
  }

  // ═══════════════════════════════════════════════════════════════════
  // NGO Inventory endpoints
  // ═══════════════════════════════════════════════════════════════════

  /// Get NGO's current inventory
  Future<Response> getInventory() async {
    return _dio.get('/ngo/inventory');
  }

  /// Distribute inventory item to beneficiaries
  Future<Response> distributeItem(String id, Map<String, dynamic> data) async {
    return _dio.post('/ngo/inventory/$id/distribute', data: data);
  }

  /// Update inventory item status
  Future<Response> updateInventoryStatus(String id, String status) async {
    return _dio.put('/ngo/inventory/$id/status', data: {'status': status});
  }

  // ═══════════════════════════════════════════════════════════════════
  // Fraud Alert endpoints (Admin only)
  // ═══════════════════════════════════════════════════════════════════

  /// Get all fraud alerts
  Future<Response> getFraudAlerts({String? severity, String? status}) async {
    return _dio.get('/verification/fraud-alerts', queryParameters: {
      if (severity != null) 'severity': severity,
      if (status != null) 'status': status,
    },);
  }

  /// Resolve a fraud alert
  Future<Response> resolveFraudAlert(String id, {required String resolution, bool isFalsePositive = false}) async {
    return _dio.post('/verification/fraud-alerts/$id/resolve', data: {
      'resolution': resolution,
      'isFalsePositive': isFalsePositive,
    },);
  }

  // AI endpoints
  Future<Response> analyzeImage(String base64Image) async {
    return _dio.post('/ai/analyze', data: {'image': base64Image});
  }

  Future<Response> voiceSearch(String query) async {
    return _dio.post('/ai/voice-search', data: {'query': query});
  }

  Future<Response> voiceForm(String query) async {
    return _dio.post('/ai/voice-form', data: {'query': query});
  }

  Future<Response> aiChat(String message, {List<Map<String, dynamic>>? history}) async {
    return _dio.post('/ai/chat', data: {
      'message': message,
      if (history != null) 'history': history,
    },);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Impact Stories endpoints
  // ═══════════════════════════════════════════════════════════════════

  Future<Response> getImpactStories({int page = 1, int limit = 20, String? category}) async {
    return _dio.get('/stories', queryParameters: {
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
    },);
  }

  Future<Response> createImpactStory(Map<String, dynamic> data) async {
    return _dio.post('/stories', data: data);
  }

  Future<Response> toggleStoryLike(String storyId) async {
    return _dio.post('/stories/$storyId/like');
  }

  Future<Response> addStoryComment(String storyId, String text) async {
    return _dio.post('/stories/$storyId/comment', data: {'text': text});
  }

  // ═══════════════════════════════════════════════════════════════════
  // AI Recommendation endpoints
  // ═══════════════════════════════════════════════════════════════════

  Future<Response> getRecommendedNgos(String category, {double? lat, double? lng}) async {
    return _dio.post('/ai/match', data: {
      'category': category,
      'lat': lat,
      'lng': lng,
    },);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Gamification endpoints
  // ═══════════════════════════════════════════════════════════════════

  Future<Response> getGamificationLeaderboard() async {
    return _dio.get('/gamification/leaderboard');
  }

  Future<Response> getGamificationStats() async {
    return _dio.get('/gamification/stats');
  }
}

