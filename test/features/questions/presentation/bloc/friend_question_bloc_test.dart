import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/usecase/block_friend_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/remove_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/domain/usecase/report_shared_question_usecase.dart';
import 'package:doormer/src/features/questions/presentation/bloc/friend_question_bloc.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_question_sharing_repository.dart';

void main() {
  setUpAll(AppLogger.disable);

  late FakeQuestionSharingRepository repository;

  setUp(() => repository = FakeQuestionSharingRepository());

  FriendQuestionBloc build() => FriendQuestionBloc(
        removeSharedQuestion: RemoveSharedQuestionUseCase(repository),
        reportSharedQuestion: ReportSharedQuestionUseCase(repository),
        blockFriend: BlockFriendUseCase(repository),
      );

  /// Sam's question, as the reader opened it.
  const opened = FriendQuestionState(questionId: '301', sharedBy: sam);

  blocTest<FriendQuestionBloc, FriendQuestionState>(
    'starts with the friend who shared the question',
    build: build,
    act: (bloc) =>
        bloc.add(const FriendQuestionStarted(questionId: '301', sharedBy: sam)),
    expect: () => [opened],
  );

  group('Remove', () {
    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'takes the question out of Shared with me, and leaves it',
      build: build,
      seed: () => opened,
      act: (bloc) => bloc.add(const SharedQuestionRemoved()),
      expect: () => [
        opened.copyWith(isRemoving: true),
        opened.copyWith(exit: FriendQuestionExit.removed),
      ],
      verify: (_) => expect(repository.calls, ['removeSharedQuestion 301']),
    );

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'a removal that fails says why, and stays',
      build: build,
      setUp: () => repository.failNext['removeSharedQuestion'] =
          NetworkFailure("We couldn't remove that question. Try again."),
      seed: () => opened,
      act: (bloc) => bloc.add(const SharedQuestionRemoved()),
      skip: 1,
      expect: () => [
        opened.copyWith(
          errorMessage: "We couldn't remove that question. Try again.",
        ),
      ],
    );

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'waits for a report on its way, so the report reaches the team before '
      'the removal ends the share it is about',
      build: build,
      seed: () => opened,
      act: (bloc) async {
        final answer = repository.hold = Completer<void>();
        bloc.add(const SharedQuestionReported(
          reason: ReportReason.bullying,
          note: '',
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedQuestionRemoved());
        await Future<void>.delayed(Duration.zero);
        expect(repository.calls, ['reportSharedQuestion 7 301 bullying '],
            reason: 'the removal waits until the report has its answer');
        answer.complete();
      },
      expect: () => [
        opened.copyWith(reportStatus: QuestionReportStatus.sending),
        opened.copyWith(
          reportStatus: QuestionReportStatus.sending,
          isRemoving: true,
        ),
        opened.copyWith(
          reportStatus: QuestionReportStatus.sent,
          isRemoving: true,
        ),
        opened.copyWith(
          reportStatus: QuestionReportStatus.sent,
          exit: FriendQuestionExit.removed,
        ),
      ],
      verify: (_) => expect(repository.calls, [
        'reportSharedQuestion 7 301 bullying ',
        'removeSharedQuestion 301',
      ]),
    );
  });

  group('Report', () {
    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'reports the friend with the question, then says it was sent',
      build: build,
      seed: () => opened,
      act: (bloc) => bloc.add(const SharedQuestionReported(
        reason: ReportReason.bullying,
        note: 'Wrote something mean on it.',
      )),
      expect: () => [
        opened.copyWith(reportStatus: QuestionReportStatus.sending),
        opened.copyWith(reportStatus: QuestionReportStatus.sent),
      ],
      verify: (_) => expect(repository.calls, [
        'reportSharedQuestion 7 301 bullying Wrote something mean on it.',
      ]),
    );

    for (final (why, failure) in [
      (
        'with no connection',
        NetworkFailure("We couldn't send the report. Try again."),
      ),
      (
        'with a server error',
        ServerFailure("We couldn't send the report. Try again."),
      ),
      (
        'with friends turned off',
        RefusedFailure(403, 'Friends is turned off for your account.'),
      ),
    ]) {
      blocTest<FriendQuestionBloc, FriendQuestionState>(
        'a report that fails $why says why, and can be sent again',
        build: build,
        setUp: () => repository.failNext['reportSharedQuestion'] = failure,
        seed: () => opened,
        act: (bloc) => bloc.add(const SharedQuestionReported(
          reason: ReportReason.other,
          note: '',
        )),
        skip: 1,
        expect: () => [opened.copyWith(errorMessage: failure.message)],
      );
    }

    for (final (why, status, words) in [
      (
        'because the share has ended',
        404,
        "That question isn't shared with you any more.",
      ),
      (
        'for the day',
        429,
        "You've done that a lot today. Try again tomorrow.",
      ),
    ]) {
      blocTest<FriendQuestionBloc, FriendQuestionState>(
        'a report refused $why ($status) says why, and is refused for good, so '
        'the student can block without it',
        build: build,
        setUp: () => repository.failNext['reportSharedQuestion'] =
            RefusedFailure(status, words),
        seed: () => opened,
        act: (bloc) => bloc.add(const SharedQuestionReported(
          reason: ReportReason.other,
          note: '',
        )),
        skip: 1,
        expect: () => [
          opened.copyWith(isReportRefusedForGood: true, errorMessage: words),
        ],
      );
    }

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'a report refused for good stays so, even when sending it again fails '
      'otherwise',
      build: build,
      setUp: () => repository.failNext['reportSharedQuestion'] =
          NetworkFailure("We couldn't send the report. Try again."),
      seed: () => opened.copyWith(isReportRefusedForGood: true),
      act: (bloc) => bloc.add(const SharedQuestionReported(
        reason: ReportReason.other,
        note: '',
      )),
      skip: 1,
      expect: () => [
        opened.copyWith(
          isReportRefusedForGood: true,
          errorMessage: "We couldn't send the report. Try again.",
        ),
      ],
    );

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'a second report while one is on its way sends nothing, and the first '
      'still gets its answer',
      build: build,
      seed: () => opened,
      act: (bloc) async {
        final answer = repository.hold = Completer<void>();
        bloc.add(const SharedQuestionReported(
          reason: ReportReason.bullying,
          note: '',
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedQuestionReported(
          reason: ReportReason.other,
          note: '',
        ));
        await Future<void>.delayed(Duration.zero);
        answer.complete();
      },
      expect: () => [
        opened.copyWith(reportStatus: QuestionReportStatus.sending),
        opened.copyWith(reportStatus: QuestionReportStatus.sent),
      ],
      verify: (_) => expect(repository.calls, [
        'reportSharedQuestion 7 301 bullying ',
      ]),
    );

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'a report sent while a removal is on its way sends nothing: the removal '
      'ends the share the report is about',
      build: build,
      seed: () => opened.copyWith(isRemoving: true),
      act: (bloc) => bloc.add(const SharedQuestionReported(
        reason: ReportReason.bullying,
        note: '',
      )),
      expect: () => const <FriendQuestionState>[],
      verify: (_) => expect(repository.calls, isEmpty),
    );
  });

  group('Block', () {
    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'blocks the friend who shared it, and leaves the question',
      build: build,
      seed: () => opened.copyWith(reportStatus: QuestionReportStatus.sent),
      act: (bloc) => bloc.add(const FriendBlocked()),
      expect: () => [
        opened.copyWith(
          reportStatus: QuestionReportStatus.sent,
          isBlocking: true,
        ),
        opened.copyWith(
          reportStatus: QuestionReportStatus.sent,
          exit: FriendQuestionExit.blocked,
        ),
      ],
      verify: (_) => expect(repository.calls, ['blockFriend 7']),
    );

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'a second Block while one is on its way sends nothing, and the first '
      'still gets its answer',
      build: build,
      seed: () => opened.copyWith(reportStatus: QuestionReportStatus.sent),
      act: (bloc) async {
        final answer = repository.hold = Completer<void>();
        bloc.add(const FriendBlocked());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FriendBlocked());
        await Future<void>.delayed(Duration.zero);
        answer.complete();
      },
      expect: () => [
        opened.copyWith(
          reportStatus: QuestionReportStatus.sent,
          isBlocking: true,
        ),
        opened.copyWith(
          reportStatus: QuestionReportStatus.sent,
          exit: FriendQuestionExit.blocked,
        ),
      ],
      verify: (_) => expect(repository.calls, ['blockFriend 7']),
    );

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'a block that fails says why, and stays',
      build: build,
      setUp: () => repository.failNext['blockFriend'] =
          RefusedFailure(404, "We couldn't find that student."),
      seed: () => opened,
      act: (bloc) => bloc.add(const FriendBlocked()),
      skip: 1,
      expect: () => [
        opened.copyWith(errorMessage: "We couldn't find that student."),
      ],
    );
  });
}
