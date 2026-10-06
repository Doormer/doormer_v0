import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/display_ad_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final _unit = DisplayAdUnit.tryCreate(
  clientId: 'ca-pub-1234567890123456',
  slotId: '1234567890',
)!;

/// How many stand-in ads were put on screen. Each one is an ad request.
int _adRequests = 0;

/// What the latest stand-in ad would call when Google has no ad.
VoidCallback? _reportNoAd;

/// Stands in for Google's ad, which only exists in a browser.
class _FakeAdView extends StatefulWidget {
  final VoidCallback onNoAd;

  const _FakeAdView({required this.onNoAd});

  @override
  State<_FakeAdView> createState() => _FakeAdViewState();
}

class _FakeAdViewState extends State<_FakeAdView> {
  @override
  void initState() {
    super.initState();
    _adRequests++;
    _reportNoAd = widget.onNoAd;
  }

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(key: Key('ad'), color: Colors.grey);
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 360,
  bool supported = true,
}) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: DisplayAdAtom(
                unit: _unit,
                supported: supported,
                buildAdView: (unit, onNoAd) => _FakeAdView(onNoAd: onNoAd),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    _adRequests = 0;
    _reportNoAd = null;
  });

  testWidgets('shows the ad in a 300×250 box under its label', (tester) async {
    await _pump(tester);

    expect(find.text('Advertisements'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('ad'))), const Size(300, 250));
    expect(
      tester.getBottomLeft(find.text('Advertisements')).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byKey(const Key('ad'))).dy),
    );
    expect(_adRequests, 1);
  });

  testWidgets('shows nothing where ads cannot run', (tester) async {
    await _pump(tester, supported: false);

    expect(find.text('Advertisements'), findsNothing);
    expect(_adRequests, 0);
  });

  testWidgets('shows nothing in less than 300 px', (tester) async {
    await _pump(tester, width: 299);

    expect(find.text('Advertisements'), findsNothing);
    expect(_adRequests, 0);
  });

  testWidgets('disappears for good once Google has no ad', (tester) async {
    await _pump(tester);

    _reportNoAd!();
    await tester.pump();
    expect(find.text('Advertisements'), findsNothing);

    await _pump(tester, width: 400);
    expect(find.text('Advertisements'), findsNothing);
    expect(_adRequests, 1);
  });

  testWidgets('an ad that loses its room never comes back', (tester) async {
    await _pump(tester, width: 320);
    await _pump(tester, width: 280);
    expect(find.text('Advertisements'), findsNothing);

    await _pump(tester, width: 320);
    expect(find.text('Advertisements'), findsNothing,
        reason: 'showing it again would ask Google for a second ad, which '
            'counts as refreshing it');
    expect(_adRequests, 1);
  });
}
