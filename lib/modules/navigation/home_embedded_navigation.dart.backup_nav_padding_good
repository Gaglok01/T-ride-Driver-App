import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:t_rider_services_app/compat/google_maps_compat.dart' as compat;

class HomeEmbeddedNavigation extends StatelessWidget {
  final gm.LatLng origin;
  final gm.LatLng destination;
  final String title;

  const HomeEmbeddedNavigation({
    super.key,
    required this.origin,
    required this.destination,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return compat.GoogleMap(
      initialCameraPosition: compat.CameraPosition(
        target: compat.LatLng(origin.latitude, origin.longitude),
        zoom: 17,
      ),
      navigationEnabled: true,
      navigationDestination: compat.LatLng(
        destination.latitude,
        destination.longitude,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: {
        compat.Marker(
          markerId: const compat.MarkerId('target'),
          position: compat.LatLng(
            destination.latitude,
            destination.longitude,
          ),
        ),
      },
    );
  }
}
