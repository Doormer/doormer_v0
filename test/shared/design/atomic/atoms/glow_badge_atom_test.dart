import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/glow_badge_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) => tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlowBadgeAtom(
              icon: Icons.group_add_rounded,
              color: QuestPalette.violet,
              size: 44,
              iconSize: 22,
              glowRadius: 16,
            ),
          ),
        ),
      ),
    );

/// How the badge is painted.
BoxDecoration _looks(WidgetTester tester) => tester
    .widget<DecoratedBox>(find.descendant(
      of: find.byType(GlowBadgeAtom),
      matching: find.byType(DecoratedBox),
    ))
    .decoration as BoxDecoration;

void main() {
  testWidgets('is a circle of the size given, holding the icon in its colour',
      (tester) async {
    await _pump(tester);

    expect(tester.getSize(find.byType(GlowBadgeAtom)), const Size(44, 44));
    expect(_looks(tester).shape, BoxShape.circle);
    final icon = tester.widget<Icon>(find.byIcon(Icons.group_add_rounded));
    expect(icon.color, QuestPalette.violet);
    expect(icon.size, 22);
  });

  testWidgets(
      'is filled with a soft wash of its colour, and glows in it outside its '
      'edge only', (tester) async {
    await _pump(tester);

    final looks = _looks(tester);
    expect(looks.color!.a, lessThan(0.5));
    expect(looks.color!.withValues(alpha: 1), QuestPalette.violet);
    final glow = looks.boxShadow!.single;
    expect(glow.color.withValues(alpha: 1), QuestPalette.violet);
    expect(glow.blurRadius, 16);
    expect(glow.blurStyle, BlurStyle.outer,
        reason: 'the glow rings the badge without brightening its fill');
  });
}
