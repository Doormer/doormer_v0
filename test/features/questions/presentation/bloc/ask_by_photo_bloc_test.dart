import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestionsRepository implements QuestionsRepository {
  _FakeQuestionsRepository({this.outcome, this.failure, this.pending});

  PhotoQuestionSolveOutcome? outcome;
  Failure? failure;
  Completer<PhotoQuestionSolveOutcome>? pending;
  int callCount = 0;
  Uint8List? lastBytes;
  String? lastContentType;

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    callCount++;
    lastBytes = imageBytes;
    lastContentType = contentType;
    if (failure != null) {
      throw failure!;
    }
    if (pending != null) {
      return pending!.future;
    }
    return outcome!;
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() {
    throw UnimplementedError();
  }
}

PhotoQuestionSolveOutcome _outcome(PhotoQuestionSolveStatus status) {
  return PhotoQuestionSolveOutcome(
    status: status,
    questionId: 'q_${status.name}',
    solution: status == PhotoQuestionSolveStatus.solved
        ? const SolutionDocument(
            schemaVersion: '1.0',
            steps: [
              SolutionStep(
                title: 'Step 1',
                body: [TextSolutionSegment('Read the question.')],
              ),
            ],
            finalAnswer: FinalAnswer(
              body: [MathSolutionSegment(latex: '42', alt: 'forty two')],
            ),
          )
        : null,
  );
}

AskByPhotoBloc _blocFor(_FakeQuestionsRepository repository) {
  return AskByPhotoBloc(
    submitPhotoQuestionUseCase: SubmitPhotoQuestionUseCase(repository),
  );
}

