import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Ads run only on the web, where Google's ad code can.
const bool displayAdsSupported = true;

String _googleAdScriptUrl(String clientId) =>
    'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'
    '?client=$clientId';

/// Where Google's ad script is loaded from. Tests point it somewhere harmless.
@visibleForTesting
String Function(String clientId) displayAdScriptUrl = _googleAdScriptUrl;

/// Whether Google's script loaded. Shared by every ad in the visit and never
/// retried: whatever blocked it once, usually an ad blocker, blocks it again.
Future<bool>? _scriptLoaded;
bool _scriptFailed = false;

/// Forgets the script and Google's ad queue, so the next ad starts afresh.
@visibleForTesting
void resetDisplayAdScriptForTest() {
  _scriptLoaded = null;
  _scriptFailed = false;
  displayAdScriptUrl = _googleAdScriptUrl;
  final scripts =
      web.document.querySelectorAll('script[data-display-ad-script]');
  for (var i = scripts.length - 1; i >= 0; i--) {
    (scripts.item(i)! as web.Element).remove();
  }
  globalContext.delete('adsbygoogle'.toJS);
}

Future<bool> _loadScript(String clientId) =>
    _scriptLoaded ??= _addScript(displayAdScriptUrl(clientId));

Future<bool> _addScript(String url) {
  final loaded = Completer<bool>();
  final script = web.HTMLScriptElement()
    ..async = true
    ..crossOrigin = 'anonymous'
    ..src = url;
  script.setAttribute('data-display-ad-script', '');
  script.addEventListener(
    'load',
    ((web.Event _) {
      if (!loaded.isCompleted) loaded.complete(true);
    }).toJS,
  );
  script.addEventListener(
    'error',
    ((web.Event _) {
      if (!loaded.isCompleted) loaded.complete(false);
    }).toJS,
  );
  web.document.head!.append(script);
  return loaded.future;
}

/// Asks Google to fill the next empty ad element on the page.
///
/// Until Google's script loads, `adsbygoogle` is a plain array that queues
/// the request. The script then replaces it with an object whose `push`
/// fills an ad.
void _pushAdRequest() {
  final queue =
      (globalContext['adsbygoogle'] as JSObject?) ?? JSArray<JSAny?>();
  globalContext['adsbygoogle'] = queue;
  queue.callMethod<JSAny?>('push'.toJS, JSObject());
}

/// Puts one AdSense ad into a host element on the page, and says when there
/// will be no ad.
///
/// Kept apart from [DisplayAdView] because Flutter's widget tests never
/// create the element an `HtmlElementView` embeds, while browser tests can
/// drive this class directly.
class DisplayAdLoader {
  final DisplayAdUnit unit;

  /// Called at most once, when there will be no ad: Google had none, its
  /// script didn't load, the ad code threw, or Google didn't answer within
  /// [fillTimeout]. Never called once the ad has filled, or after [dispose].
  final VoidCallback onNoAd;

  final Duration fillTimeout;

  DisplayAdLoader({
    required this.unit,
    required this.onNoAd,
    this.fillTimeout = displayAdFillTimeout,
  });

  bool _finished = false;
  Timer? _fillTimer;
  web.ResizeObserver? _attachObserver;
  web.MutationObserver? _statusObserver;

  /// Adds the ad element to [host] and, once [host] is on the page, asks
  /// Google to fill it.
  void start(web.HTMLElement host) {
    if (_scriptFailed) {
      scheduleMicrotask(_finishWithoutAd);
      return;
    }
    _fillTimer = Timer(fillTimeout, () {
      if (_finished) return;
      AppLogger.debug('No display ad within ${fillTimeout.inSeconds} s');
      _finishWithoutAd();
    });
    try {
      final ad = _createAdElement();
      host.append(ad);
      _whenOnPage(host, () => _request(ad));
    } catch (e, stackTrace) {
      _fail(e, stackTrace);
    }
  }

  /// Stops watching. Nothing is reported after this.
  void dispose() {
    _finished = true;
    _stop();
  }

