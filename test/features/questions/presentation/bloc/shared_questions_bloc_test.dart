import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_questions_page.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_shared_questions_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/shared_questions_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_question_sharing_repository.dart';

SharedQuestionSummary _shared(String id) => SharedQuestionSummary(
      question: SolvedQuestionSummary(
        questionId: id,
        topic: 'Topic $id',
        method: 'Method $id',
        questionText: 'Question $id',
        askedAt: DateTime.utc(2026, 10, 30),
      ),
      sharedBy: sam,
      sharedAt: DateTime.utc(2026, 11, 1),
    );

/// The cursor the API gave for the second page: the last row's share ID,
/// which is not a question ID. The app sends it back as it is.
const _cursor = '9001';

final _firstPage = SharedQuestionsPage(
  questions: [_shared('303'), _shared('302')],
  nextCursor: _cursor,
);

final _lastPage = SharedQuestionsPage(questions: [_shared('301')]);

void main() {
  setUpAll(AppLogger.disable);

  late FakeQuestionSharingRepository repository;

  setUp(() => repository = FakeQuestionSharingRepository()
    ..sharedPages = {null: _firstPage, _cursor: _lastPage});

  SharedQuestionsBloc build() => SharedQuestionsBloc(
        loadSharedQuestions: LoadSharedQuestionsUseCase(repository),
      );

  final firstShown = SharedQuestionsReady(
      questions: _firstPage.questions, nextCursor: _cursor);

  group('opening', () {
    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'shows the first page, newest share first',
      build: build,
      act: (bloc) => bloc.add(const SharedQuestionsStarted()),
      expect: () => [firstShown],
      verify: (_) => expect(repository.calls, ['loadSharedQuestions']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'shows the empty state when nothing is shared',
      build: build,
      setUp: () => repository.sharedPages = {
        null: const SharedQuestionsPage(questions: []),
      },
      act: (bloc) => bloc.add(const SharedQuestionsStarted()),
      expect: () => [const SharedQuestionsEmpty()],
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'says the questions could not load when the first page fails',
      build: build,
      setUp: () => repository.failNext['loadSharedQuestions'] =
          NetworkFailure("We couldn't load the questions shared with you."),
      act: (bloc) => bloc.add(const SharedQuestionsStarted()),
      expect: () => const [
        SharedQuestionsError("We couldn't load the questions shared with you."),
      ],
    );
  });

  group('loading more', () {
    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'sends back the cursor the API gave, and adds the next page below',
      build: build,
      seed: () => firstShown,
      act: (bloc) => bloc.add(const SharedQuestionsMoreRequested()),
      expect: () => [
        firstShown.copyWith(isLoadingMore: true),
        SharedQuestionsReady(
          questions: [..._firstPage.questions, ..._lastPage.questions],
        ),
      ],
      verify: (_) => expect(repository.calls, ['loadSharedQuestions $_cursor']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'asks for nothing once every row is loaded',
      build: build,
      seed: () => SharedQuestionsReady(questions: _lastPage.questions),
      act: (bloc) => bloc.add(const SharedQuestionsMoreRequested()),
      expect: () => const <SharedQuestionsState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'asks for the next page only once while it is on its way',
      build: build,
      setUp: () => repository.hold = Completer<void>(),
      seed: () => firstShown,
      act: (bloc) async {
        bloc
          ..add(const SharedQuestionsMoreRequested())
          ..add(const SharedQuestionsMoreRequested());
        await Future<void>.delayed(Duration.zero);
        repository.hold!.complete();
      },
      skip: 1,
      expect: () => [
        SharedQuestionsReady(
          questions: [..._firstPage.questions, ..._lastPage.questions],
        ),
      ],
      verify: (_) => expect(repository.calls, ['loadSharedQuestions $_cursor']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'a next page that fails keeps the rows, and waits for Try again',
      build: build,
      setUp: () => repository.failNext['loadSharedQuestions'] =
          NetworkFailure("We couldn't load the questions shared with you."),
      seed: () => firstShown,
      act: (bloc) async {
        bloc.add(const SharedQuestionsMoreRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedQuestionsMoreRequested());
      },
      skip: 1,
      expect: () => [firstShown.copyWith(loadMoreFailed: true)],
      verify: (_) => expect(repository.calls, ['loadSharedQuestions $_cursor']),
    );
  });

  group('Try again', () {
    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'after the first page failed, loads it again',
      build: build,
      seed: () => const SharedQuestionsError(
          "We couldn't load the questions shared with you."),
      act: (bloc) => bloc.add(const SharedQuestionsRetried()),
      expect: () => [const SharedQuestionsLoading(), firstShown],
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'after a later page failed, loads that page',
      build: build,
      seed: () => firstShown.copyWith(loadMoreFailed: true),
      act: (bloc) => bloc.add(const SharedQuestionsRetried()),
      skip: 1,
      expect: () => [
        SharedQuestionsReady(
          questions: [..._firstPage.questions, ..._lastPage.questions],
        ),
      ],
    );
  });

  group('coming back', () {
    final bothShown = SharedQuestionsReady(
      questions: [..._firstPage.questions, ..._lastPage.questions],
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'with one page showing, reads it once, as it is now: a question removed '
      'or no longer shared goes, and one shared since comes in',
      build: build,
      setUp: () => repository.sharedPages = {
        null: SharedQuestionsPage(questions: [_shared('304'), _shared('303')]),
      },
      seed: () => firstShown,
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => [
        SharedQuestionsReady(questions: [_shared('304'), _shared('303')]),
      ],
      verify: (_) => expect(repository.calls, ['loadSharedQuestions']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'with two pages showing, reads the first page and then the next, in '
      'order, and changes nothing when nothing changed',
      build: build,
      seed: () => bothShown,
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => const <SharedQuestionsState>[],
      verify: (_) => expect(repository.calls,
          ['loadSharedQuestions', 'loadSharedQuestions $_cursor']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'keeps the place: as many rows come back as were showing, minus a '
      'question removed, plus one shared since on top, ending where the last '
      'page read ends',
      build: build,
      setUp: () => repository.sharedPages = {
        null: SharedQuestionsPage(
          questions: [_shared('304'), _shared('303')],
          nextCursor: _cursor,
        ),
        _cursor: SharedQuestionsPage(
          questions: [_shared('301'), _shared('300')],
          nextCursor: '9002',
        ),
        '9002': SharedQuestionsPage(questions: [_shared('299')]),
      },
      // Two pages showing, before 304 was shared and 302 removed.
      seed: () => SharedQuestionsReady(
        questions: [
          _shared('303'),
          _shared('302'),
          _shared('301'),
          _shared('300'),
        ],
        nextCursor: '9002',
      ),
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => [
        SharedQuestionsReady(
          questions: [
            _shared('304'),
            _shared('303'),
            _shared('301'),
            _shared('300'),
          ],
          nextCursor: '9002',
        ),
      ],
      verify: (_) => expect(repository.calls,
          ['loadSharedQuestions', 'loadSharedQuestions $_cursor']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'stops at a page with no rows, even one that names a next page',
      build: build,
      setUp: () => repository.sharedPages = {
        null: SharedQuestionsPage(
          questions: [_shared('303')],
          nextCursor: _cursor,
        ),
        _cursor: const SharedQuestionsPage(questions: [], nextCursor: _cursor),
      },
      seed: () => bothShown,
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => [
        SharedQuestionsReady(questions: [_shared('303')], nextCursor: _cursor),
      ],
      verify: (_) => expect(repository.calls,
          ['loadSharedQuestions', 'loadSharedQuestions $_cursor']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'is ignored while a next page is on its way',
      build: build,
      seed: () => firstShown.copyWith(isLoadingMore: true),
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => const <SharedQuestionsState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'a next page that answers after a refresh swapped the rows is dropped: '
      'it continues the old list',
      build: build,
      seed: () => firstShown,
      act: (bloc) async {
        final refreshRead = Completer<void>();
        final nextPageRead = Completer<void>();
        repository.holdInTurn.addAll([refreshRead, nextPageRead]);
        bloc.add(const SharedQuestionsRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedQuestionsMoreRequested());
        await Future<void>.delayed(Duration.zero);
        repository.sharedPages = {
          null: SharedQuestionsPage(
            questions: [_shared('304'), _shared('303')],
            nextCursor: '9101',
          ),
          _cursor: _lastPage,
        };

        refreshRead.complete();
        await Future<void>.delayed(Duration.zero);
        nextPageRead.complete();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        firstShown.copyWith(isLoadingMore: true),
        SharedQuestionsReady(
          questions: [_shared('304'), _shared('303')],
          nextCursor: '9101',
        ),
      ],
      verify: (_) => expect(repository.calls,
          ['loadSharedQuestions', 'loadSharedQuestions $_cursor']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'a refresh that answers after a next page came in is dropped, and the '
      'rows stay as the next page left them',
      build: build,
      seed: () => firstShown,
      act: (bloc) async {
        final refreshRead = Completer<void>();
        repository.holdInTurn.add(refreshRead);
        bloc.add(const SharedQuestionsRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedQuestionsMoreRequested());
        await Future<void>.delayed(Duration.zero);
        repository.sharedPages = {
          null:
              SharedQuestionsPage(questions: [_shared('304'), _shared('303')]),
        };

        refreshRead.complete();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [firstShown.copyWith(isLoadingMore: true), bothShown],
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'quietly: a refresh whose later page fails leaves the rows as they were',
      build: build,
      seed: () => bothShown,
      act: (bloc) async {
        final firstRead = Completer<void>();
        final laterRead = Completer<void>();
        repository.holdInTurn.addAll([firstRead, laterRead]);
        bloc.add(const SharedQuestionsRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        repository.sharedPages = {
          null: SharedQuestionsPage(
            questions: [_shared('304'), _shared('303')],
            nextCursor: _cursor,
          ),
          _cursor: _lastPage,
        };
        firstRead.complete();
        await Future<void>.delayed(Duration.zero);
        repository.failNext['loadSharedQuestions'] =
            NetworkFailure("We couldn't load the questions shared with you.");

        laterRead.complete();
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const <SharedQuestionsState>[],
      verify: (_) => expect(repository.calls,
          ['loadSharedQuestions', 'loadSharedQuestions $_cursor']),
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'shows the empty state once nothing is shared any more',
      build: build,
      setUp: () => repository.sharedPages = {
        null: const SharedQuestionsPage(questions: []),
      },
      seed: () => firstShown,
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => [const SharedQuestionsEmpty()],
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'quietly: a refresh that fails leaves the rows as they were',
      build: build,
      setUp: () => repository.failNext['loadSharedQuestions'] =
          NetworkFailure("We couldn't load the questions shared with you."),
      seed: () => firstShown,
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => const <SharedQuestionsState>[],
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'after a failed load, tries again as Try again does',
      build: build,
      seed: () => const SharedQuestionsError(
          "We couldn't load the questions shared with you."),
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => [const SharedQuestionsLoading(), firstShown],
    );

    blocTest<SharedQuestionsBloc, SharedQuestionsState>(
      'waits while the first page is still on its way',
      build: build,
      act: (bloc) => bloc.add(const SharedQuestionsRefreshRequested()),
      expect: () => const <SharedQuestionsState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );
  });
}
