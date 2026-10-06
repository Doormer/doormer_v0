import 'package:doormer/src/features/questions/presentation/atoms/elapsed_time_atom.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;

  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ElapsedTimeAtom(now: () => now),
      ),
    );
  }

  setUp(() => now = DateTime(2026, 10, 6, 12));

  testWidgets('starts at 0:00 and counts each second', (tester) async {
    await pump(tester);
    expect(find.text('0:00'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:01'), findsOneWidget);
  });

  testWidgets('shows minutes and seconds', (tester) async {
    await pump(tester);

    now = now.add(const Duration(seconds: 250));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('4:10'), findsOneWidget);
  });

  testWidgets('removed, it leaves no timer behind', (tester) async {
    await pump(tester);
    await tester.pumpWidget(const SizedBox.shrink());

    // A ticker left running would fire here and call setState after dispose.
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
