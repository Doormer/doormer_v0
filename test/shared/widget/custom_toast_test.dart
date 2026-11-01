import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/toast_atom.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

/// The app as a phone shows it, with a stand-in nav bar along the bottom and
/// a button, `go`, that does [onGo].
Future<void> _pumpApp(
  WidgetTester tester, {
  required void Function(BuildContext context) onGo,
  Size window = const Size(390, 844),
  bool disableAnimations = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
      ),
      child: ResponsiveAppShell(child: child!),
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => onGo(context),
            child: const Text('go'),
          ),
        ),
        bottomNavigationBar: const SizedBox(key: Key('nav_bar'), height: 88),
      ),
    ),
  ));
}

/// Shows a toast saying [message] from the `go` button.
Future<void> _pumpToast(
  WidgetTester tester, {
  String message = 'Code copied.',
  ToastificationType type = ToastificationType.success,
  Size window = const Size(390, 844),
  bool disableAnimations = false,
}) =>
    _pumpApp(
      tester,
      window: window,
      disableAnimations: disableAnimations,
      onGo: (context) =>
          CustomToast.show(context, message: message, type: type),
    );

/// Lets a toast run its course.
Future<void> _waitOut(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Shows a success toast saying each of [messages] in turn, one for each tap
/// on `go`.
Future<void> _pumpToasts(WidgetTester tester, List<String> messages) {
  var shown = 0;
  return _pumpApp(
    tester,
    onGo: (context) => CustomToast.show(
      context,
      message: messages[shown++],
      type: ToastificationType.success,
    ),
  );
}

/// How opaque the toast saying [message] is drawn.
double _opacityOf(WidgetTester tester, String message) => tester
    .widget<FadeTransition>(find
        .ancestor(of: find.text(message), matching: find.byType(FadeTransition))
        .first)
    .opacity
    .value;

/// The semantics of the toast saying [message].
SemanticsNode _semanticsOf(WidgetTester tester, String message) =>
    tester.getSemantics(find.ancestor(
      of: find.text(message),
      matching: find.byType(ToastAtom),
    ));

void main() {
  test('errors stay longer than other toasts', () {
    expect(CustomToast.defaultDurationFor(ToastificationType.error),
        const Duration(seconds: 4));
    expect(CustomToast.defaultDurationFor(ToastificationType.info),
        const Duration(seconds: 2));
    expect(CustomToast.defaultDurationFor(ToastificationType.warning),
        const Duration(seconds: 2));
    expect(CustomToast.defaultDurationFor(ToastificationType.success),
        const Duration(seconds: 2));
  });

  testWidgets('an error toast opens and closes without throwing',
      (tester) async {
    await _pumpToast(tester,
        message: 'Nope',
        type: ToastificationType.error,
        window: const Size(800, 600));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nope'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Nope'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Nope'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long toast messages are shown without ellipsis', (tester) async {
    const message =
        "We couldn't open this HEIC photo. Check your connection and try again, or use a JPG or PNG.";
    await _pumpToast(
      tester,
      message: message,
      type: ToastificationType.error,
      window: const Size(1280, 720),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final paragraph = tester.renderObject<RenderParagraph>(find.text(message));

    expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
    expect(paragraph.didExceedMaxLines, isFalse);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows at the top of a phone, clear of the nav bar',
      (tester) async {
    await _pumpToast(tester);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final toast = tester.getRect(find.text('Code copied.'));
    expect(toast.top, lessThan(844 / 3));
    expect(toast.bottom,
        lessThan(tester.getRect(find.byKey(const Key('nav_bar'))).top));
    await _waitOut(tester);
  });

  for (final (type, kind) in [
    (ToastificationType.success, ToastKind.success),
    (ToastificationType.error, ToastKind.error),
    (ToastificationType.info, ToastKind.info),
    (ToastificationType.warning, ToastKind.warning),
  ]) {
    testWidgets("${type.name} shows as the app's own ${kind.name} toast",
        (tester) async {
      await _pumpToast(tester, type: type);

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final toast = tester.widget<ToastAtom>(find.byType(ToastAtom));
      expect(toast.message, 'Code copied.');
      expect(toast.kind, kind);
      await _waitOut(tester);
    });
  }

  testWidgets('is as wide as its message needs, and keeps 16 px from the sides',
      (tester) async {
    const long = "We couldn't copy that. Select the text and copy it yourself.";
    await _pumpApp(tester, onGo: (context) {
      CustomToast.show(context,
          message: 'Saved.', type: ToastificationType.success);
      CustomToast.show(context, message: long, type: ToastificationType.error);
    });

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    Rect toastSaying(String message) => tester.getRect(find.ancestor(
          of: find.text(message),
          matching: find.byType(ToastAtom),
        ));
    final short = toastSaying('Saved.');
    expect(short.width, lessThan(390 / 2));
    expect(short.center.dx, moreOrLessEquals(390 / 2, epsilon: 1));
    final wide = toastSaying(long);
    expect(wide.left, greaterThanOrEqualTo(16));
    expect(wide.right, lessThanOrEqualTo(390 - 16));
    await _waitOut(tester);
  });

  testWidgets('a success toast fades out on its own after 2 seconds',
      (tester) async {
    await _pumpToast(tester);

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1900));
    expect(_opacityOf(tester, 'Code copied.'), 1.0);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacityOf(tester, 'Code copied.'), inExclusiveRange(0.0, 1.0),
        reason: 'part-way through fading out at 2.08 s');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Code copied.'), findsNothing,
        reason: "gone by 2.18 s, before toastification's backstop at 2.48 s");
    await tester.pumpAndSettle();
  });

  testWidgets(
      'a toast arriving above another leaves it steady, and it still fades '
      'out on time', (tester) async {
    await _pumpToasts(tester, ['Code copied.', 'Invite link copied.']);
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();

    expect(_opacityOf(tester, 'Code copied.'), 1.0,
        reason: 'it arrived a second ago, so it does not arrive again');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacityOf(tester, 'Code copied.'), inExclusiveRange(0.0, 1.0),
        reason: 'its 2 s are up at 2 s, not 3 s, so it is fading out');
    expect(_opacityOf(tester, 'Invite link copied.'), 1.0);
    await _waitOut(tester);
  });

  testWidgets(
      'when a toast above another leaves, the one below moves up without '
      'arriving again', (tester) async {
    await _pumpToasts(tester, ['Code copied.', 'Invite link copied.']);
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final below = tester.getTopLeft(find.text('Code copied.')).dy;

    // At 0.8 s the upper toast fades out, then its empty slot closes.
    await tester.tap(find.text('Invite link copied.'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Invite link copied.'), findsNothing);
    expect(tester.getTopLeft(find.text('Code copied.')).dy, lessThan(below),
        reason: 'it moved up into the empty slot');
    expect(_opacityOf(tester, 'Code copied.'), 1.0);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 80));
    expect(_opacityOf(tester, 'Code copied.'), inExclusiveRange(0.0, 1.0),
        reason: 'its 2 s are up, so it is fading out');
    await _waitOut(tester);
  });

  testWidgets(
      'a toast keeps its live region when another arrives, so screen '
      'readers announce it once', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpToasts(tester, ['Code copied.', 'Invite link copied.']);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    final announced = _semanticsOf(tester, 'Code copied.');
    expect(announced,
        containsSemantics(label: 'Code copied.', isLiveRegion: true));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(_semanticsOf(tester, 'Code copied.').id, announced.id,
        reason: 'a new live region would be announced again');
    expect(_semanticsOf(tester, 'Invite link copied.'),
        containsSemantics(label: 'Invite link copied.', isLiveRegion: true));
    await _waitOut(tester);
    semantics.dispose();
  });

  testWidgets('a tap closes it at once', (tester) async {
    await _pumpToast(tester);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Code copied.'));
    await tester.pumpAndSettle();

    expect(find.text('Code copied.'), findsNothing);
  });

  testWidgets('a swipe up closes it at once', (tester) async {
    await _pumpToast(tester);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Code copied.'), const Offset(0, -40));
    await tester.pumpAndSettle();

    expect(find.text('Code copied.'), findsNothing);
  });

  /// Where the toast's message is a moment into its entrance, then once it
  /// has arrived, and how faded it was a moment in.
  Future<({double early, double arrived, double fade})> watchEntrance(
      WidgetTester tester) async {
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final message = find.text('Code copied.');
    final early = tester.getTopLeft(message).dy;
    final fade = _opacityOf(tester, 'Code copied.');
    await tester.pumpAndSettle();
    return (early: early, arrived: tester.getTopLeft(message).dy, fade: fade);
  }

  testWidgets('fades in and slides down into place', (tester) async {
    await _pumpToast(tester);

    final entrance = await watchEntrance(tester);

    expect(entrance.fade, lessThan(1));
    expect(entrance.early, lessThan(entrance.arrived));
    await _waitOut(tester);
  });

  testWidgets('with animations off, only fades in', (tester) async {
    await _pumpToast(tester, disableAnimations: true);

    final entrance = await watchEntrance(tester);

    expect(entrance.fade, lessThan(1));
    expect(entrance.early, entrance.arrived);
    await _waitOut(tester);
  });
}
