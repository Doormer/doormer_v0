import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:doormer/src/features/questions/presentation/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/ask_by_photo_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the nav bar and upload CTA on the idle hero screen',
      (tester) async {
    var pickCount = 0;
    var submitCount = 0;

    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          theme: AppTheme.light,
          home: AskByPhotoTemplate(
            uploadParams: PhotoUploadPanelParams(
              isLoading: false,
              copy: photoUploadCopyFor(hasPhoto: false, isRetry: false),
              onPickPhoto: () => pickCount++,
              onSubmit: () => submitCount++,
              onClear: () {},
            ),
            statusParams: const SolveStatusPanelParams(
              content: SolveStatusContent(
                title: '',
                body: '',
                showActions: false,
              ),
              onRetake: _noop,
              onTypeInstead: _noop,
            ),
            bottomBarParams: BottomActionBarParams(
              onCopy: () {},
              onAiChat: () {},
              onUpload: () {},
              onChat: () {},
              onProfile: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationBarOrganism), findsOneWidget);

    await tester.tap(find.text('UPLOAD & SOLVE'));
    expect(pickCount, 1);
    expect(submitCount, 0);
  });

  testWidgets(
      'UPLOAD & SOLVE CTA uses accent variant for contrast on primary scaffold',
      (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          theme: AppTheme.light,
          home: AskByPhotoTemplate(
            uploadParams: PhotoUploadPanelParams(
              isLoading: false,
              copy: photoUploadCopyFor(hasPhoto: false, isRetry: false),
              onPickPhoto: () {},
              onSubmit: () {},
              onClear: () {},
            ),
            statusParams: const SolveStatusPanelParams(
              content: SolveStatusContent(
                title: '',
                body: '',
                showActions: false,
              ),
              onRetake: _noop,
              onTypeInstead: _noop,
            ),
            bottomBarParams: BottomActionBarParams(
              onCopy: () {},
              onAiChat: () {},
              onUpload: () {},
              onChat: () {},
              onProfile: () {},
            ),
          ),
        ),
      ),
    );

    final btnFinder = find.byWidgetPredicate(
      (w) => w is AppButtonAtom && w.label == 'UPLOAD & SOLVE',
    );
    expect(btnFinder, findsOneWidget);
    final btn = tester.widget<AppButtonAtom>(btnFinder);
    expect(
      btn.variant,
      AppButtonVariant.accent,
      reason: 'CTA on primary scaffold must use accent so it renders with '
          'tertiary/onTertiary and has sufficient contrast',
    );

    // Also verify the rendered FilledButton uses the tertiary background.
    final tertiary = AppTheme.light.colorScheme.tertiary;
    final filledBtnFinder = find.byWidgetPredicate((w) {
      if (w is FilledButton) {
        final bg = w.style?.backgroundColor?.resolve({});
        return bg == tertiary;
      }
      return false;
    });
    expect(
      filledBtnFinder,
      findsAtLeastNWidgets(1),
      reason: 'FilledButton backing the accent CTA must resolve to tertiary',
    );
  });

  group('the dock on a wide window', () {
    // Mounted the way the app mounts it: inside the shell, which caps and
    // centres the column, and inside the page's own side margins. Handing the
    // dock a raw window width instead measures a size it is never given.
    Future<void> pumpMounted(WidgetTester tester, Size window) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              ResponsiveAppShell(child: child ?? const SizedBox.shrink()),
          home: AskByPhotoTemplate(
            uploadParams: PhotoUploadPanelParams(
              isLoading: false,
              copy: photoUploadCopyFor(hasPhoto: false, isRetry: false),
              onPickPhoto: () {},
              onSubmit: () {},
              onClear: () {},
            ),
            statusParams: const SolveStatusPanelParams(
              content: SolveStatusContent(
                title: '',
                body: '',
                showActions: false,
              ),
              onRetake: _noop,
              onTypeInstead: _noop,
            ),
            bottomBarParams: BottomActionBarParams(
              onCopy: () {},
              onAiChat: () {},
              onUpload: () {},
              onChat: () {},
              onProfile: () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    NavigationBar dock(WidgetTester tester) =>
        tester.widget<NavigationBar>(find.byType(NavigationBar));

    for (final window in const <String, Size>{
      'laptop': Size(1440, 900),
      'desktop': Size(1920, 1080),
      'tablet portrait': Size(820, 1180),
      'tablet landscape': Size(1180, 820),
    }.entries) {
      testWidgets('names its destinations on a ${window.key}', (tester) async {
        await pumpMounted(tester, window.value);

        expect(
          dock(tester).labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
          reason: 'five unlabelled icons is a guessing game when there is '
              'room to just say what they are',
        );
        for (final name in const [
          'Saved',
          'AI Tutor',
          'Solve',
          'Discuss',
          'Profile',
        ]) {
          expect(find.text(name), findsOneWidget);
        }
      });
    }

    testWidgets('stays on icons alone on a phone', (tester) async {
      await pumpMounted(tester, const Size(390, 844));

      expect(
        dock(tester).labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
        reason: 'five labels across a phone would be squeezed illegible',
      );
    });
  });
}

void _noop() {}
