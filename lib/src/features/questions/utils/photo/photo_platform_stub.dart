import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';

PhotoFileInput createPhotoFileInput() =>
    throw UnsupportedError('Choosing photos is only supported on the web.');

PhotoPreparer createPhotoPreparer() =>
    throw UnsupportedError('Preparing photos is only supported on the web.');
