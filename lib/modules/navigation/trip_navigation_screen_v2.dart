import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripNavigationScreenV2 extends StatefulWidget {
  const TripNavigationScreenV2({
    super.key,
    required this.pickupLatLng,
    required this.dropoffLatLng,
  });

  final LatLng pickupLatLng;
  final LatLng dropoffLatLng;

  @override
  State<TripNavigationScreenV2> createState() => _TripNavigationScreenV2State();
}

class _TripNavigationScreenV2State extends State<TripNavigationScreenV2> {
  final Completer<GoogleMapController> _mapController = Completer();

  bool _mapReady = false;
  bool _isFollowingDriver = false;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(41.2565, -95.9345), // Omaha fallback
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  void _setupMapData() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLatLng,
        infoWindow: const InfoWindow(title: 'Pickup'),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.dropoffLatLng,
        infoWindow: const InfoWindow(title: 'Dropoff'),
      ),
    };

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [widget.pickupLatLng, widget.dropoffLatLng],
        width: 12,
      ),
    };
  }

  Future<void> _showRouteOverview() async {
    if (!_mapReady) return;

    final controller = await _mapController.future;

    final bounds = _boundsFromLatLngList([
      widget.pickupLatLng,
      widget.dropoffLatLng,
    ]);

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 90));

    // IMPORTANT :
    // Après route overview, on désactive le follow.
    // Sinon la caméra repart vers la position conducteur.
    _isFollowingDriver = false;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _followDriverLocation(LatLng driverLatLng) async {
    if (!_mapReady) return;
    if (!_isFollowingDriver) return;

    final controller = await _mapController.future;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: driverLatLng, zoom: 17, tilt: 45, bearing: 0),
      ),
    );
  }

  void _enableFollowDriver() {
    setState(() {
      _isFollowingDriver = true;
    });

    // Plus tard ici, on passera la vraie position driver.
    // _followDriverLocation(currentDriverLatLng);
  }

  void _disableFollowDriver() {
    setState(() {
      _isFollowingDriver = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.only(bottom: 170, top: 40),
            onMapCreated: (controller) async {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }

              _mapReady = true;

              await Future.delayed(const Duration(milliseconds: 600));
              await _showRouteOverview();
            },
            onCameraMoveStarted: () {
              // Si l’utilisateur bouge la carte à la main,
              // on arrête le follow automatiquement.
              _disableFollowDriver();
            },
          ),

          Positioned(top: 50, left: 16, right: 16, child: _topCard()),

          Positioned(bottom: 0, left: 0, right: 0, child: _bottomPanel()),
        ],
      ),
    );
  }

  Widget _topCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: const Text(
        'Trip Navigation V2',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _bottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black26)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showRouteOverview,
                  icon: const Icon(Icons.route),
                  label: const Text('Route Overview'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _enableFollowDriver,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Follow Driver'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sms),
                  label: const Text('SMS'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
