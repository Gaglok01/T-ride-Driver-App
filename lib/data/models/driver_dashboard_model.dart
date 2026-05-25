/// `GET /api/app/driver/dashboard` ? `data` object.
class DriverDashboardData {
  const DriverDashboardData({
    required this.isOnline,
    this.accountStatus,
    this.driverStatus,
    this.backgroundCheckStatus,
    this.rating,
    this.totalTrips,
    this.earningsToday = 0,
    this.earningsWeekly = 0,
    this.earningsMonthly = 0,
    this.walletBalance = 0,
    this.acceptanceRate = 0,
    this.pendingDocuments = 0,
    this.approvedDocuments = 0,
    this.verified = false,
    this.canDrive = false,
    this.tier,
    this.profileImage,
      this.bidEnabled = true,
    this.poolingEnabled = true,
    this.courierEnabled = true,
    this.deliveryEnabled = true,
  });

  final bool isOnline;
  final String? accountStatus;
  final String? driverStatus;
  final String? backgroundCheckStatus;
  final num? rating;
  final int? totalTrips;
  final num earningsToday;
  final num earningsWeekly;
  final num earningsMonthly;

  final num walletBalance;
  final num acceptanceRate;
  final int pendingDocuments;
  final int approvedDocuments;
  final bool verified;
  final bool canDrive;
  final String? tier;
  final String? profileImage;
  final bool bidEnabled;
  final bool poolingEnabled;
  final bool courierEnabled;
  final bool deliveryEnabled;

  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes' || s == 'approved';
    }
    return false;
  }

  static num _parseNum(dynamic raw, [num fallback = 0]) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw) ?? fallback;
    return fallback;
  }

  static int _parseInt(dynamic raw, [int fallback = 0]) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  factory DriverDashboardData.fromJson(Map<String, dynamic> json) {
    final earnings = json['earnings'];
    num today = 0, weekly = 0, monthly = 0;

    if (earnings is Map) {
      final m = Map<String, dynamic>.from(earnings);
      today = _parseNum(m['today']);
      weekly = _parseNum(m['weekly']);
      monthly = _parseNum(m['monthly']);
    }

    return DriverDashboardData(
      isOnline: _parseBool(json['is_online']),
      accountStatus: json['account_status']?.toString(),
      driverStatus: json['driver_status']?.toString(),
      backgroundCheckStatus: json['background_check_status']?.toString(),
      rating: _parseNum(json['rating']),
      totalTrips: _parseInt(json['total_trips']),
      earningsToday: today,
      earningsWeekly: weekly,
      earningsMonthly: monthly,
      walletBalance: _parseNum(json['wallet_balance']),
      acceptanceRate: _parseNum(json['acceptance_rate']),
      pendingDocuments: _parseInt(json['pending_documents']),
      approvedDocuments: _parseInt(json['approved_documents']),
      verified: _parseBool(json['verified']),
      canDrive: _parseBool(json['can_drive']),
      tier: json['tier']?.toString(),
      profileImage: json['profile_image']?.toString(),
      bidEnabled: json['bid_enabled'] == true || json['bid_enabled'] == 1,
      poolingEnabled: json['pooling_enabled'] == true || json['pooling_enabled'] == 1,
      courierEnabled: json['courier_enabled'] == true || json['courier_enabled'] == 1,
      deliveryEnabled: json['delivery_enabled'] == true || json['delivery_enabled'] == 1,
    );
  }
}

