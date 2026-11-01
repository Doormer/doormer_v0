import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/molecules/blocked_student_row_molecule.dart';
import 'package:doormer/src/features/profile/presentation/params/blocked_student_row_params.dart';
import 'package:doormer/src/features/profile/presentation/params/blocked_students_body_params.dart';
import 'package:doormer/src/features/profile/presentation/templates/blocked_students_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Blocked page as the app shows it in a [window] of that size, with
/// Tama and Nia blocked.
Future<void> _pump(WidgetTester tester, {required Size window}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => ResponsiveAppShell(child: child!),
    home: BlockedStudentsTemplate(
      body: BlockedStudentListParams(rows: [
        for (final nickname in ['Tama', 'Nia'])
          BlockedStudentRowParams(
            nickname: nickname,
            artUrl: null,
            isUnblocking: false,
            onUnblock: () {},
          ),
      ]),
      onBack: () {},
    ),
  ));
}

Finder _row(String nickname) =>
    find.widgetWithText(BlockedStudentRowMolecule, nickname);

Finder _tileAround(Finder row) =>
    find.ancestor(of: row, matching: find.byType(SurfaceCardAtom));

void main() {
  testWidgets(
      'on a wide screen, the students sit two to a line, each in a tile with '
      'its Unblock', (tester) async {
    await _pump(tester, window: const Size(760, 900));

    final tama = tester.getRect(_tileAround(_row('Tama')));
    final nia = tester.getRect(_tileAround(_row('Nia')));
    expect(nia.top, tama.top, reason: 'on the same line');
    expect(nia.left, greaterThan(tama.right));
    expect(nia.width, moreOrLessEquals(tama.width));
    for (final (tile, nickname) in [(tama, 'Tama'), (nia, 'Nia')]) {
      final unblock = tester.getRect(find.descendant(
        of: _row(nickname),
        matching: find.text('Unblock'),
      ));
      expect(tile.contains(unblock.center), isTrue, reason: nickname);
    }
  });

  testWidgets('on a phone, the students are rows, one under another',
      (tester) async {
    await _pump(tester, window: const Size(360, 800));

    expect(_tileAround(_row('Tama')), findsNothing);
    expect(tester.getRect(_row('Nia')).top,
        greaterThanOrEqualTo(tester.getRect(_row('Tama')).bottom));
    expect(tester.getSize(_row('Tama')).width, 320);
  });
}
