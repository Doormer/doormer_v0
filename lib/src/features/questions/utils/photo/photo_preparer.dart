import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';

const photoUnreadableMessage =
    "We can't read this file. Try a JPG, PNG or HEIC photo.";

const heicConverterUnavailableMessage =
    "We couldn't open this HEIC photo. Check your connection and try again, "
    'or use a JPG or PNG.';

/// Turns a picked photo into the JPEG the student sees and the solver gets:
/// upright, scaled to fit `maxPhotoEdge`, with its metadata dropped.
///
/// Only throws typed `Failure`s. Throws
/// `ValidationFailure(photoUnreadableMessage)` when the file is not an image
/// the app can read, and `NetworkFailure(heicConverterUnavailableMessage)` when
/// a HEIC photo needs the converter and it cannot be loaded.
abstract class PhotoPreparer {
  Future<PreparedPhoto> prepare(PickedPhotoFile file);
}
