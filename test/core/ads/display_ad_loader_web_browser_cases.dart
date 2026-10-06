@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/core/ads/display_ad_view_web.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

/// Loads at once and does nothing, standing in for Google's script.
const _harmlessScript = 'data:text/javascript,';

/// Chrome refuses port 9, so loading from here always fails.
const _unreachableScript = 'http://127.0.0.1:9/adsbygoogle.js';

final _unit = DisplayAdUnit.tryCreate(
  clientId: 'ca-pub-1234567890123456',
  slotId: '1234567890',
)!;

void main() {
  setUpAll(AppLogger.disable);

  late web.HTMLDivElement host;
  final loaders = <DisplayAdLoader>[];

  setUp(() {
    resetDisplayAdScriptForTest();
    displayAdScriptUrl = (_) => _harmlessScript;
    host = web.HTMLDivElement();
    web.document.body!.append(host);
  });

  tearDown(() {
    for (final loader in loaders) {
      loader.dispose();
    }
    loaders.clear();
    host.remove();
  });

  DisplayAdLoader start({
    DisplayAdUnit? unit,
    void Function()? onNoAd,
    Duration fillTimeout = const Duration(seconds: 10),
    web.HTMLElement? into,
  }) {
    final loader = DisplayAdLoader(
      unit: unit ?? _unit,
      onNoAd: onNoAd ?? () {},
      fillTimeout: fillTimeout,
    );
    loaders.add(loader);
    loader.start(into ?? host);
    return loader;
  }

  web.HTMLDivElement extraHost({bool onPage = true}) {
    final element = web.HTMLDivElement();
    if (onPage) web.document.body!.append(element);
    addTearDown(() => element.remove());
    return element;
  }

  web.Element adElement([web.HTMLElement? within]) =>
      (within ?? host).querySelector('ins.adsbygoogle')!;

  int adRequests() {
    final queue = globalContext['adsbygoogle'];
    return queue == null ? 0 : (queue as JSArray<JSAny?>).toDart.length;
  }

  int scriptTags() =>
      web.document.querySelectorAll('script[data-display-ad-script]').length;

  /// Lets the browser deliver attribute changes, observers and script events.
  Future<void> settle([Duration wait = Duration.zero]) =>
      Future<void>.delayed(wait);

  test('the ad element names the unit, its exact size and child treatment', () {
    start();

    final ad = adElement();
    expect(ad.getAttribute('data-ad-client'), 'ca-pub-1234567890123456');
    expect(ad.getAttribute('data-ad-slot'), '1234567890');
    expect(ad.getAttribute('data-tag-for-age-treatment'), '1');
    expect(
      ad.getAttribute('style'),
      'display:inline-block;width:300px;height:250px',
    );
    expect(ad.hasAttribute('data-adtest'), isFalse);
  });

  test('test mode asks Google for test ads', () {
    start(
      unit: DisplayAdUnit.tryCreate(
        clientId: 'ca-pub-1234567890123456',
        slotId: '1234567890',
        testMode: true,
      ),
    );

    expect(adElement().getAttribute('data-adtest'), 'on');
  });

  test('asks Google to fill the ad once it is on the page', () {
    start();

    expect(adRequests(), 1);
  });

  test('waits until the host is on the page before asking', () async {
    final detached = extraHost(onPage: false);
    start(into: detached);
    expect(adRequests(), 0);

    web.document.body!.append(detached);
    // The browser reports the attachment within a frame or two.
    for (var i = 0; i < 40 && adRequests() == 0; i++) {
      await settle(const Duration(milliseconds: 50));
    }

    expect(adRequests(), 1);
  });

  test("loads Google's script once, however many ads are shown", () {
    start();
    start(into: extraHost());

    expect(scriptTags(), 1);
    final script = web.document.querySelector('script[data-display-ad-script]')
        as web.HTMLScriptElement;
    expect(script.async, isTrue);
    expect(script.crossOrigin, 'anonymous');
  });

  test('the real script comes from Google, with the publisher ID', () {
    resetDisplayAdScriptForTest();

    expect(
      displayAdScriptUrl('ca-pub-1234567890123456'),
      'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'
      '?client=ca-pub-1234567890123456',
    );
  });

  test('a filled ad stays, and is not given up on later', () async {
    var noAds = 0;
    start(
      onNoAd: () => noAds++,
      fillTimeout: const Duration(milliseconds: 50),
    );

    adElement().setAttribute('data-ad-status', 'filled');
    await settle(const Duration(milliseconds: 100));

    expect(noAds, 0);
  });

  for (final status in ['unfilled', 'unfill-optimized']) {
    test('"$status" means no ad, reported once', () async {
      var noAds = 0;
      start(onNoAd: () => noAds++);

      adElement().setAttribute('data-ad-status', status);
      await settle();
      adElement().setAttribute('data-ad-status', status);
      await settle();

      expect(noAds, 1);
    });
  }

  test('no answer within the time limit means no ad', () async {
    var noAds = 0;
    start(
      onNoAd: () => noAds++,
      fillTimeout: const Duration(milliseconds: 50),
    );

    await settle(const Duration(milliseconds: 100));

    expect(noAds, 1);
  });

  test('a script that fails to load means no ad', () async {
    displayAdScriptUrl = (_) => _unreachableScript;
    final noAd = Completer<void>();

    start(onNoAd: noAd.complete);

    await noAd.future.timeout(const Duration(seconds: 5));
  });

  test('a failed script is not tried again for later ads', () async {
    displayAdScriptUrl = (_) => _unreachableScript;
    final first = Completer<void>();
    start(onNoAd: first.complete);
    await first.future.timeout(const Duration(seconds: 5));

    final second = Completer<void>();
    start(onNoAd: second.complete, into: extraHost());
    await second.future.timeout(const Duration(seconds: 1));

    expect(scriptTags(), 1);
  });

  test('after dispose, nothing more is reported', () async {
    var noAds = 0;
    final loader = start(
      onNoAd: () => noAds++,
      fillTimeout: const Duration(milliseconds: 50),
    );

    loader.dispose();
    adElement().setAttribute('data-ad-status', 'unfilled');
    await settle(const Duration(milliseconds: 100));

    expect(noAds, 0);
  });
}
