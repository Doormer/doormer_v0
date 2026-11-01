import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/templates/invite_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/doormer_logo_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _heading = 'A friend invited you to Doormer';
const _line =
    'Snap a homework question and Doormer turns it into a step-by-step quest.';

/// The invite page as the app shows it, in a [window] of that size.
Future<void> _pump(
  WidgetTester tester, {
  Size window = const Size(390, 844),
  bool disableAnimations = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
      ),
      child: ResponsiveAppShell(child: child!),
    ),
    home: InviteTemplate(onSignUp: () {}, onLogIn: () {}),
  ));
}

final _logo = find.byType(DoormerLogoAtom);
final _signUp = find.widgetWithText(AppButtonAtom, 'Sign up');
final _logIn = find.widgetWithText(AppButtonAtom, 'Log in');

void main() {
  testWidgets(
      'shows the logo, the heading, what Doormer is, then Sign up and Log in',
      (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    final pieces = [_logo, find.text(_heading), find.text(_line), _signUp];
    for (final piece in [...pieces, _logIn]) {
      expect(piece, findsOneWidget);
    }
    for (var i = 1; i < pieces.length; i++) {
      expect(
        tester.getRect(pieces[i]).top,
        greaterThan(tester.getRect(pieces[i - 1]).bottom),
        reason: '${pieces[i]} sits under ${pieces[i - 1]}',
      );
    }
    expect(tester.getRect(_logIn).top,
        greaterThanOrEqualTo(tester.getRect(_signUp).bottom));
  });

  testWidgets('keeps to a centred column at most 400 wide in a wide window',
      (tester) async {
    await _pump(tester, window: const Size(760, 900));
    await tester.pumpAndSettle();

    final signUp = tester.getRect(_signUp);
    expect(signUp.width, lessThanOrEqualTo(400));
    expect(tester.getRect(_logIn).width, signUp.width,
        reason: 'both buttons are the width of the column');
    expect(signUp.center.dx, moreOrLessEquals(380));
    expect(tester.getRect(find.text(_line)).width, lessThanOrEqualTo(400));
    expect(tester.getCenter(_logo).dx, moreOrLessEquals(380));
  });

  testWidgets('the logo rises into place', (tester) async {
    await _pump(tester);
    await tester.pump();
    final start = tester.getTopLeft(_logo);

    await tester.pumpAndSettle();

    expect(tester.getTopLeft(_logo).dy, lessThan(start.dy));
  });

  testWidgets('with animations off, the logo never moves', (tester) async {
    await _pump(tester, disableAnimations: true);
    final start = tester.getTopLeft(_logo);

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(_logo), start);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_logo), start);
    expect(
      find.ancestor(of: _logo, matching: find.byType(Opacity)),
      findsNothing,
      reason: 'it shows in full from the first frame',
    );
  });
}
