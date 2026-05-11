import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import '../../shared/providers/auth_provider.dart';

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier(
    ref,
    ref.watch(locationServiceProvider),
    ref.watch(socketServiceProvider),
  );
});

class TrackingState {
  final bool isBroadcasting;
  final String? activeDonationId;
  final bool isGlobalOnline;

  TrackingState({
    this.isBroadcasting = false,
    this.activeDonationId,
    this.isGlobalOnline = false,
  });

  TrackingState copyWith({
    bool? isBroadcasting,
    String? activeDonationId,
    bool? isGlobalOnline,
  }) {
    return TrackingState(
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      activeDonationId: activeDonationId ?? this.activeDonationId,
      isGlobalOnline: isGlobalOnline ?? this.isGlobalOnline,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final Ref _ref;
  final LocationService _locationService;
  final SocketService _socketService;

  TrackingNotifier(this._ref, this._locationService, this._socketService) : super(TrackingState());

  Future<bool> startDonationTracking(String donationId) async {
    final hasPermission = await _locationService.handleLocationPermission();
    if (!hasPermission) return false;

    // Stop global stream if active to restart with new callback
    if (state.isGlobalOnline) {
      _locationService.stopLocationStream();
    }

    _locationService.startLocationStream((position) {
      // 1. Always emit to specific donation if active
      if (state.isBroadcasting && state.activeDonationId == donationId) {
        _socketService.emitLocation(
          donationId,
          position.latitude,
          position.longitude,
        );
      }
      
      // 2. Also emit to global channel if online
      if (state.isGlobalOnline) {
        final userId = _ref.read(authStateProvider).user?.id;
        if (userId != null) {
          _socketService.broadcastVolunteerLocation(
            userId,
            position.latitude,
            position.longitude,
          );
        }
      }
    });

    state = state.copyWith(
      isBroadcasting: true,
      activeDonationId: donationId,
    );
    return true;
  }

  Future<bool> toggleGlobalOnline(bool online) async {
    if (online) {
      final hasPermission = await _locationService.handleLocationPermission();
      if (!hasPermission) return false;

      // Start or restart stream
      _locationService.stopLocationStream();
      _locationService.startLocationStream((position) {
        // Global broadcast
        final userId = _ref.read(authStateProvider).user?.id;
        if (userId != null) {
          _socketService.broadcastVolunteerLocation(
            userId,
            position.latitude,
            position.longitude,
          );
        }

        // Specific donation broadcast if any
        if (state.isBroadcasting && state.activeDonationId != null) {
          _socketService.emitLocation(
            state.activeDonationId!,
            position.latitude,
            position.longitude,
          );
        }
      });
      state = state.copyWith(isGlobalOnline: true);
    } else {
      // If we aren't tracking a specific donation, stop the stream entirely
      if (!state.isBroadcasting) {
        _locationService.stopLocationStream();
      }
      state = state.copyWith(isGlobalOnline: false);
    }
    return true;
  }

  void stopDonationTracking() {
    state = state.copyWith(
      isBroadcasting: false,
      activeDonationId: null,
    );
    
    // If not global online, stop the stream
    if (!state.isGlobalOnline) {
      _locationService.stopLocationStream();
    }
  }
}
