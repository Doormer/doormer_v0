import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:doormer/src/features/questions/domain/repository/questions_repository.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_solved_questions_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/saved_questions_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

SolvedQuestionSummary _question(String id) => SolvedQuestionSummary(
      questionId: id,
      topic: 'Topic $id',
      method: 'Method $id',
      questionText: 'Question $id',
      askedAt: DateTime.utc(2026, 10, 6),
    );

final _firstPage = SolvedQuestionsPage(
  questions: [_question('3'), _question('2')],
  nextCursor: '2',
);

final _lastPage = SolvedQuestionsPage(questions: [_question('1')]);

/// Plays the API. It answers each cursor with what [answers] holds for it,
/// either a page or a failure, and remembers every cursor it was asked for.
/// When [held] is set, the next answer waits until the test completes it.
class _ScriptedRepository implements QuestionsRepository {
  final Map<String?, Object> answers;
  final List<String?> cursors = [];
  Completer<void>? held;

  _ScriptedRepository(this.answers);

  @override
  Future<SolvedQuestionsPage> loadSolvedQuestions({String? cursor}) async {
    cursors.add(cursor);
    final gate = held;
    if (gate != null) await gate.future;
    final answer = answers[cursor];
    if (answer is SolvedQuestionsPage) return answer;
    throw answer ?? StateError('no answer for cursor $cursor');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  setUpAll(AppLogger.disable);

  late _ScriptedRepository repository;

  SavedQuestionsBloc newBloc() => SavedQuestionsBloc(
        loadSolvedQuestions: LoadSolvedQuestionsUseCase(repository),
      );

  group('opening', () {
    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'shows the first page',
      setUp: () => repository = _ScriptedRepository({null: _firstPage}),
      build: newBloc,
      act: (bloc) => bloc.add(const SavedQuestionsStarted()),
      expect: () => [
        SavedQuestionsReady(questions: _firstPage.questions, nextCursor: '2'),
      ],
      verify: (_) => expect(repository.cursors, [null]),
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'shows the empty state when nothing is solved yet',
      setUp: () => repository =
          _ScriptedRepository({null: const SolvedQuestionsPage(questions: [])}),
      build: newBloc,
      act: (bloc) => bloc.add(const SavedQuestionsStarted()),
      expect: () => [const SavedQuestionsEmpty()],
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'says the questions could not load when the first page fails',
      setUp: () => repository =
          _ScriptedRepository({null: NetworkFailure("We couldn't connect.")}),
      build: newBloc,
      act: (bloc) => bloc.add(const SavedQuestionsStarted()),
      expect: () =>
          [const SavedQuestionsError(SavedQuestionsBloc.couldNotLoad)],
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'says the same when the first page fails unexpectedly',
      setUp: () => repository = _ScriptedRepository(
          {null: const FormatException('a reply the app cannot read')}),
      build: newBloc,
      act: (bloc) => bloc.add(const SavedQuestionsStarted()),
      expect: () =>
          [const SavedQuestionsError(SavedQuestionsBloc.couldNotLoad)],
    );
  });

