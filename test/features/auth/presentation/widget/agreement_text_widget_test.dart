import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/auth/presentation/widget/agreement_text_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('consent text is centered', (tester) async {
    await tester.pumpWidget(_pump(const AgreementTextWidget()));

    final richText = tester.widget<RichText>(find.byType(RichText).first);

    expect(richText.textAlign, TextAlign.center);
  });

  testWidgets('terms sheet shows a drag handle and closes from the header',
      (tester) async {
    await tester.pumpWidget(_pump(const AgreementTextWidget()));

    final richText = tester.widget<RichText>(find.byType(RichText).first);
    recognizerFor(richText.text, 'Terms')!.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Terms of Service'), findsOneWidget);
    expect(_findMaterialDragHandle(), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Terms of Service'), findsNothing);
  });
}

Widget _pump(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

TapGestureRecognizer? recognizerFor(InlineSpan span, String text) {
  if (span is! TextSpan) return null;
  final own = span.recognizer;
  if (own is TapGestureRecognizer && (span.text ?? '').contains(text)) {
    return own;
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    final found = recognizerFor(child, text);
    if (found != null) return found;
  }
  return null;
}

Finder _findMaterialDragHandle() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_DragHandle',
    description: 'Material bottom sheet drag handle',
  );
}
