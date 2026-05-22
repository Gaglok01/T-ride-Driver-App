import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:t_rider_services_app/consts/appConst.dart';

class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  int _selected = 0;

  final List<_BoostTab> _tabs = const [
    _BoostTab('Today', Icons.bolt_rounded),
    _BoostTab('Learn', Icons.school_rounded),
    _BoostTab('Opportunities', Icons.near_me_rounded),
    _BoostTab('Bonuses', Icons.card_giftcard_rounded),
  ];

  late final _dailyIndex = DateTime.now().difference(DateTime(2026, 1, 1)).inDays;

  List<_Article> get _articles => const [
        _Article(
          category: 'Customer Service',
          title: 'How to earn more 5-star ratings',
          time: '3 min read',
          icon: Icons.star_rounded,
          summary: 'Small habits that make riders feel safe, respected, and comfortable.',
          body: [
            'Greet the rider by name when possible and confirm the destination before moving.',
            'Keep your vehicle clean, comfortable, and free of strong odors.',
            'Drive smoothly. Avoid hard braking, aggressive turns, and loud music unless the rider requests it.',
            'Communicate delays early. A short professional message is better than silence.',
            'End the trip politely: “Thank you for riding with T-Ride. Have a safe day.”',
          ],
        ),
        _Article(
          category: 'Safety First',
          title: 'Safe pickup habits at night',
          time: '4 min read',
          icon: Icons.health_and_safety_rounded,
          summary: 'Protect yourself and your rider during late-night pickups.',
          body: [
            'Stop in a well-lit, legal, and visible area. Avoid blocking traffic.',
            'Before unlocking doors, verify the rider name and destination in the app.',
            'If the pickup spot feels unsafe, call or message the rider to meet at a safer visible location.',
            'Keep your phone charged and mounted. Do not hold it while driving.',
            'Use the Support/Safety section if a trip feels unsafe or suspicious.',
          ],
        ),
        _Article(
          category: 'Delivery Skills',
          title: 'How to handle packages professionally',
          time: '3 min read',
          icon: Icons.inventory_2_rounded,
          summary: 'Simple delivery habits that build trust and prevent complaints.',
          body: [
            'Confirm the package type, pickup address, drop-off address, and recipient instructions.',
            'Place fragile items safely and avoid stacking heavy items on top of them.',
            'Use photo proof when required. Make sure the photo clearly shows the delivery location.',
            'For food delivery, keep hot and cold items separated when possible.',
            'Never open packages. Report damage or suspicious items through Support.',
          ],
        ),
        _Article(
          category: 'Financial Tips',
          title: 'Track fuel, taxes, and weekly profit',
          time: '5 min read',
          icon: Icons.savings_rounded,
          summary: 'Know what you really earn after expenses.',
          body: [
            'Track mileage daily. Mileage records can help you understand real profit and may help at tax time.',
            'Separate fuel, maintenance, insurance, car wash, and phone expenses.',
            'Set aside a percentage of earnings for taxes and vehicle maintenance.',
            'Compare busy hours with fuel usage. Sometimes shorter rides in busy zones are more profitable.',
            'Review weekly earnings, not only daily totals. Consistency wins.',
          ],
        ),
        _Article(
          category: 'Vehicle Care',
          title: 'Daily checks before going online',
          time: '2 min read',
          icon: Icons.car_repair_rounded,
          summary: 'A professional driver checks the car before the first trip.',
          body: [
            'Check tire pressure and visible tire condition.',
            'Confirm headlights, brake lights, and turn signals work.',
            'Keep windshield, mirrors, and camera areas clean.',
            'Keep water, phone charger, and basic cleaning wipes available.',
            'If something feels unsafe, do not go online until it is fixed.',
          ],
        ),
        _Article(
          category: 'T-Ride Standards',
          title: 'What professional drivers should know',
          time: '4 min read',
          icon: Icons.verified_rounded,
          summary: 'The basics of representing T-Ride professionally.',
          body: [
            'Respect every rider, delivery customer, and business partner.',
            'Keep communication polite, short, and clear.',
            'Never ask riders for personal information outside the app.',
            'Follow local traffic laws and never drive distracted.',
            'Report issues early so support can help before they become bigger problems.',
          ],
        ),
      ];

  List<_FunItem> get _funItems => const [
        _FunItem('Driver joke of the day', 'Why did the driver bring a ladder? Because the fare was going up.'),
        _FunItem('Quick challenge', 'Today: complete your first 3 trips with a perfect greeting and smooth pickup.'),
        _FunItem('One-minute reset', 'Before going online: breathe, check mirrors, check phone battery, and set your goal.'),
        _FunItem('T-Ride idea', 'Ask one rider what would make local rides better. Great products listen first.'),
      ];

  @override
  Widget build(BuildContext context) {
    final orange = AppConst.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(orange)),
            SliverToBoxAdapter(child: _tabsBar(orange)),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverToBoxAdapter(child: _selectedBody(orange)),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          ],
        ),
      ),
    );
  }

  Widget _header(Color orange) {
    final dailyTip = _articles[_dailyIndex % _articles.length];
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      padding: EdgeInsets.all(18.w),
      decoration: _cardDecoration(radius: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(color: orange.withOpacity(.14), borderRadius: BorderRadius.circular(18.r)),
            child: Icon(Icons.bolt_rounded, color: orange, size: 30.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Boost', style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.w900, color: AppConst.black)),
              SizedBox(height: 4.h),
              Text('Learn, earn smarter, and discover opportunities with T-Ride.', style: TextStyle(fontSize: 12.5.sp, height: 1.35, color: AppConst.black.withOpacity(.58), fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        SizedBox(height: 14.h),
        GestureDetector(
          onTap: () => _openArticle(dailyTip),
          child: Container(
            padding: EdgeInsets.all(13.w),
            decoration: BoxDecoration(color: orange.withOpacity(.08), borderRadius: BorderRadius.circular(18.r)),
            child: Row(children: [
              Icon(Icons.auto_stories_rounded, color: orange),
              SizedBox(width: 10.w),
              Expanded(child: Text('Today’s free read: ${dailyTip.title}', style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w900, color: AppConst.black))),
              Icon(Icons.chevron_right_rounded, color: orange),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tabsBar(Color orange) {
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final active = _selected == index;
          return GestureDetector(
            onTap: () => setState(() => _selected = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: active ? orange : AppConst.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: active ? orange : Colors.black.withOpacity(.06)),
              ),
              child: Row(children: [
                Icon(tab.icon, size: 18.sp, color: active ? Colors.white : orange),
                SizedBox(width: 6.w),
                Text(tab.title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: active ? Colors.white : AppConst.black.withOpacity(.75))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _selectedBody(Color orange) {
    switch (_selected) {
      case 1:
        return _learn(orange);
      case 2:
        return _opportunities(orange);
      case 3:
        return _bonuses(orange);
      default:
        return _today(orange);
    }
  }

  Widget _today(Color orange) {
    final fun = _funItems[_dailyIndex % _funItems.length];
    return Column(children: [
      _sectionTitle('Demand insights', 'Know where to drive smarter'),
      _clickCard(orange, Icons.flight_takeoff_rounded, 'Airport demand playbook', 'Best practices for airport pickups and scheduled trips.', () => _openInfo('Airport demand playbook', [
            'Arrive near airport zones before peak arrival windows, not after.',
            'Keep trunk space clean for luggage.',
            'Confirm terminal or pickup door before moving.',
            'Use scheduled rides later when connected to dispatch.',
          ])),
      _clickCard(orange, Icons.location_city_rounded, 'Downtown quick-trip strategy', 'Learn how short trips can increase hourly earnings.', () => _openInfo('Downtown quick-trip strategy', [
            'Stay near safe pickup zones and busy restaurants.',
            'Short trips can improve trip count and reduce empty miles.',
            'Avoid circling too long; reposition after 10–15 minutes if inactive.',
          ])),
      _sectionTitle('Free daily content', 'Something useful, light, or fun each day'),
      _funCard(orange, fun),
      _sectionTitle('Quick learning tools', 'Tap to read inside the app'),
      _grid([
        _GridItem('Safety First', Icons.security_rounded, 'Modern safety guide', () => _openSafety()),
        _GridItem('Fuel Savings', Icons.local_gas_station_rounded, 'Save more weekly', () => _openInfo('Fuel saving tips', [
              'Avoid long idle time while waiting for rides.',
              'Keep tires properly inflated.',
              'Drive smoothly to reduce fuel use.',
              'Track fuel cost per shift so you know real profit.',
            ])),
        _GridItem('Ratings', Icons.star_rounded, 'Improve rider trust', () => _openArticle(_articles.first)),
        _GridItem('Updates', Icons.campaign_rounded, 'T-Ride news', () => _openUpdates()),
      ], orange),
    ]);
  }

  Widget _learn(Color orange) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Free driver learning', 'Short lessons you can read anytime'),
      ..._articles.map((l) => _lessonCard(l, orange)),
      _sectionTitle('Mini video ideas', 'Coming soon in-app content'),
      _clickCard(orange, Icons.play_circle_outline_rounded, '1-minute driver training clips', 'Short videos can be connected later from YouTube, Vimeo, or T-Ride backend.', () => _openInfo('Mini video ideas', [
            'How to greet riders professionally.',
            'How to inspect your car before going online.',
            'How to handle a difficult pickup location.',
            'How to deliver food without spills.',
            'Tomorrow we can connect this to real video links from the backend.',
          ])),
    ]);
  }

  Widget _opportunities(Color orange) {
    return Column(children: [
      _sectionTitle('Nearby opportunities', 'Prepared for live dispatch data'),
      _clickCard(orange, Icons.directions_car_rounded, 'Ride opportunities', 'Nearby requests will appear here when connected to dispatch.', () => _openInfo('Ride opportunities', [
            'This area will show real requests from Laravel dispatch.',
            'Drivers will see pickup distance, fare estimate, time, and trip type.',
            'Bid Ride and Pooling will be available for eligible requests.',
          ])),
      _clickCard(orange, Icons.restaurant_rounded, 'Delivery hotspots', 'Restaurants and delivery activity near you.', () => _openInfo('Delivery hotspots', [
            'Show nearby restaurants when connected to Google Places or backend partners.',
            'Useful data: prep time, distance, expected payout, and customer instructions.',
            'Delivery mode can be toggled in trip preferences.',
          ])),
      _clickCard(orange, Icons.local_shipping_rounded, 'Courier jobs', 'Packages, documents, and urgent local delivery.', () => _openInfo('Courier jobs', [
            'Courier jobs should show package size, pickup time, drop-off distance, and proof requirements.',
            'Add photo proof and OTP verification in the next backend phase.',
          ])),
      _clickCard(orange, Icons.key_rounded, 'Rental requests', 'Vehicle and rental opportunities for approved drivers.', () => _openInfo('Rental requests', [
            'This can include car rental, XL vehicles, business transport, and local rental opportunities.',
            'Drivers should only see eligible rental requests after verification.',
          ])),
    ]);
  }

  Widget _bonuses(Color orange) {
    return Column(children: [
      _sectionTitle('Promotions & achievements', 'Motivation for professional drivers'),
      _bonusCard(orange, 'Complete 10 rides', '+ bonus opportunity', .45, () => _openInfo('Complete 10 rides', [
            'Bonus campaigns will come from the backend.',
            'Example: complete 10 rides today and unlock a reward.',
            'Progress should update automatically after each completed trip.',
          ])),
      _bonusCard(orange, 'Gold Driver progress', '3 more rides to next level', .72, () => _openInfo('Driver levels', [
            'Silver: reliable active driver.',
            'Gold: strong completion and rating.',
            'Platinum: top performance and acceptance.',
            'Diamond: elite T-Ride partner.',
          ])),
      _bonusCard(orange, '5-star streak', 'Keep your current service quality', .86, () => _openArticle(_articles.first)),
      _clickCard(orange, Icons.emoji_events_rounded, 'Achievements', 'Safe driver • Reliable partner • Fast responder', () => _openInfo('Achievements', [
            'Safe Driver badge: low cancellation and safe driving history.',
            'Reliable Partner: consistent schedule and accepted requests.',
            'Fast Responder: quick response to incoming offers.',
          ])),
    ]);
  }

  Widget _sectionTitle(String title, String sub) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w900, color: AppConst.black)),
        SizedBox(height: 2.h),
        Text(sub, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: AppConst.black.withOpacity(.52))),
      ]),
    );
  }

  Widget _clickCard(Color orange, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(15.w),
        decoration: _cardDecoration(),
        child: Row(children: [
          _iconBox(icon, orange),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 3.h),
            Text(subtitle, style: TextStyle(fontSize: 11.5.sp, height: 1.35, fontWeight: FontWeight.w600, color: AppConst.black.withOpacity(.55))),
          ])),
          Icon(Icons.chevron_right_rounded, color: orange),
        ]),
      ),
    );
  }

  Widget _lessonCard(_Article lesson, Color orange) {
    return GestureDetector(
      onTap: () => _openArticle(lesson),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(14.w),
        decoration: _cardDecoration(),
        child: Row(children: [
          _iconBox(lesson.icon, orange),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lesson.category, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: orange)),
            SizedBox(height: 3.h),
            Text(lesson.title, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w900, color: AppConst.black)),
            SizedBox(height: 4.h),
            Text('${lesson.time} • ${lesson.summary}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.sp, color: AppConst.black.withOpacity(.5), fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(color: orange.withOpacity(.1), borderRadius: BorderRadius.circular(20.r)),
            child: Text('Read', style: TextStyle(color: orange, fontSize: 11.sp, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );
  }

  Widget _funCard(Color orange, _FunItem item) {
    return GestureDetector(
      onTap: () => _openInfo(item.title, [item.text, 'This section can refresh daily from Laravel later. For now it changes based on the day.']),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Row(children: [
          Container(width: 44.w, height: 44.w, decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(15.r)), child: const Icon(Icons.emoji_emotions_rounded, color: Colors.white)),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 3.h),
            Text(item.text, style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 11.5.sp, fontWeight: FontWeight.w600)),
          ])),
          Icon(Icons.chevron_right_rounded, color: orange),
        ]),
      ),
    );
  }

  Widget _grid(List<_GridItem> items, Color orange) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10.h, crossAxisSpacing: 10.w, childAspectRatio: 1.55),
        itemBuilder: (_, i) {
          final item = items[i];
          return GestureDetector(
            onTap: item.onTap,
            child: Container(
              padding: EdgeInsets.all(13.w),
              decoration: _cardDecoration(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(item.icon, color: orange, size: 24.sp),
                const Spacer(),
                Text(item.title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w900)),
                SizedBox(height: 3.h),
                Text(item.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5.sp, color: AppConst.black.withOpacity(.48), fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _bonusCard(Color orange, String title, String sub, double progress, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(15.w),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _iconBox(Icons.workspace_premium_rounded, orange),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 3.h),
              Text(sub, style: TextStyle(fontSize: 12.sp, color: AppConst.black.withOpacity(.55), fontWeight: FontWeight.w600)),
            ])),
            Icon(Icons.chevron_right_rounded, color: orange),
          ]),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(value: progress, minHeight: 7.h, backgroundColor: orange.withOpacity(.12), valueColor: AlwaysStoppedAnimation<Color>(orange)),
          ),
        ]),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: AppConst.white,
      borderRadius: BorderRadius.circular(radius.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 6))],
    );
  }

  Widget _iconBox(IconData icon, Color orange) {
    return Container(width: 42.w, height: 42.w, decoration: BoxDecoration(color: orange.withOpacity(.12), borderRadius: BorderRadius.circular(14.r)), child: Icon(icon, color: orange, size: 22.sp));
  }

  void _openArticle(_Article article) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BoostDetailScreen(article: article)));
  }

  void _openInfo(String title, List<String> points) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _InfoDetailScreen(title: title, points: points)));
  }

  void _openSafety() {
    _openInfo('Safety First', [
      'Verify the rider name and destination before starting.',
      'Use well-lit pickup and drop-off locations when possible.',
      'Do not start a trip if the pickup feels unsafe. Contact support.',
      'Keep doors locked until the rider is confirmed.',
      'Use emergency help if you feel threatened.',
      'Report harassment, suspicious packages, or unsafe behavior immediately.',
    ]);
  }

  void _openUpdates() {
    _openInfo('T-Ride Updates', [
      'Driver app is being prepared for live Laravel dispatch connection.',
      'Boost will later receive daily learning content, promotions, and opportunities from the backend.',
      'Ride, Delivery, Courier, Pooling, and Bid Ride modes are being organized for the MVP.',
      'Support contacts: WhatsApp/Phone 4026126588 and email contact@t-ride.tech.',
    ]);
  }
}

