import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_source_sheet_organism.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pump({
  required VoidCallback onCamera,
  required VoidCallback onGallery,
  required VoidCallback onCancel,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: PhotoSourceSheetOrganism(
          onCamera: onCamera,
          onGallery: onGallery,
          onCancel: onCancel,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the photo source title and actions', (tester) async {
    await tester.pumpWidget(_pump(
      onCamera: () {},
      onGallery: () {},
      onCancel: () {},
    ));

    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Open camera'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('tapping each source action reports its own callback',
      (tester) async {
    var cameraCount = 0;
    var galleryCount = 0;
    var cancelCount = 0;

    await tester.pumpWidget(_pump(
      onCamera: () => cameraCount++,
      onGallery: () => galleryCount++,
      onCancel: () => cancelCount++,
    ));

    await tester.tap(find.text('Open camera'));
    await tester.pump();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(cameraCount, 1);
    expect(galleryCount, 1);
    expect(cancelCount, 1);
  });
}
