import 'package:doormer/src/features/questions/presentation/params/photo_edit_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/photo_edit_template.dart';
import 'package:doormer/src/features/questions/utils/photo/editable_photo.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit_geometry.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_scaling.dart';
import 'package:flutter/material.dart';

/// Opens the crop & rotate screen on a photo. Resolves to the student's edit,
/// or to null if they left without pressing Use photo.
typedef PhotoEditorOpener = Future<PhotoEdit?> Function(
  BuildContext context,
  EditablePhoto photo,
);

/// The [PhotoEditorOpener] the app uses: the screen as a full-screen dialog.
Future<PhotoEdit?> openPhotoEditPage(
  BuildContext context,
  EditablePhoto photo,
) {
  return Navigator.of(context).push<PhotoEdit>(
    MaterialPageRoute<PhotoEdit>(
      fullscreenDialog: true,
      builder: (_) => PhotoEditPage(photo: photo),
    ),
  );
}

/// Lets the student turn [photo] and crop it to just the question. Opens on
/// the photo's last edit, so a crop can be widened again.
class PhotoEditPage extends StatefulWidget {
  final EditablePhoto photo;

  const PhotoEditPage({super.key, required this.photo});

  @override
  State<PhotoEditPage> createState() => _PhotoEditPageState();
}

class _PhotoEditPageState extends State<PhotoEditPage> {
  late PhotoEdit _edit = widget.photo.edit;

  void _change(PhotoEdit edit) => setState(() => _edit = edit);

  @override
  Widget build(BuildContext context) {
    final unedited = widget.photo.unedited;
    return PhotoEditTemplate(
      params: PhotoEditParams(
        imageBytes: unedited.bytes,
        imageSize: PhotoSize(unedited.width, unedited.height),
        edit: _edit,
        onEditChanged: _change,
        onTurnLeft: () => _change(turnedCounterclockwise(_edit)),
        onTurnRight: () => _change(turnedClockwise(_edit)),
        onReset: _edit.isNone ? null : () => _change(PhotoEdit.none),
        onCancel: () => Navigator.of(context).pop(),
        onUsePhoto: () => Navigator.of(context).pop(_edit),
      ),
    );
  }
}
