import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_sample_solution_usecase.dart';
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
}

SolutionReaderBloc _bloc({PhotoQuestionSolveOutcome? outcome, Failure? failure}) {
  return SolutionReaderBloc(
    loadSampleSolutionUseCase: LoadSampleSolutionUseCase(
      _StubRepository(outcome: outcome, failure: failure),
    ),
  );
}

void main() {
  group('SolutionReaderStarted', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'uses the handed-over document without touching the usecase',
      build: () => _bloc(failure: DatabaseFailure('must not be called')),
      act: (bloc) => bloc.add(const SolutionReaderStarted(document: _document)),
      expect: () => const [
        SolutionReaderReady(document: _document),
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
  });

  group('briefing', () {
    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'opens on the briefing when the document carries an approach',
      build: _bloc,
      act: (bloc) =>
          bloc.add(const SolutionReaderStarted(document: _briefedDocument)),
      expect: () => const [
        SolutionReaderReady(document: _briefedDocument, onBriefing: true),
      ],
    );

    blocTest<SolutionReaderBloc, SolutionReaderState>(
      'opens on step one when the document has no approach',
      build: _bloc,
      act: (bloc) => bloc.add(const SolutionReaderStarted(document: _document)),
      expect: () => const [
        SolutionReaderReady(document: _document),
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
      expect: () => const [
        SolutionReaderReady(document: _document, note: 'The width is derived.'),
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
      ],
    );
  });
}
