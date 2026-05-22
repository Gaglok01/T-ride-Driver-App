import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class NavigationScreen extends StatefulWidget {
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  const NavigationScreen({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleNavigationViewController? _navigationViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('T-Ride Navigation')),
      body: GoogleMapsNavigationView(
        initialNavigationUIEnabledPreference:
            NavigationUIEnabledPreference.automatic,

        initialCameraPosition: CameraPosition(
          target: LatLng(
            latitude: widget.originLat,
            longitude: widget.originLng,
          ),
          zoom: 14,
        ),

        onViewCreated: (GoogleNavigationViewController controller) async {
          _navigationViewController = controller;

          final destination = NavigationWaypoint(
            title: 'Destination',
            target: LatLng(latitude: widget.destLat, longitude: widget.destLng),
          );

          await GoogleMapsNavigator.setDestinations(
            Destinations(
              waypoints: [destination],
              displayOptions: NavigationDisplayOptions(),
            ),
          );

          await GoogleMapsNavigator.startGuidance();
        },
      ),
    );
  }
}
