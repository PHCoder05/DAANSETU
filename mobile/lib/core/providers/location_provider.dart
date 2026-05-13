import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class UserLocation {
  final Position? position;
  final String? address;

  UserLocation({this.position, this.address});

  UserLocation copyWith({Position? position, String? address}) {
    return UserLocation(
      position: position ?? this.position,
      address: address ?? this.address,
    );
  }
}

final userLocationProvider = StateNotifierProvider<UserLocationNotifier, UserLocation>(
  (ref) => UserLocationNotifier(ref.watch(locationServiceProvider)),
);

class UserLocationNotifier extends StateNotifier<UserLocation> {
  final LocationService _locationService;

  UserLocationNotifier(this._locationService) : super(UserLocation());

  Future<void> updateLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      final address = await _locationService.getAddressFromPosition(position);
      state = UserLocation(position: position, address: address);
    }
  }
  
  Future<void> setAddress(String address) async {
    final position = await _locationService.getPositionFromAddress(address);
    if (position != null) {
      state = UserLocation(position: position, address: address);
    } else {
      state = state.copyWith(address: address);
    }
  }

  void setLocation(Position position, {String? address}) {
    state = UserLocation(position: position, address: address);
  }
}
