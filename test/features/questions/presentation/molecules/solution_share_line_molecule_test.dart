import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_share_line_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_share_line_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the line asked for.
class _Taps {
  final pressed = <String>[];
}

Future<_Taps> _pump(
  WidgetTester tester,
  SolutionShareLineParams Function(_Taps taps) params, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 690);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taps = _Taps();
  await tester.pumpWidget(ScreenUtilInit(
    // Unscaled, as the app's shell draws a phone, or a 760 wide column on a
    // window as short as this one.
    designSize: Size(width, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(child: SolutionShareLineMolecule(params: params(taps))),
      ),
    ),
  ));
  return taps;
}

OwnQuestionShareLineParams _own(
  _Taps taps, {
  String sharedWithLabel = '',
  bool isStopping = false,
}) =>
    OwnQuestionShareLineParams(
      sharedWithLabel: sharedWithLabel,
      isStopping: isStopping,
      onShare: () => taps.pressed.add('share'),
      onStopSharing: () => taps.pressed.add('stop'),
    );

/// The widest nickname a student can pick: 16 of the widest letter.
const _longestNickname = 'WWWWWWWWWWWWWWWW';

/// Checks the line on a phone, with [words] too long to share a row with
/// its [buttons]: the words are drawn in full, and the buttons sit together
/// on the next line, from the left, wholly on the screen.
void _expectWordsInFullAndButtonsBelow(
  WidgetTester tester,
  String words,
  List<Key> buttons,
) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(words));
  expect(paragraph.didExceedMaxLines, isFalse, reason: 'the words are cut');

  final screen =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  final wordsBottom = tester.getRect(find.text(words)).bottom;
  final lineLeft = tester.getRect(find.byType(SolutionShareLineMolecule)).left;
  final first = tester.getRect(find.byKey(buttons.first));
  expect(first.left, lineLeft, reason: 'the buttons start at the left');
  for (final key in buttons) {
    final button = tester.getRect(find.byKey(key));
    expect(button.top, greaterThanOrEqualTo(wordsBottom),
        reason: '$key is on the line under the words');
    expect(button.top, first.top, reason: 'the buttons stay together');
    expect(screen.intersect(button), button, reason: '$key is cut off');
  }
  expect(tester.takeException(), isNull, reason: 'nothing overflows');
}

void main() {
  testWidgets('a question shared with no one offers Share alone',
      (tester) async {
    final taps = await _pump(tester, (taps) => _own(taps));

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Stop sharing'), findsNothing);
    await tester.tap(find.text('Share'));

    expect(taps.pressed, ['share']);
  });

  testWidgets('a question shared says who with, beside Share and Stop sharing',
      (tester) async {
    final taps = await _pump(
      tester,
      (taps) => _own(taps, sharedWithLabel: 'Shared with Sam, Alex'),
    );

    expect(find.text('Shared with Sam, Alex'), findsOneWidget);
    await tester.tap(find.text('Share'));
    await tester.tap(find.text('Stop sharing'));

    expect(taps.pressed, ['share', 'stop']);
  });

  testWidgets('Stop sharing is red, and spins while it stops', (tester) async {
    await _pump(
      tester,
      (taps) => _own(taps, sharedWithLabel: 'Shared with Sam'),
    );
    final red =
        Theme.of(tester.element(find.text('Stop sharing'))).colorScheme.error;
    expect(tester.widget<Text>(find.text('Stop sharing')).style?.color, red);

    await _pump(
      tester,
      (taps) =>
          _own(taps, sharedWithLabel: 'Shared with Sam', isStopping: true),
    );
    expect(find.text('Stop sharing'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'on a phone, the longest "Shared with" is drawn in full, with Share and '
      'Stop sharing together below it', (tester) async {
    // Three of the longest nicknames and two more friends: the longest label
    // the presenter makes.
    const words = 'Shared with $_longestNickname, $_longestNickname, '
        '$_longestNickname and 2 more';
    final taps = await _pump(
      tester,
      (taps) => _own(taps, sharedWithLabel: words),
    );

    _expectWordsInFullAndButtonsBelow(
      tester,
      words,
      const [Key('share_open'), Key('share_stop')],
    );
    await tester.tap(find.byKey(const Key('share_open')));
    await tester.tap(find.byKey(const Key('share_stop')));
    expect(taps.pressed, ['share', 'stop']);
  });

  testWidgets(
      'on a wide screen, the buttons follow the words instead of the far '
      'end', (tester) async {
    await _pump(
      tester,
      (taps) => _own(taps, sharedWithLabel: 'Shared with Sam'),
      width: 760,
    );

    final words = tester.getRect(find.text('Shared with Sam'));
    final share = tester.getRect(find.byKey(const Key('share_open')));
    final stop = tester.getRect(find.byKey(const Key('share_stop')));
    expect(share.left - words.right, lessThan(24));
    expect(stop.left - share.right, lessThan(24));
    expect(stop.right, lessThan(600), reason: 'not at the far end');
    for (final button in [share, stop]) {
      expect(button.center.dy, words.center.dy,
          reason: "the buttons sit on the words' row");
    }
  });

  group("a friend's question", () {
    FriendQuestionShareLineParams friendLine(
      _Taps taps, {
      bool isRemoving = false,
      String nickname = 'Sam',
    }) =>
        FriendQuestionShareLineParams(
          sharedByLabel: 'Shared by $nickname',
          nickname: nickname,
          artUrl: null,
          isRemoving: isRemoving,
          onRemove: () => taps.pressed.add('remove'),
          onReport: () => taps.pressed.add('report'),
        );

    testWidgets('says who shared it, with their picture, Remove and Report',
        (tester) async {
      final taps = await _pump(tester, friendLine);

      expect(find.text('Shared by Sam'), findsOneWidget);
      expect(find.byKey(const Key('card_picture_letter')), findsOneWidget);
      expect(find.text('Share'), findsNothing);
      await tester.tap(find.text('Remove'));
      await tester.tap(find.text('Report'));

      expect(taps.pressed, ['remove', 'report']);
    });

    testWidgets('Remove is red, and spins while it removes', (tester) async {
      await _pump(tester, friendLine);
      final red =
          Theme.of(tester.element(find.text('Remove'))).colorScheme.error;
      expect(tester.widget<Text>(find.text('Remove')).style?.color, red);

      await _pump(tester, (taps) => friendLine(taps, isRemoving: true));
      expect(find.text('Remove'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'on a phone, "Shared by" the longest nickname is drawn in full, with '
        'Remove and Report together below it', (tester) async {
      final taps = await _pump(
        tester,
        (taps) => friendLine(taps, nickname: _longestNickname),
      );

      _expectWordsInFullAndButtonsBelow(
        tester,
        'Shared by $_longestNickname',
        const [Key('shared_question_remove'), Key('shared_question_report')],
      );
      await tester.tap(find.byKey(const Key('shared_question_remove')));
      await tester.tap(find.byKey(const Key('shared_question_report')));
      expect(taps.pressed, ['remove', 'report']);
    });

    testWidgets("on a wide screen, Remove and Report sit on the words' row",
        (tester) async {
      await _pump(tester, friendLine, width: 760);

      final words = tester.getRect(find.text('Shared by Sam'));
      for (final key in const [
        Key('shared_question_remove'),
        Key('shared_question_report'),
      ]) {
        final button = tester.getRect(find.byKey(key));
        expect(button.left, greaterThan(words.right), reason: '$key follows');
        expect(button.center.dy, words.center.dy,
            reason: "$key sits on the words' row");
      }
    });
  });
}
