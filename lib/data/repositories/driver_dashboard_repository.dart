import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:t_rider_services_app/data/network/api_client.dart';

import '../../config/api_urls.dart';
import '../local/secure_storage_service.dart';

class DriverDashboardRepository {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

  Future<Map<String, dynamic>> getDashboard() async {
    final token = await _storage.getAuthToken();

    final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.driverDashboard}');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    print('DASHBOARD STATUS: ${response.statusCode}');
    print('DASHBOARD BODY: ${response.body}');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(decoded['message'] ?? 'Dashboard failed');
    }

    return decoded['data'] as Map<String, dynamic>;
  }
  Future<void> updatePreferences({
    required bool bidEnabled,
    required bool poolingEnabled,
    required bool courierEnabled,
    required bool deliveryEnabled,
    required bool petFriendlyEnabled,
  }) async {
    final token = await _storage.getAuthToken();

    final response = await _apiClient.post(
      ApiUrls.driverPreferences,
      body: {
        'bid_enabled': bidEnabled,
        'pooling_enabled': poolingEnabled,
        'courier_enabled': courierEnabled,
        'delivery_enabled': deliveryEnabled,
        'pet_friendly_enabled': petFriendlyEnabled,
      },
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

}

