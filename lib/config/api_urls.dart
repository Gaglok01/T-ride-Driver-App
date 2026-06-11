/// API base URL and endpoint constants for T-Ride.
/// Structure follows MVVM - config lives in core layer.
class ApiUrls {
  ApiUrls._();

  static const String baseUrl = 'https://order.t-ride.tech/';

  // Languages
  static const String languages = 'api/languages';

  // Roles
  static const String roles = 'api/roles';

  // Auth
  static const String login = 'api/app/login';
  static const String sendOtp = 'api/app/send-otp';
  static const String verifyOtp = 'api/app/verify-otp';
  static const String register = 'api/app/register';
  static const String logout = 'api/logout';
  static const String appLogout = 'api/app/logout';

  // Profile
  static const String getProfile = 'api/app/get-profile';
  static const String updateProfile = 'api/app/update-profile';

  /// Driver home dashboard Ã¢â‚¬â€ `GET` (is_online, stats).
  static const String driverDashboard = 'api/app/driver/dashboard';
  static const String driverPreferences = 'api/app/driver/preferences';

  /// Driver online toggle Ã¢â‚¬â€ `POST` body: `{ "is_online": true }`.
  static const String updateOnlineStatus = 'api/app/driver/toggle-online';
  static const String driverStatus = 'api/app/driver/status';
  static const String driverProfileSetup = 'api/app/driver/profile-setup';
  static const String driverUploadDocuments = 'api/app/driver/upload-docs';
  static const String deviceToken = 'api/app/device-token';

  // Feedback
  static const String submitFeedback = 'api/app/submit-feedback';

  // Location
  static const String saveLocation = 'api/app/save-location';

  // Rides
  static const String ridesEstimate = 'api/app/rides/estimate';
  static const String ridesNearbyDrivers = 'api/app/rides/nearby-drivers';
  static const String ridesRequest = 'api/app/rides/request';
  static const String ridesActive = 'api/app/rides/active';

  /// Active ride / courier / food delivery snapshot for the rider app.
  static const String ridesActiveStatus = 'api/app/rides/active-status';

  /// `POST` Ã¢â‚¬â€ `api/app/rides/{id}/cancel`
  static String rideCancel(int rideId) => 'api/app/rides/$rideId/cancel';

  /// `POST` Ã¢â‚¬â€ `api/app/driver/ride/{id}/status`
  /// Driver-side completion endpoint (replaces the old
  /// `api/app/rides/{id}/complete`). Body: none.
  static String rideComplete(int rideId) =>
      'api/app/driver/ride/$rideId/status';

  /// `GET` Ã¢â‚¬â€ `api/app/rides/{id}` (single ride details)
  static String rideDetails(int rideId) => 'api/app/rides/$rideId';

  // Courier
  static const String courierEstimate = 'api/app/courier/estimate';
  static const String courierRequest = 'api/app/courier/request';
  static const String courierNearby = 'api/app/courier/nearby';
  static const String courierActive = 'api/app/courier/active';

  /// `POST` Ã¢â‚¬â€ cancel courier job: `api/app/courier/{id}/cancel`
  static String courierCancel(int id) => 'api/app/courier/$id/cancel';

  /// `POST` Ã¢â‚¬â€ `api/app/courier/{id}/complete`
  static String courierComplete(int id) => 'api/app/courier/$id/complete';

  /// `GET` Ã¢â‚¬â€ `api/app/courier/{id}` (single courier details)
  static String courierDetails(int courierId) => 'api/app/courier/$courierId';

  /// `POST` Ã¢â‚¬â€ driver accepts a ride: `api/app/driver/ride/{id}/accept`
  static String driverAcceptRide(int rideId) =>
      'api/app/driver/ride/$rideId/accept';

  /// `POST` Ã¢â‚¬â€ `api/app/driver/courier/{id}/accept`
  static String driverAcceptCourier(int courierId) =>
      'api/app/driver/courier/$courierId/accept';

  static String driverCourierProof(int courierId) =>
      'api/app/driver/courier/$courierId/proof';

  // Food / delivery (driver)
  static const String foodOrderActive = 'api/app/food/order/active';

  /// `POST` Ã¢â‚¬â€ `api/app/food/order/{id}/cancel`
  static String foodOrderCancel(int orderId) =>
      'api/app/food/order/$orderId/cancel';

  /// `POST` Ã¢â‚¬â€ `api/app/food/order/{id}/complete`
  static String foodOrderComplete(int orderId) =>
      'api/app/food/order/$orderId/complete';

  /// `POST` Ã¢â‚¬â€ driver accepts a food delivery order.
  static String driverAcceptFoodOrder(int orderId) =>
      'api/app/driver/food/$orderId/accept';

  // Rental
  static const String rentalItems = 'api/app/rental/items';
  static const String rentalItemDetails = 'api/app/rental/item';
  static const String rentalBook = 'api/app/rental/book';

  // Driver realtime MVP endpoints (new Laravel backend can map to these)
  static const String driverRequests = 'api/app/driver/requests';
  static const String driverDispatchSettings = 'api/app/driver/dispatch-settings';
  static const String driverActiveRide = 'api/app/driver/ride/active';
  static const String driverLocationUpdate = 'api/app/driver/location';
  static String driverDeclineRide(int rideId) =>
      'api/app/driver/ride/$rideId/decline';
  static String driverArrivedRide(int rideId) =>
      'api/app/driver/ride/$rideId/arrived';
  static String driverStartRide(int rideId) =>
      'api/app/driver/ride/$rideId/start';
  static String driverCompleteRide(int rideId) =>
      'api/app/driver/ride/$rideId/complete';
  static String driverBidRide(int rideId) => 'api/app/driver/ride/$rideId/bid';

  // Add more endpoints as you integrate APIs
  // static const String profile = 'api/profile';
  // static const String rides = 'api/rides';
}


