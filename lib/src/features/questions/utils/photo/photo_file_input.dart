import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';

/// Listing extensions too lets desktop file dialogs show `.heic` files that
/// the operating system has no MIME type for.
const galleryPhotoAccept =
    'image/jpeg,image/png,image/heic,image/heif,.jpg,.jpeg,.png,.heic,.heif';

/// With [cameraCapture], phones open their own camera app; anything else
/// falls back to a file chooser.
const cameraPhotoAccept = 'image/*';

/// The back camera, which faces the page being photographed.
const cameraCapture = 'environment';

const photoPickerUnavailableMessage =
    "We couldn't open the photo picker. Please try again.";

/// Lets the student choose a photo file, or take one with the phone's own
/// camera app.
abstract class PhotoFileInput {
  /// Whether the camera button should open the phone's camera app through
  /// [pick] rather than the in-app webcam page. True on touch-first devices.
  bool get usesNativeCamera;

  /// Opens the chooser. Call it straight from a tap handler, before any
  /// `await`: browsers only open a chooser in response to a user gesture.
  ///
  /// Returns null when the student cancels. Throws
  /// `ValidationFailure(photoUnreadableMessage)` when the chosen file
  /// cannot be read.
  Future<PickedPhotoFile?> pick({required bool fromCamera});
}
