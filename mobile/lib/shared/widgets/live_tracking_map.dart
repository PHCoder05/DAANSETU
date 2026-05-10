import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/socket_service.dart';

class LocationData {
  final double lat;
  final double lng;
  
  LocationData({required this.lat, required this.lng});
}

class LiveTrackingMap extends ConsumerStatefulWidget {
  final String donationId;
  final LocationData? initialLocation;
  final LocationData? pickupLocation;

  const LiveTrackingMap({
    Key? key,
    required this.donationId,
    this.initialLocation,
    this.pickupLocation,
  }) : super(key: key);

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  LocationData? _currentLocation;
  final List<LatLng> _route = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    
    if (widget.initialLocation != null) {
      _route.add(LatLng(widget.initialLocation!.lat, widget.initialLocation!.lng));
    } else if (widget.pickupLocation != null) {
      _route.add(LatLng(widget.pickupLocation!.lat, widget.pickupLocation!.lng));
    }

    _setupTracking();
  }

  void _setupTracking() {
    final socketService = ref.read(socketServiceProvider);
    
    socketService.joinTracking(widget.donationId);
    
    socketService.onLocationUpdated((data) {
      if (!mounted) return;
      
      final dynamic location = data['location'];
      if (location != null && data['donationId'] == widget.donationId) {
        setState(() {
          _currentLocation = LocationData(
            lat: location['lat'] is String ? double.parse(location['lat']) : location['lat'].toDouble(),
            lng: location['lng'] is String ? double.parse(location['lng']) : location['lng'].toDouble(),
          );
          
          final newPoint = LatLng(_currentLocation!.lat, _currentLocation!.lng);
          _route.add(newPoint);
          
          // Optionally move map to new location
          // _mapController.move(newPoint, _mapController.zoom);
        });
      }
    });
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    socketService.leaveTracking(widget.donationId);
    socketService.off('location_updated');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLocation != null
        ? LatLng(_currentLocation!.lat, _currentLocation!.lng)
        : widget.pickupLocation != null
            ? LatLng(widget.pickupLocation!.lat, widget.pickupLocation!.lng)
            : const LatLng(20.5937, 78.9629);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.daansetu.app',
          ),
          
          if (_route.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _route,
                  strokeWidth: 4.0,
                  color: Colors.blue,
                ),
              ],
            ),
            
          MarkerLayer(
            markers: [
              if (widget.pickupLocation != null)
                Marker(
                  point: LatLng(widget.pickupLocation!.lat, widget.pickupLocation!.lng),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              if (_currentLocation != null)
                Marker(
                  point: LatLng(_currentLocation!.lat, _currentLocation!.lng),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
