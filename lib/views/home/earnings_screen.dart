import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:t_rider_services_app/consts/appConst.dart';

class EarningsScreen extends StatelessWidget {
  final num today;
  final num weekly;
  final num monthly;
  final num wallet;

  const EarningsScreen({
    super.key,
    this.today = 0,
    this.weekly = 0,
    this.monthly = 0,
    this.wallet = 0,
  });

  String _money(num value) => '\$' + value.toStringAsFixed(2);

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
                'Earnings',
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6.h),
              Text(
                'Your balance, payouts, trips, tips, and weekly performance.',
                style: TextStyle(fontSize: 13.sp, color: Colors.black54),
              ),
              SizedBox(height: 18.h),

              _balanceCard(),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _metric('Today', '\$0.00', Icons.today_rounded),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _metric(
                      'This week',
                      '\$0.00',
                      Icons.calendar_month_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _metric('This month', _money(monthly), Icons.route_rounded)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _metric(
                      'Tips',
                      '\$0.00',
                      Icons.volunteer_activism_rounded,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              _sectionTitle('Payout'),
              _actionTile(
                Icons.account_balance_rounded,
                'Payout method',
                'Add bank or debit card',
                'Setup',
              ),
              _actionTile(
                Icons.schedule_rounded,
                'Pending payout',
                '\$0.00 waiting to settle',
                'View',
              ),
              _actionTile(
                Icons.receipt_long_rounded,
                'Tax statements',
                'Weekly and annual documents',
                'Open',
              ),

              SizedBox(height: 20.h),
              _sectionTitle('Recent activity'),
              _emptyHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: TextStyle(color: Colors.white70, fontSize: 13.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            '\$0.00',
            style: TextStyle(
              color: AppConst.primaryColor,
              fontSize: 36.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Ready for instant cash out when payouts are enabled.',
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Cash out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConst.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConst.primaryColor),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    String action,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConst.primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            action,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: AppConst.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Text(
        'No earnings yet. Completed trips, tips, bonuses, and cash outs will appear here.',
        style: TextStyle(fontSize: 13.sp, color: Colors.black54),
      ),
    );
  }
}


