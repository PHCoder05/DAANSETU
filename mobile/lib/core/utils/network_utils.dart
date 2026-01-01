import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity state
enum NetworkStatus { connected, disconnected }

/// Network connectivity notifier for checking internet connection
class NetworkNotifier extends StateNotifier<NetworkStatus> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  
  NetworkNotifier() : super(NetworkStatus.connected) {
    _init();
  }

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        state = NetworkStatus.disconnected;
      } else {
        state = NetworkStatus.connected;
      }
    });
  }

  Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final isConnected = !result.contains(ConnectivityResult.none);
    state = isConnected ? NetworkStatus.connected : NetworkStatus.disconnected;
    return isConnected;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider for network status
final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkStatus>((ref) {
  return NetworkNotifier();
});

/// Offline banner widget to show at top of screen when offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkProvider);
    
    if (status == NetworkStatus.connected) {
      return const SizedBox.shrink();
    }

    return Material(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.red.shade600,
        child: const SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'No internet connection',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper that shows offline banner above content
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  
  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}
