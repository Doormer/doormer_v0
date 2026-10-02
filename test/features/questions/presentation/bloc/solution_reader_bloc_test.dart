import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quark_balance_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_quest_profile_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/reveal_answer_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/solution_reader_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _document = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'One', body: [], rationale: [
      TextSolutionSegment('because'),
    ]),
    SolutionStep(title: 'Two', body: []),
    SolutionStep(title: 'Three', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    MathSolutionSegment(latex: r'\boxed{160}', alt: '160'),
  ]),
);

/// Same shape as [_document] but carrying an approach, so the reader opens on
/// a briefing.
const _briefedDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'One', body: [], rationale: [
      TextSolutionSegment('because'),
    ]),
    SolutionStep(title: 'Two', body: []),
    SolutionStep(title: 'Three', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    MathSolutionSegment(latex: r'\boxed{160}', alt: '160'),
  ]),
  approach: SolutionSection(body: [
    TextSolutionSegment('Use the road angle, then the width.'),
  ]),
);

/// A single-step document with a briefing. This is the only shape that exposes
/// the two isLastStep guards: at stepIndex 0 the reader is simultaneously on
/// the briefing and on the last step.
const _oneStepBriefedDocument = SolutionDocument(
  schemaVersion: '3.0',
  steps: [
    SolutionStep(title: 'Only', body: []),
  ],
  finalAnswer: FinalAnswer(body: [
    MathSolutionSegment(latex: r'\boxed{160}', alt: '160'),
  ]),
  approach: SolutionSection(body: [
    TextSolutionSegment('One move is enough.'),
  ]),
);

class _StubRepository implements QuestionsRepository {
  final PhotoQuestionSolveOutcome? outcome;
  final Failure? failure;
  int balance = 128;
  AnswerReward reward = const AnswerReward(quarksEarned: 3, quarkBalance: 131);
  Object? balanceError;
  Object? revealError;
  final List<String> revealedIds = [];

  _StubRepository({this.outcome, this.failure});

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() async {
    if (failure != null) throw failure!;
    return outcome!;
  }

  @override
  Future<PhotoQuestionSolveOutcome> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<QuestProfile> loadQuestProfile() async => const QuestProfile(
        streakDays: 3,
        topic: 'Geometry - Area',
        questionTitle: 'Road through a field',
      );

  @override
  Future<int> loadQuarkBalance() async {
    final error = balanceError;
    if (error != null) throw error;
    return balance;
  }

  @override
  Future<AnswerReward> revealAnswer(String questionId) async {
    revealedIds.add(questionId);
    final error = revealError;
    if (error != null) throw error;
    return reward;
  }
}

({SolutionReaderBloc bloc, _StubRepository repository}) _blocWithRepository({
  PhotoQuestionSolveOutcome? outcome,
  Failure? failure,
}) {
  final repository = _StubRepository(outcome: outcome, failure: failure);
  final bloc = SolutionReaderBloc(
    loadSampleSolutionUseCase: LoadSampleSolutionUseCase(repository),
    loadQuestProfileUseCase: LoadQuestProfileUseCase(repository),
    loadQuarkBalanceUseCase: LoadQuarkBalanceUseCase(repository),
    revealAnswerUseCase: RevealAnswerUseCase(repository),
  );
  return (bloc: bloc, repository: repository);
}

SolutionReaderBloc _bloc(
    {PhotoQuestionSolveOutcome? outcome, Failure? failure}) {
  return _blocWithRepository(outcome: outcome, failure: failure).bloc;
}

