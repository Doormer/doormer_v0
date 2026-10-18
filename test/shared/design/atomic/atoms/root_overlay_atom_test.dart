import 'package:doormer/src/shared/design/atomic/atoms/root_overlay_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// An app with a line of text above the atom, so a test can tell whether
/// the overlay child covers what the atom doesn't hold.
Widget _app({Widget? overlayChild, bool withAtom = true}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const Text('Underneath'),
          if (withAtom)
            // Its own boundary for screen readers, like the page around it in
            // the app. An OverlayPortal would put the overlay child inside
            // it, where a BlockSemantics can't hide the text above.
            Semantics(
              container: true,
              child: RootOverlayAtom(
                overlayChild: overlayChild,
                child: const Text('In place'),
              ),
            ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('shows the overlay child above the whole app', (tester) async {
    var overlayTaps = 0;
    await tester.pumpWidget(_app(
      overlayChild: Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => overlayTaps++,
          child: const Center(child: Text('On top')),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('On top'), findsOneWidget);
    expect(find.text('In place'), findsOneWidget);
    await tester.tap(find.text('Underneath'), warnIfMissed: false);
    expect(overlayTaps, 1, reason: 'the tap lands on what covers the app');
  });

  testWidgets('takes the overlay child away when it becomes null',
      (tester) async {
    await tester.pumpWidget(
      _app(overlayChild: const Positioned.fill(child: Text('On top'))),
    );
    await tester.pump();

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('On top'), findsNothing);
    expect(find.text('In place'), findsOneWidget);
  });

  // As on the Cards page: only the page rebuilds, with a new overlay child.
  testWidgets('shows the new overlay child when it changes', (tester) async {
    final label = ValueNotifier('First');
    addTearDown(label.dispose);
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder<String>(
        valueListenable: label,
        builder: (_, text, __) => RootOverlayAtom(
          overlayChild: Positioned.fill(child: Center(child: Text(text))),
          child: const SizedBox.shrink(),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('First'), findsOneWidget);

    label.value = 'Second';
    await tester.pump();
    await tester.pump();

    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First'), findsNothing);
  });

  testWidgets('takes the overlay child away when the atom goes',
      (tester) async {
    await tester.pumpWidget(
      _app(overlayChild: const Positioned.fill(child: Text('On top'))),
    );
    await tester.pump();

    await tester.pumpWidget(_app(withAtom: false));
    await tester.pump();

    expect(find.text('On top'), findsNothing);
  });

  testWidgets(
      'a BlockSemantics in the overlay child hides the app from '
      'screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    // What a screen reader can move through, in order.
    Iterable<String> heard() => tester.semantics
        .simulatedAccessibilityTraversal()
        .map((node) => node.label);
    await tester.pumpWidget(_app(
      overlayChild: const Positioned.fill(
        child: BlockSemantics(child: Center(child: Text('On top'))),
      ),
    ));
    await tester.pump();

    expect(heard(), contains(contains('On top')));
    expect(heard(), isNot(contains(contains('Underneath'))));
    expect(heard(), isNot(contains(contains('In place'))));
    semantics.dispose();
  });
}
