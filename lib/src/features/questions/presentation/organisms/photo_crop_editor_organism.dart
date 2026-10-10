import 'dart:math' as math;
import 'dart:typed_data';

import 'package:doormer/src/features/questions/presentation/atoms/crop_handle_atom.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit_geometry.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The smallest the crop box may get on screen, so a thumb can still grab it.
const double _minCropSide = 48;

/// Shows a photo as [edit] turns it, with a crop box the student drags to
/// keep just the question.
///
/// Controlled: it shows [edit] and reports each change through [onChanged].
class PhotoCropEditorOrganism extends StatefulWidget {
  /// The upright photo with no edit applied.
  final Uint8List imageBytes;
  final PhotoSize imageSize;
  final PhotoEdit edit;
  final ValueChanged<PhotoEdit> onChanged;

  const PhotoCropEditorOrganism({
    super.key,
    required this.imageBytes,
    required this.imageSize,
    required this.edit,
    required this.onChanged,
  });

  @override
  State<PhotoCropEditorOrganism> createState() =>
      _PhotoCropEditorOrganismState();
}

class _PhotoCropEditorOrganismState extends State<PhotoCropEditorOrganism> {
  // Every update is worked out from where the drag started rather than from
  // the last frame, so no movement is lost between rebuilds.
  CropArea _cropAtDragStart = CropArea.whole;
  Offset _dragDistance = Offset.zero;

  void _startDrag(DragStartDetails _) {
    _cropAtDragStart = widget.edit.crop;
    _dragDistance = Offset.zero;
  }

  void _report(CropArea crop) => widget.onChanged(
        PhotoEdit(quarterTurns: widget.edit.quarterTurns, crop: crop),
      );

  @override
  Widget build(BuildContext context) {
    final edit = widget.edit;
    final turned = edit.quarterTurns.isOdd
        ? PhotoSize(widget.imageSize.height, widget.imageSize.width)
        : widget.imageSize;
    const inset = CropHandleAtom.touchSize / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          (constraints.maxWidth - 2 * inset) / turned.width,
          (constraints.maxHeight - 2 * inset) / turned.height,
        );
        final shown = Size(turned.width * scale, turned.height * scale);
        final crop = edit.crop;
        final cropRect = Rect.fromLTRB(
          crop.left * shown.width,
          crop.top * shown.height,
          crop.right * shown.width,
          crop.bottom * shown.height,
        );

        void move(DragUpdateDetails details) {
          _dragDistance += details.delta;
          _report(movedBy(
            _cropAtDragStart,
            dx: _dragDistance.dx / shown.width,
            dy: _dragDistance.dy / shown.height,
          ));
        }

        void resize(CropCorner corner, DragUpdateDetails details) {
          _dragDistance += details.delta;
          _report(resizedFrom(
            _cropAtDragStart,
            corner,
            dx: _dragDistance.dx / shown.width,
            dy: _dragDistance.dy / shown.height,
            minWidth: math.min(1, _minCropSide / shown.width),
            minHeight: math.min(1, _minCropSide / shown.height),
          ));
        }

        // The photo is inset by half a handle on every side, so handles on
        // the photo's edge stay fully inside the editor and fully tappable.
        return Center(
          child: SizedBox(
            width: shown.width + 2 * inset,
            height: shown.height + 2 * inset,
            child: Stack(
              children: [
                Positioned(
                  left: inset,
                  top: inset,
                  width: shown.width,
                  height: shown.height,
                  child: RotatedBox(
                    quarterTurns: edit.quarterTurns,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                Positioned(
                  left: inset,
                  top: inset,
                  width: shown.width,
                  height: shown.height,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CropShadePainter(
                        cropRect: cropRect,
                        shadeColor: Colors.black.withValues(alpha: 0.55),
                        borderColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: cropRect.shift(const Offset(inset, inset)),
                  child: GestureDetector(
                    key: const ValueKey('crop-area'),
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onPanStart: _startDrag,
                    onPanUpdate: move,
                  ),
                ),
                for (final corner in CropCorner.values)
                  Positioned(
                    left: _isLeft(corner) ? cropRect.left : cropRect.right,
                    top: _isTop(corner) ? cropRect.top : cropRect.bottom,
                    child: GestureDetector(
                      key: ValueKey('crop-handle-${corner.name}'),
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onPanStart: _startDrag,
                      onPanUpdate: (details) => resize(corner, details),
                      child: Semantics(
                        label: 'Crop corner',
                        child: const CropHandleAtom(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static bool _isLeft(CropCorner corner) =>
      corner == CropCorner.topLeft || corner == CropCorner.bottomLeft;

  static bool _isTop(CropCorner corner) =>
      corner == CropCorner.topLeft || corner == CropCorner.topRight;
}

/// Dims the photo outside the crop box and outlines the box.
class _CropShadePainter extends CustomPainter {
  final Rect cropRect;
  final Color shadeColor;
  final Color borderColor;

  const _CropShadePainter({
    required this.cropRect,
    required this.shadeColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(cropRect);
    canvas
      ..drawPath(outside, Paint()..color = shadeColor)
      ..drawRect(
        cropRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = borderColor,
      );
  }

  @override
  bool shouldRepaint(_CropShadePainter old) =>
      old.cropRect != cropRect ||
      old.shadeColor != shadeColor ||
      old.borderColor != borderColor;
}