  web.Element _createAdElement() {
    final ad = web.document.createElement('ins')
      ..className = 'adsbygoogle'
      ..setAttribute(
        'style',
        'display:inline-block;'
            'width:${DisplayAdUnit.width.toInt()}px;'
            'height:${DisplayAdUnit.height.toInt()}px',
      )
      ..setAttribute('data-ad-client', unit.clientId)
      ..setAttribute('data-ad-slot', unit.slotId)
      ..setAttribute(
        'data-tag-for-age-treatment',
        DisplayAdUnit.childAgeTreatment,
      );
    if (unit.testMode) ad.setAttribute('data-adtest', 'on');
    return ad;
  }

  /// Google's code finds ad elements by searching the page, so nothing can be
  /// asked for until [host] is on it. Flutter attaches it after creating it.
  void _whenOnPage(web.HTMLElement host, void Function() then) {
    if (host.isConnected) {
      then();
      return;
    }
    final observer = web.ResizeObserver(
      ((JSArray<web.ResizeObserverEntry> _, web.ResizeObserver self) {
        if (_finished || !host.isConnected) return;
        self.disconnect();
        _attachObserver = null;
        then();
      }).toJS,
    );
    _attachObserver = observer;
    observer.observe(host);
  }

  void _request(web.Element ad) {
    try {
      _watchStatus(ad);
      unawaited(_loadScript(unit.clientId).then(_onScriptLoaded));
      _pushAdRequest();
    } catch (e, stackTrace) {
      _fail(e, stackTrace);
    }
  }

  void _watchStatus(web.Element ad) {
    final observer = web.MutationObserver(
      ((JSArray<web.MutationRecord> _, web.MutationObserver __) {
        _readStatus(ad);
      }).toJS,
    );
    _statusObserver = observer;
    observer.observe(
      ad,
      web.MutationObserverInit(
        attributes: true,
        attributeFilter: <JSString>['data-ad-status'.toJS].toJS,
      ),
    );
  }

  /// AdSense sets `data-ad-status` once it has answered: `filled`, or
  /// `unfilled` or `unfill-optimized` when it had no ad.
  void _readStatus(web.Element ad) {
    if (_finished) return;
    final status = ad.getAttribute('data-ad-status');
    if (status == null) return;
    if (status == 'filled') {
      _finished = true;
      _stop();
      return;
    }
    AppLogger.debug('Google had no display ad ($status)');
    _finishWithoutAd();
  }

  void _onScriptLoaded(bool loaded) {
    if (!loaded) _scriptFailed = true;
    if (loaded || _finished) return;
    AppLogger.info(
      'The ad script did not load. An ad blocker or a dropped connection '
      'is the usual cause.',
    );
    _finishWithoutAd();
  }

  void _fail(Object error, StackTrace stackTrace) {
    if (_finished) return;
    AppLogger.error('Display ad failed', error: error, stackTrace: stackTrace);
    _finishWithoutAd();
  }

  void _finishWithoutAd() {
    if (_finished) return;
    _finished = true;
    _stop();
    onNoAd();
  }

  void _stop() {
    _fillTimer?.cancel();
    _fillTimer = null;
    _attachObserver?.disconnect();
    _attachObserver = null;
    _statusObserver?.disconnect();
    _statusObserver = null;
  }
}

/// One AdSense ad, embedded in the Flutter page.
class DisplayAdView extends StatefulWidget {
  final DisplayAdUnit unit;

  /// See [DisplayAdLoader.onNoAd].
  final VoidCallback onNoAd;

  const DisplayAdView({super.key, required this.unit, required this.onNoAd});

  @override
  State<DisplayAdView> createState() => _DisplayAdViewState();
}

class _DisplayAdViewState extends State<DisplayAdView> {
  late final DisplayAdLoader _loader = DisplayAdLoader(
    unit: widget.unit,
    onNoAd: () => widget.onNoAd(),
  );

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (element) => _loader.start(element as web.HTMLElement),
    );
  }
}
