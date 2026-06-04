import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:t_rider_services_app/config/api_urls.dart';
import 'package:t_rider_services_app/data/local/secure_storage_service.dart';
import 'package:t_rider_services_app/data/network/api_client.dart';

class DriverOnboardingRepository {
  DriverOnboardingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final SecureStorageService _storage = SecureStorageService();

  Future<Map<String, dynamic>> getStatus() async {
    final token = await _storage.getAuthToken();

    final response = await _apiClient.get(
      ApiUrls.driverStatus,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriverOnboardingException(response.statusCode, response.body);
    }

    return decoded;
  }

  Future<Map<String, dynamic>> uploadDocuments({
    File? profilePhoto,
    File? licenseFront,
    File? licenseBack,
    File? vehicleRegistration,
    File? vehiclePhoto,
    File? insurance,
  }) async {
    final token = await _storage.getAuthToken();

    final uri = Uri.parse('${ApiUrls.baseUrl}${ApiUrls.driverUploadDocuments}');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    Future<void> addFile(String field, File? file) async {
      if (file == null) return;
      request.files.add(await http.MultipartFile.fromPath(field, file.path));
    }

    await addFile('image', profilePhoto);
    await addFile('license_front', licenseFront);
    await addFile('license_back', licenseBack);
    await addFile('vehicle_registration', vehicleRegistration);
    await addFile('vehicle_photo', vehiclePhoto);
    await addFile('insurance', insurance);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print('UPLOAD DOCS STATUS: ' + response.statusCode.toString());
    print('UPLOAD DOCS BODY: ' + response.body);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DriverOnboardingException(response.statusCode, response.body);
    }

    return decoded;
  }
}

class DriverOnboardingException implements Exception {
  DriverOnboardingException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'DriverOnboardingException($statusCode): $body';
}
