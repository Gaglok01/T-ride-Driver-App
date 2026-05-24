import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    as nav;

import '../../compat/google_maps_compat.dart';
import '../../data/models/driver_ride_request_model.dart';
import '../../data/repositories/driver_realtime_repository.dart';

class TripNavigationScreen extends StatefulWidget {
  final DriverRideRequest ride;

  const TripNavigationScreen({super.key, required this.ride});

  @override
  State<TripNavigationScreen> createState() => _TripNavigationScreenState();
}

class _TripNavigationScreenState extends State<TripNavigationScreen> {
  final DriverRealtimeRepository _repo = DriverRealtimeRepository();

  late DriverRideRequest _ride;
  GoogleMapController? _mapController;
  Timer? _etaTimer;
  Timer? _waitTimer;

  int _waitSeconds = 0;

  String _eta = '-- min';
  String _distance = '-- mi';

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _etaTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateEta());
    Future.delayed(const Duration(seconds: 1), _updateEta);
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    _waitTimer?.cancel();
    try {
      nav.GoogleMapsNavigator.cleanup();
    } catch (_) {}
    super.dispose();
  }

  void _startWaitTimerIfNeeded() {
    final status = _ride.status.toLowerCase();

    if (status != 'arrived' || _waitTimer != null) return;

    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _waitSeconds++);
    });
  }

  String get _waitText {
    final freeLeft = 300 - _waitSeconds;

    if (freeLeft > 0) {
      final m = freeLeft ~/ 60;
      final s = freeLeft % 60;
      return 'Free wait ${m}:${s.toString().padLeft(2, '0')}';
    }

    final extra = _waitSeconds - 300;
    final m = extra ~/ 60;
    final s = extra % 60;
    return 'Extra wait ${m}:${s.toString().padLeft(2, '0')}';
  }

  bool get _canCancelNoShow => _waitSeconds >= 300;
  LatLng get _target {
    final status = _ride.status.toLowerCase();

    final point = (status == 'started' || status == 'in_progress')
        ? _ride.dropoffLatLng
        : _ride.pickupLatLng;

    return LatLng(point.latitude, point.longitude);
  }

  String get _title {
    final status = _ride.status.toLowerCase();
    if (status == 'arrived') return 'Waiting for rider';
    if (status == 'started' || status == 'in_progress')
      return 'Trip in progress';
    return 'Heading to rider';
  }

  String get _address {
    final status = _ride.status.toLowerCase();
    if (status == 'started' || status == 'in_progress') {
      return _ride.dropoffAddress;
    }
    return _ride.pickupAddress;
  }

  double _distanceMiles(double a, double b, double c, double d) {
    return Geolocator.distanceBetween(a, b, c, d) / 1609.34;
  }

  Future<void> _updateEta() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final miles = _distanceMiles(
        pos.latitude,
        pos.longitude,
        _target.latitude,
        _target.longitude,
      );

      final minutes = (miles / 25 * 60).clamp(1, 999).round();

      if (!mounted) return;
      setState(() {
        _distance = '${miles.toStringAsFixed(1)} mi';
        _eta = '$minutes min';
      });
    } catch (_) {}
  }

  Future<bool> _nearPickup() async {
    final pos = await Geolocator.getCurrentPosition();
    return _distanceMiles(
          pos.latitude,
          pos.longitude,
          _ride.pickupLatLng.latitude,
          _ride.pickupLatLng.longitude,
        ) <=
        0.2;
  }

  Future<bool> _nearDropoff() async {
    final pos = await Geolocator.getCurrentPosition();
    return _distanceMiles(
          pos.latitude,
          pos.longitude,
          _ride.dropoffLatLng.latitude,
          _ride.dropoffLatLng.longitude,
        ) <=
        0.5;
  }

  Future<void> _arrived() async {
    if (!await _nearPickup()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Move closer to the rider before marking arrived.'),
        ),
      );
      return;
    }

    final updated = await _repo.arrived(_ride.id);
    if (updated != null && mounted) {
      setState(() => _ride = updated);
      _startWaitTimerIfNeeded();
    }
  }

  Future<void> _startTrip() async {
    final updated = await _repo.startRide(_ride.id);
    if (updated != null && mounted) {
      setState(() => _ride = updated);
      _startWaitTimerIfNeeded();
    }
  }

  Future<void> _completeTrip() async {
    if (!await _nearDropoff()) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Early dropoff?'),
          content: const Text(
            'You are not close to the dropoff location. Complete anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    await _repo.completeRide(_ride.id);
    try {
      await nav.GoogleMapsNavigator.cleanup();
    } catch (_) {}
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _cancelRide() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel ride?'),
        content: const Text(
          'This will cancel the accepted ride and return you to the home screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _repo.declineRide(_ride.id);

    try {
      await nav.GoogleMapsNavigator.cleanup();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _actionButton(String status) {
    if (status == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelRide,
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _arrived,
              child: const Text('Arrived'),
            ),
          ),
        ],
      );
    }

    if (status == 'arrived') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startTrip,
          child: const Text('Start trip'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _completeTrip,
        child: const Text('Complete trip'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _ride.status.toLowerCase();
    _startWaitTimerIfNeeded();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _target, zoom: 16),
              navigationDestination: _target,
              navigationEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) async {
                _mapController = controller;
                try {
                  await controller.rawController.followMyLocation(
                    nav.CameraPerspective.tilted,
                    zoomLevel: 17,
                  );
                } catch (_) {}
              },
              markers: {
                Marker(markerId: const MarkerId('target'), position: _target),
              },
            ),
          ),

          Positioned(
            right: 16.w,
            bottom: MediaQuery.of(context).padding.bottom + 230.h,
            child: FloatingActionButton.small(
              heroTag: 'overview',
              onPressed: () async {
                try {
                  await _mapController?.rawController?.showRouteOverview();
                } catch (_) {}
              },
              child: const Icon(Icons.alt_route),
            ),
          ),

          Positioned(
            right: 16.w,
            bottom: MediaQuery.of(context).padding.bottom + 170.h,
            child: FloatingActionButton.small(
              heroTag: 'follow',
              onPressed: () async {
                try {
                  await _mapController?.rawController?.followMyLocation(
                    nav.CameraPerspective.tilted,
                    zoomLevel: 17,
                  );
                } catch (_) {}
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                child: Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26.r),
                    boxShadow: const [
                      BoxShadow(blurRadius: 18, color: Colors.black26),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: TextStyle(
                          fontSize: 23.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Chip(label: Text(_distance)),
                          SizedBox(width: 10.w),
                          Chip(label: Text(_eta)),
                        ],
                      ),
                      if (status == 'arrived') ...[
                        SizedBox(height: 10.h),
                        Chip(
                          avatar: const Icon(Icons.timer, size: 18),
                          label: Text(_waitText),
                        ),
                      ],
                      SizedBox(height: 14.h),
                      _actionButton(status),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
