import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:t_rider_services_app/compat/google_maps_compat.dart' as compat;

class HomeEmbeddedNavigation extends StatefulWidget {
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
  State<HomeEmbeddedNavigation> createState() => _HomeEmbeddedNavigationState();
}

class _HomeEmbeddedNavigationState extends State<HomeEmbeddedNavigation> {
  bool _navigationEnabled = true;

  @override
  void dispose() {
    compat.forceStopTNavigation();
    _navigationEnabled = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return compat.GoogleMap(
      key: ValueKey(
        'home_nav_${widget.destination.latitude}_${widget.destination.longitude}_$_navigationEnabled',
      ),
      initialCameraPosition: compat.CameraPosition(
        target: compat.LatLng(widget.origin.latitude, widget.origin.longitude),
        zoom: 17,
      ),
      navigationEnabled: _navigationEnabled,
      navigationDestination: compat.LatLng(
        widget.destination.latitude,
        widget.destination.longitude,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: {
        compat.Marker(
          markerId: const compat.MarkerId('target'),
          position: compat.LatLng(
            widget.destination.latitude,
            widget.destination.longitude,
          ),
        ),
      },
    );
  }
}
