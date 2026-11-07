import 'dart:async';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/data/datasource/question_sharing_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/model/shared_questions_response_model.dart';
import 'package:doormer/src/features/questions/data/model/solved_questions_response_model.dart';
import 'package:doormer/src/features/questions/data/repository/question_sharing_repository_impl.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:doormer/src/shared/friends/model/friend_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _sam = FriendSummaryModel(friendId: '7', nickname: 'Sam');

/// Answers like the API, and records what it was asked. Set [failure] to make
/// every call fail with it instead.
class _FakeRemoteDataSource implements QuestionSharingRemoteDataSource {
  Failure? failure;
  final List<String> calls = [];

  /// While set, a Remove or a Block waits for it before it answers, and fails
  /// if it fails.
  Completer<void>? changeAnswer;

  void _record(String call) {
    calls.add(call);
    final failure = this.failure;
    if (failure != null) throw failure;
  }

  @override
  Future<List<FriendSummaryModel>> friends() async {
    _record('friends');
    return const [_sam];
  }

  @override
  Future<List<FriendSummaryModel>> share(
    String questionId,
    List<String> friendIds,
  ) async {
    _record('share $questionId ${friendIds.join(',')}');
    return const [_sam];
  }

  @override
  Future<void> stopSharing(String questionId) async =>
      _record('stopSharing $questionId');

  @override
  Future<SharedQuestionsResponseModel> sharedQuestions({String? cursor}) async {
    _record('sharedQuestions $cursor');
    return SharedQuestionsResponseModel(
      questions: [
        SharedQuestionSummaryModel(
          question: SolvedQuestionSummaryModel(
            questionId: '501',
            topic: 'Algebra - Linear equations',
            method: 'Inverse operations',
            questionText: 'Solve x + 3 = 7',
            askedAt: DateTime.utc(2026, 10, 30),
          ),
          sharedBy: _sam,
          sharedAt: DateTime.utc(2026, 11, 1),
        ),
      ],
      nextCursor: '9001',
    );
  }

  @override
  Future<void> removeSharedQuestion(String questionId) async {
    _record('removeSharedQuestion $questionId');
    await changeAnswer?.future;
  }

  @override
  Future<void> report({
    required String friendId,
    required String questionId,
    required ReportReason reason,
    required String note,
  }) async =>
      _record('report $friendId $questionId ${reason.name} $note');

  @override
  Future<void> block(String friendId) async {
    _record('block $friendId');
    await changeAnswer?.future;
  }
}

const _samEntity = FriendSummary(friendId: '7', nickname: 'Sam');

void main() {
  late _FakeRemoteDataSource remote;
  late QuestionSharingRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemoteDataSource();
    repository = QuestionSharingRepositoryImpl(remoteDataSource: remote);
  });

  test('the friends, and who a question is shared with, come back as entities',
      () async {
    expect(await repository.loadFriends(), [_samEntity]);
    expect(await repository.share('501', ['7']), [_samEntity]);
    expect(remote.calls, ['friends', 'share 501 7']);
  });

  test('a page of Shared with me comes back in the domain terms', () async {
    final page = await repository.loadSharedQuestions(cursor: '9002');

    expect(page.questions.single.question.questionId, '501');
    expect(page.questions.single.sharedBy, _samEntity);
    expect(page.nextCursor, '9001');
    expect(remote.calls, ['sharedQuestions 9002']);
  });

  test('stopping, removing, reporting and blocking pass straight through',
      () async {
    await repository.stopSharing('501');
    await repository.removeSharedQuestion('502');
    await repository.reportSharedQuestion(
      friendId: '7',
      questionId: '502',
      reason: ReportReason.bullying,
      note: 'Mean.',
    );
    await repository.blockFriend('7');

    expect(remote.calls, [
      'stopSharing 501',
      'removeSharedQuestion 502',
      'report 7 502 bullying Mean.',
      'block 7',
    ]);
  });

  test('a failure passes through as it is', () async {
    final failure = RefusedFailure(404, "We couldn't find that student.");
    remote.failure = failure;

    await expectLater(repository.blockFriend('7'), throwsA(same(failure)));
  });

  group('a read of Shared with me', () {
    test('waits for a Remove on its way, and asks once it has answered',
        () async {
      final removal = remote.changeAnswer = Completer<void>();
      final removed = repository.removeSharedQuestion('301');

      final read = repository.loadSharedQuestions();
      await Future<void>.delayed(Duration.zero);
      expect(remote.calls, ['removeSharedQuestion 301']);

      removal.complete();
      await removed;
      await read;
      expect(
          remote.calls, ['removeSharedQuestion 301', 'sharedQuestions null']);
    });

    test(
        'still asks after a Remove that failed, which fails where it was '
        'asked for', () async {
      final failure = NetworkFailure("We couldn't remove that question.");
      final removal = remote.changeAnswer = Completer<void>();
      final removed = repository.removeSharedQuestion('301');

      final read = repository.loadSharedQuestions();
      await Future<void>.delayed(Duration.zero);
      expect(remote.calls, ['removeSharedQuestion 301']);

      removal.completeError(failure);
      await expectLater(removed, throwsA(same(failure)));
      expect((await read).questions.single.question.questionId, '501');
      expect(
          remote.calls, ['removeSharedQuestion 301', 'sharedQuestions null']);
    });

    test('waits for a Block on its way too', () async {
      final blocking = remote.changeAnswer = Completer<void>();
      final blocked = repository.blockFriend('7');

      final read = repository.loadSharedQuestions(cursor: '9002');
      await Future<void>.delayed(Duration.zero);
      expect(remote.calls, ['block 7']);

      blocking.complete();
      await blocked;
      await read;
      expect(remote.calls, ['block 7', 'sharedQuestions 9002']);
    });
  });
}
