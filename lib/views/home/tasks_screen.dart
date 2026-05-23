import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/views/home/widgets/active_orders_section.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedTab = 0;

  final tabs = const ['Active', 'Completed', 'Cancelled', 'Scheduled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Trips',
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6.h),
              Text(
                'Trips, deliveries, receipts, and scheduled work.',
                style: TextStyle(fontSize: 13.sp, color: Colors.black54),
              ),
              SizedBox(height: 18.h),

              Row(
                children: [
                  Expanded(child: _summary('Total', '0', Icons.route_rounded)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _summary(
                      'Earnings',
                      '\$0.00',
                      Icons.payments_rounded,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(child: _summary('Hours', '0h', Icons.timer_rounded)),
                ],
              ),

              SizedBox(height: 18.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final selected = _selectedTab == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppConst.primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.black : Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 20.h),

              if (_selectedTab == 0)
                const ActiveOrdersSection(previewCardLimit: null)
              else if (_selectedTab == 1)
                _emptyState(
                  'No completed trips yet.',
                  Icons.check_circle_rounded,
                )
              else if (_selectedTab == 2)
                _emptyState('No cancelled trips.', Icons.cancel_rounded)
              else
                _emptyState(
                  'No scheduled trips.',
                  Icons.event_available_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppConst.primaryColor, size: 22.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 3.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40.sp, color: AppConst.primaryColor),
          SizedBox(height: 12.h),
          Text(
            text,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6.h),
          Text(
            'When Laravel trip history is connected, trip details, fares, receipts, distance, and ratings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
