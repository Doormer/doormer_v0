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
}
