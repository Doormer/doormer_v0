import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/solution_share_line_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/solution_share_line_params.dart';
import 'package:flutter/material.dart';
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
  });
}
