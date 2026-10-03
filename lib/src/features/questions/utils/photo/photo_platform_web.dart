import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_file_input_web.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer_web.dart';

PhotoFileInput createPhotoFileInput() => WebPhotoFileInput();

PhotoPreparer createPhotoPreparer() => WebPhotoPreparer();
