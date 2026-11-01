import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/organisms/share_question_sheet_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/share_question_sheet_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the sheet asked for.
class _Taps {
  final toggled = <String>[];
  var sends = 0;
  var retries = 0;
  var closes = 0;
}

Future<_Taps> _pump(
  WidgetTester tester,
  ShareSheetBodyParams Function(_Taps taps) body, {
  Size screen = const Size(360, 690),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final taps = _Taps();
  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ShareQuestionSheetOrganism(
            params: ShareQuestionSheetParams(
              body: body(taps),
              onClose: () => taps.closes++,
            ),
          ),
        ),
      ),
    ),
  ));
  return taps;
}

ShareFriendRowParams _friend(
  _Taps taps,
  String nickname, {
  bool isTicked = false,
  bool isShared = false,
  bool canToggle = true,
}) =>
    ShareFriendRowParams(
      nickname: nickname,
      artUrl: null,
      isTicked: isTicked,
      isShared: isShared,
      onToggle: canToggle ? () => taps.toggled.add(nickname) : null,
    );

ShareSheetFriendsParams _friends(
  _Taps taps, {
  List<ShareFriendRowParams>? rows,
  bool isFull = false,
  bool isSending = false,
  bool canSend = true,
}) =>
    ShareSheetFriendsParams(
      friends: rows ??
          [
            _friend(taps, 'Alex', isTicked: true),
            _friend(taps, 'Kate'),
            _friend(taps, 'Sam',
                isTicked: true, isShared: true, canToggle: false),
          ],
      isFull: isFull,
      isSending: isSending,
      onSend: canSend ? () => taps.sends++ : null,
    );

/// The button with [label], found by its label even while it spins.
AppButtonAtom _button(WidgetTester tester, String label) =>
    tester.widget<AppButtonAtom>(find.byWidgetPredicate(
        (widget) => widget is AppButtonAtom && widget.label == label));

void main() {
  testWidgets('says what friends will see, above a tick box for each friend',
      (tester) async {
    await _pump(tester, (taps) => _friends(taps));

    expect(find.text('Share with friends'), findsOneWidget);
    expect(find.text('Friends will see your photo and the full solution'),
        findsOneWidget);
    for (final nickname in ['Alex', 'Kate', 'Sam']) {
      expect(find.text(nickname), findsOneWidget);
    }
    expect(find.byType(Checkbox), findsNWidgets(3));
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('tapping a friend ticks or unticks them', (tester) async {
    final taps = await _pump(tester, (taps) => _friends(taps));

    await tester.tap(find.text('Kate'));
    await tester.tap(find.text('Alex'));

    expect(taps.toggled, ['Kate', 'Alex']);
  });

  testWidgets(
      'a friend it is already shared with shows ticked, as Shared, and stays '
      'ticked', (tester) async {
    final taps = await _pump(tester, (taps) => _friends(taps));

    final sam = find.ancestor(
        of: find.text('Sam'), matching: find.byType(CheckboxListTile));
    expect(tester.widget<CheckboxListTile>(sam).value, isTrue);
    expect(find.text('Shared'), findsOneWidget);
    await tester.tap(find.text('Sam'));

    expect(taps.toggled, isEmpty);
  });

  testWidgets('says so once 10 are ticked', (tester) async {
    await _pump(tester, (taps) => _friends(taps));
    expect(find.text('Up to 10 at a time.'), findsNothing);

    await _pump(tester, (taps) => _friends(taps, isFull: true));
    expect(find.text('Up to 10 at a time.'), findsOneWidget);
  });

  testWidgets('Send sends, and spins while sending', (tester) async {
    final taps = await _pump(tester, (taps) => _friends(taps));

    await tester.tap(find.text('Send'));
    expect(taps.sends, 1);

    await _pump(tester, (taps) => _friends(taps, isSending: true));
    expect(_button(tester, 'Send').isLoading, isTrue);
  });

  testWidgets('Send does nothing until a friend is ticked', (tester) async {
    await _pump(tester, (taps) => _friends(taps, canSend: false));

    expect(_button(tester, 'Send').onPressed, isNull);
  });

  testWidgets('spins while the friends load', (tester) async {
    await _pump(tester, (_) => const ShareSheetLoadingParams());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Send'), findsNothing);
  });

  testWidgets('says why there is no one to tick, with Try again when it helps',
      (tester) async {
    await _pump(
      tester,
      (_) => const ShareSheetMessageParams(
          message: 'Add friends on Profile to share questions with them.'),
    );
    expect(find.text('Add friends on Profile to share questions with them.'),
        findsOneWidget);
    expect(find.text('Try again'), findsNothing);

    final taps = await _pump(
      tester,
      (taps) => ShareSheetMessageParams(
        message: "We couldn't load your friends.",
        onRetry: () => taps.retries++,
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(taps.retries, 1);
  });

  testWidgets('closes', (tester) async {
    final taps = await _pump(tester, (taps) => _friends(taps));

    await tester.tap(find.byKey(const Key('share_close')));

    expect(taps.closes, 1);
  });

  testWidgets(
      'on a wide screen, keeps the tick boxes, names and Send together on '
      'the left', (tester) async {
    await _pump(tester, (taps) => _friends(taps), screen: const Size(760, 690));

    final send = tester.getRect(find.byType(AppButtonAtom));
    final kate = tester.getRect(find.text('Kate'));
    expect(send.width, lessThanOrEqualTo(520));
    expect(send.left, lessThan(60));
    expect(kate.left, lessThan(200));
  });
}
