import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:t_rider_services_app/config/api_urls.dart';
import 'package:t_rider_services_app/data/local/secure_storage_service.dart';
import 'package:t_rider_services_app/data/models/heat_map_zone.dart';

class DriverHeatMapRepository {
  final SecureStorageService _storage = SecureStorageService();

  Future<List<HeatMapZone>> fetchHeatMapZones() async {
    final token = await _storage.getAuthToken();

    final response = await http.get(
      Uri.parse('${ApiUrls.baseUrl}api/public/driver/heat-map'),
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    print('HEAT MAP API STATUS => ${response.statusCode}');
    print('HEAT MAP API BODY => ${response.body}');

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['status'] != true) {
      throw Exception(body['message'] ?? 'Unable to load heat map.');
    }

    return (body['data'] as List)
        .map((e) => HeatMapZone.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
