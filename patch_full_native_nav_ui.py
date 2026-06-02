from pathlib import Path

path = Path("lib/modules/navigation/trip_navigation_screen.dart")
s = path.read_text(encoding="utf-8")

start = s.find("\n          Positioned(\n            top: MediaQuery.of(context).padding.top + 10.h,")
if start == -1:
    raise SystemExit("START marker not found")

end = s.find("\n        ],", start)
if end == -1:
    raise SystemExit("END marker not found")

new_block = r'''
          Positioned(
            right: 14.w,
            bottom: MediaQuery.of(context).padding.bottom + 28.h,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'call_rider',
                  backgroundColor: Colors.black,
                  onPressed: () {},
                  child: const Icon(Icons.call, color: Colors.white),
                ),
                SizedBox(height: 10.h),
                FloatingActionButton.small(
                  heroTag: 'sms_rider',
                  backgroundColor: Colors.black,
                  onPressed: () {},
                  child: const Icon(Icons.message_rounded, color: Colors.white),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: 145.w,
                  height: 46.h,
                  child: _actionButton(status),
                ),
              ],
            ),
          ),
'''

s = s[:start] + "\n" + new_block + s[end:]
path.write_text(s, encoding="utf-8")
print("Full native navigation UI applied")
