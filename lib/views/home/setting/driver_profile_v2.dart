import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/data/models/driver_dashboard_model.dart';
import 'package:t_rider_services_app/data/repositories/driver_dashboard_repository.dart';
import 'package:t_rider_services_app/views/home/setting/setting_screen.dart';

class DriverProfileV2 extends StatefulWidget {
  const DriverProfileV2({super.key});

  @override
  State<DriverProfileV2> createState() => _DriverProfileV2State();
}

class _DriverProfileV2State extends State<DriverProfileV2> {
  final DriverDashboardRepository _dashboardRepository = DriverDashboardRepository();

  DriverDashboardData? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final json = await _dashboardRepository.getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = DriverDashboardData.fromJson(json);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  padding: EdgeInsets.all(18.w),
                  children: [
                    if (_error != null) _errorCard(_error!),
            _header(),
            SizedBox(height: 16.h),
            _heroCard(),
            SizedBox(height: 14.h),
            _aiVerificationCard(),
            SizedBox(height: 14.h),
            _vehicleCard(),
            SizedBox(height: 14.h),
            _documentsCard(),
            SizedBox(height: 14.h),
            _preferencesCard(),
            SizedBox(height: 14.h),
            _backgroundCheckCard(),
            SizedBox(height: 14.h),
            _quickActionsCard(),
            SizedBox(height: 24.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            'Driver profile',
            style: TextStyle(fontSize: 27.sp, fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          onPressed: () => Get.to(() => const SettingScreen()),
          icon: const Icon(Icons.tune_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppConst.primaryColor,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _heroCard() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConst.primaryColor.withOpacity(0.18),
              border: Border.all(color: AppConst.primaryColor, width: 3),
            ),
            child: (_dashboard?.profileImage != null && _dashboard!.profileImage!.isNotEmpty)
                  ? ClipOval(
                      child: Image.network(
                        _dashboard!.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person_rounded, size: 36.sp),
                      ),
                    )
                  : Icon(Icons.person_rounded, size: 36.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'T-Ride Driver',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5.h),
                _statusPill('Verified driver', Icons.verified_rounded),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    _miniStat((_dashboard?.rating ?? 0).toString(), 'Rating'),
                    _divider(),
                    _miniStat((_dashboard?.totalTrips ?? 0).toString(), 'Trips'),
                    _divider(),
                    _miniStat('\$240', 'Today'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiVerificationCard() {
    return _sectionCard(
      title: 'AI verification',
      icon: Icons.auto_awesome_rounded,
      children: [
        _verificationStep('Driver license', 'AI verifying identity and expiration', true),
        _verificationStep('Vehicle registration', 'Reading VIN, plate and vehicle details', true),
        _verificationStep('Insurance', 'Checking active coverage', false),
      ],
    );
  }

  Widget _vehicleCard() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: AppConst.primaryColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(Icons.directions_car_filled_rounded, size: 25.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Detected vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome_rounded, color: AppConst.primaryColor),
            ],
          ),
          SizedBox(height: 18.h),
          _genericVehicleVisual(),
          SizedBox(height: 16.h),
          Text(
            _vehicleTitle(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _darkPill(_dashboard?.vehiclePlateNumber?.isNotEmpty == true ? _dashboard!.vehiclePlateNumber! : 'Plate pending'),
              _darkPill(_dashboard?.vehicleColor?.isNotEmpty == true ? _dashboard!.vehicleColor! : 'Color pending'),
              _darkPill(_maskedVin()),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'T-Ride AI reads registration documents automatically. No manual vehicle form needed.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _genericVehicleVisual() {
    final make = (_dashboard?.vehicleMake ?? '').toLowerCase();
    final model = (_dashboard?.vehicleModel ?? '').toLowerCase();
    final color = (_dashboard?.vehicleColor ?? 'Gray').toLowerCase();

    final isSuv = model.contains('cr-v') ||
        model.contains('rav4') ||
        model.contains('escape') ||
        model.contains('pilot') ||
        model.contains('suv');

    final label = isSuv ? 'Generic SUV' : 'Generic sedan';

    return Container(
      width: double.infinity,
      height: 118.h,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(child: Icon(Icons.directions_car_filled_rounded, color: AppConst.primaryColor, size: 82.sp)),
          ),
          SizedBox(width: 14.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                color.capitalizeFirst ?? color,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _documentsCard() {
    return _sectionCard(
      title: 'Documents',
      icon: Icons.shield_rounded,
      children: [
        _documentTile(Icons.badge_rounded, 'Driver license', 'Front and back required', 'AI verifying'),
        _documentTile(Icons.article_rounded, 'Registration', 'Vehicle, VIN and plate detection', 'Required'),
        _documentTile(Icons.verified_user_rounded, 'Insurance', 'Proof of active coverage', 'Required'),
        _documentTile(Icons.person_rounded, 'Profile photo', 'Clear face photo for rider trust', 'Required'),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Upload or update documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _preferencesCard() {
    return _sectionCard(
      title: 'Preferences',
      icon: Icons.tune_rounded,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _preferenceChip('Ride requests', true),
            _preferenceChip('Delivery', true),
            _preferenceChip('Pooling', true),
            _preferenceChip('Pet friendly', false),
          ],
        ),
      ],
    );
  }

  Widget _backgroundCheckCard() {
    final status = (_dashboard?.backgroundCheckStatus ?? 'not_started')
        .replaceAll('_', ' ')
        .capitalizeFirst ?? 'Not started';

    return _sectionCard(
      title: 'Background check',
      icon: Icons.policy_rounded,
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppConst.primaryColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.black, size: 26.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Powered by Checkr. Required before going online.',
                      style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorCard(String message) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _vehicleTitle() {
    final parts = [
      _dashboard?.vehicleYear,
      _dashboard?.vehicleMake,
      _dashboard?.vehicleModel,
    ].where((v) => v != null && v.toString().trim().isNotEmpty).join(' ');

    return parts.isEmpty ? 'Vehicle details will appear here after OCR parsing' : parts;
  }

  String _maskedVin() {
    final vin = _dashboard?.vehicleVin;
    if (vin == null || vin.trim().isEmpty) return 'VIN pending';
    final clean = vin.trim();
    final last = clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
    return 'VIN •••• ';
  }
  Widget _quickActionsCard() {
    return _sectionCard(
      title: 'Quick actions',
      icon: Icons.dashboard_customize_rounded,
      children: [
        _actionTile(Icons.account_balance_wallet_rounded, 'Wallet', 'Earnings and payouts'),
        _actionTile(Icons.support_agent_rounded, 'Support', 'Get help from T-Ride'),
        _actionTile(Icons.settings_rounded, 'Settings', 'Language, account and privacy'),
        _actionTile(Icons.logout_rounded, 'Logout', 'Sign out of this account'),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _verificationStep(String title, String subtitle, bool active) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: active ? AppConst.primaryColor.withOpacity(0.14) : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded,
            color: active ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                SizedBox(height: 3.h),
                Text(subtitle, style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentTile(IconData icon, String title, String subtitle, String status) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
                SizedBox(height: 3.h),
                Text(subtitle, style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: status.contains('verifying') ? Colors.orange : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppConst.primaryColor.withOpacity(0.18),
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }

  Widget _preferenceChip(String label, bool enabled) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: enabled ? AppConst.primaryColor.withOpacity(0.18) : Colors.grey.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: enabled ? AppConst.primaryColor : Colors.black12,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _darkPill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _statusPill(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppConst.primaryColor.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp),
          SizedBox(width: 5.w),
          Text(text, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.black54)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      width: 1,
      height: 24.h,
      color: Colors.black12,
    );
  }

}




class _VehicleSilhouettePainter extends CustomPainter {
  const _VehicleSilhouettePainter({required this.isSuv});

  final bool isSuv;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = AppConst.primaryColor
      ..style = PaintingStyle.fill;

    final glassPaint = Paint()
      ..color = Colors.black.withOpacity(0.30)
      ..style = PaintingStyle.fill;

    final wheelPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.42, w * 0.84, h * 0.28),
      Radius.circular(h * 0.11),
    );
    canvas.drawRRect(body, bodyPaint);

    final roof = Path()
      ..moveTo(w * 0.25, h * 0.43)
      ..lineTo(w * (isSuv ? 0.38 : 0.44), h * 0.22)
      ..lineTo(w * (isSuv ? 0.72 : 0.65), h * 0.22)
      ..lineTo(w * 0.84, h * 0.43)
      ..close();
    canvas.drawPath(roof, bodyPaint);

    final glass = Path()
      ..moveTo(w * 0.37, h * 0.39)
      ..lineTo(w * 0.46, h * 0.27)
      ..lineTo(w * 0.65, h * 0.27)
      ..lineTo(w * 0.74, h * 0.39)
      ..close();
    canvas.drawPath(glass, glassPaint);

    canvas.drawCircle(Offset(w * 0.28, h * 0.72), h * 0.11, wheelPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.72), h * 0.11, wheelPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.72), h * 0.055, bodyPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.72), h * 0.055, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _VehicleSilhouettePainter oldDelegate) {
    return oldDelegate.isSuv != isSuv;
  }
}
