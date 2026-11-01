import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/presentation/organisms/profile_header_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/profile_header_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The header as Profile shows it, 20 in from each side of a [window] of
/// that size.
Future<void> _pump(
  WidgetTester tester, {
  required Size window,
  String nickname = 'Kai',
  VoidCallback? onEdit,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => ResponsiveAppShell(child: child!),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ProfileHeaderOrganism(
          params: ProfileHeaderParams(
            nickname: nickname,
            artUrl: null,
            friendCode: 'K7QM-2XPA',
            onEdit: onEdit ?? () {},
          ),
        ),
      ),
    ),
  ));
}

final _edit = find.ancestor(
  of: find.text('Edit'),
  matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
);

void main() {
  testWidgets("Edit sits just after the nickname, on the nickname's line",
      (tester) async {
    await _pump(tester, window: const Size(1280, 800));

    final nickname = tester.getRect(find.text('Kai'));
    final edit = tester.getRect(_edit);
    expect(edit.left - nickname.right, inInclusiveRange(0, 40));
    expect(edit.center.dy, inInclusiveRange(nickname.top, nickname.bottom));
    expect(
      find.descendant(of: _edit, matching: find.byIcon(Icons.edit_outlined)),
      findsOneWidget,
    );
  });

  testWidgets('tapping Edit calls onEdit', (tester) async {
    var edits = 0;
    await _pump(tester, window: const Size(1280, 800), onEdit: () => edits++);

    await tester.tap(_edit);

    expect(edits, 1);
  });

  testWidgets('on a small phone, Edit keeps a full-height tap target',
      (tester) async {
    await _pump(tester, window: const Size(360, 640));

    expect(
      tester.getSize(_edit).height,
      greaterThanOrEqualTo(32 * AppLayout.minScale),
      reason: 'Edit is 32 design pixels tall, so at least 27 px even at the '
          'smallest UI scale',
    );
  });

  testWidgets(
      'a long nickname is cut short with an ellipsis, and Edit stays in view',
      (tester) async {
    const longest = 'WWWWWWWWWWWWWWWW';
    await _pump(tester, window: const Size(360, 690), nickname: longest);

    final nickname = tester.renderObject<RenderParagraph>(find.text(longest));
    expect(nickname.didExceedMaxLines, isTrue);
    expect(nickname.overflow, TextOverflow.ellipsis);
    expect(tester.getRect(_edit).right, lessThanOrEqualTo(360 - 20));
  });
}
