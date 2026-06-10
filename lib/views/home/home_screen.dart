import 'dart:async';
import 'package:t_rider_services_app/data/repositories/driver_onboarding_repository.dart';
import 'package:t_rider_services_app/data/repositories/driver_dashboard_repository.dart';
import 'package:t_rider_services_app/data/repositories/driver_heat_map_repository.dart';
import 'package:t_rider_services_app/data/models/heat_map_zone.dart';
import 'package:t_rider_services_app/data/repositories/profile_repository.dart';
import 'package:t_rider_services_app/data/models/user_profile_model.dart';
import 'package:t_rider_services_app/config/api_urls.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:t_rider_services_app/main.dart' as app_main;
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:t_rider_services_app/modules/navigation/home_embedded_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:t_rider_services_app/config/home_map_styles.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/data/models/driver_ride_request_model.dart';
import 'package:t_rider_services_app/data/repositories/driver_realtime_repository.dart';
import 'package:t_rider_services_app/data/repositories/rider_status_repository.dart';
import 'package:t_rider_services_app/views/home/setting/setting_screen.dart';
import 'package:t_rider_services_app/views/home/earnings_screen.dart';
import 'package:t_rider_services_app/views/home/setting/profile_screen.dart';
import 'package:t_rider_services_app/views/home/setting/driver_profile_v2.dart';
import 'package:t_rider_services_app/views/widgets/app_snackbar.dart';
import 'package:t_rider_services_app/modules/navigation/trip_navigation_screen_v3.dart';

class HomeScreen extends StatefulWidget {
  static final ValueNotifier<bool> activeRideNotifier = ValueNotifier<bool>(false);
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final RiderStatusRepository _statusRepository = RiderStatusRepository();
  final DriverRealtimeRepository _driverRepository = DriverRealtimeRepository();
  final DriverDashboardRepository _dashboardRepository =
      DriverDashboardRepository();
  final DriverHeatMapRepository _heatMapRepository = DriverHeatMapRepository();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  Timer? _pollingTimer;
  Timer? _locationPushTimer;
  Timer? _driverStatusTimer;

  final DriverOnboardingRepository _onboardingRepository =
      DriverOnboardingRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  UserProfile? _driverProfile;
  Timer? _arrivalCountdownTimer;
  Timer? _requestCountdownTimer;

  int _arrivalCountdownSeconds = 0;
  int _requestSecondsLeft = 20;
  int _dispatchAcceptTimeoutSeconds = 20;
  int? _countdownRequestId;
  String _remainingDistanceText = '';
  String _remainingDurationText = '';
  List<LatLng> _routePoints = [];
  DateTime? _lastRouteFetchAt;

  bool _isOnline = false;
  bool _loadingDashboard = true;
  bool _updatingOnline = false;
  bool _loadingRequests = false;
  String _accountStatus = 'pending';
  bool _canDrive = false;
  bool _adminOverride = false;
  Map<String, dynamic> _eligibility = {};
  String? _dashboardProfileImage;
  bool _bidEnabled = true;
  bool _poolingEnabled = true;
  bool _courierEnabled = true;
  bool _deliveryEnabled = true;
  bool _petFriendlyEnabled = false;

  num _todayEarnings = 0;
  num _weekEarnings = 0;
  num _monthEarnings = 0;
  num _walletBalance = 0;
  num _rating = 0;
  int _totalTrips = 0;

  LatLng? _driverLatLng;
  double _heading = 0;
  DriverRideRequest? _activeRide;
  bool _navigationStartedForActiveRide = false;
  List<DriverRideRequest> _requests = [];
  final Set<int> _expiredRequestIds = <int>{};
  List<HeatMapZone> _heatMapZones = [];

  static const LatLng _fallbackCenter = LatLng(41.2565, -95.9345);
  static const double _startTripMaxMiles = 0.5;
  static const String _googleDirectionsApiKey =
      'AIzaSyCXpA-QVjMCk9Q6KWONfDKvPlMx0jidrR0';

  bool get _hasActiveRide => _activeRide != null;
  bool get hasActiveRide => _hasActiveRide;
  DriverRideRequest? get _topRequest =>
      _requests.isEmpty ? null : _requests.first;

