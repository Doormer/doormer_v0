@TestOn('vm')
library;

import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/core/ads/display_ad_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ads are only supported on the web', () {
    expect(displayAdsSupported, isFalse);
  });

  testWidgets('off the web, an ad view shows nothing', (tester) async {
    await tester.pumpWidget(
      Center(
        child: DisplayAdView(
          unit: DisplayAdUnit.tryCreate(
            clientId: 'ca-pub-1234567890123456',
            slotId: '1234567890',
          )!,
          onNoAd: () {},
        ),
      ),
    );

    expect(tester.getSize(find.byType(DisplayAdView)), Size.zero);
  });
}
