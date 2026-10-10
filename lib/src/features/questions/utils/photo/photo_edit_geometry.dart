import 'dart:math' as math;

import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';

enum CropCorner { topLeft, topRight, bottomLeft, bottomRight }

/// [edit] with the photo turned a quarter clockwise. The crop box turns with
/// the photo, so it still covers the same part of it.
PhotoEdit turnedClockwise(PhotoEdit edit) => PhotoEdit(
      quarterTurns: (edit.quarterTurns + 1) % 4,
      crop: _cropTurnedClockwise(edit.crop),
    );

/// [edit] with the photo turned a quarter counterclockwise.
PhotoEdit turnedCounterclockwise(PhotoEdit edit) => PhotoEdit(
      quarterTurns: (edit.quarterTurns + 3) % 4,
      crop: _cropTurnedCounterclockwise(edit.crop),
    );

// A point (x, y) moves to (1 - y, x) when the photo turns clockwise.
CropArea _cropTurnedClockwise(CropArea c) => CropArea(
      left: 1 - c.bottom,
      top: c.left,
      right: 1 - c.top,
      bottom: c.right,
    );

// A point (x, y) moves to (y, 1 - x) when the photo turns counterclockwise.
CropArea _cropTurnedCounterclockwise(CropArea c) => CropArea(
      left: c.top,
      top: 1 - c.right,
      right: c.bottom,
      bottom: 1 - c.left,
    );

/// [crop] moved by [dx] and [dy], stopping at the photo's edges.
CropArea movedBy(CropArea crop, {required double dx, required double dy}) {
  final x = _between(dx, -crop.left, 1 - crop.right);
  final y = _between(dy, -crop.top, 1 - crop.bottom);
  return CropArea(
    left: crop.left + x,
    top: crop.top + y,
    right: crop.right + x,
    bottom: crop.bottom + y,
  );
}

/// [crop] with [corner] dragged by [dx] and [dy]. The opposite corner stays
/// put, the box stays inside the photo, and it never gets narrower than
/// [minWidth] or shorter than [minHeight].
CropArea resizedFrom(
  CropArea crop,
  CropCorner corner, {
  required double dx,
  required double dy,
  required double minWidth,
  required double minHeight,
}) {
  var left = crop.left;
  var top = crop.top;
  var right = crop.right;
  var bottom = crop.bottom;
  final movesLeftEdge =
      corner == CropCorner.topLeft || corner == CropCorner.bottomLeft;
  final movesTopEdge =
      corner == CropCorner.topLeft || corner == CropCorner.topRight;

  if (movesLeftEdge) {
    left = _between(left + dx, 0, right - minWidth);
  } else {
    right = _between(right + dx, left + minWidth, 1);
  }
  if (movesTopEdge) {
    top = _between(top + dy, 0, bottom - minHeight);
  } else {
    bottom = _between(bottom + dy, top + minHeight, 1);
  }
  return CropArea(left: left, top: top, right: right, bottom: bottom);
}

// Unlike num.clamp, never throws when rounding leaves low a hair above high.
double _between(double value, double low, double high) =>
    math.min(math.max(value, low), high);

/// What to read from an upright photo, and how big the result is before
/// scaling, to apply an edit.
class PhotoEditDrawing {
  /// The part of the upright photo to read, in its pixels.
  final int sourceX;
  final int sourceY;
  final int sourceWidth;
  final int sourceHeight;

  /// Clockwise quarter turns to draw that part with.
  final int quarterTurns;

  /// The size of the turned, cropped photo before it is scaled down.
  final PhotoSize outputSize;

  const PhotoEditDrawing({
    required this.sourceX,
    required this.sourceY,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.quarterTurns,
    required this.outputSize,
  });
}

/// How to draw [edit] from an upright photo of size [upright].
PhotoEditDrawing drawingFor(PhotoEdit edit, PhotoSize upright) {
  // The crop is measured on the turned photo; turn it back to find it on the
  // upright one.
  var crop = edit.crop;
  for (var i = 0; i < edit.quarterTurns; i++) {
    crop = _cropTurnedCounterclockwise(crop);
  }
  final x = (crop.left * upright.width).round();
  final y = (crop.top * upright.height).round();
  final width = math.max(1, (crop.right * upright.width).round() - x);
  final height = math.max(1, (crop.bottom * upright.height).round() - y);
  return PhotoEditDrawing(
    sourceX: x,
    sourceY: y,
    sourceWidth: width,
    sourceHeight: height,
    quarterTurns: edit.quarterTurns,
    outputSize: edit.quarterTurns.isOdd
        ? PhotoSize(height, width)
        : PhotoSize(width, height),
  );
}
