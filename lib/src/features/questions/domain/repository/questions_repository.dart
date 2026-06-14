import 'dart:typed_data';

import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';

abstract class QuestionsRepository {
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  });
}
