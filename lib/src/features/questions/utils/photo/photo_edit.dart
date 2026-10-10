import 'package:equatable/equatable.dart';

/// An area of a photo given as fractions (0–1) of its width and height, so the
/// same area fits the photo at any size.
class CropArea extends Equatable {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const CropArea({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  static const whole = CropArea(left: 0, top: 0, right: 1, bottom: 1);

  double get width => right - left;

  double get height => bottom - top;

  @override
  List<Object?> get props => [left, top, right, bottom];
}

/// How the student turned and cropped a photo before sending it.
class PhotoEdit extends Equatable {
  /// Clockwise quarter turns, 0 to 3.
  final int quarterTurns;

  /// The part to keep, measured on the photo after it is turned.
  final CropArea crop;

  const PhotoEdit({this.quarterTurns = 0, this.crop = CropArea.whole})
      : assert(quarterTurns >= 0 && quarterTurns < 4);

  static const none = PhotoEdit();

  bool get isNone => this == none;

  @override
  List<Object?> get props => [quarterTurns, crop];
}
