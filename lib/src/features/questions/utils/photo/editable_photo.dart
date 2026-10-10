import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:equatable/equatable.dart';

/// What is needed to crop and rotate a photo again: the file the student
/// chose, that file prepared with no edit (what the editor shows), and the
/// edit now applied.
///
/// Keeping the original lets a later edit widen a crop again, and lets every
/// edit be applied to the full-resolution photo.
class EditablePhoto extends Equatable {
  final PickedPhotoFile original;
  final PreparedPhoto unedited;
  final PhotoEdit edit;

  const EditablePhoto({
    required this.original,
    required this.unedited,
    this.edit = PhotoEdit.none,
  });

  EditablePhoto withEdit(PhotoEdit edit) =>
      EditablePhoto(original: original, unedited: unedited, edit: edit);

  @override
  List<Object?> get props => [original, unedited, edit];
}