void main() {
  group('SolutionReaderStarted', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'uses the handed-over document without touching the usecase',
      build: () => _bloc(failure: DatabaseFailure('must not be called')),
      act: (bloc) => bloc.add(const SolutionReaderStarted(document: _document)),
      // The solution lands first; the quark balance and the standing follow.
      // Holding the solution back until either resolves would make a slow
      // call cost the student the thing they came for.
      expect: () => [
        const SolutionReaderReady(document: _document),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 128),
        isA<SolutionReaderReady>()
            .having((s) => s.profile, 'profile', isNotNull),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'falls back to the sample solution when no document is handed over',
      build: () => _bloc(
        outcome: const PhotoQuestionSolveOutcome(
          status: PhotoQuestionSolveStatus.solved,
          questionId: '57',
          solution: _document,
        ),
      ),
      act: (bloc) => bloc.add(const SolutionReaderStarted()),
      expect: () => [
        isA<SolutionReaderLoading>(),
        isA<SolutionReaderReady>()
            .having((s) => s.document.steps, 'steps', hasLength(3))
            .having((s) => s.stepIndex, 'stepIndex', 0),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 128),
        isA<SolutionReaderReady>()
            .having((s) => s.profile?.streakDays, 'streakDays', 3),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'emits the failure message when the sample cannot be loaded',
      build: () => _bloc(failure: DatabaseFailure('We could not open it.')),
      act: (bloc) => bloc.add(const SolutionReaderStarted()),
      expect: () => [
        isA<SolutionReaderLoading>(),
        const SolutionReaderError('We could not open it.'),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'errors when the outcome carries no solution',
      build: () => _bloc(
        outcome: const PhotoQuestionSolveOutcome(
          status: PhotoQuestionSolveStatus.unreadable,
          questionId: '57',
          solution: null,
        ),
      ),
      act: (bloc) => bloc.add(const SolutionReaderStarted()),
      expect: () => [
        isA<SolutionReaderLoading>(),
        isA<SolutionReaderError>(),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'loads the quark balance after the solution opens',
      build: () => _bloc(failure: DatabaseFailure('must not be called')),
      act: (bloc) => bloc.add(const SolutionReaderStarted(document: _document)),
      expect: () => [
        const SolutionReaderReady(document: _document),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 128),
        isA<SolutionReaderReady>()
            .having((s) => s.profile, 'profile', isNotNull),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'a balance failure leaves the pill hidden and keeps the solution open',
      build: () {
        final built = _blocWithRepository(
          outcome: const PhotoQuestionSolveOutcome(
            status: PhotoQuestionSolveStatus.solved,
            questionId: '57',
            solution: _document,
          ),
        );
        built.repository.balanceError = ServerFailure('Something went wrong.');
        return built.bloc;
      },
      act: (bloc) => bloc.add(const SolutionReaderStarted()),
      expect: () => [
        isA<SolutionReaderLoading>(),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', isNull),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', isNull)
            .having((s) => s.profile, 'profile', isNotNull),
      ],
    );
  });

  group('travel', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'returns to a step already read',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _document,
        stepIndex: 2,
        rationaleVisible: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderTravelled(0)),
      expect: () => const [
        SolutionReaderReady(document: _document),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'refuses to travel forward',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document),
      act: (bloc) => bloc.add(const SolutionReaderTravelled(2)),
      expect: () => const <SolutionReaderState>[],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'refuses to travel to where it already is',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document, stepIndex: 1),
      act: (bloc) => bloc.add(const SolutionReaderTravelled(1)),
      expect: () => const <SolutionReaderState>[],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'returns to the briefing',
      build: _bloc,
      seed: () =>
          const SolutionReaderReady(document: _briefedDocument, stepIndex: 2),
      act: (bloc) => bloc
          .add(const SolutionReaderTravelled(SolutionReaderTravelled.briefing)),
      expect: () => const [
        SolutionReaderReady(
          document: _briefedDocument,
          stepIndex: 2,
          onBriefing: true,
        ),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'has no briefing to return to when the document carries no approach',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document, stepIndex: 1),
      act: (bloc) => bloc
          .add(const SolutionReaderTravelled(SolutionReaderTravelled.briefing)),
      expect: () => const <SolutionReaderState>[],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'refuses to leave the briefing by travelling forward to a step',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderTravelled(0)),
      expect: () => const <SolutionReaderState>[],
    );
  });

  group('navigation', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'advances to the next step and re-hides the rationale',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _document,
        rationaleVisible: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderAdvanced()),
      expect: () => const [
        SolutionReaderReady(document: _document, stepIndex: 1),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'does not advance past the last step',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document, stepIndex: 2),
      act: (bloc) => bloc.add(const SolutionReaderAdvanced()),
      expect: () => const <SolutionReaderState>[],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'goes back a step',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document, stepIndex: 2),
      act: (bloc) => bloc.add(const SolutionReaderWentBack()),
      expect: () => const [
        SolutionReaderReady(document: _document, stepIndex: 1),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'does not go back past the first step',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document),
      act: (bloc) => bloc.add(const SolutionReaderWentBack()),
      expect: () => const <SolutionReaderState>[],
    );
  });

  group('reveals', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'toggles the rationale on and off',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document),
      act: (bloc) => bloc
        ..add(const SolutionReaderRationaleToggled())
        ..add(const SolutionReaderRationaleToggled()),
      expect: () => const [
        SolutionReaderReady(document: _document, rationaleVisible: true),
        SolutionReaderReady(document: _document),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'reveals the answer only on the last step',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document),
      act: (bloc) => bloc.add(const SolutionReaderAnswerRevealed()),
      expect: () => const <SolutionReaderState>[],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'reveals the answer on the last step',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _document, stepIndex: 2),
      act: (bloc) => bloc.add(const SolutionReaderAnswerRevealed()),
      expect: () => const [
        SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
        ),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'calls reveal-answer once with the question id',
      build: () {
        final built = _blocWithRepository();
        addTearDown(() {
          expect(built.repository.revealedIds, ['123']);
        });
        return built.bloc;
      },
      seed: () => const SolutionReaderReady(
        document: _document,
        stepIndex: 2,
        quarkBalance: 128,
      ),
      act: (bloc) => bloc
        ..add(const SolutionReaderAnswerRevealed(questionId: '123'))
        ..add(const SolutionReaderAnswerRevealed(questionId: '123')),
      wait: const Duration(milliseconds: 1),
      expect: () => [
        const SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
          quarkBalance: 128,
          revealRewardRequested: true,
        ),
        const SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
          quarkBalance: 131,
          quarksEarned: 3,
          rewardFlightId: 1,
          revealRewardRequested: true,
        ),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'never calls reveal-answer without a question id',
      build: () {
        final built = _blocWithRepository();
        addTearDown(() => expect(built.repository.revealedIds, isEmpty));
        return built.bloc;
      },
      seed: () => const SolutionReaderReady(document: _document, stepIndex: 2),
      act: (bloc) => bloc.add(const SolutionReaderAnswerRevealed()),
      expect: () => const [
        SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
        ),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'a reveal failure still opens the answer and changes nothing else',
      build: () {
        final built = _blocWithRepository();
        built.repository.revealError = ServerFailure('Something went wrong.');
        return built.bloc;
      },
      seed: () => const SolutionReaderReady(
        document: _document,
        stepIndex: 2,
        quarkBalance: 128,
      ),
      act: (bloc) =>
          bloc.add(const SolutionReaderAnswerRevealed(questionId: '123')),
      wait: const Duration(milliseconds: 1),
      expect: () => const [
        SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
          quarkBalance: 128,
          revealRewardRequested: true,
        ),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'when the balance pill was hidden, reveal sets the balance but starts no flight',
      build: () => _bloc(),
      seed: () => const SolutionReaderReady(document: _document, stepIndex: 2),
      act: (bloc) =>
          bloc.add(const SolutionReaderAnswerRevealed(questionId: '123')),
      wait: const Duration(milliseconds: 1),
      expect: () => const [
        SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
          revealRewardRequested: true,
        ),
        SolutionReaderReady(
          document: _document,
          stepIndex: 2,
          answerRevealed: true,
          quarkBalance: 131,
          quarksEarned: 3,
          rewardFlightId: 0,
          revealRewardRequested: true,
        ),
      ],
    );
  });

  group('briefing', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'opens on the briefing when the document carries an approach',
      build: _bloc,
      act: (bloc) =>
          bloc.add(const SolutionReaderStarted(document: _briefedDocument)),
      expect: () => [
        const SolutionReaderReady(
          document: _briefedDocument,
          onBriefing: true,
        ),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 128)
            .having((s) => s.onBriefing, 'onBriefing', isTrue),
        isA<SolutionReaderReady>()
            .having((s) => s.onBriefing, 'onBriefing', isTrue),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'opens on step one when the document has no approach',
      build: _bloc,
      act: (bloc) => bloc.add(const SolutionReaderStarted(document: _document)),
      // The solution lands first; the quark balance and the standing follow.
      // Holding the solution back until either resolves would make a slow
      // call cost the student the thing they came for.
      expect: () => [
        const SolutionReaderReady(document: _document),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 128),
        isA<SolutionReaderReady>()
            .having((s) => s.profile, 'profile', isNotNull),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'leaves the briefing without consuming a step',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderAdvanced()),
      expect: () => const [
        SolutionReaderReady(document: _briefedDocument),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'goes back from step one to the briefing',
      build: _bloc,
      seed: () => const SolutionReaderReady(document: _briefedDocument),
      act: (bloc) => bloc.add(const SolutionReaderWentBack()),
      expect: () => const [
        SolutionReaderReady(document: _briefedDocument, onBriefing: true),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'does not go back past the briefing',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderWentBack()),
      expect: () => const <SolutionReaderState>[],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'ignores the rationale toggle while on the briefing',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _briefedDocument,
        onBriefing: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderRationaleToggled()),
      expect: () => const <SolutionReaderState>[],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'advances off the briefing even when the only step is also the last',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _oneStepBriefedDocument,
        onBriefing: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderAdvanced()),
      expect: () => const [
        SolutionReaderReady(document: _oneStepBriefedDocument),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'cannot reveal the answer from the briefing of a one-step solution',
      build: _bloc,
      seed: () => const SolutionReaderReady(
        document: _oneStepBriefedDocument,
        onBriefing: true,
      ),
      act: (bloc) => bloc.add(const SolutionReaderAnswerRevealed()),
      expect: () => const <SolutionReaderState>[],
    );
  });

  group('note', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'keeps the note handed over from a solve',
      build: _bloc,
      act: (bloc) => bloc.add(const SolutionReaderStarted(
        document: _document,
        note: 'The width is derived.',
      )),
      expect: () => [
        const SolutionReaderReady(
          document: _document,
          note: 'The width is derived.',
        ),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 128)
            .having((s) => s.note, 'note', 'The width is derived.'),
        isA<SolutionReaderReady>()
            .having((s) => s.note, 'note', 'The width is derived.'),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'keeps the note loaded from the sample',
      build: () => _bloc(
        outcome: const PhotoQuestionSolveOutcome(
          status: PhotoQuestionSolveStatus.solved,
          questionId: '57',
          solution: _document,
          note: 'The width is derived.',
        ),
      ),
      act: (bloc) => bloc.add(const SolutionReaderStarted()),
      expect: () => [
        isA<SolutionReaderLoading>(),
        isA<SolutionReaderReady>()
            .having((s) => s.note, 'note', 'The width is derived.'),
        isA<SolutionReaderReady>()
            .having((s) => s.quarkBalance, 'quarkBalance', 128)
            .having((s) => s.note, 'note', 'The width is derived.'),
        isA<SolutionReaderReady>()
            .having((s) => s.note, 'note', 'The width is derived.')
            .having((s) => s.profile, 'profile', isNotNull),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'keeps the topic and the method handed over from a solve',
      build: _bloc,
      act: (bloc) => bloc.add(const SolutionReaderStarted(
        document: _document,
        topic: 'Algebra - Linear equations',
        method: 'Inverse operations',
      )),
      verify: (bloc) {
        expect(
          bloc.state,
          isA<SolutionReaderReady>()
              .having((s) => s.topic, 'topic', 'Algebra - Linear equations')
              .having((s) => s.method, 'method', 'Inverse operations'),
        );
      },
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'keeps the topic and the method loaded from the sample',
      build: () => _bloc(
        outcome: const PhotoQuestionSolveOutcome(
          status: PhotoQuestionSolveStatus.solved,
          questionId: '57',
          solution: _document,
          topic: 'Geometry - Area',
          method: 'Trigonometry and parallelogram area',
        ),
      ),
      act: (bloc) => bloc.add(const SolutionReaderStarted()),
      verify: (bloc) {
        expect(
          bloc.state,
          isA<SolutionReaderReady>()
              .having((s) => s.topic, 'topic', 'Geometry - Area')
              .having(
                (s) => s.method,
                'method',
                'Trigonometry and parallelogram area',
              ),
        );
      },
    );
  });
}
