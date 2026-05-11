import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

final userLocationProvider = StateNotifierProvider<UserLocationNotifier, Position?>(
  (ref) => UserLocationNotifier(ref.watch(locationServiceProvider)),
);

class UserLocationNotifier extends StateNotifier<Position?> {
  final LocationService _locationService;

  UserLocationNotifier(this._locationService) : super(null);

  Future<void> updateLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      state = position;
    }
  }
  
  void setLocation(Position position) {
    state = position;
  }
}