  @override
  Future<void> _refreshDriverApprovalStatus() async {
    try {
      final response = await _onboardingRepository.getStatus();

      final accountStatus = response['account_status']
          ?.toString()
          .toLowerCase();

      if (accountStatus != 'approved') {
        if (mounted) {
          setState(() {
            _isOnline = false;
          });
        }

        Get.snackbar(
          'Account Status Changed',
          'Your driver account is no longer approved.',
        );
      }
    } catch (e) {
      debugPrint('Driver status refresh error: $e');
    }
  }

  Future<void> _loadDriverProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      if (mounted) {
        setState(() {
          _driverProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Driver profile load error: $e');
    }
  }

  String? _profilePhotoUrl() {
    final raw = (_dashboardProfileImage ?? _driverProfile?.photo)?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    final cleanBase = ApiUrls.baseUrl.endsWith('/')
        ? ApiUrls.baseUrl.substring(0, ApiUrls.baseUrl.length - 1)
        : ApiUrls.baseUrl;

    final cleanRaw = raw.startsWith('/') ? raw.substring(1) : raw;

    return cleanRaw.startsWith('storage/')
        ? '$cleanBase/$cleanRaw'
        : '$cleanBase/storage/$cleanRaw';
  }

  void initState() {
    super.initState();
    _loadDriverProfile();

    _driverStatusTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshDriverApprovalStatus(),
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadDispatchSettings();
    await _startLocation();
    await refreshDashboard();
    await _loadHeatMapZones();
    await _loadActiveRide();
    _configurePolling();
  }

  Future<void> _loadHeatMapZones() async {
    try {
      final zones = await _heatMapRepository.fetchHeatMapZones();
      debugPrint('HEAT MAP ZONES LOADED => ${zones.length}');

      if (!mounted) return;

      setState(() {
        _heatMapZones = zones;
      });
    } catch (e) {
      debugPrint('HEAT MAP LOAD ERROR => $e');
    }
  }

  Future<void> refreshDashboard() async {
    setState(() => _loadingDashboard = true);
    try {
      final dash = await _statusRepository.fetchDriverDashboard();
      debugPrint(
        'REAL DASHBOARD => rating=' +
            dash.rating.toString() +
            ', trips=' +
            dash.totalTrips.toString() +
            ', wallet=' +
            dash.walletBalance.toString() +
            ', acceptance=' +
            dash.acceptanceRate.toString() +
            ', tier=' +
            dash.tier.toString() +
            ', verified=' +
            dash.verified.toString() +
            ', pending=' +
            dash.pendingDocuments.toString(),
      );
      if (!mounted) return;
      setState(() {
        _accountStatus = dash.accountStatus ?? 'pending';
        _canDrive = dash.canDrive;
        _eligibility = dash.eligibility;
        _adminOverride = dash.adminOverride;
        _dashboardProfileImage = dash.profileImage;
        _isOnline = dash.isOnline;
        _rating = dash.rating ?? 0;
        _totalTrips = dash.totalTrips ?? 0;
        _todayEarnings = dash.earningsToday;
        _weekEarnings = dash.earningsWeekly;
        _monthEarnings = dash.earningsMonthly;
        _walletBalance = dash.walletBalance;
        debugPrint(
          'EARNINGS DEBUG => today=' +
              _todayEarnings.toString() +
              ' week=' +
              _weekEarnings.toString() +
              ' month=' +
              _monthEarnings.toString() +
              ' wallet=' +
              _walletBalance.toString(),
        );
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
          distanceFilter: 4,
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

    if (_hasActiveRide) return;

    final ride = _activeRide;

    if (_mapController != null) {
      if (ride != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: next,
              zoom: 17.5,
              tilt: 35,
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
    _requestCountdownTimer?.cancel();

    setState(() {
      _arrivalCountdownSeconds = 300;
    });

    _arrivalCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

    final miles = meters / 1609.344;
    final minutes = math.max(1, (miles / 0.45).round());

    if (mounted) {
      setState(() {
        _remainingDistanceText = ' mi remaining';
        _remainingDurationText = '$minutes min remaining';
      });
    }

    final now = DateTime.now();
    if (_lastRouteFetchAt != null &&
        now.difference(_lastRouteFetchAt!).inSeconds < 8) {
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
        debugPrint('DIRECTIONS HTTP ERROR BODY: ' + response.body);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        debugPrint('DIRECTIONS NO ROUTES BODY: ' + response.body);
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
    } catch (e) {
      debugPrint('DIRECTIONS EXCEPTION: ');
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


  Future<void> _loadDispatchSettings() async {
    try {
      final settings = await _driverRepository.fetchDispatchSettings();
      final rawTimeout = settings['accept_timeout_seconds'];
      final timeout = rawTimeout is num ? rawTimeout.toInt() : int.tryParse('$rawTimeout');

      if (!mounted || timeout == null) return;

      setState(() {
        _dispatchAcceptTimeoutSeconds = timeout.clamp(5, 300);
        _requestSecondsLeft = _dispatchAcceptTimeoutSeconds;
      });
    } catch (_) {
      // Keep safe fallback if dispatcher settings cannot be loaded.
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

  void _syncRequestCountdown() {
    final request = _topRequest;

    if (request == null) {
      _requestCountdownTimer?.cancel();
      _countdownRequestId = null;
      if (_requestSecondsLeft != _dispatchAcceptTimeoutSeconds && mounted) {
        setState(() => _requestSecondsLeft = _dispatchAcceptTimeoutSeconds);
      }
      return;
    }

    if (_countdownRequestId == request.id && _requestCountdownTimer != null) {
      return;
    }

    _requestCountdownTimer?.cancel();
    _countdownRequestId = request.id;
    _requestSecondsLeft = _dispatchAcceptTimeoutSeconds;

    _requestCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_topRequest == null || _topRequest!.id != _countdownRequestId) {
        timer.cancel();
        return;
      }

      if (_requestSecondsLeft <= 1) {
        final expiredId = _countdownRequestId;
        setState(() {
          _expiredRequestIds.add(expiredId ?? -1);
          _requests.removeWhere((r) => r.id == expiredId);
          _requestSecondsLeft = _dispatchAcceptTimeoutSeconds;
          _countdownRequestId = null;
        });
        timer.cancel();
        return;
      }

      setState(() => _requestSecondsLeft--);
    });
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
        _requests = requests.where((r) => !_expiredRequestIds.contains(r.id)).toList();
        _loadingRequests = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncRequestCountdown());
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
    try { await app_main.dispatchAudioPlayer.stop(); } catch (_) {}
    try {
      final active = await _driverRepository.acceptRide(ride.id);
      if (!mounted) return;
      setState(() {
        _activeRide = active ?? ride;
        _navigationStartedForActiveRide = false;
        _requests.removeWhere((e) => e.id == ride.id);
      });
      _lastRouteFetchAt = null;
      await _refreshRemainingTripInfo();
    } catch (e) {
      AppSnackbar.showApiError(
        e,
        fallbackMessage: 'Unable to accept this ride.',
      );
    }
  }

  Future<void> _declineRide(DriverRideRequest ride) async {
    setState(() => _requests.removeWhere((e) => e.id == ride.id));
    _syncRequestCountdown();
    try {
      await _driverRepository.declineRide(ride.id);
    } catch (e) {
      debugPrint('HEAT MAP LOAD ERROR => ');
    }
  }

  Future<void> _openNavigationForActiveRide() async {
    final ride = _activeRide;
    if (ride == null) return;

    Get.to(() => TripNavigationScreenV3(ride: ride));
  }

  void _startDrivingToRider() {
    if (_activeRide == null) return;
    setState(() {
      _navigationStartedForActiveRide = true;
    });
  }

  Future<void> _arrived() async {
    final ride = _activeRide;
    final p = _driverLatLng;
    if (ride == null || p == null) return;

    final miles = _distanceMiles(p, ride.pickupLatLng);
    if (miles > _startTripMaxMiles) {
      AppSnackbar.showError(
        message: 'Arrived will unlock when you are within 0.5 miles of the rider.',
      );
      return;
    }

    try {
      final updated = await _driverRepository.arrived(ride.id);
      if (!mounted) return;

      setState(() {
        _activeRide = updated ?? ride;
        _navigationStartedForActiveRide = true;
      });

      _startArrivalCountdown();
      _lastRouteFetchAt = null;
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
    _requestCountdownTimer?.cancel();

      setState(() {
        _arrivalCountdownSeconds = 0;
        _activeRide = updated ?? ride;
        _navigationStartedForActiveRide = true;
      });

      _lastRouteFetchAt = null;
      await _refreshRemainingTripInfo();
    } catch (e) {
      AppSnackbar.showApiError(e, fallbackMessage: 'Unable to start trip.');
    }
  }

  Future<void> _showTripEarnedSheet(DriverRideRequest ride) async {
    final earned =
        ride.estimatedFare == null ? r'$--' : _money(ride.estimatedFare!);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 90.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_rounded, size: 54.sp, color: AppConst.primaryColor),
                  SizedBox(height: 14.h),
                  Text('Nice work!', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6.h),
                  Text('You just earned', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black54)),
                  SizedBox(height: 4.h),
                  Text(earned, style: TextStyle(fontSize: 44.sp, fontWeight: FontWeight.w900)),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.primaryColor,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Future<bool> _showCompletionReviewSheet() async {
    int stars = 5;
    final commentController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18.w,
                  0,
                  18.w,
                  MediaQuery.of(context).viewInsets.bottom + 85.h,
                ),
                child: Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rate passenger',
                        style: TextStyle(
                          fontSize: 21.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final selected = index < stars;
                          return IconButton(
                            onPressed: () =>
                                modalSetState(() => stars = index + 1),
                            icon: Icon(
                              selected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.orange,
                              size: 38.sp,
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: commentController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Add a comment (optional)',
                          filled: true,
                          fillColor: const Color(0xFFF4F4F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Skip'),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConst.primaryColor,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    commentController.dispose();
    return result == true;
  }

  Future<void> _cancelTrip() async {
    try { await app_main.dispatchAudioPlayer.stop(); } catch (_) {}
    final ride = _activeRide;
    if (ride == null) return;

    try {
      await _driverRepository.declineRide(ride.id);

      if (!mounted) return;

      _arrivalCountdownTimer?.cancel();
    _requestCountdownTimer?.cancel();

      setState(() {
        _activeRide = null;
        _navigationStartedForActiveRide = false;
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

    try {
      await _driverRepository.completeRide(ride.id);
      if (!mounted) return;

      await _showTripEarnedSheet(ride);
      await _showCompletionReviewSheet();

      _arrivalCountdownTimer?.cancel();
      _requestCountdownTimer?.cancel();

      setState(() {
        _activeRide = null;
        _navigationStartedForActiveRide = false;
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
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800),
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
    final driver = _driverLatLng;
    if (c == null || driver == null) return;

    await c.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: driver,
          zoom: 17.5,
          tilt: 35,
          bearing: _heading.isFinite ? _heading : 0,
        ),
      ),
    );
  }

  Set<Circle> _heatMapCircles() {
    return _heatMapZones.map((zone) {
      final isHigh = zone.demandLevel.toLowerCase() == 'high';
      final isMedium = zone.demandLevel.toLowerCase() == 'medium';

      final color = isHigh
          ? Colors.red
          : isMedium
          ? Colors.orange
          : AppConst.primaryColor;

      return Circle(
        circleId: CircleId('heat_zone_${zone.id}'),
        center: LatLng(zone.lat, zone.lng),
        radius: zone.radiusMeters.toDouble(),
        fillColor: color.withOpacity(isHigh ? 0.40 : 0.28),
        strokeColor: color.withOpacity(0.85),
        strokeWidth: 4,
      );
    }).toSet();
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
        color: const Color(0xFF202124),
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
    _driverStatusTimer?.cancel();
    _positionSub?.cancel();
    _pollingTimer?.cancel();
    _locationPushTimer?.cancel();
    _arrivalCountdownTimer?.cancel();
    _requestCountdownTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _driverLatLng ?? _fallbackCenter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (HomeScreen.activeRideNotifier.value != _hasActiveRide) {
        HomeScreen.activeRideNotifier.value = _hasActiveRide;
      }
    });
    return Scaffold(
      body: Stack(
        children: [
          if (_hasActiveRide && _driverLatLng != null && _navigationStartedForActiveRide)
            HomeEmbeddedNavigation(
              origin: _driverLatLng!,
              destination: (_activeRide!.status.toLowerCase() == 'in_progress' || _activeRide!.status.toLowerCase() == 'started')
                  ? _activeRide!.dropoffLatLng
                  : _activeRide!.pickupLatLng,
              title: (_activeRide!.status.toLowerCase() == 'in_progress' || _activeRide!.status.toLowerCase() == 'started')
                  ? 'Dropoff'
                  : 'Pickup',
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(target: mapCenter, zoom: 11),
              markers: _markers(),
              circles: _heatMapCircles(),
              polylines: _polylines(),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              style: HomeMapStyles.lightUberLike,
              onMapCreated: (controller) => _mapController = controller,
            ),
          if (!_hasActiveRide)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  children: [
                    _topBar(),
                    if (_accountStatus != 'approved') ...[
                      _complianceWarningCard(),
                      SizedBox(height: 12.h),
                    ],
                    SizedBox(height: 12.h),
                    const Spacer(),
                    _requestsPanel(),
                  ],
                ),
              ),
            ),
          if (_hasActiveRide)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _activeTripCard(),
            ),
        ],
      ),
    );
  }

  Widget _complianceWarningCard() {
    final docsApproved = _eligibility['documents_approved'] == true;
    final bgApproved = _eligibility['background_check_approved'] == true;

    final issues = <String>[];

    if (!docsApproved) {
      issues.add('Required documents pending');
    }

    if (!bgApproved) {
      issues.add('Background check pending');
    }

    if (_canDrive && issues.isEmpty && !_adminOverride) {
      return const SizedBox.shrink();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => Get.to(() => DriverProfileV2()),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: _adminOverride
              ? Colors.blue.withOpacity(0.18)
              : AppConst.primaryColor.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _adminOverride
                ? Colors.blue.withOpacity(0.25)
                : Colors.black.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _adminOverride
                  ? Icons.admin_panel_settings_rounded
                  : Icons.warning_amber_rounded,
              color: _adminOverride ? Colors.blue : Colors.orange,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _adminOverride
                    ? 'Admin override active for testing'
                    : issues.join('   '),
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.74),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Get.to(() => const SettingScreen()),
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
            ),
          ),
          SizedBox(width: 12.w),
          CircleAvatar(
            radius: 26.r,
            backgroundColor: Colors.white,
            child: _profilePhotoUrl() == null
                ? Icon(Icons.person_rounded, color: Colors.black, size: 30.sp)
                : CircleAvatar(
                    radius: 23.r,
                    backgroundImage: NetworkImage(_profilePhotoUrl()!),
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ' +
                      ((_driverProfile?.name ?? 'Driver').split(' ').first),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppConst.primaryColor,
                    borderRadius: BorderRadius.circular(8.r),
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
          InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => Get.to(
              () => EarningsScreen(
                today: _todayEarnings,
                weekly: _weekEarnings,
                monthly: _monthEarnings,
                wallet: _walletBalance,
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Today ${_money(_todayEarnings)}',
                    style: TextStyle(
                      color: AppConst.primaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Trips $_totalTrips',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsBar() {
    return Container(
      padding: EdgeInsets.all(12.w),
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
                    color: Colors.black54,
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
                  fontSize: 17.sp,
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
                  color: Colors.black,
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
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

                SizedBox(height: 12.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _quickHomeChip(
                        icon: Icons.local_offer_rounded,
                        title: 'Promos',
                        value: '2',
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10.w),
                      _quickHomeChip(
                        icon: Icons.schedule_rounded,
                        title: 'Scheduled',
                        value: '1',
                        color: Colors.blue,
                      ),
                      SizedBox(width: 10.w),
                      _quickHomeChip(
                        icon: Icons.emoji_events_rounded,
                        title: 'Challenges',
                        value: '3',
                        color: Colors.green,
                      ),
                      SizedBox(width: 10.w),
                      _quickHomeChip(
                        icon: Icons.attach_money_rounded,
                        title: 'Today',
                        value: _todayEarnings.toStringAsFixed(0),
                        color: Colors.purple,
                        onTap: () => Get.to(
                          () => EarningsScreen(
                            today: _todayEarnings,
                            weekly: _weekEarnings,
                            monthly: _monthEarnings,
                            wallet: _walletBalance,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 58.h,
                  child: ElevatedButton.icon(
                    onPressed: _accountStatus == 'approved'
                        ? () => _toggleOnline(true)
                        : null,
                    icon: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 22,
                    ),
                    label: Text(
                      'GO ONLINE',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConst.primaryColor,
                      foregroundColor: Colors.black,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
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

                SizedBox(height: 12.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _quickHomeChip(
                        icon: Icons.local_offer_rounded,
                        title: 'Promos',
                        value: '2',
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10.w),
                      _quickHomeChip(
                        icon: Icons.schedule_rounded,
                        title: 'Scheduled',
                        value: '1',
                        color: Colors.blue,
                      ),
                      SizedBox(width: 10.w),
                      _quickHomeChip(
                        icon: Icons.emoji_events_rounded,
                        title: 'Challenges',
                        value: '3',
                        color: Colors.green,
                      ),
                      SizedBox(width: 10.w),
                      _quickHomeChip(
                        icon: Icons.attach_money_rounded,
                        title: 'Today',
                        value: _todayEarnings.toStringAsFixed(0),
                        color: Colors.purple,
                        onTap: () => Get.to(
                          () => EarningsScreen(
                            today: _todayEarnings,
                            weekly: _weekEarnings,
                            monthly: _monthEarnings,
                            wallet: _walletBalance,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18.h),
                SizedBox(
                  width: double.infinity,
                  height: 58.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleOnline(false),
                    icon: const Icon(
                      Icons.power_settings_new_rounded,
                      size: 22,
                    ),
                    label: Text(
                      'GO OFFLINE',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: AppConst.primaryColor,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(width: double.infinity, child: _requestCard(request)),
    );
  }

  Widget _miniStatusPanel(IconData icon, String title, String subtitle) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => Get.to(() => DriverProfileV2()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: Colors.black87),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.black54,
                      height: 1.25,
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

  Widget _emptyPanel(IconData icon, String title, String subtitle) {
    return const SizedBox.shrink();
  }

  Widget _approvalBanner() {
    return const SizedBox.shrink();
  }

  Widget _quickHomeChip({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(DriverRideRequest ride) {
    final progress = (_requestSecondsLeft / 12).clamp(0.0, 1.0).toDouble();
    final pickupMiles = ride.pickupDistanceMiles;
    final pickupEta = pickupMiles == null ? null : math.max(1, (pickupMiles / 25 * 60).round());
    final pickupEtaLine = pickupMiles == null ? 'ETA pending' : pickupEta.toString() + ' min Ã‚Â· ' + pickupMiles.toStringAsFixed(1) + ' mi';

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
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                ride.rideType.toUpperCase(),
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900),
              ),
            ),
            const Spacer(),
            Text(
              ride.estimatedFare == null ? '\$--' : _money(ride.estimatedFare!),
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          pickupEtaLine,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 12.h),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppConst.primaryColor.withOpacity(0.35),
                        valueColor: AlwaysStoppedAnimation<Color>(AppConst.primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _acceptRide(ride),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'ACCEPT',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
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
    final target = toPickup ? ride.pickupLatLng : ride.dropoffLatLng;
    final address = toPickup ? ride.pickupAddress : ride.dropoffAddress;

    double? miles;
    String etaDistText = '--';
    if (_driverLatLng != null) {
      final meters = Geolocator.distanceBetween(
        _driverLatLng!.latitude,
        _driverLatLng!.longitude,
        target.latitude,
        target.longitude,
      );
      miles = meters / 1609.344;
      final minutes = math.max(1, (miles / 0.45).round());
      etaDistText = '$minutes min • ${miles.toStringAsFixed(1)} mi';
    }

    final nearTarget = miles != null && miles <= _startTripMaxMiles;

    String? actionLabel;
    VoidCallback? action;

    final riderName = (ride.riderName ?? '').trim();
    final riderFirstName = riderName.isEmpty ? 'rider' : riderName.split(' ').first;

    if (status == 'accepted') {
      if (!_navigationStartedForActiveRide) {
        actionLabel = 'DRIVE TO ' + riderFirstName.toUpperCase();
        action = _startDrivingToRider;
      } else if (nearTarget) {
        actionLabel = 'ARRIVED';
        action = _arrived;
      }
    } else if (status == 'arrived') {
      actionLabel = 'START';
      action = _startTrip;
    } else if (status == 'started' || status == 'in_progress') {
      if (nearTarget) {
        actionLabel = 'COMPLETE';
        action = _completeTrip;
      }
    }

    final waitText = status == 'arrived' && _arrivalCountdownSeconds > 0
        ? 'Wait ${_formatCountdown(_arrivalCountdownSeconds)}'
        : '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        12.w,
        7.h,
        12.w,
        MediaQuery.of(context).padding.bottom + 7.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(width: 36.w),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      etaDistText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    if (waitText.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        waitText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                        ),
                      ),
                    ],
                    SizedBox(height: 2.h),
                    Text(
                      address,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 36.w,
                height: 42.h,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _showTripActionSheet(),
                ),
              ),
            ],
          ),
          if (actionLabel != null) ...[
            SizedBox(height: 5.h),
            SizedBox(
              width: double.infinity,
              height: 36.h,
              child: ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConst.primaryColor,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],        ],
      ),
    );
  }

  Future<void> _showTripActionSheet() async {
    final ride = _activeRide;
    if (ride == null) return;

    final status = ride.status.toLowerCase();
    final canCancelNoShow = status == 'arrived' && _arrivalCountdownSeconds <= 0;
    final canEarlyDropoff = status == 'started' || status == 'in_progress';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                SizedBox(height: 16.h),
                ListTile(
                  leading: const Icon(Icons.person_pin_circle_rounded),
                  title: const Text('Pickup'),
                  subtitle: Text(ride.pickupAddress),
                ),
                ListTile(
                  leading: const Icon(Icons.flag_rounded),
                  title: const Text('Destination'),
                  subtitle: Text(ride.dropoffAddress),
                ),
                if (ride.estimatedFare != null)
                  ListTile(
                    leading: const Icon(Icons.payments_rounded),
                    title: const Text('Fare'),
                    subtitle: Text(_money(ride.estimatedFare!)),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.volume_off_rounded),
                  title: const Text('Navigation audio / vibration'),
                  subtitle: const Text('Coming next: voice, vibration, silent mode'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.call_rounded),
                  title: const Text('Call rider'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.message_rounded),
                  title: const Text('Message rider'),
                  onTap: () {},
                ),
                if (canEarlyDropoff)
                  ListTile(
                    leading: const Icon(Icons.flag_circle_rounded),
                    title: const Text('Early dropoff'),
                    subtitle: const Text('Complete before reaching 0.5 mi zone'),
                    onTap: () {
                      Navigator.pop(context);
                      _completeTrip();
                    },
                  ),
                ListTile(
                  enabled: canCancelNoShow || status == 'accepted',
                  leading: const Icon(Icons.cancel_rounded, color: Colors.red),
                  title: Text(
                    canCancelNoShow || status == 'accepted'
                        ? 'Cancel trip'
                        : 'Cancel available after wait timer',
                    style: TextStyle(
                      color: canCancelNoShow || status == 'accepted'
                          ? Colors.red
                          : Colors.black38,
                    ),
                  ),
                  onTap: canCancelNoShow || status == 'accepted'
                      ? () {
                          Navigator.pop(context);
                          _cancelTrip();
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _smallPill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.r),
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

















































































