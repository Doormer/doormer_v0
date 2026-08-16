import 'dart:typed_data';

import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  group('canRetry', () {
    // Retry is only worth offering where resubmitting the identical bytes
    // could plausibly land differently.
    test('a network error can be retried', () {
      final content = solveStatusContentFor(
        AskByPhotoNetworkError('No connection.', imageBytes: bytes),
      );

      expect(content.canRetry, isTrue);
      expect(content.showActions, isTrue);
    });

    test('a solver timeout can be retried', () {
      final content = solveStatusContentFor(
        AskByPhotoTimeout(questionId: 'q', imageBytes: bytes),
      );

      expect(content.canRetry, isTrue);
    });

    test('an unreadable photo cannot be retried', () {
      final content = solveStatusContentFor(
        AskByPhotoUnreadable(questionId: 'q', imageBytes: bytes),
      );

      expect(content.canRetry, isFalse,
          reason: 'the same blurry photo reads as blurry every time, so a '
              'retry only costs a round trip');
      expect(content.showActions, isTrue,
          reason: 'Retake is still the way out');
    });

    test('a non-question photo cannot be retried', () {
      final content = solveStatusContentFor(
        AskByPhotoNotAQuestion(questionId: 'q', imageBytes: bytes),
      );

      expect(content.canRetry, isFalse);
    });

    test('a validation error cannot be retried', () {
      final content = solveStatusContentFor(
        const AskByPhotoValidationError("HEIC isn't supported."),
      );

      expect(content.canRetry, isFalse);
    });

    // Nothing was picked, or the bytes were dropped: there is no photo to
    // resubmit, so the retry button must not appear even on a retryable state.
    test('a retryable state with no photo cannot be retried', () {
      final content = solveStatusContentFor(
        const AskByPhotoNetworkError('No connection.'),
      );

      expect(content.canRetry, isFalse);
    });

    test('the idle and loading states offer no retry', () {
      expect(solveStatusContentFor(const AskByPhotoInitial()).canRetry, isFalse);
      expect(solveStatusContentFor(const AskByPhotoLoading()).canRetry, isFalse);
    });
  });

  group('showRetake', () {
    // Retake belongs with the photo. Repeating it here would show the same
    // button twice on one screen.
    test('is suppressed while the failed photo is still on screen', () {
      final content = solveStatusContentFor(
        AskByPhotoUnreadable(questionId: 'q', imageBytes: bytes),
      );

      expect(content.photoOnScreen, isTrue);
      expect(content.showRetake, isFalse);
      expect(content.showActions, isTrue,
          reason: 'Type instead is still offered');
    });

    test('is shown when there is no photo to attach it to', () {
      final content = solveStatusContentFor(
        const AskByPhotoValidationError("HEIC isn't supported."),
      );

      expect(content.photoOnScreen, isFalse);
      expect(content.showRetake, isTrue);
    });
  });
}
