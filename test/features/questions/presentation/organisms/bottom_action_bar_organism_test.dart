import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpNavigation(
    WidgetTester tester, {
    required Size size,
    required List<String> tapped,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: NavigationBarOrganism(
                params: BottomActionBarParams(
                  selectedIndex: 0,
                  onCopy: () => tapped.add('saved'),
                  onAiChat: () => tapped.add('tutor'),
                  onUpload: () => tapped.add('solve'),
                  onChat: () => tapped.add('discuss'),
                  onProfile: () => tapped.add('profile'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('keeps sections selected while Solve remains an action',
      (tester) async {
    final tapped = <String>[];

    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      tapped: tapped,
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tester.tap(find.byIcon(Icons.smart_toy_outlined));
    await tester.pump();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);

    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pump();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
    expect(tapped, ['tutor', 'solve']);
  });

  testWidgets('renders Solve like the other navigation destinations',
      (tester) async {
    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      tapped: <String>[],
    );

    expect(find.byKey(const Key('solve-action')), findsNothing);

    final solveIcon = tester.widget<Icon>(
      find.byIcon(Icons.document_scanner_outlined),
    );
    final tutorIcon = tester.widget<Icon>(
      find.byIcon(Icons.smart_toy_outlined),
    );
    expect(solveIcon.size, tutorIcon.size);
    expect(solveIcon.color, tutorIcon.color);
  });

  testWidgets('inherits Material navigation colors from the built-in theme',
      (tester) async {
    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      tapped: <String>[],
    );

    final material = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(NavigationBarOrganism),
            matching: find.byType(Material),
          ),
        )
        .firstWhere((material) => material.borderRadius != null);
    expect(material.color, AppTheme.light.colorScheme.surfaceContainer);

    final navigationBar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.indicatorColor, isNull);

    for (final destination in tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination))) {
      final icon = destination.icon as Icon;
      expect(icon.color, isNull);

      final selectedIcon = destination.selectedIcon;
      if (selectedIcon != null) {
        expect((selectedIcon as Icon).color, isNull);
      }
    }
  });

  testWidgets('shows destination labels on wide screens', (tester) async {
    await pumpNavigation(
      tester,
      size: const Size(1100, 800),
      tapped: <String>[],
    );

    final navigationBar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(tester.getSize(find.byType(NavigationBar)).width, 760);
    expect(
      navigationBar.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(
      tester
          .widgetList<NavigationDestination>(
            find.byType(NavigationDestination),
          )
          .map((destination) => destination.label),
      ['Saved', 'AI Tutor', 'Solve', 'Discuss', 'Profile'],
    );
  });

  testWidgets('keeps labels hidden and all actions available on mobile',
      (tester) async {
    final tapped = <String>[];
    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      tapped: tapped,
    );

    final navigationBar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navigationBar.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.tap(find.byIcon(Icons.smart_toy_outlined));
    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.tap(find.byIcon(Icons.forum_outlined));
    await tester.tap(find.byIcon(Icons.person_outline));

    expect(tapped, ['saved', 'tutor', 'solve', 'discuss', 'profile']);
  });
}
