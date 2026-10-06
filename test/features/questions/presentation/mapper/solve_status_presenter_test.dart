import 'dart:typed_data';

import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('the starting tips say which photo formats work', () {
    final content = solveStatusContentFor(const AskByPhotoInitial());

    expect(
      content.body,
      'Use bright light, keep the question flat, and include every line of '
      'the problem. JPG, PNG or HEIC.',
    );
  });

  test('while solving, says how long it can take and that it opens by itself',
      () {
    final content = solveStatusContentFor(const AskByPhotoLoading());

    expect(content.title, 'Solving your photo');
    expect(
      content.body,
      'This can take from a few seconds to a few minutes. Keep this page '
      "open and your solution opens as soon as it's ready.",
    );
  });

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
      expect(
          solveStatusContentFor(const AskByPhotoInitial()).canRetry, isFalse);
      expect(
          solveStatusContentFor(const AskByPhotoLoading()).canRetry, isFalse);
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
          reason: 'the status panel still explains what happened');
    });

    test('is shown when there is no photo to attach it to', () {
      final content = solveStatusContentFor(
        const AskByPhotoValidationError("HEIC isn't supported."),
      );

      expect(content.photoOnScreen, isFalse);
      expect(content.showRetake, isTrue);
    });
  });

  group('error copy', () {
    for (final (cause, title) in [
      (SolveErrorCause.network, 'Could not reach the solver'),
      (SolveErrorCause.server, 'The solver ran into a problem'),
      (SolveErrorCause.unknown, 'Something went wrong'),
    ]) {
      test('a $cause failure is titled "$title"', () {
        final content = solveStatusContentFor(AskByPhotoNetworkError(
          'Please try again.',
          cause: cause,
          imageBytes: Uint8List(1),
        ));
        expect(content.title, title);
      });
    }

    test('no copy offers typing the question', () {
      final states = <AskByPhotoState>[
        const AskByPhotoInitial(),
        AskByPhotoNotAQuestion(questionId: 'q', imageBytes: Uint8List(1)),
        const AskByPhotoNotAQuestion(questionId: 'q'),
        const AskByPhotoTimeout(questionId: 'q'),
      ];
      for (final state in states) {
        expect(
          solveStatusContentFor(state).body.toLowerCase(),
          isNot(contains('type')),
        );
      }
    });
  });
}
