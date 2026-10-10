import 'dart:convert';
import 'dart:typed_data';

import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/features/questions/presentation/atoms/crop_handle_atom.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_crop_editor_organism.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const _box = CropArea(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75);

Matcher _area(double left, double top, double right, double bottom) =>
    isA<CropArea>()
        .having((c) => c.left, 'left', closeTo(left, 0.005))
        .having((c) => c.top, 'top', closeTo(top, 0.005))
        .having((c) => c.right, 'right', closeTo(right, 0.005))
        .having((c) => c.bottom, 'bottom', closeTo(bottom, 0.005));

/// Pumps a 400 x 300 photo with room for the handles, so it is shown at 1:1
/// and a drag of one pixel moves the box by 1/400 across or 1/300 down.
Future<List<PhotoEdit>> _pumpEditor(
  WidgetTester tester, {
  PhotoEdit edit = const PhotoEdit(crop: _box),
}) async {
  final changes = <PhotoEdit>[];
  var current = edit;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400 + CropHandleAtom.touchSize,
            height: 400 + CropHandleAtom.touchSize,
            child: StatefulBuilder(
              builder: (context, setState) => PhotoCropEditorOrganism(
                imageBytes: _pngBytes,
                imageSize: const PhotoSize(400, 300),
                edit: current,
                onChanged: (next) {
                  changes.add(next);
                  setState(() => current = next);
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return changes;
}

void main() {
  testWidgets('dragging inside the box moves it', (tester) async {
    final changes = await _pumpEditor(tester);

    await tester.drag(find.byKey(const ValueKey('crop-area')), const Offset(40, 30));
    await tester.pump();

    expect(changes.last.crop, _area(0.35, 0.35, 0.85, 0.85));
    expect(changes.last.quarterTurns, 0);
  });

  testWidgets('dragging a corner resizes the box', (tester) async {
    final changes = await _pumpEditor(tester);

    await tester.drag(
      find.byKey(const ValueKey('crop-handle-bottomRight')),
      const Offset(-40, -30),
    );
    await tester.pump();

    expect(changes.last.crop, _area(0.25, 0.25, 0.65, 0.65));
  });

  testWidgets('the box never gets smaller than a thumb can grab',
      (tester) async {
    final changes = await _pumpEditor(tester);

    await tester.drag(
      find.byKey(const ValueKey('crop-handle-bottomRight')),
      const Offset(-1000, -1000),
    );
    await tester.pump();

    // 48 px of a 400 x 300 photo.
    expect(changes.last.crop, _area(0.25, 0.25, 0.25 + 48 / 400, 0.25 + 48 / 300));
  });

  testWidgets('a turned photo is shown turned, at its turned shape',
      (tester) async {
    await _pumpEditor(tester, edit: const PhotoEdit(quarterTurns: 1));

    final rotated = tester.widget<RotatedBox>(find.byType(RotatedBox));
    expect(rotated.quarterTurns, 1);
    expect(tester.getSize(find.byType(RotatedBox)), const Size(300, 400));
  });
}
