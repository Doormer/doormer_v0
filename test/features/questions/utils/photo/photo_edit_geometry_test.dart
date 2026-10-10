import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit_geometry.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _area(double left, double top, double right, double bottom) =>
    isA<CropArea>()
        .having((c) => c.left, 'left', closeTo(left, 1e-9))
        .having((c) => c.top, 'top', closeTo(top, 1e-9))
        .having((c) => c.right, 'right', closeTo(right, 1e-9))
        .having((c) => c.bottom, 'bottom', closeTo(bottom, 1e-9));

void main() {
  const quarter = CropArea(left: 0.25, top: 0, right: 0.5, bottom: 0.5);

  group('PhotoEdit', () {
    test('none keeps the whole photo, unturned', () {
      expect(PhotoEdit.none.isNone, isTrue);
      expect(PhotoEdit.none.crop, CropArea.whole);
      expect(const PhotoEdit(quarterTurns: 1).isNone, isFalse);
      expect(const PhotoEdit(crop: quarter).isNone, isFalse);
    });
  });

  group('turning', () {
    test('a clockwise turn keeps the whole photo whole', () {
      final turned = turnedClockwise(PhotoEdit.none);
      expect(turned.quarterTurns, 1);
      expect(turned.crop, CropArea.whole);
    });

    test('the crop box turns with the photo', () {
      // The top-left of the photo moves to the top-right on a clockwise turn.
      final turned = turnedClockwise(const PhotoEdit(crop: quarter));
      expect(turned.crop, _area(0.5, 0.25, 1, 0.5));
    });

    test('four clockwise turns come back to the start', () {
      var edit = const PhotoEdit(crop: quarter);
      for (var i = 0; i < 4; i++) {
        edit = turnedClockwise(edit);
      }
      expect(edit.quarterTurns, 0);
      expect(edit.crop, _area(0.25, 0, 0.5, 0.5));
    });

    test('a counterclockwise turn undoes a clockwise one', () {
      final back =
          turnedCounterclockwise(turnedClockwise(const PhotoEdit(crop: quarter)));
      expect(back.quarterTurns, 0);
      expect(back.crop, _area(0.25, 0, 0.5, 0.5));
    });

    test('turning counterclockwise from upright gives three quarter turns', () {
      expect(turnedCounterclockwise(PhotoEdit.none).quarterTurns, 3);
    });
  });

  group('moving the box', () {
    const box = CropArea(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75);

    test('moves by the drag', () {
      expect(movedBy(box, dx: 0.1, dy: -0.1), _area(0.35, 0.15, 0.85, 0.65));
    });

    test('stops at the right and bottom edges', () {
      expect(movedBy(box, dx: 0.5, dy: 0.5), _area(0.5, 0.5, 1, 1));
    });

    test('stops at the left and top edges', () {
      expect(movedBy(box, dx: -0.5, dy: -0.5), _area(0, 0, 0.5, 0.5));
    });
  });

  group('resizing the box', () {
    const box = CropArea(left: 0.25, top: 0.25, right: 0.75, bottom: 0.75);

    test('the bottom-right corner follows the drag', () {
      expect(
        resizedFrom(box, CropCorner.bottomRight,
            dx: -0.1, dy: 0.1, minWidth: 0.1, minHeight: 0.1),
        _area(0.25, 0.25, 0.65, 0.85),
      );
    });

    test('the top-left corner follows the drag', () {
      expect(
        resizedFrom(box, CropCorner.topLeft,
            dx: -0.1, dy: 0.05, minWidth: 0.1, minHeight: 0.1),
        _area(0.15, 0.3, 0.75, 0.75),
      );
    });

    test('never shrinks below the minimum size', () {
      expect(
        resizedFrom(box, CropCorner.topRight,
            dx: -1, dy: 1, minWidth: 0.1, minHeight: 0.2),
        _area(0.25, 0.55, 0.35, 0.75),
      );
    });

    test('never grows past the photo', () {
      expect(
        resizedFrom(box, CropCorner.bottomLeft,
            dx: -1, dy: 1, minWidth: 0.1, minHeight: 0.1),
        _area(0, 0.25, 0.75, 1),
      );
    });
  });

  group('drawingFor', () {
    const upright = PhotoSize(4000, 3000);

    test('no edit reads the whole photo at its own size', () {
      final drawing = drawingFor(PhotoEdit.none, upright);
      expect(
        [drawing.sourceX, drawing.sourceY, drawing.sourceWidth, drawing.sourceHeight],
        [0, 0, 4000, 3000],
      );
      expect(drawing.quarterTurns, 0);
      expect(drawing.outputSize, const PhotoSize(4000, 3000));
    });

    test('a crop reads only that part, at full resolution', () {
      final drawing = drawingFor(
        const PhotoEdit(
          crop: CropArea(left: 0.5, top: 0, right: 1, bottom: 0.5),
        ),
        upright,
      );
      expect(
        [drawing.sourceX, drawing.sourceY, drawing.sourceWidth, drawing.sourceHeight],
        [2000, 0, 2000, 1500],
      );
      expect(drawing.outputSize, const PhotoSize(2000, 1500));
    });

    test('a quarter turn swaps the output width and height', () {
      final drawing = drawingFor(const PhotoEdit(quarterTurns: 1), upright);
      expect(drawing.sourceWidth, 4000);
      expect(drawing.sourceHeight, 3000);
      expect(drawing.outputSize, const PhotoSize(3000, 4000));
    });

    test('a crop on the turned photo maps back to the upright photo', () {
      // The top half of the photo after one clockwise turn is the left half of
      // the upright photo.
      final drawing = drawingFor(
        const PhotoEdit(
          quarterTurns: 1,
          crop: CropArea(left: 0, top: 0, right: 1, bottom: 0.5),
        ),
        upright,
      );
      expect(
        [drawing.sourceX, drawing.sourceY, drawing.sourceWidth, drawing.sourceHeight],
        [0, 0, 2000, 3000],
      );
      expect(drawing.outputSize, const PhotoSize(3000, 2000));
    });
  });
}
