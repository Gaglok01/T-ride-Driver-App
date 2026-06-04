import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/controllers/app_theme_controller.dart';
import 'package:t_rider_services_app/data/repositories/auth_repository.dart';
import 'package:t_rider_services_app/views/splash/auth_screens/login_screen.dart';
import 'package:t_rider_services_app/views/widgets/app_snackbar.dart';
import 'package:t_rider_services_app/views/home/navbar.dart';
import 'feedback_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final AppThemeController _themeController = Get.find<AppThemeController>();

  bool _pushNotificationsEnabled = true;
  bool _autoAcceptEnabled = false;
  bool _isLoggingOut = false;

  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _authRepository.logout();
      if (!mounted) return;
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      if (mounted)
        AppSnackbar.showApiError(e, fallbackMessage: 'Unable to sign out.');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _showComingSoon(String title) {
    AppSnackbar.showSuccess(
      title: title,
      message: 'This section is ready for backend connection.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(18.w),
          children: [
            _header(),
            SizedBox(height: 18.h),
            _section('Account', [
              _item(
                Icons.person_outline_rounded,
                'Driver profile',
                'Vehicle, documents, payout and trust profile',
                () => Get.offAll(() => const Navbar(initialIndex: 4)),
              ),
              _item(
                Icons.lock_outline_rounded,
                'Security',
                'Password, phone verification and device safety',
                () => _showComingSoon('Security'),
              ),
              _item(
                Icons.account_balance_wallet_outlined,
                'Earnings & payout',
                'Balance, cash out and payment history',
                () => _showComingSoon('Earnings & payout'),
              ),
            ]),
            SizedBox(height: 14.h),
            _section('Work preferences', [
              _toggleItem(
                Icons.notifications_active_outlined,
                'Push notifications',
                'Ride offers, trip updates and alerts',
                _pushNotificationsEnabled,
                (v) => setState(() => _pushNotificationsEnabled = v),
              ),
              _toggleItem(
                Icons.flash_on_rounded,
                'Auto-accept',
                'Automatically accept eligible requests',
                _autoAcceptEnabled,
                (v) => setState(() => _autoAcceptEnabled = v),
              ),
              Obx(
                () => _toggleItem(
                  Icons.contrast_rounded,
                  'Dark mode',
                  'Adjust the app appearance',
                  _themeController.isDarkMode,
                  _themeController.setDarkMode,
                ),
              ),
            ]),
            SizedBox(height: 14.h),
            _section('Support', [
              _item(
                Icons.support_agent_rounded,
                'Help center',
                'Get help with trips, riders and payments',
                () => _showComingSoon('Help center'),
              ),
              _item(
                Icons.feedback_outlined,
                'Send feedback',
                'Report an issue or suggest an improvement',
                () => Get.to(() => const FeedbackScreen()),
              ),
              _item(
                Icons.emergency_share_outlined,
                'Safety tools',
                'Emergency contact and trip sharing',
                () => _showComingSoon('Safety tools'),
              ),
            ]),
            SizedBox(height: 18.h),
            _logoutButton(),
            SizedBox(height: 12.h),
            Text(
              'T-Ride Driver',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Get.offAll(() => const Navbar(initialIndex: 4)),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppConst.primaryColor,
          ),
          style: IconButton.styleFrom(backgroundColor: Colors.white),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Manage your driver account',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      leading: _iconBox(icon),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.sp, color: Colors.black54, height: 1.25),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppConst.primaryColor.withOpacity(0.75),
      ),
      onTap: onTap,
    );
  }

  Widget _toggleItem(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      leading: _iconBox(icon),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.sp, color: Colors.black54, height: 1.25),
      ),
      trailing: Switch(
        value: value,
        activeTrackColor: AppConst.primaryColor.withOpacity(0.55),
        activeColor: AppConst.primaryColor,
        inactiveThumbColor: AppConst.primaryColor.withOpacity(0.75),
        onChanged: onChanged,
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        color: AppConst.primaryColor.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(icon, color: AppConst.primaryColor, size: 21.sp),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _onLogoutPressed,
        icon: _isLoggingOut
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_rounded),
        label: Text(_isLoggingOut ? 'Signing out...' : 'Sign out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade100),
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
