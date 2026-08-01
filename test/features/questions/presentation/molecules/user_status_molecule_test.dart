import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/molecules/user_status_molecule.dart';
import 'package:doormer/src/features/questions/presentation/params/user_status_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pumpMolecule({ThemeData? theme}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: const Scaffold(
        body: UserStatusMolecule(
          params: UserStatusParams(
            levelLabel: 'LV.7',
            collectedCount: 12,
            totalCount: 50,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders level and collected character count once',
      (tester) async {
    await tester.pumpWidget(_pumpMolecule());

    expect(find.text('LV.7'), findsOneWidget);
    expect(find.text('Characters collected: 12/50'), findsOneWidget);
  });

  testWidgets('status surface uses the primary container color pair',
      (tester) async {
    await tester.pumpWidget(_pumpMolecule(theme: AppTheme.dark));
    final theme = AppTheme.dark;

    final container = tester.widget<Container>(
      find.byKey(const Key('user_status_surface')),
    );
    expect(
      (container.decoration as BoxDecoration).color,
      theme.colorScheme.primaryContainer,
    );

    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(UserStatusMolecule),
        matching: find.byType(Text),
      ),
    );
    expect(
      texts.every(
        (text) => text.style?.color == theme.colorScheme.onPrimaryContainer,
      ),
      isTrue,
    );
  });

  testWidgets('avatar placeholder uses the highest surface container',
      (tester) async {
    await tester.pumpWidget(_pumpMolecule(theme: AppTheme.dark));
    final theme = AppTheme.dark;

    final avatarContainer = tester
        .widgetList<Container>(
          find.byType(Container),
        )
        .firstWhere(
          (container) =>
              container.decoration is BoxDecoration &&
              (container.decoration as BoxDecoration).shape == BoxShape.circle,
        );

    expect(
      (avatarContainer.decoration as BoxDecoration).color,
      theme.colorScheme.surfaceContainerHighest,
    );
  });
}
