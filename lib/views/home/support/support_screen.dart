import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:t_rider_services_app/consts/appConst.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String supportPhone = '4026126588';
  static const String supportEmail = 'contact@t-ride.tech';

  @override
  Widget build(BuildContext context) {
    final orange = AppConst.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _header(orange),
            SizedBox(height: 16.h),
            _emergencyCard(context, orange),
            SizedBox(height: 16.h),
            _section('Contact T-Ride'),
            _item(
              context,
              orange,
              Icons.chat_bubble_outline_rounded,
              'WhatsApp chat',
              'Message support at $supportPhone',
              () => _copy(context, supportPhone, 'WhatsApp number copied'),
            ),
            _item(
              context,
              orange,
              Icons.phone_outlined,
              'Phone support',
              'Call or text $supportPhone',
              () => _copy(context, supportPhone, 'Phone number copied'),
            ),
            _item(
              context,
              orange,
              Icons.mail_outline_rounded,
              'Email support',
              supportEmail,
              () => _copy(context, supportEmail, 'Email copied'),
            ),
            SizedBox(height: 12.h),
            _section('Common help'),
            _item(
              context,
              orange,
              Icons.route_rounded,
              'Trip issue',
              'Pickup, route, rider, cancellation, or completion problem',
              () => _openDetail(context, 'Trip issue', [
                'Select the trip when backend history is connected.',
                'Explain what happened clearly: pickup, route, rider behavior, payment, or completion issue.',
                'Add photos or screenshots when available.',
                'For urgent safety concerns, use Safety First instead.',
              ]),
            ),
            _item(
              context,
              orange,
              Icons.account_balance_wallet_rounded,
              'Earnings & payouts',
              'Wallet, cash out, bonus, and weekly statements',
              () => _openDetail(context, 'Earnings & payouts', [
                'Check your completed trips and weekly summary.',
                'Report missing trips with date, time, and rider/delivery details.',
                'Cash out will become available once payment backend is connected.',
                'Keep your bank/payment information updated when that feature is enabled.',
              ]),
            ),
            _item(
              context,
              orange,
              Icons.verified_user_rounded,
              'Documents & verification',
              'License, insurance, registration, background check',
              () => _openDetail(context, 'Documents & verification', [
                'Keep driver license, insurance, and vehicle registration active.',
                'Expired documents may pause your ability to receive requests.',
                'Background check status will show Approved, Pending, or Expired.',
                'Use clear photos with readable text when uploading documents.',
              ]),
            ),
            _item(
              context,
              orange,
              Icons.map_rounded,
              'Map & navigation',
              'Location, route, ETA, and live tracking help',
              () => _openDetail(context, 'Map & navigation', [
                'Enable location permission for the Driver App.',
                'Keep GPS on and avoid battery saver while online.',
                'If map is blank, confirm Google Maps API key and Android restrictions.',
                'Live location will sync with the rider after Laravel/Firebase connection.',
              ]),
            ),
            SizedBox(height: 12.h),
            _section('Updates'),
            _item(
              context,
              orange,
              Icons.campaign_rounded,
              'T-Ride updates',
              'Product changes, policies, and announcements',
              () => _openDetail(context, 'T-Ride updates', [
                'Driver App is being prepared for live dispatch connection.',
                'Order App and Driver App will connect to Laravel backend for real ride requests.',
                'Boost includes free learning, safety, delivery, finance, and opportunity content.',
                'Support contacts: WhatsApp/Phone $supportPhone and email $supportEmail.',
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Color orange) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppConst.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: orange.withOpacity(.12),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: orange,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: TextStyle(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w900,
                    color: AppConst.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Get help with trips, earnings, safety, documents, and your account.',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    height: 1.35,
                    color: AppConst.black.withOpacity(.58),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2.w, 6.h, 2.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w900,
          color: AppConst.black,
        ),
      ),
    );
  }

  Widget _emergencyCard(BuildContext context, Color orange) {
    return GestureDetector(
      onTap: () => _openDetail(context, 'Safety First', [
        'If a trip feels unsafe, stop at a safe public place when possible.',
        'Contact T-Ride support immediately through WhatsApp or phone: $supportPhone.',
        'For immediate danger, call local emergency services first.',
        'Verify rider identity and destination before starting.',
        'Do not transport illegal or suspicious packages.',
        'Report harassment, threats, or unsafe behavior as soon as possible.',
      ]),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety first',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Open safety tools and driver safety guidance.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.7),
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.1),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Text(
                'Open',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    Color orange,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 9.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppConst.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: orange.withOpacity(.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: orange, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w900,
                      color: AppConst.black,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppConst.black.withOpacity(.52),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: orange),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openDetail(BuildContext context, String title, List<String> points) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SupportDetailScreen(title: title, points: points),
      ),
    );
  }
}

class _SupportDetailScreen extends StatelessWidget {
  final String title;
  final List<String> points;
  const _SupportDetailScreen({required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    final orange = AppConst.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: AppConst.white,
        elevation: 0,
        foregroundColor: AppConst.black,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: points.map((point) {
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: AppConst.white,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: orange, size: 22.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppConst.black.withOpacity(.75),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
