import 'dart:typed_data';

import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:doormer/src/features/questions/presentation/molecules/study_tip_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solve_status_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/organisms/solving_progress_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_progress_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_view_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/ask_by_photo_template.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/display_ad_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/show_after_delay_atom.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
            ),
            navigationBarParams: _navigationBarParams,
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
            ),
            navigationBarParams: _navigationBarParams,
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

  testWidgets('shows the upload panel while a photo is being prepared',
      (tester) async {
    var pickCount = 0;
    var submitCount = 0;
    var clearCount = 0;

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
              isPreparing: true,
              copy: photoUploadCopyFor(hasPhoto: false, isRetry: false),
              onPickPhoto: () => pickCount++,
              onSubmit: () => submitCount++,
              onClear: () => clearCount++,
            ),
            statusParams: const SolveStatusPanelParams(
              content: SolveStatusContent(
                title: '',
                body: '',
                showActions: false,
              ),
              onRetake: _noop,
            ),
            navigationBarParams: _navigationBarParams,
          ),
        ),
      ),
    );

    expect(find.text('Preparing your photo…'), findsOneWidget);
    expect(find.text('UPLOAD & SOLVE'), findsNothing);

    final buttons = tester.widgetList<AppButtonAtom>(find.descendant(
      of: find.byType(PhotoUploadPanelOrganism),
      matching: find.byType(AppButtonAtom),
    ));
    expect(buttons, isNotEmpty);
    for (final button in buttons) {
      expect(button.onPressed, isNull, reason: button.label);
      expect(button.isLoading, isFalse, reason: button.label);
    }
    expect(pickCount + submitCount + clearCount, 0);
  });
  group('while a photo is being solved', () {
    final adUnit = DisplayAdUnit.tryCreate(
      clientId: 'ca-pub-1234567890123456',
      slotId: '1234567890',
    )!;

    testWidgets('the solving view replaces the heading and the photo panels',
        (tester) async {
      await _pumpSolving(tester);

      expect(find.byType(SolvingProgressOrganism), findsOneWidget);
      expect(find.byType(StudyTipMolecule), findsOneWidget);
      expect(find.text('Check your answer.'), findsOneWidget);
      expect(find.text('Upload a photo'), findsNothing);
      expect(find.byType(PhotoUploadPanelOrganism), findsNothing);
      expect(find.byType(SolveStatusPanelOrganism), findsNothing);
      expect(find.byType(NavigationBarOrganism), findsOneWidget);
    });

    testWidgets('the view sits at the top of the screen', (tester) async {
      await _pumpSolving(tester);

      expect(
        tester.getTopLeft(find.byType(SolvingProgressOrganism)).dy,
        lessThan(100),
        reason: 'a centred view would move up when the ad card appears '
            'below it, and could slide a button under a finger',
      );
    });

    testWidgets('the ad card appears once the solve has run for 3 s',
        (tester) async {
      await _pumpSolving(tester, adUnit: adUnit);

      await tester.pump(const Duration(milliseconds: 2999));
      expect(find.byType(DisplayAdAtom), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(DisplayAdAtom), findsOneWidget);
    });

    testWidgets('the ad card comes last, below the tip', (tester) async {
      await _pumpSolving(tester, adUnit: adUnit);
      await tester.pump(AskByPhotoTemplate.adDelay);

      expect(
        tester.getTopLeft(find.byType(DisplayAdAtom)).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byType(StudyTipMolecule)).dy,
        ),
      );
    });

    testWidgets('with ads off there is never an ad card', (tester) async {
      await _pumpSolving(tester);
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(ShowAfterDelayAtom), findsNothing);
      expect(find.byType(DisplayAdAtom), findsNothing);
    });
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
            ),
            navigationBarParams: _navigationBarParams,
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
          'Cards',
          'Profile',
        ]) {
          expect(find.text(name), findsOneWidget);
        }
      });
    }

    testWidgets('names its destinations on a phone', (tester) async {
      await pumpMounted(tester, const Size(390, 844));

      expect(
        dock(tester).labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
        reason: 'the phone dock keeps each nav destination named',
      );
      expect(find.text('AI Tutor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  for (final window in const <String, Size>{
    'phone': Size(390, 844),
    'desktop': Size(1280, 800),
  }.entries) {
    testWidgets('the illustration never covers the heading on a ${window.key}',
        (tester) async {
      await _pumpTemplate(tester, window: window.value);

      final illustration = tester.getRect(_starterIllustrationFinder());
      expect(
        illustration.overlaps(tester.getRect(find.text('Upload a photo'))),
        isFalse,
      );
      expect(
        illustration.overlaps(tester.getRect(find.text('Ready to solve?'))),
        isFalse,
      );
    });
  }

  testWidgets('the illustration steps aside once a photo is picked',
      (tester) async {
    await _pumpTemplate(
      tester,
      window: const Size(390, 844),
      imageBytes: _transparentPngBytes,
    );

    expect(_starterIllustrationFinder(), findsNothing);
  });

  testWidgets('headings use the display font and the button the body font',
      (tester) async {
    await _pumpTemplate(tester, window: const Size(390, 844));

    final uploadHeading = tester.widget<Text>(find.text('Upload a photo'));
    expect(uploadHeading.style?.fontFamily, kDisplayFont);

    final buttonParagraph =
        tester.renderObject<RenderParagraph>(find.text('UPLOAD & SOLVE'));
    final buttonText = buttonParagraph.text as TextSpan;
    final buttonStyle = buttonText.style;
    final usesBodyFont = buttonStyle?.fontFamily == kBodyFont ||
        (buttonStyle?.fontFamilyFallback ?? const <String>[])
            .contains(kBodyFont);
    expect(usesBodyFont, isTrue);
  });
}

void _noop() {}

Finder _starterIllustrationFinder() {
  return find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'assets/images/starter_bg_person.png';
  });
}

Future<void> _pumpTemplate(
  WidgetTester tester, {
  required Size window,
  Uint8List? imageBytes,
}) async {
  tester.view.physicalSize = window;
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
            imageBytes: imageBytes,
            isLoading: false,
            copy: photoUploadCopyFor(
              hasPhoto: imageBytes != null,
              isRetry: false,
            ),
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
          ),
          navigationBarParams: _navigationBarParams,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpSolving(WidgetTester tester, {DisplayAdUnit? adUnit}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.dark,
        home: AskByPhotoTemplate(
          uploadParams: PhotoUploadPanelParams(
            imageBytes: _transparentPngBytes,
            fileName: 'question.jpg',
            isLoading: true,
            copy: photoUploadCopyFor(hasPhoto: true, isRetry: false),
            onPickPhoto: _noop,
            onSubmit: _noop,
            onClear: _noop,
          ),
          statusParams: const SolveStatusPanelParams(
            content: SolveStatusContent(
              title: 'Solving your photo',
              body: '',
              showActions: false,
            ),
            onRetake: _noop,
          ),
          solving: SolvingViewParams(
            progress: SolvingProgressParams(
              imageBytes: _transparentPngBytes,
              title: 'Solving your photo',
              body: 'This can take from a few seconds to a few minutes.',
            ),
            tip: 'Check your answer.',
            adUnit: adUnit,
          ),
          navigationBarParams: _navigationBarParams,
        ),
      ),
    ),
  );
}

const _navigationBarParams = NavigationBarParams(
  current: AppDestination.solve,
  onSaved: _noop,
  onAiTutor: _noop,
  onSolve: _noop,
  onCards: _noop,
  onProfile: _noop,
);

final _transparentPngBytes = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
