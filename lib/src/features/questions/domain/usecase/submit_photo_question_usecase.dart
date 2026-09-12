import 'dart:typed_data';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/utils/photo_question_image_validator.dart';

class SubmitPhotoQuestionUseCase {
  final QuestionsRepository repository;

  const SubmitPhotoQuestionUseCase(this.repository);

  Future<PhotoQuestionSolveOutcome> call({
    required Uint8List imageBytes,
    required String fileName,
    String? mimeType,
  }) async {
    final validation = PhotoQuestionImageValidator.validate(
      imageBytes: imageBytes,
      fileName: fileName,
      mimeType: mimeType,
    );

    if (!validation.isValid) {
      throw ValidationFailure(validation.message!);
    }

    return repository.submitPhotoQuestion(
      imageBytes: imageBytes,
      contentType: validation.contentType!,
    );
  }
}