void main() {
  setUpAll(AppLogger.disable);

  final validBytes = Uint8List.fromList([1, 2, 3]);

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'emits Solved with question id and solution for solved outcome',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.jpg'),
      isA<AskByPhotoSolved>()
          .having((state) => state.questionId, 'questionId', 'q_solved')
          .having(
              (state) => state.solution.schemaVersion, 'schemaVersion', '1.0'),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'emits Unreadable for unreadable success outcome',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.unreadable),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.png',
      mimeType: 'image/png',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.png'),
      AskByPhotoUnreadable(
        questionId: 'q_unreadable',
        imageBytes: validBytes,
        fileName: 'problem.png',
        mimeType: 'image/png',
      ),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'emits NotAQuestion for not_a_question success outcome',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.notAQuestion),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.png',
      mimeType: 'image/png',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.png'),
      AskByPhotoNotAQuestion(
        questionId: 'q_notAQuestion',
        imageBytes: validBytes,
        fileName: 'problem.png',
        mimeType: 'image/png',
      ),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'emits Timeout for timeout success outcome',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.timeout),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.png',
      mimeType: 'image/png',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.png'),
      AskByPhotoTimeout(
        questionId: 'q_timeout',
        imageBytes: validBytes,
        fileName: 'problem.png',
        mimeType: 'image/png',
      ),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'emits ValidationError and skips repository for HEIC selection',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.heic',
      mimeType: 'image/heic',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.heic'),
      const AskByPhotoValidationError(
        "HEIC isn't supported — please use JPEG or PNG.",
      ),
    ],
    verify: (bloc) {
      final repository = bloc.submitPhotoQuestionUseCase.repository
          as _FakeQuestionsRepository;
      expect(repository.callCount, 0);
    },
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'emits NetworkError for network failures',
    build: () => _blocFor(_FakeQuestionsRepository(
      failure: NetworkFailure('We could not reach the solver. Try again.'),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.jpg'),
      AskByPhotoNetworkError(
        'We could not reach the solver. Try again.',
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'carries the selected photo into Loading so the preview survives the solve',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      isA<AskByPhotoLoading>()
          .having((state) => state.imageBytes, 'imageBytes', validBytes)
          .having((state) => state.fileName, 'fileName', 'problem.jpg'),
      isA<AskByPhotoSolved>(),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'Loading carries no photo when submitting without a selection',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      const AskByPhotoLoading(),
      const AskByPhotoValidationError(
        'Please choose a JPEG or PNG photo before submitting.',
      ),
    ],
  );

  test('emits Loading before the pending submission completes', () async {
    final completer = Completer<PhotoQuestionSolveOutcome>();
    final repository = _FakeQuestionsRepository(pending: completer);
    final bloc = _blocFor(repository);
    final emittedStates = <AskByPhotoState>[];
    final subscription = bloc.stream.listen(emittedStates.add);

    bloc.add(AskByPhotoPhotoPicked(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
    ));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const AskByPhotoSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(
      emittedStates,
      contains(
        AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.jpg'),
      ),
    );
    expect(completer.isCompleted, isFalse);

    completer.complete(_outcome(PhotoQuestionSolveStatus.timeout));
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    await bloc.close();
  });

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'picker cancellation is non-blocking and never submits',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    act: (bloc) => bloc.add(const AskByPhotoPickCancelled()),
    expect: () => [
      const AskByPhotoNotice('No photo selected.'),
    ],
    verify: (bloc) {
      final repository = bloc.submitPhotoQuestionUseCase.repository
          as _FakeQuestionsRepository;
      expect(repository.callCount, 0);
    },
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'picker cancellation preserves an already selected photo',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
    ),
    act: (bloc) => bloc.add(const AskByPhotoPickCancelled()),
    expect: () => [
      const AskByPhotoNotice('No photo selected.'),
      AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
    ],
    verify: (bloc) {
      final repository = bloc.submitPhotoQuestionUseCase.repository
          as _FakeQuestionsRepository;
      expect(repository.callCount, 0);
    },
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'no-camera path preserves an already selected photo',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
    ),
    act: (bloc) => bloc.add(
      const AskByPhotoPickUnavailable(
          'No camera found. You can upload a JPEG or PNG instead.'),
    ),
    expect: () => [
      const AskByPhotoNotice(
          'No camera found. You can upload a JPEG or PNG instead.'),
      AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
    ],
    verify: (bloc) {
      final repository = bloc.submitPhotoQuestionUseCase.repository
          as _FakeQuestionsRepository;
      expect(repository.callCount, 0);
    },
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'no-camera path is non-blocking and never submits',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    act: (bloc) => bloc.add(
      const AskByPhotoPickUnavailable(
          'No camera found. You can upload a JPEG or PNG instead.'),
    ),
    expect: () => [
      const AskByPhotoNotice(
          'No camera found. You can upload a JPEG or PNG instead.'),
    ],
    verify: (bloc) {
      final repository = bloc.submitPhotoQuestionUseCase.repository
          as _FakeQuestionsRepository;
      expect(repository.callCount, 0);
    },
  );

  group('a failed solve keeps the photo', () {
    // Losing the bytes unmounts the preview and leaves no way back except
    // finding and picking the same file again. A dropped connection should
    // cost a tap, not a re-pick.
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'network failure carries the photo through',
      build: () => _blocFor(_FakeQuestionsRepository(
        failure: NetworkFailure('No connection.'),
      )),
      seed: () => AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      skip: 1,
      expect: () => [
        isA<AskByPhotoNetworkError>()
            .having((s) => s.imageBytes, 'imageBytes', validBytes)
            .having((s) => s.fileName, 'fileName', 'problem.jpg')
            .having((s) => s.mimeType, 'mimeType', 'image/jpeg')
            .having((s) => s.isRetryable, 'isRetryable', isTrue),
      ],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a solver timeout carries the photo through and stays retryable',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.timeout),
      )),
      seed: () => AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      skip: 1,
      expect: () => [
        isA<AskByPhotoTimeout>()
            .having((s) => s.imageBytes, 'imageBytes', validBytes)
            .having((s) => s.isRetryable, 'isRetryable', isTrue),
      ],
    );

    // The bytes survive so the student can see what was rejected, but the
    // same blurry photo reads as blurry every time - retrying it is a dead
    // end, so only Retake is offered.
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'an unreadable photo is kept on screen but not retryable',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.unreadable),
      )),
      seed: () => AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      skip: 1,
      expect: () => [
        isA<AskByPhotoUnreadable>()
            .having((s) => s.imageBytes, 'imageBytes', validBytes)
            .having((s) => s.questionId, 'questionId', 'q_unreadable')
            .having((s) => s.isRetryable, 'isRetryable', isFalse),
      ],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a non-question photo is kept on screen but not retryable',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.notAQuestion),
      )),
      seed: () => AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      skip: 1,
      expect: () => [
        isA<AskByPhotoNotAQuestion>()
            .having((s) => s.imageBytes, 'imageBytes', validBytes)
            .having((s) => s.isRetryable, 'isRetryable', isFalse),
      ],
    );
  });

  group('retrying after a failure', () {
    // `_onSubmitted` used to read the photo only out of AskByPhotoPhotoSelected,
    // so resubmitting from an error state would fall through to the "choose a
    // photo first" branch and report a validation error over a photo that was
    // sitting right there.
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'resubmits the same bytes rather than asking for a photo again',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.solved),
      )),
      seed: () => AskByPhotoNetworkError(
        'No connection.',
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      expect: () => [
        AskByPhotoLoading(imageBytes: validBytes, fileName: 'problem.jpg'),
        isA<AskByPhotoSolved>()
            .having((s) => s.questionId, 'questionId', 'q_solved'),
      ],
      verify: (bloc) {
        final repository = bloc.submitPhotoQuestionUseCase.repository
            as _FakeQuestionsRepository;
        expect(repository.callCount, 1);
        expect(repository.lastBytes, validBytes);
        expect(repository.lastContentType, 'image/jpeg');
      },
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a retry that fails again still keeps the photo',
      build: () => _blocFor(_FakeQuestionsRepository(
        failure: NetworkFailure('Still no connection.'),
      )),
      seed: () => AskByPhotoNetworkError(
        'No connection.',
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      skip: 1,
      expect: () => [
        isA<AskByPhotoNetworkError>()
            .having((s) => s.imageBytes, 'imageBytes', validBytes)
            .having((s) => s.isRetryable, 'isRetryable', isTrue),
      ],
    );

    // Nothing was ever picked, so there is nothing to retry - this must still
    // reach the validation branch rather than submitting empty bytes.
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'submitting with no photo at all still reports a validation error',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.solved),
      )),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      expect: () => [
        const AskByPhotoLoading(),
        isA<AskByPhotoValidationError>(),
      ],
      verify: (bloc) {
        final repository = bloc.submitPhotoQuestionUseCase.repository
            as _FakeQuestionsRepository;
        expect(repository.callCount, 0);
      },
    );
  });
}
