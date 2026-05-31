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
    print('FCM DEBUG: registerDeviceToken called');
    try {
      print('FCM STEP 1');

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      print('FCM STEP 2');

      final fcmToken = await _messaging.getToken();

      print("FCM TOKEN: $fcmToken");

      final authToken = await _storage.getAuthToken();

      print('FCM STEP 3');

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

      print("FCM POST RESULT => ${response.statusCode} : ${response.body}");



    } catch (e) {
      print("FCM DEBUG ERROR: $e");
    }
  }
}






