import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'setting/driver_profile_v2.dart';
import 'home_screen.dart';
import 'earnings_screen.dart';
import 'nearby_firestore_orders_screen.dart';
import 'tasks_screen.dart';

class Navbar extends StatefulWidget {
  final int initialIndex;

  const Navbar({super.key, this.initialIndex = 0});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeScreenKey),
    const TasksScreen(),
    const NearbyFirestoreOrdersScreen(),
    const EarningsScreen(),
    // Profile Screen
    const DriverProfileV2(),
  ];

  void _selectIndex(int index) {
    final switchedTab = _currentIndex != index;
    setState(() {
      _currentIndex = index;
    });
    if (index == 0 && switchedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _homeScreenKey.currentState?.refreshDashboard();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: HomeScreen.activeRideNotifier,
      builder: (context, hasActiveRide, _) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: (_currentIndex == 0 && hasActiveRide) ? null : (_currentIndex == 0 && (_homeScreenKey.currentState?.hasActiveRide ?? false)) ? null : Container(
        decoration: BoxDecoration(
          color: AppConst.white,
          boxShadow: [
            BoxShadow(
              color: AppConst.blackWithOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 55.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'My trips',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Earnings',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectIndex(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 3.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConst.primaryColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppConst.primaryColor
                    : AppConst.black.withOpacity(0.45),
                size: 21.sp,
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected
                      ? AppConst.primaryColor
                      : AppConst.black.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildCenterButton() {
  //   return GestureDetector(
  //     onTap: () => _selectIndex(2),
  //     child: Container(
  //       width: 65.w,
  //       height: 65.w,
  //       decoration: BoxDecoration(
  //         shape: BoxShape.circle,
  //         color: AppConst.black,
  //         boxShadow: [
  //           BoxShadow(
  //             color: AppConst.blackWithOpacity(0.3),
  //             blurRadius: 8,
  //             offset: const Offset(0, 4),
  //           ),
  //         ],
  //       ),
  //       child: Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(
  //               Icons.keyboard_arrow_down_sharp,
  //               size: 24.sp,
  //               color: AppConst.white,
  //             ),
  //             Text(
  //               'order'.tr,
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 color: AppConst.white,
  //                 fontSize: 11.sp,
  //                 fontWeight: FontWeight.w700,
  //               ),
  //             ),
  //             SizedBox(height: 10.h),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}


