import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_daily_limit_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/daily_limit_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each read only when the test says, so a test can decide the order
/// reads and reports land in.
class _ReadsOnDemand implements QuestionsRepository {
  final reads = <Completer<DailyLimit>>[];

  @override
  Future<DailyLimit> loadDailyLimit() {
    final read = Completer<DailyLimit>();
    reads.add(read);
    return read.future;
  }

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() =>
      throw UnimplementedError();

  @override
  Future<PhotoQuestionSolveOutcome> loadQuestion(String questionId) =>
      throw UnimplementedError();

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<AnswerReward> revealAnswer(String questionId) =>
      throw UnimplementedError();

  @override
  Future<int> loadQuarkBalance() => throw UnimplementedError();
}

DailyLimit _left(int questionsLeft) =>
    DailyLimit(questionsLeft: questionsLeft, resetsAt: DateTime(2026, 10, 19));

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUpAll(AppLogger.disable);

  late _ReadsOnDemand repository;

  // The time the bloc reads: the evening before _left's questions reset,
  // unless a test moves it on.
  late DateTime now;

  DailyLimitBloc build() => DailyLimitBloc(
        loadDailyLimitUseCase: LoadDailyLimitUseCase(repository),
        now: () => now,
      );

  setUp(() {
    repository = _ReadsOnDemand();
    now = DateTime(2026, 10, 18, 21);
  });

  test('nothing is known before the first read', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state, const DailyLimitUnknown());
  });

  blocTest<DailyLimitBloc, DailyLimitState>(
    'a read gives the questions left',
    build: build,
    act: (bloc) async {
      bloc.add(const DailyLimitRequested());
      await _settle();
      repository.reads.single.complete(_left(3));
    },
    expect: () => [DailyLimitKnown(_left(3))],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    "an ask's count is shown without reading again",
    build: build,
    act: (bloc) => bloc.add(DailyLimitReported(_left(4))),
    expect: () => [DailyLimitKnown(_left(4))],
    verify: (_) => expect(repository.reads, isEmpty),
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    'a read that fails keeps the count Solve had',
    build: build,
    seed: () => DailyLimitKnown(_left(3)),
    act: (bloc) async {
      bloc.add(const DailyLimitRequested());
      await _settle();
      repository.reads.single.completeError(NetworkFailure('No connection.'));
    },
    expect: () => <DailyLimitState>[],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    'a first read that fails leaves the count unknown',
    build: build,
    act: (bloc) async {
      bloc.add(const DailyLimitRequested());
      await _settle();
      repository.reads.single.completeError(StateError('unexpected'));
    },
    expect: () => <DailyLimitState>[],
    verify: (bloc) => expect(bloc.state, const DailyLimitUnknown()),
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    'a read that fails after the count has reset forgets it',
    build: build,
    seed: () => DailyLimitKnown(_left(0)),
    act: (bloc) async {
      now = DateTime(2026, 10, 19, 7);
      bloc.add(const DailyLimitRequested());
      await _settle();
      repository.reads.single.completeError(NetworkFailure('No connection.'));
    },
    expect: () => [const DailyLimitUnknown()],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    'a count is out of date from the moment it resets',
    build: build,
    seed: () => DailyLimitKnown(_left(0)),
    act: (bloc) async {
      now = DateTime(2026, 10, 19);
      bloc.add(const DailyLimitRequested());
      await _settle();
      repository.reads.single.completeError(StateError('unexpected'));
    },
    expect: () => [const DailyLimitUnknown()],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    "a read that started before an ask's count does not replace it",
    build: build,
    act: (bloc) async {
      bloc.add(const DailyLimitRequested());
      await _settle();
      bloc.add(DailyLimitReported(_left(4)));
      await _settle();
      repository.reads.single.complete(_left(5));
    },
    expect: () => [DailyLimitKnown(_left(4))],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    'of two reads, the later one wins whichever answers last',
    build: build,
    act: (bloc) async {
      bloc
        ..add(const DailyLimitRequested())
        ..add(const DailyLimitRequested());
      await _settle();
      repository.reads[1].complete(_left(3));
      await _settle();
      repository.reads[0].complete(_left(5));
    },
    expect: () => [DailyLimitKnown(_left(3))],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    "an earlier read's answer shows until the later read answers",
    build: build,
    act: (bloc) async {
      bloc
        ..add(const DailyLimitRequested())
        ..add(const DailyLimitRequested());
      await _settle();
      repository.reads[0].complete(_left(5));
      await _settle();
      repository.reads[1].complete(_left(3));
    },
    expect: () => [DailyLimitKnown(_left(5)), DailyLimitKnown(_left(3))],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    "an earlier read's answer stays when the later read fails",
    build: build,
    act: (bloc) async {
      bloc
        ..add(const DailyLimitRequested())
        ..add(const DailyLimitRequested());
      await _settle();
      repository.reads[0].complete(_left(5));
      await _settle();
      repository.reads[1].completeError(NetworkFailure('No connection.'));
    },
    expect: () => [DailyLimitKnown(_left(5))],
  );

  blocTest<DailyLimitBloc, DailyLimitState>(
    "a later read's answer shows when the earlier read fails",
    build: build,
    act: (bloc) async {
      bloc
        ..add(const DailyLimitRequested())
        ..add(const DailyLimitRequested());
      await _settle();
      repository.reads[0].completeError(NetworkFailure('No connection.'));
      await _settle();
      repository.reads[1].complete(_left(3));
    },
    expect: () => [DailyLimitKnown(_left(3))],
  );
}
