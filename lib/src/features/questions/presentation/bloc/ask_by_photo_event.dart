part of 'ask_by_photo_bloc.dart';

abstract class AskByPhotoEvent extends Equatable {
  const AskByPhotoEvent();

  @override
  List<Object?> get props => [];
}

class AskByPhotoPhotoPicked extends AskByPhotoEvent {
  final Uint8List imageBytes;
  final String fileName;
  final String? mimeType;

  /// Lets the student crop and rotate this photo again. Null only for photos
  /// that did not come through the picker.
  final EditablePhoto? editablePhoto;

  const AskByPhotoPhotoPicked({
    required this.imageBytes,
    required this.fileName,
    this.mimeType,
    this.editablePhoto,
  });

  @override
  List<Object?> get props => [imageBytes, fileName, mimeType, editablePhoto];
}

class AskByPhotoSubmitted extends AskByPhotoEvent {
  const AskByPhotoSubmitted();
}

class AskByPhotoClearRequested extends AskByPhotoEvent {
  const AskByPhotoClearRequested();
}

class AskByPhotoTypeInsteadRequested extends AskByPhotoEvent {
  const AskByPhotoTypeInsteadRequested();
}

class AskByPhotoPickCancelled extends AskByPhotoEvent {
  const AskByPhotoPickCancelled();
}

class AskByPhotoPickUnavailable extends AskByPhotoEvent {
  final String message;

  const AskByPhotoPickUnavailable(this.message);

  @override
  List<Object?> get props => [message];
}

/// A chosen photo is being turned into the JPEG that will be shown and sent.
class AskByPhotoPreparationStarted extends AskByPhotoEvent {
  const AskByPhotoPreparationStarted();
}