  group('loading more', () {
    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'adds the next page below the rows already shown',
      setUp: () => repository = _ScriptedRepository({'2': _lastPage}),
      build: newBloc,
      seed: () =>
          SavedQuestionsReady(questions: _firstPage.questions, nextCursor: '2'),
      act: (bloc) => bloc.add(const SavedQuestionsMoreRequested()),
      expect: () => [
        SavedQuestionsReady(
          questions: _firstPage.questions,
          nextCursor: '2',
          isLoadingMore: true,
        ),
        SavedQuestionsReady(
          questions: [..._firstPage.questions, ..._lastPage.questions],
        ),
      ],
      verify: (_) => expect(repository.cursors, ['2']),
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'asks for nothing once every row is loaded',
      setUp: () => repository = _ScriptedRepository({}),
      build: newBloc,
      seed: () => SavedQuestionsReady(questions: _lastPage.questions),
      act: (bloc) => bloc.add(const SavedQuestionsMoreRequested()),
      expect: () => <SavedQuestionsState>[],
      verify: (_) => expect(repository.cursors, isEmpty),
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'asks for the next page only once while it is on its way',
      setUp: () => repository = _ScriptedRepository({'2': _lastPage})
        ..held = Completer(),
      build: newBloc,
      seed: () =>
          SavedQuestionsReady(questions: _firstPage.questions, nextCursor: '2'),
      act: (bloc) async {
        bloc
          ..add(const SavedQuestionsMoreRequested())
          ..add(const SavedQuestionsMoreRequested());
        await Future<void>.delayed(Duration.zero);
        repository.held!.complete();
      },
      expect: () => [
        SavedQuestionsReady(
          questions: _firstPage.questions,
          nextCursor: '2',
          isLoadingMore: true,
        ),
        SavedQuestionsReady(
          questions: [..._firstPage.questions, ..._lastPage.questions],
        ),
      ],
      verify: (_) => expect(repository.cursors, ['2']),
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'keeps the rows when the next page fails',
      setUp: () => repository = _ScriptedRepository({'2': ServerFailure()}),
      build: newBloc,
      seed: () =>
          SavedQuestionsReady(questions: _firstPage.questions, nextCursor: '2'),
      act: (bloc) => bloc.add(const SavedQuestionsMoreRequested()),
      expect: () => [
        SavedQuestionsReady(
          questions: _firstPage.questions,
          nextCursor: '2',
          isLoadingMore: true,
        ),
        SavedQuestionsReady(
          questions: _firstPage.questions,
          nextCursor: '2',
          loadMoreFailed: true,
        ),
      ],
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'keeps the rows when the next page fails unexpectedly',
      setUp: () => repository = _ScriptedRepository(
          {'2': const FormatException('a reply the app cannot read')}),
      build: newBloc,
      seed: () =>
          SavedQuestionsReady(questions: _firstPage.questions, nextCursor: '2'),
      act: (bloc) => bloc.add(const SavedQuestionsMoreRequested()),
      expect: () => [
        SavedQuestionsReady(
          questions: _firstPage.questions,
          nextCursor: '2',
          isLoadingMore: true,
        ),
        SavedQuestionsReady(
          questions: _firstPage.questions,
          nextCursor: '2',
          loadMoreFailed: true,
        ),
      ],
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'waits for Try again after a failed page instead of asking on scroll',
      setUp: () => repository = _ScriptedRepository({'2': _lastPage}),
      build: newBloc,
      seed: () => SavedQuestionsReady(
        questions: _firstPage.questions,
        nextCursor: '2',
        loadMoreFailed: true,
      ),
      act: (bloc) => bloc.add(const SavedQuestionsMoreRequested()),
      expect: () => <SavedQuestionsState>[],
      verify: (_) => expect(repository.cursors, isEmpty),
    );
  });

  group('Try again', () {
    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'loads the first page again after it failed',
      setUp: () => repository = _ScriptedRepository({null: _firstPage}),
      build: newBloc,
      seed: () => const SavedQuestionsError(SavedQuestionsBloc.couldNotLoad),
      act: (bloc) => bloc.add(const SavedQuestionsRetried()),
      expect: () => [
        const SavedQuestionsLoading(),
        SavedQuestionsReady(questions: _firstPage.questions, nextCursor: '2'),
      ],
    );

    blocTest<SavedQuestionsBloc, SavedQuestionsState>(
      'asks again for the page that failed',
      setUp: () => repository = _ScriptedRepository({'2': _lastPage}),
      build: newBloc,
      seed: () => SavedQuestionsReady(
        questions: _firstPage.questions,
        nextCursor: '2',
        loadMoreFailed: true,
      ),
      act: (bloc) => bloc.add(const SavedQuestionsRetried()),
      expect: () => [
        SavedQuestionsReady(
          questions: _firstPage.questions,
          nextCursor: '2',
          isLoadingMore: true,
        ),
        SavedQuestionsReady(
          questions: [..._firstPage.questions, ..._lastPage.questions],
        ),
      ],
      verify: (_) => expect(repository.cursors, ['2']),
    );
  });
}
