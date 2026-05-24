import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:t_rider_services_app/config/home_map_styles.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/data/models/driver_ride_request_model.dart';
import 'package:t_rider_services_app/data/repositories/driver_realtime_repository.dart';
import 'package:t_rider_services_app/data/repositories/rider_status_repository.dart';
import 'package:t_rider_services_app/views/home/setting/setting_screen.dart';
import 'package:t_rider_services_app/views/profile_screen/profile_screen.dart';
import 'package:t_rider_services_app/views/widgets/app_snackbar.dart';
import 'package:t_rider_services_app/modules/navigation/trip_navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final RiderStatusRepository _statusRepository = RiderStatusRepository();
  final DriverRealtimeRepository _driverRepository = DriverRealtimeRepository();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  Timer? _pollingTimer;
  Timer? _locationPushTimer;
  Timer? _arrivalCountdownTimer;

  int _arrivalCountdownSeconds = 0;
  String _remainingDistanceText = '';
  String _remainingDurationText = '';
  List<LatLng> _routePoints = [];
  DateTime? _lastRouteFetchAt;

  bool _isOnline = false;
  bool _loadingDashboard = true;
  bool _updatingOnline = false;
  bool _loadingRequests = false;
  String _accountStatus = 'pending';
  bool _bidEnabled = true;
  bool _poolingEnabled = true;
  bool _courierEnabled = true;
  bool _deliveryEnabled = true;
  bool _petFriendlyEnabled = false;

  num _todayEarnings = 0;
  num _weekEarnings = 0;
  num _rating = 0;
  int _totalTrips = 0;

  LatLng? _driverLatLng;
  double _heading = 0;
  DriverRideRequest? _activeRide;
  List<DriverRideRequest> _requests = [];

  static const LatLng _fallbackCenter = LatLng(41.2565, -95.9345);
  static const double _startTripMaxMiles = 0.5;
  static const String _googleDirectionsApiKey =
      'AIzaSyCXpA-QVjMCk9Q6KWONfDKvPlMx0jidrR0';

  bool get _hasActiveRide => _activeRide != null;
  DriverRideRequest? get _topRequest =>
      _requests.isEmpty ? null : _requests.first;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _startLocation();
    await refreshDashboard();
    await _loadActiveRide();
    _configurePolling();
  }

  Future<void> refreshDashboard() async {
    setState(() => _loadingDashboard = true);
    try {
      final dash = await _statusRepository.fetchDriverDashboard();
      if (!mounted) return;
      setState(() {
        _accountStatus = dash.accountStatus ?? 'pending';
        _isOnline = dash.isOnline;
        _rating = dash.rating ?? 0;
        _totalTrips = dash.totalTrips ?? 0;
        _todayEarnings = dash.earningsToday;
        _weekEarnings = dash.earningsWeekly;
        _loadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDashboard = false);
    }
  }

  Future<void> _startLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final current = await Geolocator.getCurrentPosition();
      _setPosition(current);

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 8,
        ),
      ).listen(_setPosition);
    } catch (_) {
      // Location can fail on web/emulator. Android APK is the real test.
    }
  }

  void _setPosition(Position p) {
    final next = LatLng(p.latitude, p.longitude);

    setState(() {
      _driverLatLng = next;
      _heading = p.heading.isFinite ? p.heading : _heading;
    });

    _refreshRemainingTripInfo();

    final ride = _activeRide;

    if (_mapController != null) {
      if (ride != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: next,
              zoom: 17.2,
              tilt: 50,
              bearing: _heading,
            ),
          ),
        );
      } else {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: next, zoom: 15),
          ),
        );
      }
    }
  }

  void _startArrivalCountdown() {
    _arrivalCountdownTimer?.cancel();

    setState(() {
      _arrivalCountdownSeconds = 300;
    });

    _arrivalCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_arrivalCountdownSeconds <= 0) {
        timer.cancel();
        return;
      }

      setState(() {
        _arrivalCountdownSeconds--;
      });
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshRemainingTripInfo() async {
    final ride = _activeRide;
    final driver = _driverLatLng;
    if (ride == null || driver == null) return;

    final status = ride.status.toLowerCase();
    final toPickup = status != 'in_progress' && status != 'started';
    final target = toPickup ? ride.pickupLatLng : ride.dropoffLatLng;

    final meters = Geolocator.distanceBetween(
      driver.latitude,
      driver.longitude,
      target.latitude,
      target.longitude,
    );

    final km = meters / 1000;
    final minutes = math.max(1, (km / 0.55).round());

    if (mounted) {
      setState(() {
        _remainingDistanceText = '${km.toStringAsFixed(1)} km remaining';
        _remainingDurationText = '$minutes min remaining';
      });
    }

    final now = DateTime.now();
    if (_lastRouteFetchAt != null &&
        now.difference(_lastRouteFetchAt!).inSeconds < 12) {
      return;
    }

    _lastRouteFetchAt = now;
    await _fetchGoogleRoute(driver, target);
  }

  Future<void> _fetchGoogleRoute(LatLng origin, LatLng destination) async {
    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
            'origin': '${origin.latitude},${origin.longitude}',
            'destination': '${destination.latitude},${destination.longitude}',
            'mode': 'driving',
            'key': _googleDirectionsApiKey,
          });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        debugPrint('DIRECTIONS HTTP ERROR:  ');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        debugPrint('DIRECTIONS NO ROUTES: ');
        return;
      }

      final encoded = routes.first['overview_polyline']?['points'] as String?;
      if (encoded == null || encoded.isEmpty) {
        debugPrint('DIRECTIONS NO POLYLINE: ');
        return;
      }

      final points = _decodePolyline(encoded);

      if (!mounted || points.isEmpty) {
        debugPrint('DIRECTIONS DECODE EMPTY');
        return;
      }

      setState(() {
        _routePoints = points;
      });
    } catch (_) {
      // Keep straight line fallback if Directions API fails.
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _configurePolling() {
    _pollingTimer?.cancel();
    _locationPushTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isOnline) _loadRequests(silent: true);
      if (_hasActiveRide) _loadActiveRide(silent: true);
    });

    _locationPushTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_isOnline) _pushDriverLocation();
    });
  }

  Future<void> _pushDriverLocation() async {
    final p = _driverLatLng;
    if (p == null) return;
    try {
      await _driverRepository.updateLocation(
        lat: p.latitude,
        lng: p.longitude,
        heading: _heading,
        isOnline: _isOnline,
      );
    } catch (_) {
      // Do not interrupt the driver UI because of one location sync failure.
    }
  }

  Future<void> _loadActiveRide({bool silent = false}) async {
    try {
      final active = await _driverRepository.fetchActiveRide();
      if (!mounted) return;
      setState(() => _activeRide = active);
      await _refreshRemainingTripInfo();
    } catch (_) {
      // New backend may not be ready yet. Keep UI ready without fake rides.
    }
  }

  Future<void> _loadRequests({bool silent = false}) async {
    if (!_isOnline) return;
    if (!silent) setState(() => _loadingRequests = true);
    try {
      final p = _driverLatLng;
      final requests = await _driverRepository.fetchRequests(
        lat: p?.latitude,
        lng: p?.longitude,
        bid: _bidEnabled,
        pooling: _poolingEnabled,
      );
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loadingRequests = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRequests = false);
      if (!silent) {
        AppSnackbar.showApiError(
          e,
          fallbackMessage: 'Unable to load ride requests.',
        );
      }
    }
  }

  Future<void> _toggleOnline(bool value) async {
    if (_updatingOnline || _loadingDashboard) return;
    final previous = _isOnline;
    setState(() {
      _isOnline = value;
      _updatingOnline = true;
      if (!value) _requests = [];
    });
    try {
      await _statusRepository.updateOnlineStatus(isOnline: value);
      await _pushDriverLocation();
      if (value) await _loadRequests(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOnline = previous);
      AppSnackbar.showApiError(
        e,
        fallbackMessage: 'Unable to update online status.',
      );
    } finally {
      if (mounted) setState(() => _updatingOnline = false);
    }
  }

  Future<void> _acceptRide(DriverRideRequest ride) async {
    try {
      final active = await _driverRepository.acceptRide(ride.id);
      if (!mounted) return;
      setState(() {
        _activeRide = active ?? ride;
        _requests.removeWhere((e) => e.id == ride.id);
      });
      await _refreshRemainingTripInfo();
      _fitRideOnMap(_activeRide!);
    } catch (e) {
      AppSnackbar.showApiError(
        e,
        fallbackMessage: 'Unable to accept this ride.',
      );
    }
  }

  Future<void> _declineRide(DriverRideRequest ride) async {
    setState(() => _requests.removeWhere((e) => e.id == ride.id));
    try {
      await _driverRepository.declineRide(ride.id);
    } catch (_) {}
  }

  Future<void> _openNavigationForActiveRide() async {
    final ride = _activeRide;
    if (ride == null) return;

    Get.to(() => TripNavigationScreen(ride: ride));
  }

  Future<void> _arrived() async {
    final ride = _activeRide;
    if (ride == null) return;

    _startArrivalCountdown();

    try {
      final updated = await _driverRepository.arrived(ride.id);
      if (!mounted) return;

      setState(() {
        _activeRide = updated ?? ride;
      });

      await _refreshRemainingTripInfo();
    } catch (e) {
      AppSnackbar.showApiError(e, fallbackMessage: 'Unable to mark arrived.');
    }
  }

  Future<void> _startTrip() async {
    final ride = _activeRide;
    final p = _driverLatLng;
    if (ride == null || p == null) return;

    final miles = _distanceMiles(p, ride.pickupLatLng);
    if (miles > _startTripMaxMiles) {
      AppSnackbar.showError(
        message: 'You must be within 0.5 miles of the rider to start the trip.',
      );
      return;
    }

    try {
      final updated = await _driverRepository.startRide(ride.id);
      if (!mounted) return;

      _arrivalCountdownTimer?.cancel();

      setState(() {
        _arrivalCountdownSeconds = 0;
        _activeRide = updated ?? ride;
      });

      await _refreshRemainingTripInfo();
    } catch (e) {
      AppSnackbar.showApiError(e, fallbackMessage: 'Unable to start trip.');
    }
  }

  Future<bool> _showCompletionReviewSheet() async {
    int stars = 5;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                20.h,
                20.w,
                MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Review trip',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final selected = index < stars;
                      return IconButton(
                        onPressed: () => modalSetState(() => stars = index + 1),
                        icon: Icon(
                          selected
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.orange,
                          size: 34.sp,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: const Text('Submit review and complete'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result == true;
  }

  Future<void> _cancelTrip() async {
    final ride = _activeRide;
    if (ride == null) return;

    try {
      await _driverRepository.declineRide(ride.id);

      if (!mounted) return;

      _arrivalCountdownTimer?.cancel();

      setState(() {
        _activeRide = null;
        _arrivalCountdownSeconds = 0;
        _remainingDistanceText = '';
        _remainingDurationText = '';
        _routePoints = [];
      });

      await refreshDashboard();
      await _loadRequests(silent: true);

      AppSnackbar.showSuccess(message: 'Trip cancelled.');
    } catch (e) {
      AppSnackbar.showApiError(e, fallbackMessage: 'Unable to cancel trip.');
    }
  }

  Future<void> _completeTrip() async {
    final ride = _activeRide;
    if (ride == null) return;

    final confirmed = await _showCompletionReviewSheet();
    if (!confirmed) return;

    try {
      await _driverRepository.completeRide(ride.id);
      if (!mounted) return;

      _arrivalCountdownTimer?.cancel();

      setState(() {
        _activeRide = null;
        _arrivalCountdownSeconds = 0;
        _remainingDistanceText = '';
        _remainingDurationText = '';
        _routePoints = [];
      });

      await refreshDashboard();
      await _loadRequests(silent: true);
    } catch (e) {
      AppSnackbar.showApiError(e, fallbackMessage: 'Unable to complete trip.');
    }
  }

  Future<void> _submitBid(DriverRideRequest ride) async {
    final controller = TextEditingController(
      text: ride.estimatedFare == null
          ? ''
          : ride.estimatedFare!.toStringAsFixed(0),
    );
    final amount = await showModalBottomSheet<num>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          20.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit your bid',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: r'$ ',
                labelText: 'Your price',
              ),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  num.tryParse(controller.text.trim()),
                ),
                child: const Text('Send bid'),
              ),
            ),
          ],
        ),
      ),
    );
    if (amount == null || amount <= 0) return;
    try {
      await _driverRepository.submitBid(rideId: ride.id, amount: amount);
      if (mounted)
        AppSnackbar.showSuccess(
          title: 'Bid sent',
          message: 'Your offer was sent to the rider.',
        );
    } catch (e) {
      AppSnackbar.showApiError(e, fallbackMessage: 'Unable to send bid.');
    }
  }

  double _distanceMiles(LatLng a, LatLng b) {
    final meters = Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    return meters / 1609.344;
  }

  Future<void> _fitRideOnMap(DriverRideRequest ride) async {
    final c = _mapController;
    if (c == null) return;
    final points = [
      if (_driverLatLng != null) _driverLatLng!,
      ride.pickupLatLng,
      ride.dropoffLatLng,
    ];
    final minLat = points.map((e) => e.latitude).reduce(math.min);
    final maxLat = points.map((e) => e.latitude).reduce(math.max);
    final minLng = points.map((e) => e.longitude).reduce(math.min);
    final maxLng = points.map((e) => e.longitude).reduce(math.max);
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        70,
      ),
    );
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};
    final p = _driverLatLng;
    if (p != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: p,
          rotation: _heading,
          flat: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }
    final active = _activeRide;
    if (active != null) {
      markers.add(
        Marker(
          markerId: MarkerId('pickup_${active.id}'),
          position: active.pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: active.pickupAddress,
          ),
        ),
      );
      markers.add(
        Marker(
          markerId: MarkerId('dropoff_${active.id}'),
          position: active.dropoffLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Drop-off',
            snippet: active.dropoffAddress,
          ),
        ),
      );
    } else {
      for (final r in _requests.take(5)) {
        markers.add(
          Marker(
            markerId: MarkerId('request_${r.id}'),
            position: r.pickupLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: r.rideType.toUpperCase(),
              snippet: r.pickupAddress,
            ),
          ),
        );
      }
    }
    return markers;
  }

  Set<Polyline> _polylines() {
    final active = _activeRide;
    final p = _driverLatLng;

    if (active == null || p == null) return {};

    final status = active.status.toLowerCase();
    final toPickup = status != 'in_progress' && status != 'started';

    final fallbackPoints = toPickup
        ? <LatLng>[p, active.pickupLatLng]
        : <LatLng>[p, active.dropoffLatLng];

    final points = _routePoints.length >= 2 ? _routePoints : fallbackPoints;

    return {
      Polyline(
        polylineId: const PolylineId('active_route'),
        points: points,
        width: 8,
        color: AppConst.accentColor,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  String _money(num value) => '\$${value.toStringAsFixed(2)}';

  @override
  void dispose() {
    _positionSub?.cancel();
    _pollingTimer?.cancel();
    _locationPushTimer?.cancel();
    _arrivalCountdownTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _driverLatLng ?? _fallbackCenter;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: mapCenter, zoom: 14),
            markers: _markers(),
            polylines: {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            style: AppConst.isDarkMode
                ? HomeMapStyles.darkUberLike
                : HomeMapStyles.lightUberLike,
            onMapCreated: (controller) => _mapController = controller,
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                children: [
                  _topBar(),
                  if (_accountStatus != 'approved') ...[
                    _approvalBanner(),
                    SizedBox(height: 12.h),
                  ],
                  SizedBox(height: 12.h),
                  _earningsBar(),
                  const Spacer(),
                  if (_hasActiveRide) _activeTripCard() else _requestsPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        Container(
          width: 58.w,
          height: 58.w,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.menu_rounded, color: Colors.white),
        ),

        SizedBox(width: 12.w),

        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: AppConst.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppConst.primaryColor.withOpacity(0.45),
                blurRadius: 18,
              ),
            ],
          ),
          child: Icon(
            Icons.local_taxi_rounded,
            color: Colors.black,
            size: 30.sp,
          ),
        ),

        SizedBox(width: 12.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Driver',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color.fromARGB(255, 8, 8, 8),
                ),
              ),

              SizedBox(height: 5.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppConst.primaryColor,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  _isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 58.w,
          height: 58.w,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Get.to(() => const SettingScreen()),
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppConst.primaryColor,
              size: 28.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _earningsBar() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.94),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppConst.primaryColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppConst.primaryColor,
              size: 32.sp,
            ),
          ),

          SizedBox(width: 14.w),

          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earnings today',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 5.h),

                Text(
                  _money(_todayEarnings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 46.h, color: Colors.white12),

          SizedBox(width: 12.w),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trips',
                style: TextStyle(color: Colors.white60, fontSize: 11.sp),
              ),

              SizedBox(height: 5.h),

              Text(
                '$_totalTrips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          SizedBox(width: 14.w),

          Container(width: 1, height: 46.h, color: Colors.white12),

          SizedBox(width: 14.w),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(color: Colors.white60, fontSize: 11.sp),
              ),

              SizedBox(height: 5.h),

              Text(
                _isOnline ? 'Active' : 'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestsPanel() {
    final request = _topRequest;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: !_isOnline
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _emptyPanel(
                  Icons.radio_button_checked_rounded,
                  'Ready to go online',
                  'Start receiving ride and courier requests instantly.',
                ),

                SizedBox(height: 18.h),

                SizedBox(
                  width: double.infinity,
                  height: 64.h,
                  child: ElevatedButton.icon(
                    onPressed: _accountStatus == 'approved'
                        ? () => _toggleOnline(true)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      'GO ONLINE',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConst.primaryColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _loadingRequests
          ? const Center(child: CircularProgressIndicator())
          : request == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _emptyPanel(
                  Icons.radar_rounded,
                  'Waiting for requests',
                  'You are online. New ride and courier requests will appear here.',
                ),

                SizedBox(height: 18.h),

                SizedBox(
                  width: double.infinity,
                  height: 64.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleOnline(false),
                    icon: const Icon(Icons.pause_circle_filled_rounded),
                    label: Text(
                      'GO OFFLINE',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: AppConst.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _requestCard(request),
    );
  }

  Widget _emptyPanel(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFFFFF8E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: AppConst.primaryColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Icon(icon, color: AppConst.primaryColor, size: 36.sp),
          ),

          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    'Ready to roll',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                SizedBox(height: 10.h),

                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),

                SizedBox(height: 6.h),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12.sp,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalBanner() {
    return InkWell(
      borderRadius: BorderRadius.circular(26.r),
      onTap: () => Get.to(() => ProfileScreen()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8DE), Color(0xFFFFF1B8)],
          ),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: AppConst.primaryColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58.w,
              height: 58.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade800,
                size: 34.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account pending approval',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Complete your onboarding documents to start receiving trip requests.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black87,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppConst.primaryColor,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Complete onboarding',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16.sp,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(DriverRideRequest ride) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppConst.primaryColor,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                ride.rideType.toUpperCase(),
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900),
              ),
            ),
            if (ride.isPooling) ...[
              SizedBox(width: 8.w),
              _smallPill('POOLING'),
            ],
            if (ride.canBid) ...[SizedBox(width: 8.w), _smallPill('BID')],
            const Spacer(),
            Text(
              ride.estimatedFare == null
                  ? 'ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â'
                  : _money(ride.estimatedFare!),
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        _locationRow(
          Icons.radio_button_checked_rounded,
          'Pickup',
          ride.pickupAddress,
        ),
        SizedBox(height: 10.h),
        _locationRow(
          Icons.location_on_rounded,
          'Drop-off',
          ride.dropoffAddress,
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            _meta(
              Icons.route_rounded,
              ride.distanceMiles == null
                  ? 'Distance pending'
                  : '${ride.distanceMiles!.toStringAsFixed(1)} mi',
            ),
            SizedBox(width: 10.w),
            _meta(
              Icons.schedule_rounded,
              ride.durationMinutes == null
                  ? 'ETA pending'
                  : '${ride.durationMinutes!.round()} min',
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _declineRide(ride),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: const Text('Decline'),
              ),
            ),
            SizedBox(width: 10.w),
            if (ride.canBid)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submitBid(ride),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: const Text('Bid'),
                ),
              ),
            if (ride.canBid) SizedBox(width: 10.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _acceptRide(ride),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _activeTripCard() {
    final ride = _activeRide!;
    final status = ride.status.toLowerCase();
    final toPickup = status != 'in_progress' && status != 'started';
    final title = toPickup ? 'Drive to rider' : 'Trip in progress';
    final address = toPickup ? ride.pickupAddress : ride.dropoffAddress;
    final miles = _driverLatLng == null
        ? null
        : _distanceMiles(_driverLatLng!, ride.pickupLatLng);

    Widget primaryButton() {
      if (status == 'accepted') {
        return ElevatedButton(
          onPressed: _arrived,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
          child: const Text('Arrived'),
        );
      }

      if (status == 'arrived') {
        return ElevatedButton(
          onPressed: _startTrip,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
          child: const Text('Start trip'),
        );
      }

      return ElevatedButton(
        onPressed: _completeTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        child: const Text('Complete'),
      );
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              const Spacer(),
              if (ride.estimatedFare != null)
                Text(
                  _money(ride.estimatedFare!),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.navigation_rounded, size: 22.sp, color: Colors.black),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              if (miles != null && toPickup)
                Expanded(
                  child: _meta(
                    Icons.social_distance_rounded,
                    '${miles.toStringAsFixed(2)} mi',
                  ),
                ),
              if (_remainingDurationText.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _remainingDurationText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'ETA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openNavigationForActiveRide,
                  icon: const Icon(Icons.near_me_rounded),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              if (status == 'accepted' || status == 'arrived') ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelTrip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Expanded(child: primaryButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallPill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _locationRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: AppConst.primaryColor),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.black45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: AppConst.primaryColor.withOpacity(0.85),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
