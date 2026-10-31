import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/failure/photo_question_failures.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/submit_photo_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/utils/photo/editable_photo.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_edit.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestionsRepository implements QuestionsRepository {
  _FakeQuestionsRepository({this.outcome, this.failure, this.pending});

  PhotoQuestionSolveOutcome? outcome;
  Object? failure;
  Completer<PhotoQuestionSolveOutcome>? pending;
  int callCount = 0;
  Uint8List? lastBytes;
  String? lastContentType;
  final List<String> idempotencyKeys = [];

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey);
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
  Future<DailyLimit> loadDailyLimit() => throw UnimplementedError();

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() {
    throw UnimplementedError();
  }

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) {
    throw UnimplementedError();
  }

  @override
  Future<int> loadQuarkBalance() {
    throw UnimplementedError();
  }

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) {
    throw UnimplementedError();
  }

  @override
  Future<AnswerReward> revealAnswer(String questionId) {
    throw UnimplementedError();
  }
}

PhotoQuestionSolveOutcome _outcome(
  PhotoQuestionSolveStatus status, {
  String note = '',
  String topic = '',
  String method = '',
  DailyLimit? dailyLimit,
}) {
  return PhotoQuestionSolveOutcome(
    status: status,
    questionId: 'q_${status.name}',
    note: note,
    topic: topic,
    method: method,
    dailyLimit: dailyLimit,
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

/// Hands out photo-key-1, photo-key-2, … in order, so a test knows which key
/// each photo gets.
String Function() _countingKeys() {
  var made = 0;
  return () => 'photo-key-${++made}';
}

AskByPhotoBloc _blocFor(_FakeQuestionsRepository repository) {
  return AskByPhotoBloc(
    submitPhotoQuestionUseCase: SubmitPhotoQuestionUseCase(repository),
    newIdempotencyKey: _countingKeys(),
  );
}

final _midnight =
    DailyLimit(questionsLeft: 0, resetsAt: DateTime(2026, 10, 19));

void main() {
  setUpAll(AppLogger.disable);

  final validBytes = Uint8List.fromList([1, 2, 3]);

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'carries the solver note across the solve handoff',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(
        PhotoQuestionSolveStatus.solved,
        note: 'The rectangle width is derived, not printed.',
      ),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.jpg',
          idempotencyKey: 'photo-key-1'),
      isA<AskByPhotoSolved>().having(
        (state) => state.note,
        'note',
        'The rectangle width is derived, not printed.',
      ),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'carries the topic and the method across the solve handoff',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(
        PhotoQuestionSolveStatus.solved,
        topic: 'Algebra - Linear equations',
        method: 'Inverse operations',
      ),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.jpg',
          idempotencyKey: 'photo-key-1'),
      isA<AskByPhotoSolved>()
          .having((state) => state.topic, 'topic', 'Algebra - Linear equations')
          .having((state) => state.method, 'method', 'Inverse operations'),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'emits Solved with question id and solution for solved outcome',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.jpg',
          idempotencyKey: 'photo-key-1'),
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
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.png',
          idempotencyKey: 'photo-key-1'),
      AskByPhotoUnreadable(
        questionId: 'q_unreadable',
        imageBytes: validBytes,
        fileName: 'problem.png',
        mimeType: 'image/png',
        idempotencyKey: 'photo-key-1',
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
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.png',
          idempotencyKey: 'photo-key-1'),
      AskByPhotoNotAQuestion(
        questionId: 'q_notAQuestion',
        imageBytes: validBytes,
        fileName: 'problem.png',
        mimeType: 'image/png',
        idempotencyKey: 'photo-key-1',
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
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.png',
          idempotencyKey: 'photo-key-1'),
      AskByPhotoTimeout(
        questionId: 'q_timeout',
        imageBytes: validBytes,
        fileName: 'problem.png',
        mimeType: 'image/png',
        idempotencyKey: 'photo-key-1',
      ),
    ],
  );

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'refuses a photo that is not JPEG or PNG without calling the solver',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.heic',
      mimeType: 'image/heic',
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.heic',
          idempotencyKey: 'photo-key-1'),
      const AskByPhotoValidationError(photoUnreadableMessage),
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
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
    expect: () => [
      AskByPhotoLoading(
          imageBytes: validBytes,
          fileName: 'problem.jpg',
          idempotencyKey: 'photo-key-1'),
      AskByPhotoNetworkError(
        'We could not reach the solver. Try again.',
        cause: SolveErrorCause.network,
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
        idempotencyKey: 'photo-key-1',
      ),
    ],
  );

  for (final (failure, cause) in [
    (NetworkFailure(), SolveErrorCause.network),
    (ServerFailure(), SolveErrorCause.server),
    (ApiFailure(418), SolveErrorCause.unknown),
    (Exception('boom'), SolveErrorCause.unknown),
  ]) {
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'emits NetworkError cause $cause for ${failure.runtimeType}',
      build: () => _blocFor(_FakeQuestionsRepository(failure: failure)),
      seed: () => AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
        idempotencyKey: 'photo-key-1',
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      skip: 1,
      expect: () => [
        isA<AskByPhotoNetworkError>()
            .having((state) => state.cause, 'cause', cause)
            .having((state) => state.imageBytes, 'imageBytes', validBytes)
            .having((state) => state.idempotencyKey, 'idempotencyKey',
                'photo-key-1'),
      ],
    );
  }

  blocTest<AskByPhotoBloc, AskByPhotoState>(
    'carries the selected photo into Loading so the preview survives the solve',
    build: () => _blocFor(_FakeQuestionsRepository(
      outcome: _outcome(PhotoQuestionSolveStatus.solved),
    )),
    seed: () => AskByPhotoPhotoSelected(
      imageBytes: validBytes,
      fileName: 'problem.jpg',
      mimeType: 'image/jpeg',
      idempotencyKey: 'photo-key-1',
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
        'Please choose a photo before submitting.',
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
        AskByPhotoLoading(
            imageBytes: validBytes,
            fileName: 'problem.jpg',
            idempotencyKey: 'photo-key-1'),
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
      idempotencyKey: 'photo-key-1',
    ),
    act: (bloc) => bloc.add(const AskByPhotoPickCancelled()),
    expect: () => [
      const AskByPhotoNotice('No photo selected.'),
      AskByPhotoPhotoSelected(
        imageBytes: validBytes,
        fileName: 'problem.jpg',
        mimeType: 'image/jpeg',
        idempotencyKey: 'photo-key-1',
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
      idempotencyKey: 'photo-key-1',
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
        idempotencyKey: 'photo-key-1',
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

  group('preparing a photo', () {
    final selected = AskByPhotoPhotoSelected(
      imageBytes: Uint8List.fromList([9, 9, 9]),
      fileName: 'earlier.jpg',
      mimeType: 'image/jpeg',
      idempotencyKey: 'photo-key-1',
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'starts with no earlier photo to fall back to',
      build: () => _blocFor(_FakeQuestionsRepository()),
      act: (bloc) => bloc.add(const AskByPhotoPreparationStarted()),
      expect: () => [const AskByPhotoPreparingPhoto()],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'remembers the photo it is replacing',
      build: () => _blocFor(_FakeQuestionsRepository()),
      seed: () => selected,
      act: (bloc) => bloc.add(const AskByPhotoPreparationStarted()),
      expect: () => [AskByPhotoPreparingPhoto(previousSelection: selected)],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'shows the prepared photo when it is ready',
      build: () => _blocFor(_FakeQuestionsRepository()),
      seed: () => AskByPhotoPreparingPhoto(previousSelection: selected),
      act: (bloc) => bloc.add(AskByPhotoPhotoPicked(
        imageBytes: validBytes,
        fileName: 'IMG_1.jpg',
        mimeType: 'image/jpeg',
      )),
      expect: () => [
        AskByPhotoPhotoSelected(
          imageBytes: validBytes,
          fileName: 'IMG_1.jpg',
          mimeType: 'image/jpeg',
          idempotencyKey: 'photo-key-1',
        ),
      ],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a failed preparation brings the earlier photo back',
      build: () => _blocFor(_FakeQuestionsRepository()),
      seed: () => AskByPhotoPreparingPhoto(previousSelection: selected),
      act: (bloc) =>
          bloc.add(const AskByPhotoPickUnavailable('Could not prepare it.')),
      expect: () => [
        const AskByPhotoNotice('Could not prepare it.'),
        selected,
      ],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a failed preparation with no earlier photo leaves just the notice',
      build: () => _blocFor(_FakeQuestionsRepository()),
      seed: () => const AskByPhotoPreparingPhoto(),
      act: (bloc) =>
          bloc.add(const AskByPhotoPickUnavailable('Could not prepare it.')),
      expect: () => [const AskByPhotoNotice('Could not prepare it.')],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a second preparation still remembers the first earlier photo',
      build: () => _blocFor(_FakeQuestionsRepository()),
      seed: () => AskByPhotoPreparingPhoto(previousSelection: selected),
      act: (bloc) => bloc.add(const AskByPhotoPreparationStarted()),
      // Equal to the seed, so bloc_test sees no new state.
      expect: () => const <AskByPhotoState>[],
      verify: (bloc) => expect(
        bloc.state,
        AskByPhotoPreparingPhoto(previousSelection: selected),
      ),
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'submitting while preparing does nothing',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.solved),
      )),
      seed: () => AskByPhotoPreparingPhoto(previousSelection: selected),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      expect: () => const <AskByPhotoState>[],
      verify: (bloc) {
        final repository = bloc.submitPhotoQuestionUseCase.repository
            as _FakeQuestionsRepository;
        expect(repository.callCount, 0);
      },
    );
  });

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
        idempotencyKey: 'photo-key-1',
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
        idempotencyKey: 'photo-key-1',
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
        idempotencyKey: 'photo-key-1',
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
        idempotencyKey: 'photo-key-1',
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
        AskByPhotoLoading(
            imageBytes: validBytes,
            fileName: 'problem.jpg',
            idempotencyKey: 'photo-key-1'),
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

  group('the photo stays editable', () {
    final editable = EditablePhoto(
      original: PickedPhotoFile(
        bytes: Uint8List.fromList([7, 7, 7]),
        name: 'IMG_9.HEIC',
      ),
      unedited: PreparedPhoto(
        bytes: Uint8List.fromList([8, 8, 8]),
        fileName: 'IMG_9.jpg',
        width: 4,
        height: 3,
      ),
      edit: const PhotoEdit(quarterTurns: 1),
    );

    AskByPhotoPhotoSelected selectedWithEditable() => AskByPhotoPhotoSelected(
          imageBytes: validBytes,
          fileName: 'IMG_9.jpg',
          mimeType: 'image/jpeg',
          editablePhoto: editable,
          idempotencyKey: 'photo-key-1',
        );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a picked photo keeps what is needed to edit it again',
      build: () => _blocFor(_FakeQuestionsRepository()),
      act: (bloc) => bloc.add(AskByPhotoPhotoPicked(
        imageBytes: validBytes,
        fileName: 'IMG_9.jpg',
        mimeType: 'image/jpeg',
        editablePhoto: editable,
      )),
      expect: () => [selectedWithEditable()],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a solve in flight and a failed one keep it too',
      build: () => _blocFor(_FakeQuestionsRepository(
        failure: NetworkFailure('No connection.'),
      )),
      seed: selectedWithEditable,
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      expect: () => [
        isA<AskByPhotoLoading>()
            .having((s) => s.editablePhoto, 'editablePhoto', editable),
        isA<AskByPhotoNetworkError>()
            .having((s) => s.editablePhoto, 'editablePhoto', editable),
      ],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a photo the solver found no question in keeps it',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.notAQuestion),
      )),
      seed: selectedWithEditable,
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      skip: 1,
      expect: () => [
        isA<AskByPhotoNotAQuestion>()
            .having((s) => s.editablePhoto, 'editablePhoto', editable),
      ],
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a retry after a failure keeps it',
      build: () => _blocFor(_FakeQuestionsRepository(
        outcome: _outcome(PhotoQuestionSolveStatus.timeout),
      )),
      seed: () => AskByPhotoNetworkError(
        'No connection.',
        imageBytes: validBytes,
        fileName: 'IMG_9.jpg',
        mimeType: 'image/jpeg',
        editablePhoto: editable,
      ),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      expect: () => [
        isA<AskByPhotoLoading>()
            .having((s) => s.editablePhoto, 'editablePhoto', editable),
        isA<AskByPhotoTimeout>()
            .having((s) => s.editablePhoto, 'editablePhoto', editable),
      ],
    );

    // Editing the photo after a failed solve prepares it again. If that fails,
    // the photo must come back rather than vanish.
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'preparing again after a failed solve can fall back to its photo',
      build: () => _blocFor(_FakeQuestionsRepository()),
      seed: () => AskByPhotoNotAQuestion(
        questionId: 'q_1',
        imageBytes: validBytes,
        fileName: 'IMG_9.jpg',
        mimeType: 'image/jpeg',
        editablePhoto: editable,
      ),
      act: (bloc) => bloc
        ..add(const AskByPhotoPreparationStarted())
        ..add(const AskByPhotoPickUnavailable('Could not prepare it.')),
      expect: () => [
        AskByPhotoPreparingPhoto(previousSelection: selectedWithEditable()),
        const AskByPhotoNotice('Could not prepare it.'),
        selectedWithEditable(),
      ],
    );
  });

  group('one key per photo', () {
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a picked photo gets a new key, and so does an edited one',
      build: () => _blocFor(_FakeQuestionsRepository()),
      act: (bloc) => bloc
        ..add(AskByPhotoPhotoPicked(
            imageBytes: validBytes, fileName: 'a.jpg', mimeType: 'image/jpeg'))
        ..add(AskByPhotoPhotoPicked(
            imageBytes: validBytes,
            fileName: 'a-cropped.jpg',
            mimeType: 'image/jpeg')),
      expect: () => [
        AskByPhotoPhotoSelected(
            imageBytes: validBytes,
            fileName: 'a.jpg',
            mimeType: 'image/jpeg',
            idempotencyKey: 'photo-key-1'),
        AskByPhotoPhotoSelected(
            imageBytes: validBytes,
            fileName: 'a-cropped.jpg',
            mimeType: 'image/jpeg',
            idempotencyKey: 'photo-key-2'),
      ],
    );

    for (final firstTry in <Object>[
      NetworkFailure('No connection.'),
      PhotoBeingSolvedFailure(),
    ]) {
      test('Try again after ${firstTry.runtimeType} sends the same key',
          () async {
        final repository = _FakeQuestionsRepository(failure: firstTry);
        final bloc = _blocFor(repository);
        bloc.add(AskByPhotoPhotoPicked(
            imageBytes: validBytes, fileName: 'a.jpg', mimeType: 'image/jpeg'));
        bloc.add(const AskByPhotoSubmitted());
        await bloc.stream.firstWhere((s) => s is AskByPhotoSolveFailed);
        repository
          ..failure = null
          ..outcome = _outcome(PhotoQuestionSolveStatus.solved);

        bloc.add(const AskByPhotoSubmitted());
        await bloc.stream.firstWhere((s) => s is AskByPhotoSolved);

        expect(repository.idempotencyKeys, ['photo-key-1', 'photo-key-1']);
        await bloc.close();
      });
    }

    test('Try again after a timeout sends the same key', () async {
      final repository = _FakeQuestionsRepository(
          outcome: _outcome(PhotoQuestionSolveStatus.timeout));
      final bloc = _blocFor(repository);
      bloc.add(AskByPhotoPhotoPicked(
          imageBytes: validBytes, fileName: 'a.jpg', mimeType: 'image/jpeg'));
      bloc.add(const AskByPhotoSubmitted());
      await bloc.stream.firstWhere((s) => s is AskByPhotoTimeout);
      repository.outcome = _outcome(PhotoQuestionSolveStatus.solved);

      bloc.add(const AskByPhotoSubmitted());
      await bloc.stream.firstWhere((s) => s is AskByPhotoSolved);

      expect(repository.idempotencyKeys, ['photo-key-1', 'photo-key-1']);
      await bloc.close();
    });

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'a cancelled pick keeps the photo on screen under its key',
      build: () => _blocFor(_FakeQuestionsRepository()),
      seed: () => AskByPhotoNetworkError('No connection.',
          imageBytes: validBytes,
          fileName: 'a.jpg',
          mimeType: 'image/jpeg',
          idempotencyKey: 'photo-key-1'),
      act: (bloc) => bloc.add(const AskByPhotoPickCancelled()),
      expect: () => [
        const AskByPhotoNotice('No photo selected.'),
        AskByPhotoPhotoSelected(
            imageBytes: validBytes,
            fileName: 'a.jpg',
            mimeType: 'image/jpeg',
            idempotencyKey: 'photo-key-1'),
      ],
    );

    test('Try again after a cancelled pick sends the same key', () async {
      final repository =
          _FakeQuestionsRepository(failure: NetworkFailure('No connection.'));
      final bloc = _blocFor(repository);
      bloc.add(AskByPhotoPhotoPicked(
          imageBytes: validBytes, fileName: 'a.jpg', mimeType: 'image/jpeg'));
      bloc.add(const AskByPhotoSubmitted());
      await bloc.stream.firstWhere((s) => s is AskByPhotoSolveFailed);
      bloc.add(const AskByPhotoPickCancelled());
      await bloc.stream.firstWhere((s) => s is AskByPhotoPhotoSelected);
      repository
        ..failure = null
        ..outcome = _outcome(PhotoQuestionSolveStatus.solved);

      bloc.add(const AskByPhotoSubmitted());
      await bloc.stream.firstWhere((s) => s is AskByPhotoSolved);

      expect(repository.idempotencyKeys, ['photo-key-1', 'photo-key-1']);
      await bloc.close();
    });
  });

  group('refusals', () {
    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'another photo still being solved keeps this one, ready to try again',
      build: () => _blocFor(
          _FakeQuestionsRepository(failure: PhotoBeingSolvedFailure())),
      seed: () => AskByPhotoPhotoSelected(
          imageBytes: validBytes,
          fileName: 'a.jpg',
          mimeType: 'image/jpeg',
          idempotencyKey: 'photo-key-1'),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      expect: () => [
        AskByPhotoLoading(
            imageBytes: validBytes,
            fileName: 'a.jpg',
            idempotencyKey: 'photo-key-1'),
        AskByPhotoStillSolving(
            imageBytes: validBytes,
            fileName: 'a.jpg',
            mimeType: 'image/jpeg',
            idempotencyKey: 'photo-key-1'),
      ],
      verify: (bloc) =>
          expect((bloc.state as AskByPhotoSolveFailed).isRetryable, isTrue),
    );

    blocTest<AskByPhotoBloc, AskByPhotoState>(
      'no questions left keeps the photo and its key, and offers no retry',
      build: () => _blocFor(_FakeQuestionsRepository(
          failure: DailyLimitReachedFailure(_midnight))),
      seed: () => AskByPhotoPhotoSelected(
          imageBytes: validBytes,
          fileName: 'a.jpg',
          mimeType: 'image/jpeg',
          idempotencyKey: 'photo-key-1'),
      act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
      expect: () => [
        AskByPhotoLoading(
            imageBytes: validBytes,
            fileName: 'a.jpg',
            idempotencyKey: 'photo-key-1'),
        AskByPhotoLimitReached(
            dailyLimit: _midnight,
            imageBytes: validBytes,
            fileName: 'a.jpg',
            mimeType: 'image/jpeg',
            idempotencyKey: 'photo-key-1'),
      ],
      verify: (bloc) =>
          expect((bloc.state as AskByPhotoSolveFailed).isRetryable, isFalse),
    );

    test(
        'once the day resets, a submit sends the turned-away photo under its key',
        () async {
      final repository = _FakeQuestionsRepository(
          failure: DailyLimitReachedFailure(_midnight));
      final bloc = _blocFor(repository);
      bloc.add(AskByPhotoPhotoPicked(
          imageBytes: validBytes, fileName: 'a.jpg', mimeType: 'image/jpeg'));
      bloc.add(const AskByPhotoSubmitted());
      await bloc.stream.firstWhere((s) => s is AskByPhotoLimitReached);
      repository
        ..failure = null
        ..outcome = _outcome(PhotoQuestionSolveStatus.solved);

      bloc.add(const AskByPhotoSubmitted());
      await bloc.stream.firstWhere((s) => s is AskByPhotoSolved);

      expect(repository.idempotencyKeys, ['photo-key-1', 'photo-key-1']);
      await bloc.close();
    });
  });

  group('each answer carries the questions left after it', () {
    final threeLeft =
        DailyLimit(questionsLeft: 3, resetsAt: DateTime(2026, 10, 19));
    final reportedBy =
        <PhotoQuestionSolveStatus, DailyLimit? Function(AskByPhotoState)>{
      PhotoQuestionSolveStatus.solved: (s) =>
          (s as AskByPhotoSolved).dailyLimit,
      PhotoQuestionSolveStatus.unreadable: (s) =>
          (s as AskByPhotoUnreadable).dailyLimit,
      PhotoQuestionSolveStatus.notAQuestion: (s) =>
          (s as AskByPhotoNotAQuestion).dailyLimit,
      PhotoQuestionSolveStatus.timeout: (s) =>
          (s as AskByPhotoTimeout).dailyLimit,
    };
    for (final answer in reportedBy.entries) {
      blocTest<AskByPhotoBloc, AskByPhotoState>(
        '${answer.key.name} carries the count',
        build: () => _blocFor(_FakeQuestionsRepository(
            outcome: _outcome(answer.key, dailyLimit: threeLeft))),
        seed: () => AskByPhotoPhotoSelected(
            imageBytes: validBytes,
            fileName: 'a.jpg',
            mimeType: 'image/jpeg',
            idempotencyKey: 'photo-key-1'),
        act: (bloc) => bloc.add(const AskByPhotoSubmitted()),
        verify: (bloc) => expect(answer.value(bloc.state), threeLeft),
      );
    }
  });
}
