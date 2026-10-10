import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:doormer/src/features/questions/presentation/molecules/ads_notice_molecule.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_upload_panel_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPanel(WidgetTester tester, {VoidCallback? onWhyAds}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhotoUploadPanelOrganism(
              params: PhotoUploadPanelParams(
                isLoading: false,
                showWhenEmpty: true,
                copy: photoUploadCopyFor(hasPhoto: false, isRetry: false),
                onPickPhoto: () {},
                onSubmit: () {},
                onClear: () {},
                onWhyAds: onWhyAds,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<void> _pumpPanelWithPhoto(
  WidgetTester tester, {
  VoidCallback? onEditPhoto,
  bool isLoading = false,
}) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PhotoUploadPanelOrganism(
              params: PhotoUploadPanelParams(
                imageBytes: _pngBytes,
                fileName: 'IMG_1.jpg',
                isLoading: isLoading,
                copy: photoUploadCopyFor(hasPhoto: true, isRetry: false),
                onPickPhoto: () {},
                onSubmit: () {},
                onClear: () {},
                onEditPhoto: onEditPhoto,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

IconButton _cropButton(WidgetTester tester) => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.crop_rotate),
    );

void main() {
  testWidgets('Crop & rotate opens the editor for the photo', (tester) async {
    var opened = 0;
    await _pumpPanelWithPhoto(tester, onEditPhoto: () => opened++);

    expect(find.byTooltip('Crop & rotate'), findsOneWidget);
    await tester.tap(find.byTooltip('Crop & rotate'));
    expect(opened, 1);
  });

  testWidgets('Crop & rotate waits while the photo is being solved',
      (tester) async {
    await _pumpPanelWithPhoto(tester, onEditPhoto: () {}, isLoading: true);

    expect(_cropButton(tester).onPressed, isNull);
  });

  testWidgets('a photo that cannot be edited has no Crop & rotate',
      (tester) async {
    await _pumpPanelWithPhoto(tester);

    expect(find.byTooltip('Crop & rotate'), findsNothing);
  });

  testWidgets('with ads on, the ads notice sits under the Submit button',
      (tester) async {
    await _pumpPanel(tester, onWhyAds: () {});

    expect(find.byType(AdsNoticeMolecule), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(AdsNoticeMolecule)).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(find.text('Submit to solver')).dy,
      ),
    );
  });

  testWidgets('tapping "Why ads?" asks for the explanation', (tester) async {
    var whyAdsCount = 0;
    await _pumpPanel(tester, onWhyAds: () => whyAdsCount++);

    await tester.tap(find.text('Why ads?'));
    await tester.pump();

    expect(whyAdsCount, 1);
  });

  testWidgets('with ads off, there is no ads notice', (tester) async {
    await _pumpPanel(tester);

    expect(find.byType(AdsNoticeMolecule), findsNothing);
    expect(find.text('Why ads?'), findsNothing);
  });
}