class _BoostDetailScreen extends StatelessWidget {
  final _Article article;
  const _BoostDetailScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    final orange = AppConst.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(backgroundColor: AppConst.white, elevation: 0, foregroundColor: AppConst.black, title: Text(article.category, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(color: AppConst.white, borderRadius: BorderRadius.circular(24.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 18, offset: const Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(article.icon, color: orange, size: 34.sp),
              SizedBox(height: 12.h),
              Text(article.title, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: AppConst.black)),
              SizedBox(height: 8.h),
              Text('${article.time} • Free T-Ride learning', style: TextStyle(fontSize: 12.sp, color: orange, fontWeight: FontWeight.w800)),
              SizedBox(height: 12.h),
              Text(article.summary, style: TextStyle(fontSize: 13.sp, height: 1.45, color: AppConst.black.withOpacity(.65), fontWeight: FontWeight.w600)),
            ]),
          ),
          SizedBox(height: 14.h),
          ...article.body.asMap().entries.map((entry) => _pointCard(orange, entry.key + 1, entry.value)),
        ],
      ),
    );
  }

  Widget _pointCard(Color orange, int number, String text) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(color: AppConst.white, borderRadius: BorderRadius.circular(18.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 5))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 14.r, backgroundColor: orange.withOpacity(.12), child: Text('$number', style: TextStyle(color: orange, fontSize: 11.sp, fontWeight: FontWeight.w900))),
        SizedBox(width: 10.w),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13.sp, height: 1.45, fontWeight: FontWeight.w600, color: AppConst.black.withOpacity(.75)))),
      ]),
    );
  }
}

class _InfoDetailScreen extends StatelessWidget {
  final String title;
  final List<String> points;
  const _InfoDetailScreen({required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    final orange = AppConst.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(backgroundColor: AppConst.white, elevation: 0, foregroundColor: AppConst.black, title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: points.asMap().entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(color: AppConst.white, borderRadius: BorderRadius.circular(18.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 5))]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.check_circle_rounded, color: orange, size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(child: Text(entry.value, style: TextStyle(fontSize: 13.sp, height: 1.45, fontWeight: FontWeight.w600, color: AppConst.black.withOpacity(.75)))),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _BoostTab {
  final String title;
  final IconData icon;
  const _BoostTab(this.title, this.icon);
}

class _Article {
  final String category;
  final String title;
  final String time;
  final IconData icon;
  final String summary;
  final List<String> body;
  const _Article({required this.category, required this.title, required this.time, required this.icon, required this.summary, required this.body});
}

class _FunItem {
  final String title;
  final String text;
  const _FunItem(this.title, this.text);
}

class _GridItem {
  final String title;
  final IconData icon;
  final String sub;
  final VoidCallback onTap;
  const _GridItem(this.title, this.icon, this.sub, this.onTap);
}
