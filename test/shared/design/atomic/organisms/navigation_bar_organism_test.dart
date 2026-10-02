import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpNavigation(
    WidgetTester tester, {
    required Size size,
    required List<String> tapped,
    AppDestination current = AppDestination.saved,
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
                params: NavigationBarParams(
                  current: current,
                  onSaved: () => tapped.add('saved'),
                  onAiTutor: () => tapped.add('tutor'),
                  onSolve: () => tapped.add('solve'),
                  onCards: () => tapped.add('cards'),
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

  // Sizes the dock itself rather than the window: what decides whether the
  // names show is the room the dock is given, and the page it lives on keeps a
  // margin either side. Testing it by window width measures the wrong number
  // and reports a pass for a width the app never hands over -- which is how the
  // labels came to be unreachable in the first place. That the app does give it
  // the room lives in the template's tests, where the margins are real.
  Future<void> pumpDockOfWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = const Size(1400, 900);
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
              child: SizedBox(
                width: width,
                child: NavigationBarOrganism(
                  params: NavigationBarParams(
                    current: AppDestination.saved,
                    onSaved: () {},
                    onAiTutor: () {},
                    onSolve: () {},
                    onCards: () {},
                    onProfile: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  const destinations = 5;

  testWidgets('names its destinations once each one has room to be named',
      (tester) async {
    await pumpDockOfWidth(
      tester,
      NavigationBarOrganism.labelRoom * destinations,
    );

    final navigationBar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
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
      ['Saved', 'AI Tutor', 'Solve', 'Cards', 'Profile'],
    );
  });

  testWidgets('drops the hover tooltip once the name is on screen',
      (tester) async {
    await pumpDockOfWidth(
      tester,
      NavigationBarOrganism.labelRoom * destinations,
    );

    for (final destination in tester.widgetList<NavigationDestination>(
      find.byType(NavigationDestination),
    )) {
      expect(destination.tooltip, '',
          reason: 'a tooltip that repeats the label the user is already '
              'reading is noise');
    }
  });

  testWidgets('keeps the hover tooltip while the name is hidden',
      (tester) async {
    await pumpDockOfWidth(
      tester,
      NavigationBarOrganism.labelRoom * destinations - 1,
    );

    for (final destination in tester.widgetList<NavigationDestination>(
      find.byType(NavigationDestination),
    )) {
      expect(destination.tooltip, isNull,
          reason: 'null lets the destination fall back to naming itself, '
              'which is the only name a bare icon has');
    }
  });

  testWidgets('keeps quiet while a name would be squeezed', (tester) async {
    await pumpDockOfWidth(
      tester,
      NavigationBarOrganism.labelRoom * destinations - 1,
    );

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
  });

  testWidgets('never grows past the reading column', (tester) async {
    await pumpDockOfWidth(tester, AppLayout.maxContentWidth + 400);

    expect(
      tester.getSize(find.byType(NavigationBar)).width,
      AppLayout.maxContentWidth,
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
    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.tap(find.byIcon(Icons.person_outline));

    expect(tapped, ['saved', 'tutor', 'solve', 'cards', 'profile']);
  });

  AppDestination lit(WidgetTester tester) => AppDestination.values[
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex];

  testWidgets('a tap on Cards leaves Solve lit on the Solve page',
      (tester) async {
    final tapped = <String>[];
    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      tapped: tapped,
      current: AppDestination.solve,
    );

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump();

    expect(lit(tester), AppDestination.solve,
        reason: 'Cards opens its own page, whose bar lights it. Lit here, it '
            'would stay lit on home whenever the tap is refused mid-solve');
    expect(tapped, ['cards']);
  });

  testWidgets('on the Cards page, Cards is lit and lights again when tapped',
      (tester) async {
    await pumpNavigation(
      tester,
      size: const Size(390, 844),
      tapped: <String>[],
      current: AppDestination.cards,
    );
    expect(lit(tester), AppDestination.cards);
    expect(find.byIcon(Icons.style), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_outline));
    await tester.pump();
    expect(lit(tester), AppDestination.saved);

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump();
    expect(lit(tester), AppDestination.cards);
  });
}
