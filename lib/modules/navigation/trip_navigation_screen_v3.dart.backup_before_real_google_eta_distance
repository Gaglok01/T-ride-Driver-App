import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    as nav;

import '../../compat/google_maps_compat.dart';
import '../../data/models/driver_ride_request_model.dart';
import '../../data/repositories/driver_realtime_repository.dart';

class _StableNavigationMap extends StatefulWidget {
  final LatLng target;

  const _StableNavigationMap({required this.target});

  @override
  State<_StableNavigationMap> createState() => _StableNavigationMapState();
}

class _StableNavigationMapState extends State<_StableNavigationMap> {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      key: const ValueKey('stable_trip_navigation_map'),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60.h,
        right: 16.w,
        bottom: 430.h + MediaQuery.of(context).padding.bottom,
      ),
      initialCameraPosition: CameraPosition(target: widget.target, zoom: 16),
      navigationDestination: widget.target,
      navigationEnabled: true,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: {
        Marker(markerId: const MarkerId('target'), position: widget.target),
      },
    );
  }
}

class TripNavigationScreenV3 extends StatefulWidget {
  final DriverRideRequest ride;

  const TripNavigationScreenV3({super.key, required this.ride});

  @override
  State<TripNavigationScreenV3> createState() => _TripNavigationScreenV3State();
}

class _TripNavigationScreenV3State extends State<TripNavigationScreenV3> {
  final DriverRealtimeRepository _repo = DriverRealtimeRepository();
  late DriverRideRequest _ride;

  GoogleMapController? _mapController;

  bool _autoFollowEnabled = false;

  final ValueNotifier<String> _navInfo = ValueNotifier<String>(
    '-- min | -- mi',
  );
  String _eta = '-- min';
  String _distance = '-- mi';
  Timer? _pickupWaitTimer;
  StreamSubscription<Position>? _positionSub;
  int _pickupWaitSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _updateEtaDistance();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          _updateEtaDistance();

          if (!_autoFollowEnabled) {
            return;
          }

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(pos.latitude, pos.longitude),
                zoom: 17.5,
                tilt: 45,
                bearing: pos.heading < 0 ? 0 : pos.heading,
              ),
            ),
          );
        });
  }

  LatLng get _target {
    final status = _ride.status.toLowerCase();
    final point = status == 'started' || status == 'in_progress'
        ? _ride.dropoffLatLng
        : _ride.pickupLatLng;

    return LatLng(point.latitude, point.longitude);
  }

  String get _title {
    final status = _ride.status.toLowerCase();
    final name = (_ride.riderName ?? '').trim();

    if (status == 'started' || status == 'in_progress')
      return 'Trip in progress';
    if (status == 'arrived') return 'Arrived at pickup';

    return name.isEmpty ? 'Heading to rider' : 'Heading to $name';
  }

  Future<void> _updateEtaDistance() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final meters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _target.latitude,
        _target.longitude,
      );

      final miles = meters / 1609.34;
      final minutes = (miles / 25 * 60).clamp(1, 999).round();

      if (!mounted) {
        return;
      }
      setState(() {
        _distance = '${miles.toStringAsFixed(1)} mi';
        _eta = '$minutes min';
      });
    } catch (_) {}
  }

  double _distanceMiles(double a, double b, double c, double d) {
    return Geolocator.distanceBetween(a, b, c, d) / 1609.34;
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
      if (!mounted) {
        return;
      }
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
      _startPickupWaitTimer();
      await _updateEtaDistance();
    }
  }

  Future<void> _startTrip() async {
    final updated = await _repo.startRide(_ride.id);
    if (updated != null && mounted) {
      setState(() => _ride = updated);
      _startPickupWaitTimer();
      await _updateEtaDistance();
    }
  }

  Future<void> _completeTrip() async {
    if (!await _nearDropoff()) {
      if (!mounted) {
        return;
      }
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

  Future<void> _handleAction() async {
    final status = _ride.status.toLowerCase();

    if (status == 'accepted') {
      await _arrived();
      return;
    }

    if (status == 'arrived') {
      await _startTrip();
      return;
    }

    await _completeTrip();
  }

  void _startPickupWaitTimer() {
    _pickupWaitTimer?.cancel();
    _navInfo.dispose();
    _positionSub?.cancel();
    _pickupWaitSeconds = 0;

    _pickupWaitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _pickupWaitSeconds++);
    });
  }

  String get _pickupWaitText {
    final remaining = 300 - _pickupWaitSeconds;

    if (remaining > 0) {
      final m = remaining ~/ 60;
      final s = remaining % 60;
      return 'Pickup wait: ${m}:${s.toString().padLeft(2, '0')}';
    }

    final overtime = _pickupWaitSeconds - 300;
    final m = overtime ~/ 60;
    final s = overtime % 60;
    return 'No-show eligible: ${m}:${s.toString().padLeft(2, '0')}';
  }

  bool get _canChargeNoShow => _pickupWaitSeconds >= 300;

  bool get _canContactRider {
    final status = _ride.status.toLowerCase();
    return status == 'accepted' || status == 'arrived';
  }

  Widget _actionButton() {
    final status = _ride.status.toLowerCase();

    String label = 'COMPLETE';
    if (status == 'accepted') label = 'ARRIVED';
    if (status == 'arrived') label = 'START';

    return ElevatedButton(
      onPressed: _handleAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFB000),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  void dispose() {
    _pickupWaitTimer?.cancel();
    _navInfo.dispose();
    _positionSub?.cancel();
    try {
      nav.GoogleMapsNavigator.cleanup();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              key: const ValueKey('trip_navigation_v3_map'),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 60.h,
                right: 16.w,
                bottom: 430.h + MediaQuery.of(context).padding.bottom,
              ),
              initialCameraPosition: CameraPosition(target: _target, zoom: 16),
              navigationDestination: _target,
              navigationEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: {
                Marker(markerId: const MarkerId('target'), position: _target),
              },
              onMapCreated: (controller) async {
                _mapController = controller;

                await Future.delayed(const Duration(milliseconds: 800));

                try {
                  await _mapController?.rawController?.showRouteOverview();
                } catch (_) {}

                await Future.delayed(const Duration(seconds: 6));

                if (!mounted) {
                  return;
                }
                _autoFollowEnabled = true;
              },
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                12.w,
                8.h,
                12.w,
                MediaQuery.of(context).padding.bottom + 8.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _ride.status.toLowerCase() == 'arrived'
                        ? _pickupWaitText
                        : '$_eta | $_distance',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      if (_canContactRider) ...[
                        IconButton(
                          onPressed: () => debugPrint('CALL RIDER VIA TWILIO'),
                          icon: const Icon(
                            Icons.call_rounded,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => debugPrint('SMS RIDER VIA TWILIO'),
                          icon: const Icon(
                            Icons.message_rounded,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(
                          height: 38.h,
                          child: OutlinedButton(
                            onPressed: () => debugPrint('CANCEL TRIP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.4,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Expanded(
                        child: SizedBox(height: 38.h, child: _actionButton()),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.black87,
                        ),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Text('Ride details'),
                          ),
                          const PopupMenuItem(
                            value: 'last_trip',
                            child: Text('Last trip then offline'),
                          ),
                          PopupMenuItem(
                            value: 'cancel',
                            child: Text(
                              _ride.status.toLowerCase() == 'arrived' &&
                                      _canChargeNoShow
                                  ? 'Cancel - rider no-show fee'
                                  : 'Cancel trip',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
