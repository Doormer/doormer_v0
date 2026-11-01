import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/molecules/page_heading_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, PageHeadingMolecule heading) =>
    tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: heading),
      ),
    ));

void main() {
  testWidgets('shows the title as a heading', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const PageHeadingMolecule(title: 'Blocked'));

    expect(
      tester.getSemantics(find.text('Blocked')),
      matchesSemantics(label: 'Blocked', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('has no back arrow with nowhere to go back to', (tester) async {
    await _pump(tester, const PageHeadingMolecule(title: 'Profile'));

    expect(find.byKey(const Key('page_back')), findsNothing);
  });

  testWidgets('before the title is known, shows only the back arrow',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, PageHeadingMolecule(title: null, onBack: () {}));

    expect(find.byKey(const Key('page_back')), findsOneWidget);
    expect(find.semantics.byFlag(SemanticsFlag.isHeader), findsNothing,
        reason: 'An empty heading would still be read out.');
    semantics.dispose();
  });

  testWidgets('the back arrow goes back', (tester) async {
    var backs = 0;
    await _pump(
      tester,
      PageHeadingMolecule(title: 'Add a friend', onBack: () => backs++),
    );

    await tester.tap(find.byKey(const Key('page_back')));

    expect(backs, 1);
  });

  testWidgets('puts what leads the title before it', (tester) async {
    await _pump(
      tester,
      const PageHeadingMolecule(
        title: "Sam's cards",
        leading: SizedBox(key: Key('picture'), width: 24, height: 24),
      ),
    );

    expect(
      tester.getTopRight(find.byKey(const Key('picture'))).dx,
      lessThan(tester.getTopLeft(find.text("Sam's cards")).dx),
    );
  });

  testWidgets('puts what trails the title straight after it', (tester) async {
    await _pump(
      tester,
      const PageHeadingMolecule(
        title: "Sam's cards",
        trailing: SizedBox(key: Key('level'), width: 24, height: 24),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('level'))).dx -
          tester.getTopRight(find.text("Sam's cards")).dx,
      moreOrLessEquals(8.w),
    );
  });
}
