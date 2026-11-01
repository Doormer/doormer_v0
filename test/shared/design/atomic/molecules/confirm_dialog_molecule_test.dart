import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/confirm_dialog_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _title = 'Reset code?';
const _message = 'Your old code and invite links will stop working.';

/// Opens the dialog with [showConfirmDialog] on a screen [width] wide, and
/// answers with what the helper will answer once the dialog closes.
Future<Future<bool>> _open(
  WidgetTester tester, {
  bool isRisky = true,
  double width = 390,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);

  Future<bool>? answer;
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => answer = showConfirmDialog(
                context,
                title: _title,
                message: _message,
                confirmLabel: 'Reset code',
                icon: Icons.restart_alt_rounded,
                isRisky: isRisky,
              ),
              child: const Text('ask'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('ask'));
  await tester.pumpAndSettle();
  return answer!;
}

Finder _button(String label) => find.widgetWithText(AppButtonAtom, label);

void main() {
  testWidgets('shows the title, the message, Cancel and the confirm button',
      (tester) async {
    await _open(tester);

    expect(find.byType(ConfirmDialogMolecule), findsOneWidget);
    expect(find.text(_title), findsOneWidget);
    expect(find.text(_message), findsOneWidget);
    expect(_button('Cancel'), findsOneWidget);
    expect(_button('Reset code'), findsOneWidget);
  });

  testWidgets('Cancel answers false and closes the dialog', (tester) async {
    final answer = await _open(tester);

    await tester.tap(_button('Cancel'));
    await tester.pumpAndSettle();

    expect(await answer, isFalse);
    expect(find.byType(ConfirmDialogMolecule), findsNothing);
  });

  testWidgets('Escape answers false', (tester) async {
    final answer = await _open(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(await answer, isFalse);
    expect(find.byType(ConfirmDialogMolecule), findsNothing);
  });

  testWidgets('a tap outside the dialog answers false', (tester) async {
    final answer = await _open(tester);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(await answer, isFalse);
  });

  testWidgets('confirming answers true', (tester) async {
    final answer = await _open(tester);

    await tester.tap(_button('Reset code'));
    await tester.pumpAndSettle();

    expect(await answer, isTrue);
    expect(find.byType(ConfirmDialogMolecule), findsNothing);
  });

  testWidgets('Cancel has the focus first', (tester) async {
    await _open(tester);

    expect(
        Focus.of(tester.element(find.text('Cancel'))).hasPrimaryFocus, isTrue);
  });

  testWidgets(
      'a risky action confirms with the danger button, beside an outlined '
      'Cancel', (tester) async {
    await _open(tester);

    expect(tester.widget<AppButtonAtom>(_button('Reset code')).variant,
        AppButtonVariant.danger);
    expect(tester.widget<AppButtonAtom>(_button('Cancel')).variant,
        AppButtonVariant.outlined);
  });

  testWidgets('an action that is not risky confirms with the filled button',
      (tester) async {
    await _open(tester, isRisky: false);

    expect(tester.widget<AppButtonAtom>(_button('Reset code')).variant,
        AppButtonVariant.filled);
  });

  testWidgets('puts Cancel on the left and confirm on the right',
      (tester) async {
    await _open(tester);

    final cancel = tester.getRect(_button('Cancel'));
    final confirm = tester.getRect(_button('Reset code'));
    expect(cancel.right, lessThan(confirm.left));
    expect(cancel.center.dy, moreOrLessEquals(confirm.center.dy));
    expect(cancel.width, moreOrLessEquals(confirm.width));
  });

  testWidgets('on a narrow screen, stacks the buttons with confirm on top',
      (tester) async {
    await _open(tester, width: 320);

    final cancel = tester.getRect(_button('Cancel'));
    final confirm = tester.getRect(_button('Reset code'));
    expect(confirm.bottom, lessThanOrEqualTo(cancel.top));
    expect(confirm.width, moreOrLessEquals(cancel.width));
  });

  testWidgets('tells screen readers the dialog by its title', (tester) async {
    final semantics = tester.ensureSemantics();
    await _open(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel(_title).first),
      containsSemantics(label: _title, namesRoute: true, scopesRoute: true),
    );
    semantics.dispose();
  });
}
