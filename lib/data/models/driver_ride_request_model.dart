import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRideRequest {
  const DriverRideRequest({
    required this.id,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.estimatedFare,
    this.distanceMiles,
    this.durationMinutes,
    this.rideType = 'ride',
    this.status = 'requested',
    this.riderName,
    this.canBid = false,
    this.isPooling = false,
  });

  final int id;
  final String pickupAddress;
  final String dropoffAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final num? estimatedFare;
  final num? distanceMiles;
  final num? durationMinutes;
  final String rideType;
  final String status;
  final String? riderName;
  final bool canBid;
  final bool isPooling;

  LatLng get pickupLatLng => LatLng(pickupLat, pickupLng);
  LatLng get dropoffLatLng => LatLng(dropoffLat, dropoffLng);

  factory DriverRideRequest.fromJson(Map<String, dynamic> json) {
    final pickup = _asMap(json['pickup']) ?? _asMap(json['pickup_location']);
    final dropoff = _asMap(json['dropoff']) ?? _asMap(json['destination']);
    return DriverRideRequest(
      id: _asInt(json['id'] ?? json['ride_id']),
      pickupAddress: _asString(
        json['pickup_address'] ?? pickup?['address'] ?? pickup?['name'],
        fallback: 'Pickup location',
      ),
      dropoffAddress: _asString(
        json['dropoff_address'] ?? json['destination_address'] ?? dropoff?['address'] ?? dropoff?['name'],
        fallback: 'Destination',
      ),
      pickupLat: _asDouble(json['pickup_lat'] ?? pickup?['lat'] ?? pickup?['latitude']),
      pickupLng: _asDouble(json['pickup_lng'] ?? pickup?['lng'] ?? pickup?['longitude']),
      dropoffLat: _asDouble(json['dropoff_lat'] ?? json['destination_lat'] ?? dropoff?['lat'] ?? dropoff?['latitude']),
      dropoffLng: _asDouble(json['dropoff_lng'] ?? json['destination_lng'] ?? dropoff?['lng'] ?? dropoff?['longitude']),
      estimatedFare: _asNum(json['estimated_fare'] ?? json['fare'] ?? json['price']),
      distanceMiles: _asNum(json['distance_miles'] ?? json['distance']),
      durationMinutes: _asNum(json['duration_minutes'] ?? json['eta_minutes']),
      rideType: _asString(json['ride_type'] ?? json['type'], fallback: 'ride'),
      status: _asString(json['status'], fallback: 'requested'),
      riderName: json['rider_name']?.toString() ?? _asMap(json['rider'])?['name']?.toString(),
      canBid: _asBool(json['can_bid'] ?? json['bid_enabled']),
      isPooling: _asBool(json['is_pooling'] ?? json['pooling']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? 0}') ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? 0}') ?? 0;
  }

  static num? _asNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse('${v ?? ''}');
  }

  static String _asString(dynamic v, {required String fallback}) {
    final s = v?.toString().trim();
    return s == null || s.isEmpty ? fallback : s;
  }

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
}
