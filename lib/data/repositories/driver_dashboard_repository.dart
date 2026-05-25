import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_urls.dart';
import '../local/secure_storage_service.dart';

class DriverDashboardRepository {
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
}
