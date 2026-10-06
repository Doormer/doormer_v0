import 'package:doormer/src/shared/design/atomic/atoms/show_after_delay_atom.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows nothing until the delay has passed, then the child',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ShowAfterDelayAtom(
          delay: Duration(seconds: 3),
          child: Text('ad'),
        ),
      ),
    );
    expect(find.text('ad'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2999));
    expect(find.text('ad'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('ad'), findsOneWidget);
  });

  testWidgets('takes no space while waiting', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: ShowAfterDelayAtom(
          delay: Duration(seconds: 3),
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ShowAfterDelayAtom)), Size.zero);
  });

  testWidgets('removed before the delay, it leaves no timer behind',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ShowAfterDelayAtom(
          delay: Duration(hours: 1),
          child: Text('ad'),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());

    // A timer left running would fire here and call setState after dispose.
    await tester.pump(const Duration(hours: 2));
    expect(tester.takeException(), isNull);
  });
}
