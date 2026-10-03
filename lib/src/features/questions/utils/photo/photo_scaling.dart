import 'dart:math' as math;

/// The solver's vision model fits every image inside 2048×2048 before reading
/// it, so a longer edge adds upload size without adding detail.
const int maxPhotoEdge = 2048;

/// Mobile Safari refuses to draw a canvas with more pixels than this.
const int maxCanvasPixels = 16777216;

class PhotoSize {
  final int width;
  final int height;

  const PhotoSize(this.width, this.height);

  int get longEdge => math.max(width, height);

  int get pixels => width * height;

  PhotoSize get half => PhotoSize(
        math.max(1, (width / 2).round()),
        math.max(1, (height / 2).round()),
      );

  @override
  bool operator ==(Object other) =>
      other is PhotoSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}

/// [source] scaled down so its long edge is at most [maxEdge]. Never enlarges.
PhotoSize fitWithin(PhotoSize source, {int maxEdge = maxPhotoEdge}) {
  if (source.longEdge <= maxEdge) return source;
  final scale = maxEdge / source.longEdge;
  return PhotoSize(
    math.max(1, (source.width * scale).round()),
    math.max(1, (source.height * scale).round()),
  );
}

/// The canvas sizes to draw through, ending at [fitWithin].
///
/// Halving one step at a time keeps small print sharp; a single big jump
/// skips source pixels and makes letters jagged. Halvings larger than
/// [maxPixels] are skipped because mobile Safari cannot draw them.
List<PhotoSize> scalingSteps(
  PhotoSize source, {
  int maxEdge = maxPhotoEdge,
  int maxPixels = maxCanvasPixels,
}) {
  final target = fitWithin(source, maxEdge: maxEdge);
  final steps = <PhotoSize>[];
  var current = source;
  while (current.half.longEdge > target.longEdge) {
    current = current.half;
    if (current.pixels <= maxPixels) steps.add(current);
  }
  steps.add(target);
  return steps;
}
