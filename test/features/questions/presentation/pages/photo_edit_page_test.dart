import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/pages/photo_edit_page.dart';
import 'package:doormer/src/features/questions/utils/photo/editable_photo.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

EditablePhoto _photo({PhotoEdit edit = PhotoEdit.none}) => EditablePhoto(
      original: PickedPhotoFile(bytes: _pngBytes, name: 'IMG_1.HEIC'),
      unedited: PreparedPhoto(
        bytes: _pngBytes,
        fileName: 'IMG_1.jpg',
        width: 400,
        height: 300,
      ),
      edit: edit,
    );

/// What the editor returned, and whether it has closed at all.
class _Outcome {
  bool closed = false;
  PhotoEdit? edit;
}

Future<_Outcome> _openEditor(WidgetTester tester, EditablePhoto photo) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final outcome = _Outcome();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              outcome.edit = await openPhotoEditPage(context, photo);
              outcome.closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return outcome;
}

void main() {
  testWidgets('shows the photo with the crop tools', (tester) async {
    await _openEditor(tester, _photo());

    expect(find.text('Crop & rotate'), findsOneWidget);
    expect(
      find.text('Drag the corners so only the question is inside the box.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Turn left'), findsOneWidget);
    expect(find.byTooltip('Turn right'), findsOneWidget);
    expect(find.text('Use photo'), findsOneWidget);
  });

  testWidgets('Use photo returns the edit', (tester) async {
    final outcome = await _openEditor(tester, _photo());

    await tester.tap(find.byTooltip('Turn right'));
    await tester.pump();
    await tester.tap(find.text('Use photo'));
    await tester.pumpAndSettle();

    expect(outcome.closed, isTrue);
    expect(outcome.edit, const PhotoEdit(quarterTurns: 1));
  });

  testWidgets('Turn left turns counterclockwise', (tester) async {
    final outcome = await _openEditor(tester, _photo());

    await tester.tap(find.byTooltip('Turn left'));
    await tester.pump();
    await tester.tap(find.text('Use photo'));
    await tester.pumpAndSettle();

    expect(outcome.edit?.quarterTurns, 3);
  });

  testWidgets('Cancel returns nothing', (tester) async {
    final outcome = await _openEditor(tester, _photo());

    await tester.tap(find.byTooltip('Turn right'));
    await tester.pump();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(outcome.closed, isTrue);
    expect(outcome.edit, isNull);
  });

  testWidgets('opens on the last edit, and Reset clears it', (tester) async {
    const earlier = PhotoEdit(
      quarterTurns: 2,
      crop: CropArea(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75),
    );
    final outcome = await _openEditor(tester, _photo(edit: earlier));

    expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns, 2);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    await tester.tap(find.text('Use photo'));
    await tester.pumpAndSettle();

    expect(outcome.edit, PhotoEdit.none);
  });

  testWidgets('Reset is off when there is nothing to reset', (tester) async {
    await _openEditor(tester, _photo());

    final reset = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Reset'),
    );
    expect(reset.onPressed, isNull);
  });
}
