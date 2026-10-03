import 'package:doormer/src/core/routes/popup_route_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PopupRouteTracker tracker;
  setUp(() => tracker = PopupRouteTracker());

  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [tracker],
      home: Builder(builder: (context) {
        captured = context;
        return const SizedBox();
      }),
    ));
    return captured;
  }

  testWidgets('counts a dialog while it is open', (tester) async {
    final context = await pump(tester);
    expect(tracker.hasOpenPopup, isFalse);

    showDialog<void>(context: context, builder: (_) => const Text('hi'));
    await tester.pumpAndSettle();
    expect(tracker.hasOpenPopup, isTrue);

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(tracker.hasOpenPopup, isFalse);
  });

  testWidgets('counts a bottom sheet', (tester) async {
    final context = await pump(tester);
    showModalBottomSheet<void>(
        context: context, builder: (_) => const Text('sheet'));
    await tester.pumpAndSettle();
    expect(tracker.hasOpenPopup, isTrue);
  });

  testWidgets('ignores full pages', (tester) async {
    final context = await pump(tester);
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const Text('page')));
    await tester.pumpAndSettle();
    expect(tracker.hasOpenPopup, isFalse);
  });

  testWidgets('dismissTop closes a dismissible popup', (tester) async {
    final context = await pump(tester);
    showDialog<void>(context: context, builder: (_) => const Text('hi'));
    await tester.pumpAndSettle();

    tracker.dismissTop();
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsNothing);
    expect(tracker.hasOpenPopup, isFalse);
  });

  testWidgets('dismissTop leaves a non-dismissible popup open', (tester) async {
    final context = await pump(tester);
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Text('hi'));
    await tester.pumpAndSettle();

    tracker.dismissTop();
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
  });

  test('tracks and closes page overlays', () {
    final owner = Object();
    var dismissed = 0;

    tracker.openOverlay(
      owner,
      barrierColor: Colors.red,
      onDismiss: () => dismissed++,
    );

    expect(tracker.hasOpenPopup, isTrue);
    expect(tracker.barrierColor, Colors.red);

    tracker.dismissTop();
    expect(dismissed, 1);

    tracker.closeOverlay(owner);
    expect(tracker.hasOpenPopup, isFalse);
  });

  testWidgets('uses the most recently opened barrier and dismiss action',
      (tester) async {
    final context = await pump(tester);
    final owner = Object();
    var overlayDismissed = 0;

    showDialog<void>(
      context: context,
      barrierColor: Colors.green,
      builder: (_) => const Text('dialog'),
    );
    await tester.pumpAndSettle();

    tracker.openOverlay(
      owner,
      barrierColor: Colors.blue,
      onDismiss: () => overlayDismissed++,
    );

    expect(tracker.barrierColor, Colors.blue);
    tracker.dismissTop();
    expect(overlayDismissed, 1);
    expect(find.text('dialog'), findsOneWidget);

    tracker.closeOverlay(owner);
    expect(tracker.barrierColor, Colors.green);

    tracker.dismissTop();
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsNothing);
  });

  testWidgets('a popup opened after an overlay becomes the top barrier',
      (tester) async {
    final context = await pump(tester);
    final owner = Object();
    var overlayDismissed = 0;

    tracker.openOverlay(
      owner,
      barrierColor: Colors.red,
      onDismiss: () => overlayDismissed++,
    );

    showDialog<void>(
      context: context,
      barrierColor: Colors.green,
      builder: (_) => const Text('dialog'),
    );
    await tester.pumpAndSettle();

    expect(tracker.barrierColor, Colors.green);
    tracker.dismissTop();
    await tester.pumpAndSettle();

    expect(find.text('dialog'), findsNothing);
    expect(overlayDismissed, 0);
    expect(tracker.barrierColor, Colors.red);
  });
}
