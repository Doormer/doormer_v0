import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solution_segment_order.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solution_vault_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final _answer = diagramFirstOrder(const [
  TextSolutionSegment('The paved area is 160 square metres.'),
]);

Widget _pump({
  required bool revealed,
  required bool unlockable,
  VoidCallback? onReveal,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SolutionVaultOrganism(
            revealed: revealed,
            unlockable: unlockable,
            lockedLabel: 'Answer unlocks after step 3',
            answerBody: _answer,
            onReveal: onReveal ?? () {},
            onEnlargeVisual: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the locked strip with the supplied label before the end',
      (tester) async {
    await tester.pumpWidget(_pump(revealed: false, unlockable: false));
    await tester.pump();

    expect(find.byKey(const Key('vault_locked')), findsOneWidget);
    expect(find.text('Answer unlocks after step 3'), findsOneWidget);
    expect(find.byKey(const Key('vault_revealed')), findsNothing);
    expect(find.text('The paved area is 160 square metres.'), findsNothing);
  });

  testWidgets('stays compact while locked', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_pump(revealed: false, unlockable: false));
    await tester.pump();

    final height = tester.getSize(find.byKey(const Key('vault_locked'))).height;
    expect(height, lessThan(72),
        reason: 'the vault must not squat at full size while locked');
  });

  testWidgets('reveals the answer body once revealed', (tester) async {
    await tester.pumpWidget(_pump(revealed: true, unlockable: true));
    await tester.pump();

    expect(find.byKey(const Key('vault_revealed')), findsOneWidget);
    expect(find.text('The paved area is 160 square metres.'), findsOneWidget);
    expect(find.byKey(const Key('vault_locked')), findsNothing);
  });

  testWidgets('tapping the unlockable vault reports upward', (tester) async {
    var reveals = 0;
    await tester.pumpWidget(
      _pump(revealed: false, unlockable: true, onReveal: () => reveals++),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('vault_locked')));
    await tester.pump();

    expect(reveals, 1);
  });
}
