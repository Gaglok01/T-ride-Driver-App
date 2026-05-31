import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../config/api_urls.dart';
import '../local/secure_storage_service.dart';
import '../network/api_client.dart';

class FcmTokenService {
  FcmTokenService({
    FirebaseMessaging? messaging,
    SecureStorageService? storage,
    ApiClient? apiClient,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _storage = storage ?? SecureStorageService(),
        _apiClient = apiClient ?? ApiClient();

  final FirebaseMessaging _messaging;
  final SecureStorageService _storage;
  final ApiClient _apiClient;

  Future<void> registerDeviceToken() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final fcmToken = await _messaging.getToken();
      final authToken = await _storage.getAuthToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM DEBUG: token unavailable');
        return;
      }

      if (authToken == null || authToken.isEmpty) {
        print('FCM DEBUG: auth token unavailable');
        return;
      }

      final response = await _apiClient.post(
        ApiUrls.deviceToken,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: {
          'fcm_token': fcmToken,
        },
      );

      developer.log(
        'POST ${ApiUrls.deviceToken} -> ${response.statusCode}: ${response.body}',
        name: 'FcmTokenService',
      );
    } catch (e) {
      developer.log('Failed to register FCM token: $e', name: 'FcmTokenService');
    }
  }
}

