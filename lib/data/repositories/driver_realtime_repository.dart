import 'dart:convert';

import 'package:t_rider_services_app/config/api_urls.dart';
import 'package:t_rider_services_app/data/local/secure_storage_service.dart';
import 'package:t_rider_services_app/data/models/driver_ride_request_model.dart';
import 'package:t_rider_services_app/data/network/api_client.dart';

class DriverRealtimeRepository {
  DriverRealtimeRepository({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  }) : _apiClient = apiClient ?? ApiClient(),
       _storageService = storageService ?? SecureStorageService();

  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  Future<Map<String, String>> _headers() async {
    final token = await _storageService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw DriverRealtimeException(401, 'Missing auth token');
    }
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<List<DriverRideRequest>> fetchRequests({
    required double? lat,
    required double? lng,
    bool bid = true,
    bool pooling = true,
  }) async {
    final response = await _apiClient.get(
      ApiUrls.driverRequests,
      headers: await _headers(),
      query: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'bid': bid ? 1 : 0,
        'pooling': pooling ? 1 : 0,
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriverRealtimeException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
// ignore: avoid_print
print('DriverRealtimeRepository.fetchActiveRide body: ' + response.body);
    dynamic raw = decoded;
    if (decoded is Map) {
      raw = decoded['data'] ?? decoded['requests'] ?? decoded['rides'] ?? [];
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DriverRideRequest.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList();
  }


  Future<Map<String, dynamic>> fetchDispatchSettings() async {
    final response = await _apiClient.get(
      ApiUrls.driverDispatchSettings,
      headers: await _headers(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriverRealtimeException(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body);
// ignore: avoid_print
print('DriverRealtimeRepository.fetchActiveRide body: ' + response.body);
    final raw = decoded is Map ? decoded['data'] : null;

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return const <String, dynamic>{};
  }

  Future<DriverRideRequest?> fetchActiveRide() async {
    final response = await _apiClient.get(
      ApiUrls.driverActiveRide,
      headers: await _headers(),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriverRealtimeException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
// ignore: avoid_print
print('DriverRealtimeRepository.fetchActiveRide body: ' + response.body);
    dynamic raw = decoded is Map
        ? (decoded['data'] ?? decoded['ride'])
        : decoded;

    // ignore: avoid_print
    print('DriverRealtimeRepository.fetchActiveRide raw: ' + raw.toString());

    if (raw is List) {
      // ignore: avoid_print
      print('DriverRealtimeRepository.fetchActiveRide ignored list data: ' + raw.toString());
      return null;
    }
    if (raw is! Map) return null;

    final parsed = DriverRideRequest.fromJson(Map<String, dynamic>.from(raw));

    // ignore: avoid_print
    print('DriverRealtimeRepository.fetchActiveRide parsed: id=' + parsed.id.toString() + ', type=' + parsed.rideType + ', status=' + parsed.status);

    return parsed;
  }

  Future<void> updateLocation({
    required double lat,
    required double lng,
    required double heading,
    required bool isOnline,
  }) async {
    final response = await _apiClient.post(
      ApiUrls.driverLocationUpdate,
      headers: await _headers(),
      body: {'lat': lat, 'lng': lng, 'heading': heading, 'is_online': isOnline},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DriverRealtimeException(response.statusCode, response.body);
    }
  }

  Future<DriverRideRequest?> acceptRide(int rideId) async {
    return _postRideAction(ApiUrls.driverAcceptRide(rideId));
  }

  Future<DriverRideRequest?> acceptCourierJob(int courierId) async {
    return _postRideAction(
      ApiUrls.driverAcceptCourier(courierId),
      body: {'action': 'accept'},
    );
  }

  Future<void> declineRide(int rideId) async {
    await _postVoid(ApiUrls.driverDeclineRide(rideId));
  }

  Future<DriverRideRequest?> arrived(int rideId) async {
    return _postRideAction(ApiUrls.driverArrivedRide(rideId));
  }

  Future<DriverRideRequest?> startRide(int rideId) async {
    return _postRideAction(ApiUrls.driverStartRide(rideId));
  }

  Future<DriverRideRequest?> completeRide(int rideId) async {
    return _postRideAction(ApiUrls.driverCompleteRide(rideId));
  }

  Future<void> submitBid({required int rideId, required num amount}) async {
    await _postVoid(ApiUrls.driverBidRide(rideId), body: {'amount': amount});
  }

  Future<DriverRideRequest?> _postRideAction(String endpoint, {Object? body}) async {
    final response = await _apiClient.post(
      endpoint,
      headers: await _headers(),
      body: body,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriverRealtimeException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
// ignore: avoid_print
print('DriverRealtimeRepository.fetchActiveRide body: ' + response.body);
    dynamic raw = decoded is Map
        ? (decoded['data'] ?? decoded['ride'])
        : decoded;
    if (raw is Map)
      return DriverRideRequest.fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  Future<void> _postVoid(String endpoint, {Object? body}) async {
    final response = await _apiClient.post(
      endpoint,
      headers: await _headers(),
      body: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DriverRealtimeException(response.statusCode, response.body);
    }
  }
}

class DriverRealtimeException implements Exception {
  DriverRealtimeException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'DriverRealtimeException($statusCode): $body';
}











