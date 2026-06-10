import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class EmbeddedNavigationView extends StatefulWidget {
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String title;

  const EmbeddedNavigationView({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    this.title = 'T-Ride Navigation',
  });

  @override
  State<EmbeddedNavigationView> createState() => _EmbeddedNavigationViewState();
}

class _EmbeddedNavigationViewState extends State<EmbeddedNavigationView> {
  bool _ready = false;
  bool _starting = false;

  Future<void> _start(GoogleNavigationViewController controller) async {
    if (_starting) return;
    _starting = true;

    try {
      await GoogleMapsNavigator.initializeNavigationSession();

      await controller.setNavigationHeaderEnabled(true);
      await controller.setNavigationFooterEnabled(false);
      await controller.setRecenterButtonEnabled(true);
      await controller.setSpeedometerEnabled(true);
      await controller.setReportIncidentButtonEnabled(false);
      await controller.setTrafficIncidentCardsEnabled(false);
      await controller.setTrafficPromptsEnabled(false);
      await controller.setPadding(const EdgeInsets.only(top: 70, bottom: 80, right: 12));

      final destination = NavigationWaypoint(
        title: widget.title,
        target: LatLng(latitude: widget.destLat, longitude: widget.destLng),
      );

      await GoogleMapsNavigator.setDestinations(
        Destinations(
          waypoints: [destination],
          displayOptions: NavigationDisplayOptions(),
        ),
      );

      await GoogleMapsNavigator.startGuidance();

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('T-RIDE EMBEDDED NAV ERROR: $e');
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMapsNavigationView(
          initialMapColorScheme: MapColorScheme.light,
          initialForceNightMode: NavigationForceNightMode.forceDay,
          initialNavigationUIEnabledPreference:
              NavigationUIEnabledPreference.automatic,
          initialCameraPosition: CameraPosition(
            target: LatLng(latitude: widget.originLat, longitude: widget.originLng),
            zoom: 17,
          ),
          onViewCreated: _start,
        ),

        if (!_ready)
          Container(
            color: Colors.white,
            alignment: Alignment.center,
            child: const Text(
              'Starting T-Ride navigation...',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}
