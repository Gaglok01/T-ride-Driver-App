import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    as nav;

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;
  const LatLngBounds({required this.southwest, required this.northeast});
}

class CameraPosition {
  final LatLng target;
  final double zoom;
  final double tilt;
  final double bearing;

  const CameraPosition({
    required this.target,
    this.zoom = 14,
    this.tilt = 0,
    this.bearing = 0,
  });
}

class CameraUpdate {
  const CameraUpdate();

  static CameraUpdate newCameraPosition(CameraPosition position) =>
      const CameraUpdate();
  static CameraUpdate newLatLng(LatLng target) => const CameraUpdate();
  static CameraUpdate newLatLngZoom(LatLng target, double zoom) =>
      const CameraUpdate();
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) =>
      const CameraUpdate();
}

class GoogleMapController {
  final dynamic rawController;
  GoogleMapController([this.rawController]);

  Future<void> animateCamera(CameraUpdate update) async {}
  Future<void> moveCamera(CameraUpdate update) async {}
  Future<void> dispose() async {}
}

enum MapType { normal, satellite, terrain, hybrid, none }

class MarkerId {
  final String value;
  const MarkerId(this.value);
}

class PolylineId {
  final String value;
  const PolylineId(this.value);
}

class InfoWindow {
  final String? title;
  final String? snippet;
  const InfoWindow({this.title, this.snippet});
}

class BitmapDescriptor {
  const BitmapDescriptor();

  static const BitmapDescriptor defaultMarker = BitmapDescriptor();

  static BitmapDescriptor defaultMarkerWithHue(double hue) =>
      const BitmapDescriptor();
  static Future<BitmapDescriptor> fromBytes(List<int> bytes) async =>
      const BitmapDescriptor();

  static Future<BitmapDescriptor> bytes(List<int> bytes) async =>
      const BitmapDescriptor();

  static const double hueRed = 0;
  static const double hueGreen = 120;
  static const double hueBlue = 240;
  static const double hueOrange = 30;
  static const double hueYellow = 60;
  static const double hueAzure = 210;
  static const double hueViolet = 270;
}

class Marker {
  final MarkerId markerId;
  final LatLng position;
  final BitmapDescriptor icon;
  final InfoWindow infoWindow;
  final double rotation;
  final bool flat;
  final Offset anchor;

  const Marker({
    required this.markerId,
    required this.position,
    this.icon = BitmapDescriptor.defaultMarker,
    this.infoWindow = const InfoWindow(),
    this.rotation = 0,
    this.flat = false,
    this.anchor = const Offset(0.5, 1),
    int? zIndexInt,
  });
}

class Cap {
  const Cap();
  static const Cap roundCap = Cap();
  static const Cap buttCap = Cap();
  static const Cap squareCap = Cap();
}

class JointType {
  static const int round = 1;
  static const int bevel = 2;
  static const int mitered = 3;
}

class Polyline {
  final PolylineId polylineId;
  final List<LatLng> points;
  final int width;
  final Color color;
  final bool geodesic;
  final Cap startCap;
  final Cap endCap;
  final int jointType;

  const Polyline({
    required this.polylineId,
    required this.points,
    this.width = 5,
    this.color = Colors.blue,
    this.geodesic = false,
    this.startCap = Cap.roundCap,
    this.endCap = Cap.roundCap,
    this.jointType = JointType.round,
  });
}

class GoogleMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final MapType mapType;
  final void Function(GoogleMapController)? onMapCreated;
  final LatLng? navigationDestination;
  final bool navigationEnabled;

  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.polylines = const {},
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.mapType = MapType.normal,
    this.onMapCreated,
    this.navigationDestination,
    this.navigationEnabled = false,
    dynamic zoomControlsEnabled,
    dynamic compassEnabled,
    dynamic mapToolbarEnabled,
    dynamic trafficEnabled,
    dynamic buildingsEnabled,
    dynamic indoorViewEnabled,
    dynamic padding,
    dynamic onCameraMove,
    dynamic onCameraIdle,
    dynamic onTap,
    dynamic style,
    dynamic gestureRecognizers,
  });

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  GoogleMapController? _controller;
  bool _guidanceStarted = false;
  LatLng? _lastDestination;

  @override
  void initState() {
    super.initState();
    if (!widget.navigationEnabled) {
      Future.microtask(() async {
        try {
          await nav.GoogleMapsNavigator.cleanup();
        } catch (_) {}
      });
    }
    Future.delayed(const Duration(milliseconds: 800), _tryStartNavigation);
  }

  @override
  void didUpdateWidget(covariant GoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.navigationEnabled) {
      Future.microtask(() async {
        try {
          await nav.GoogleMapsNavigator.cleanup();
        } catch (_) {}
      });
    }
    Future.delayed(const Duration(milliseconds: 500), _tryStartNavigation);
  }

  LatLng? _findDestination() {
    if (widget.navigationDestination != null) {
      return widget.navigationDestination;
    }
    if (widget.polylines.isNotEmpty &&
        widget.polylines.first.points.length >= 2) {
      return widget.polylines.first.points.last;
    }

    if (widget.markers.isNotEmpty) {
      return widget.markers.last.position;
    }

    return null;
  }

  Future<void> _tryStartNavigation() async {
    if (!widget.navigationEnabled) return;
    final destination = _findDestination();

    debugPrint(
      'NAV BUILD ${DateTime.now()} markers=${widget.markers.length}',
    );

    if (destination == null) return;

    if (_lastDestination != null &&
        _lastDestination!.latitude == destination.latitude &&
        _lastDestination!.longitude == destination.longitude) {
      return;
    }

    _lastDestination = destination;

    try {
      await nav.GoogleMapsNavigator.initializeNavigationSession();
    } on nav.SessionInitializationException catch (e) {
      debugPrint('NAV SESSION ERROR: ');

      if (e.code == nav.SessionInitializationError.termsNotAccepted) {
        await nav.GoogleMapsNavigator.showTermsAndConditionsDialog(
          'T-Ride Driver',
          'en-US',
        );

        await nav.GoogleMapsNavigator.initializeNavigationSession();
      }
    }
    debugPrint('T-RIDE NAV SDK: navigation session initialized');

    if (!await nav.GoogleMapsNavigator.areTermsAccepted()) {
      await nav.GoogleMapsNavigator.showTermsAndConditionsDialog(
        'T-Ride Navigation',
        'T-Ride LLC',
      );
    }

    final status = await nav.GoogleMapsNavigator.setDestinations(
      nav.Destinations(
        waypoints: [
          nav.NavigationWaypoint(
            title: 'Ride Destination',
            target: nav.LatLng(
              latitude: destination.latitude,
              longitude: destination.longitude,
            ),
          ),
        ],
        displayOptions: nav.NavigationDisplayOptions(),
      ),
    );

    debugPrint('T-RIDE NAV SDK: setDestinations status=$status');

    if (status == nav.NavigationRouteStatus.statusOk) {
      await nav.GoogleMapsNavigator.startGuidance();
      debugPrint('T-RIDE NAV SDK: guidance started');

      await Future.delayed(const Duration(milliseconds: 1200));
      await _controller?.rawController?.followMyLocation(nav.CameraPerspective.tilted, zoomLevel: 17.0);

      
      try {
        await _controller?.rawController?.setNavigationUIEnabled(true);
        await _controller?.rawController?.setNavigationHeaderEnabled(true);
        await _controller?.rawController?.setNavigationFooterEnabled(false);
        await _controller?.rawController?.setPadding(const EdgeInsets.only(top: 65, bottom: 430, right: 10, left: 10));

        
      } catch (e) {
        debugPrint('T-RIDE ROUTE OVERVIEW FOLLOW TEST ERROR: $e');
      }

      try {
        await _controller?.rawController?.setNavigationUIEnabled(true);
        await _controller?.rawController?.setNavigationHeaderEnabled(true);
        await _controller?.rawController?.setNavigationFooterEnabled(false);
        await _controller?.rawController?.setPadding(const EdgeInsets.only(top: 65, bottom: 430, right: 10, left: 10));
} catch (e) {
        debugPrint('T-RIDE NAV CAMERA FINAL TEST ERROR: ');
      }

      try {
        await _controller?.rawController?.setNavigationFooterEnabled(false);
        await _controller?.rawController?.setRecenterButtonEnabled(true);

        await _controller?.rawController?.setSpeedometerEnabled(true);
        await _controller?.rawController?.setReportIncidentButtonEnabled(false);
        await _controller?.rawController?.setTrafficIncidentCardsEnabled(false);
        await _controller?.rawController?.setTrafficPromptsEnabled(false);
} catch (e) {
        debugPrint('T-RIDE NAV AFTER START SETTINGS ERROR: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navCamera = nav.CameraPosition(
      target: nav.LatLng(
        latitude: widget.initialCameraPosition.target.latitude,
        longitude: widget.initialCameraPosition.target.longitude,
      ),
      zoom: widget.initialCameraPosition.zoom,
    );

    if (!widget.navigationEnabled) {
      return nav.GoogleMapsMapView(
        initialCameraPosition: navCamera,
        onViewCreated: (controller) async {
          try {
            await nav.GoogleMapsNavigator.cleanup();
          } catch (_) {}

          _controller = GoogleMapController(controller);
          widget.onMapCreated?.call(_controller!);
        },
      );
    }

    return nav.GoogleMapsNavigationView(
      initialPadding: const EdgeInsets.only(top: 65, bottom: 430, right: 10, left: 10),
      initialMapColorScheme: nav.MapColorScheme.light,
      initialForceNightMode: nav.NavigationForceNightMode.forceDay,
      initialNavigationUIEnabledPreference:
          nav.NavigationUIEnabledPreference.automatic,
      initialCameraPosition: navCamera,
      onViewCreated: (controller) async {
        _controller = GoogleMapController(controller);

        try {
          await controller.setNavigationHeaderEnabled(true);
          await controller.setNavigationFooterEnabled(false);
          await controller.setRecenterButtonEnabled(true);
          await controller.setPadding(const EdgeInsets.only(top: 65, bottom: 430, right: 10, left: 10));
          await controller.setSpeedometerEnabled(true);
          await controller.setReportIncidentButtonEnabled(false);
          await controller.setTrafficIncidentCardsEnabled(false);
          await controller.setTrafficPromptsEnabled(false);
        } catch (e) {
          debugPrint('T-RIDE NAV UI SETTINGS ERROR: $e');
        }

        widget.onMapCreated?.call(_controller!);
        await _tryStartNavigation();
      },
    );
  }
}





























