import 'package:doormer/src/core/config/app_config.dart';

/// How long Google gets to answer an ad request before the ad card gives up.
const Duration displayAdFillTimeout = Duration(seconds: 10);

/// One AdSense display ad unit: whose ads, which ad unit, and whether to ask
/// for test ads.
///
/// Every request made for it is tagged for child treatment, which turns off
/// interest-based ads and remarketing. Some of the app's students may be
/// under 13.
class DisplayAdUnit {
  /// The unit's size in logical pixels. Google's 300×250 ads need exactly
  /// this box, so it is never scaled with the screen.
  static const double width = 300;
  static const double height = 250;

  /// AdSense's `data-tag-for-age-treatment` value for child treatment.
  static const String childAgeTreatment = '1';

  /// The AdSense publisher ID, such as `ca-pub-1234567890123456`.
  final String clientId;

  /// The ad unit's ID, which AdSense calls the ad slot.
  final String slotId;

  /// Asks Google for test ads instead of real ones. Staging only.
  final bool testMode;

  const DisplayAdUnit._({
    required this.clientId,
    required this.slotId,
    required this.testMode,
  });

  /// Null unless both IDs are set: ads stay off until they are.
  static DisplayAdUnit? tryCreate({
    required String clientId,
    required String slotId,
    bool testMode = false,
  }) {
    if (clientId.isEmpty || slotId.isEmpty) return null;
    return DisplayAdUnit._(
      clientId: clientId,
      slotId: slotId,
      testMode: testMode,
    );
  }

  /// The unit shown while a photo is being solved, or null when the build
  /// was not given its IDs.
  static DisplayAdUnit? solvingScreen() => tryCreate(
        clientId: AppConfig.adsenseClientId,
        slotId: AppConfig.adsenseSolvingSlotId,
        testMode: AppConfig.adsenseTestMode,
      );
}
