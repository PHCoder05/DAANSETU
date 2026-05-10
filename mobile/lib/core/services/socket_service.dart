import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../config/constants.dart';
import '../../shared/providers/auth_provider.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(ref);
});

class SocketService {
  late IO.Socket socket;
  final Ref ref;
  bool _isConnected = false;

  SocketService(this.ref) {
    _initSocket();
  }

  void _initSocket() {
    // Get socket URL from constants (configured via env)
    final String socketUrl = AppConstants.socketUrl;

    socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect() 
        .enableForceNew()
        .build());

    socket.onConnect((_) {
      debugPrint('⚡ Socket Connected: ${socket.id}');
      _isConnected = true;
      
      // Emit user_connected with userId for proper tracking
      final user = ref.read(authStateProvider).user;
      if (user != null) {
        socket.emit('user_connected', user.id);
      }
    });

    socket.onDisconnect((_) {
      debugPrint('🔌 Socket Disconnected');
      _isConnected = false;
    });

    socket.onError((data) => debugPrint('❌ Socket Error: $data'));
  }

  void connect() {
    if (!_isConnected) {
      socket.connect();
    }
  }

  void disconnect() {
    socket.disconnect();
  }

  void joinRoom(String room) {
    socket.emit('join_room', room);
  }

  void sendMessage({
    required String senderId,
    required String recipientId,
    required String content,
    String? donationId,
  }) {
    socket.emit('send_message', {
      'sender': senderId,
      'recipient': recipientId,
      'content': content,
      'donationId': donationId,
    });
  }

  void sendTyping({required String recipientId, required bool isTyping}) {
    socket.emit('typing', {
      'recipient': recipientId,
      'isTyping': isTyping,
    });
  }

  // Listeners
  void onMessageReceived(Function(dynamic) callback) {
    socket.on('receive_message', callback);
  }
  
  void onMessageSent(Function(dynamic) callback) {
    socket.on('message_sent', callback);
  }
  
  void onTypingStatus(Function(dynamic) callback) {
    socket.on('typing_status', callback);
  }
  
  void onUserOnline(Function(dynamic) callback) {
    socket.on('user_online', callback);
  }

  // --- Tracking Events ---
  void joinTracking(String donationId) {
    socket.emit('join_tracking', donationId);
    debugPrint('Joined tracking room: $donationId');
  }

  void leaveTracking(String donationId) {
    socket.emit('leave_tracking', donationId);
    debugPrint('Left tracking room: $donationId');
  }

  void emitLocation(String donationId, double lat, double lng) {
    socket.emit('update_location', {
      'donationId': donationId,
      'lat': lat,
      'lng': lng,
    });
  }

  void broadcastVolunteerLocation(String userId, double lat, double lng) {
    socket.emit('volunteer_location_update', {
      'userId': userId,
      'lat': lat,
      'lng': lng,
    });
  }

  void onLocationUpdated(Function(dynamic) callback) {
    socket.on('location_updated', callback);
  }

  void off(String event) {
    socket.off(event);
  }
}

