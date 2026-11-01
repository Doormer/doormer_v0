import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/toast_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shows [toast] on a phone, with at most [width] to fit in.
Future<void> _pump(
  WidgetTester tester,
  ToastAtom toast, {
  double width = 340,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: Center(child: toast)),
        ),
      ),
    ),
  ));
}

/// The box the toast paints its card and its edge with.
BoxDecoration _surfaceOf(WidgetTester tester) => tester
    .widget<DecoratedBox>(find
        .descendant(
          of: find.byType(ToastAtom),
          matching: find.byType(DecoratedBox),
        )
        .first)
    .decoration as BoxDecoration;

void main() {
  final looks = {
    ToastKind.success: (QuestPalette.mint, Icons.check_rounded),
    ToastKind.error: (
      AppTheme.dark.colorScheme.error,
      Icons.error_outline_rounded,
    ),
    ToastKind.info: (QuestPalette.markerLine, Icons.info_outline_rounded),
    ToastKind.warning: (QuestPalette.amber, Icons.warning_amber_rounded),
  };
  for (final MapEntry(key: kind, value: (accent, icon)) in looks.entries) {
    testWidgets('a ${kind.name} toast shows its icon and edge in its colour',
        (tester) async {
      await _pump(tester, ToastAtom(message: 'Done.', kind: kind));

      expect(tester.widget<Icon>(find.byIcon(icon)).color, accent);
      final edge = (_surfaceOf(tester).border! as Border).top.color;
      expect(edge.withValues(alpha: 1), accent);
    });
  }

  testWidgets('is opaque, so the page under it never shows through',
      (tester) async {
    await _pump(
      tester,
      const ToastAtom(message: 'Code copied.', kind: ToastKind.success),
    );

    final surface = _surfaceOf(tester);
    expect(surface.color, QuestPalette.card);
    expect(surface.color!.a, 1.0);
  });

  testWidgets('wraps a long message rather than cutting it short',
      (tester) async {
    const message =
        "We couldn't copy that. Select the text and copy it yourself.";
    await _pump(
      tester,
      const ToastAtom(message: message, kind: ToastKind.error),
      width: 260,
    );

    final paragraph = tester.renderObject<RenderParagraph>(find.text(message));
    final lineTops = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: message.length),
        )
        .map((box) => box.top)
        .toSet();
    expect(lineTops.length, greaterThan(1));
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('screen readers announce the message as it shows',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const ToastAtom(message: 'Code copied.', kind: ToastKind.success),
    );

    expect(
      tester.getSemantics(find.byType(ToastAtom)),
      containsSemantics(label: 'Code copied.', isLiveRegion: true),
    );
    semantics.dispose();
  });
}
