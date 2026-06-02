from pathlib import Path

path = Path("lib/modules/navigation/trip_navigation_screen.dart")
s = path.read_text(encoding="utf-8")

start = s.find("\n          SafeArea(\n            child: Align(\n              alignment: Alignment.bottomCenter,")
if start == -1:
    raise SystemExit("START marker not found")

end = s.find("\n        ],", start)
if end == -1:
    raise SystemExit("END marker not found")

new_block = r'''
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.h,
            left: 12.w,
            right: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 18,
                    offset: Offset(0, 6),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded, color: Colors.black),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 12.w,
            right: 12.w,
            bottom: MediaQuery.of(context).padding.bottom + 10.h,
            child: Container(
              padding: EdgeInsets.all(9.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _eta + ' • ' + _distance,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 18.sp),
                            SizedBox(width: 12.w),
                            Icon(Icons.message_rounded, color: Colors.white, size: 18.sp),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (status == 'arrived') ...[
                    SizedBox(height: 6.h),
                    Text(
                      _waitText,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  _actionButton(status),
                ],
              ),
            ),
          ),
'''

s = s[:start] + "\n" + new_block + s[end:]
path.write_text(s, encoding="utf-8")
print("Custom nav UI patch applied")
