import 'package:doormer/src/core/theme/app_theme.dart';
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
}

void _noop() {}
