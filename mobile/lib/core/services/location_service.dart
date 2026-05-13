import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,);
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  Future<String?> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.name}, ${place.subLocality}, ${place.locality}";
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  Future<Position?> getPositionFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          longitude: locations[0].longitude,
          latitude: locations[0].latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (e) {
      debugPrint('Error getting position from address: $e');
    }
    return null;
  }

  void startLocationStream(Function(Position) onData) async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return;

    final locationSettings = kIsWeb 
      ? const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
      : AndroidSettings(
          accuracy: LocationAccuracy.medium, // More battery efficient than high
          distanceFilter: 15, // Update every 15 meters
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 10), // Every 10 seconds
          // Add foreground notification to keep it alive in background
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: 'DaanSetu is tracking your location for delivery',
            notificationTitle: 'Active Delivery Tracking',
            enableWakeLock: true,
          ),
        );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      onData(position);
    }, onError: (e) {
      debugPrint('Location stream error: $e');
    },);
  }

  void stopLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
