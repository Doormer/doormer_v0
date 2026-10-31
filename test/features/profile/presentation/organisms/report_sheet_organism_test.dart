import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/profile/domain/entity/report_reason.dart';
import 'package:doormer/src/features/profile/presentation/organisms/report_sheet_organism.dart';
import 'package:doormer/src/features/profile/presentation/params/report_sheet_params.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the sheet asked for.
class _Taps {
  final sent = <(ReportReason, String)>[];
  final links = <Uri>[];
  var blocks = 0;
  var closes = 0;
}

Future<_Taps> _pump(
  WidgetTester tester, {
  bool isSending = false,
  bool isSent = false,
}) async {
  tester.view.physicalSize = const Size(360, 1400);
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
          child: ReportSheetOrganism(
            params: ReportSheetParams(
              title: 'Report Sam',
              isSending: isSending,
              isSent: isSent,
              onSend: (reason, note) => taps.sent.add((reason, note)),
              onBlock: () => taps.blocks++,
              onClose: () => taps.closes++,
              onOpenLink: taps.links.add,
            ),
          ),
        ),
      ),
    ),
  ));
  return taps;
}

/// The button with [label], found by its label even while it spins.
AppButtonAtom _button(WidgetTester tester, String label) =>
    tester.widget<AppButtonAtom>(find.byWidgetPredicate(
        (widget) => widget is AppButtonAtom && widget.label == label));

void main() {
  testWidgets('offers the four reasons, and sends nothing until one is picked',
      (tester) async {
    await _pump(tester);

    expect(find.text('Report Sam'), findsOneWidget);
    for (final label in [
      'Rude or hurtful nickname',
      'Bullying or being mean',
      'Pretending to be someone else',
      'Something else',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(_button(tester, 'Send report').onPressed, isNull);
  });

  testWidgets('sends the reason picked and the note, trimmed', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Bullying or being mean'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('report_note')), '  Mean in class.  ');
    await tester.tap(find.text('Send report'));

    expect(taps.sent, [(ReportReason.bullying, 'Mean in class.')]);
  });

  testWidgets('a note is optional', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Something else'));
    await tester.pump();
    await tester.tap(find.text('Send report'));

    expect(taps.sent, [(ReportReason.other, '')]);
  });

  testWidgets('a note holds at most 500 characters', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byKey(const Key('report_note')), 'a' * 600);

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('report_note')))
          .controller!
          .text,
      hasLength(500),
    );
  });

  testWidgets('caps the note at 500 code points, as the API counts them',
      (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Something else'));
    await tester.pump();
    // 👍🏽 is one character on screen, but two code points.
    await tester.enterText(find.byKey(const Key('report_note')), '👍🏽' * 300);
    await tester.pump();
    await tester.tap(find.text('Send report'));

    final (_, note) = taps.sent.single;
    expect(note.runes.length, lessThanOrEqualTo(500));
    expect(note, '👍🏽' * 250, reason: 'Only whole emoji, as many as fit.');
    expect(find.text('500/500'), findsOneWidget);
  });

  testWidgets(
      'never sends more than 500 code points, even when the note lost focus '
      'while a word was still composing', (tester) async {
    final taps = await _pump(tester);
    await tester.tap(find.text('Something else'));
    await tester.pump();
    await tester.showKeyboard(find.byKey(const Key('report_note')));
    // A keyboard such as Gboard composes the word being typed, and the note
    // may go past the cap until the composing ends.
    final typed = '${'a' * 497} hello';
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: typed,
      selection: TextSelection.collapsed(offset: typed.length),
      composing: TextRange(start: 498, end: typed.length),
    ));
    await tester.pump();
    // A touch outside the note unfocuses it on a mobile browser. That ends
    // the composing without the formatter's cut.
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    expect(find.text('503/500'), findsOneWidget);

    await tester.tap(find.text('Send report'));

    final (_, note) = taps.sent.single;
    expect(note.runes.length, lessThanOrEqualTo(500));
    expect(note, '${'a' * 497} he');
  });

  testWidgets('the button spins while the report is on its way',
      (tester) async {
    await _pump(tester, isSending: true);

    expect(_button(tester, 'Send report').isLoading, isTrue);
  });

  testWidgets('once sent, thanks the student', (tester) async {
    await _pump(tester, isSent: true);

    expect(find.text('Thanks. The Doormer team will look at this.'),
        findsOneWidget);
    expect(find.text('Send report'), findsNothing);
  });

  testWidgets('links to Netsafe and eSafety', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.text('Netsafe (New Zealand)'));
    await tester.tap(find.text('eSafety (Australia)'));

    expect(taps.links, [
      Uri.parse('https://netsafe.org.nz'),
      Uri.parse('https://www.esafety.gov.au/report'),
    ]);
  });

  testWidgets('offers Block, before and after sending', (tester) async {
    final taps = await _pump(tester);
    await tester.tap(find.text('Block'));
    final sentTaps = await _pump(tester, isSent: true);
    await tester.tap(find.text('Block'));

    expect(taps.blocks, 1);
    expect(sentTaps.blocks, 1);
  });

  testWidgets('closes', (tester) async {
    final taps = await _pump(tester);

    await tester.tap(find.byKey(const Key('report_close')));

    expect(taps.closes, 1);
  });
}
