import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/trail_connector_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

Size _fillSize(WidgetTester tester) {
  return tester.getSize(find.byKey(const Key('trail_link_fill_0')));
}

void main() {
  group('horizontal', () {
    testWidgets('runs along the trail and is 3 thick across it',
        (tester) async {
      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: true,
      )));
      await tester.pumpAndSettle();

      final box = tester.getSize(find.byType(TrailConnectorAtom));
      expect(box.width, 40 + 4 * 2, reason: 'margin sits along the trail');
      expect(box.height, 3);
    });

    testWidgets('a lit run covers the whole length', (tester) async {
      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: true,
      )));
      await tester.pumpAndSettle();

      expect(_fillSize(tester).width, 40);
    });

    testWidgets('an unlit run covers none of it', (tester) async {
      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: false,
      )));
      await tester.pumpAndSettle();

      expect(_fillSize(tester).width, 0);
    });
  });

  group('vertical', () {
    testWidgets('runs down the trail and is 3 thick across it', (tester) async {
      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: true,
        axis: Axis.vertical,
      )));
      await tester.pumpAndSettle();

      final box = tester.getSize(find.byType(TrailConnectorAtom));
      expect(box.height, 40 + 4 * 2, reason: 'margin sits along the trail');
      expect(box.width, 3);
    });

    testWidgets('a lit run fills downward, from the node above it',
        (tester) async {
      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: true,
        axis: Axis.vertical,
      )));
      await tester.pumpAndSettle();

      expect(_fillSize(tester).height, 40);
    });

    testWidgets('an unlit run covers none of it', (tester) async {
      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: false,
        axis: Axis.vertical,
      )));
      await tester.pumpAndSettle();

      expect(_fillSize(tester).height, 0);
    });

    testWidgets('wipes from the top, so the road is covered in travel order',
        (tester) async {
      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: false,
        axis: Axis.vertical,
      )));
      await tester.pumpAndSettle();

      final unlitTop = tester.getTopLeft(find.byKey(
        const Key('trail_link_fill_0'),
      ));

      await tester.pumpWidget(_pump(const TrailConnectorAtom(
        index: 0,
        length: 40,
        margin: 4,
        lit: true,
        axis: Axis.vertical,
      )));
      await tester.pumpAndSettle();

      final litTop = tester.getTopLeft(find.byKey(
        const Key('trail_link_fill_0'),
      ));

      expect(litTop.dy, unlitTop.dy,
          reason: 'the run grows downward rather than up from the far node');
    });
  });
}
