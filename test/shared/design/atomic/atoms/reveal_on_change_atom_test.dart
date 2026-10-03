import 'package:doormer/src/shared/design/atomic/atoms/reveal_on_change_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget page(Object? trigger) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 2000),
              RevealOnChangeAtom(
                trigger: trigger,
                child:
                    const SizedBox(key: Key('target'), height: 100, width: 100),
              ),
            ]),
          ),
        ),
      );

  testWidgets('scrolls the child into view when the trigger changes',
      (tester) async {
    await tester.pumpWidget(page(null));
    expect(tester.getTopLeft(find.byKey(const Key('target'))).dy,
        greaterThan(600));

    await tester.pumpWidget(page('error'));
    await tester.pumpAndSettle();
    expect(
        tester.getTopLeft(find.byKey(const Key('target'))).dy, lessThan(600));
  });

  testWidgets('does nothing when the trigger goes back to null',
      (tester) async {
    await tester.pumpWidget(page(null));
    await tester.pumpWidget(page(null));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('target'))).dy,
        greaterThan(600));
  });
}
