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
  });

  group('Report', () {
    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'reports the friend with the question, then says it was sent',
      build: build,
      seed: () => opened,
      act: (bloc) => bloc
        ..add(const SharedQuestionReportOpened())
        ..add(const SharedQuestionReported(
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

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'a report that fails says why, and can be sent again',
      build: build,
      setUp: () => repository.failNext['reportSharedQuestion'] =
          RefusedFailure(404, "That question isn't shared with you any more."),
      seed: () => opened,
      act: (bloc) => bloc.add(const SharedQuestionReported(
        reason: ReportReason.other,
        note: '',
      )),
      skip: 1,
      expect: () => [
        opened.copyWith(
          errorMessage: "That question isn't shared with you any more.",
        ),
      ],
    );

    blocTest<FriendQuestionBloc, FriendQuestionState>(
      'opening the sheet again starts a new report',
      build: build,
      seed: () => opened.copyWith(reportStatus: QuestionReportStatus.sent),
      act: (bloc) => bloc.add(const SharedQuestionReportOpened()),
      expect: () => [opened],
    );

    group('a sheet reopened while a report is sending', () {
      /// Sends a report the fake holds open, then reopens the sheet. Answers
      /// with what lets the report through.
      Future<Completer<void>> sendThenReopen(FriendQuestionBloc bloc) async {
        final answer = repository.hold = Completer<void>();
        bloc.add(const SharedQuestionReported(
          reason: ReportReason.bullying,
          note: '',
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedQuestionReportOpened());
        await Future<void>.delayed(Duration.zero);
        return answer;
      }

      blocTest<FriendQuestionBloc, FriendQuestionState>(
        'keeps that report on its way, and sends no second one',
        build: build,
        seed: () => opened,
        act: (bloc) async {
          final answer = await sendThenReopen(bloc);
          bloc.add(const SharedQuestionReported(
            reason: ReportReason.other,
            note: '',
          ));
          await Future<void>.delayed(Duration.zero);
          answer.complete();
        },
        verify: (_) => expect(repository.calls, [
          'reportSharedQuestion 7 301 bullying ',
        ]),
      );

      blocTest<FriendQuestionBloc, FriendQuestionState>(
        'says when that report is sent',
        build: build,
        seed: () => opened,
        act: (bloc) async {
          final answer = await sendThenReopen(bloc);
          answer.complete();
        },
        expect: () => [
          opened.copyWith(reportStatus: QuestionReportStatus.sending),
          opened.copyWith(reportStatus: QuestionReportStatus.sent),
        ],
      );

      blocTest<FriendQuestionBloc, FriendQuestionState>(
        'says why that report failed, and can send again',
        build: build,
        setUp: () => repository.failNext['reportSharedQuestion'] =
            NetworkFailure("We couldn't send the report. Try again."),
        seed: () => opened,
        act: (bloc) async {
          final answer = await sendThenReopen(bloc);
          answer.complete();
        },
        expect: () => [
          opened.copyWith(reportStatus: QuestionReportStatus.sending),
          opened.copyWith(
            reportStatus: QuestionReportStatus.unsent,
            errorMessage: "We couldn't send the report. Try again.",
          ),
        ],
      );
    });
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
