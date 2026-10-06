import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DisplayAdUnit.tryCreate', () {
    test('needs both IDs, so ads stay off until both are set', () {
      expect(
        DisplayAdUnit.tryCreate(clientId: '', slotId: '1234567890'),
        isNull,
      );
      expect(
        DisplayAdUnit.tryCreate(
          clientId: 'ca-pub-1234567890123456',
          slotId: '',
        ),
        isNull,
      );
    });

    test('carries both IDs, and asks for real ads by default', () {
      final unit = DisplayAdUnit.tryCreate(
        clientId: 'ca-pub-1234567890123456',
        slotId: '1234567890',
      )!;

      expect(unit.clientId, 'ca-pub-1234567890123456');
      expect(unit.slotId, '1234567890');
      expect(unit.testMode, isFalse);
    });

    test('carries test mode through', () {
      final unit = DisplayAdUnit.tryCreate(
        clientId: 'ca-pub-1234567890123456',
        slotId: '1234567890',
        testMode: true,
      )!;

      expect(unit.testMode, isTrue);
    });
  });

  test('the solving screen has no ad unless the build passes both IDs', () {
    // Tests run without --dart-define, like a local build.
    expect(DisplayAdUnit.solvingScreen(), isNull);
  });

  test('is a 300×250 unit, tagged for child treatment', () {
    expect(DisplayAdUnit.width, 300);
    expect(DisplayAdUnit.height, 250);
    expect(DisplayAdUnit.childAgeTreatment, '1');
  });

  test('Google gets 10 s to fill an ad', () {
    expect(displayAdFillTimeout, const Duration(seconds: 10));
  });
}
