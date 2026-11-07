import 'package:dio/dio.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/features/profile/data/datasource/friends_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/question_sharing_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/shared/friends/entity/report_reason.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _refused(int status, String message) => throwsA(isA<RefusedFailure>()
    .having((f) => f.statusCode, 'statusCode', status)
    .having((f) => f.message, 'message', message));

void main() {
  // The worked solution is read from the app's assets.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLogger.disable);

  /// The fake's data, which a test can change where no request can.
  late FakeBackendState state;
  late Dio dio;
  late QuestionSharingRemoteDataSource sharing;
  late QuestionsRemoteDataSource questions;
  late FriendsRemoteDataSource friends;

  setUp(() {
    final now = DateTime.utc(2026, 11, 1, 9);
    state = FakeBackendState.starting(now: now);
    dio = Dio(BaseOptions(
      baseUrl: 'https://api.test',
      headers: {'Authorization': 'Bearer a-student-token'},
    ))
      ..httpClientAdapter = fakeBackend(
        state: state,
        delay: Duration.zero,
        solveDelay: Duration.zero,
        clock: () => now,
      );
    sharing = QuestionSharingRemoteDataSourceImpl(dio: dio);
    questions = QuestionsRemoteDataSourceImpl(dio: dio);
    friends = FriendsRemoteDataSourceImpl(dio: dio);
  });

  /// Shared with me, as question IDs and who shared each, newest share first.
  Future<List<String>> sharedWithMe() async => [
        for (final shared in (await sharing.sharedQuestions()).questions)
          '${shared.question.questionId} ${shared.sharedBy.nickname}',
      ];

  /// Who the student's own question [questionId] is shared with.
  Future<List<String>> sharedWith(String questionId) async => [
        for (final friend
            in (await questions.loadQuestion(questionId)).sharedWith)
          friend.nickname,
      ];

  test('Shared with me starts with what Sam and Alex shared, newest first',
      () async {
    final page = (await sharing.sharedQuestions()).toEntity();

    expect(await sharedWithMe(), ['301 Sam', '302 Alex', '303 Sam']);
    expect(page.nextCursor, isNull);
    final sams = page.questions.first;
    expect(sams.question.topic, 'Algebra - Simultaneous equations');
    expect(sams.question.questionText, 'Solve 2x + y = 7 and x - y = 2.');
    expect(sams.sharedBy.picture?.cardId, 'flint');
    expect(sams.sharedAt, DateTime.utc(2026, 11, 1, 7));
  });

  test('Shared with me comes 20 at a time, and its cursor brings the rest',
      () async {
    // Alex shares 20 more questions, a minute apart, after the first three.
    for (var minute = 1; minute <= 20; minute++) {
      final questionId = '${400 + minute}';
      state.friends
        ..friendQuestions.add(FakeFriendQuestion(
          askedById: '202',
          question: FakeSolvedQuestion(
            id: questionId,
            topic: 'Number - Fractions',
            method: 'Common denominators',
            questionText: 'Add the fractions in question $minute.',
            askedAt: DateTime.utc(2026, 10, 30),
          ),
        ))
        ..share(
          questionId,
          fromId: '202',
          toId: FakeFriends.studentId,
          at: DateTime.utc(2026, 11, 1, 8, minute),
        );
    }

    final first = (await sharing.sharedQuestions()).toEntity();
    final rest =
        (await sharing.sharedQuestions(cursor: first.nextCursor)).toEntity();

    expect(first.questions, hasLength(20));
    expect(first.nextCursor, isNotNull);
    expect(rest.nextCursor, isNull);
    // All 23, newest share first, each once.
    expect(
      [
        for (final shared in [...first.questions, ...rest.questions])
          shared.question.questionId,
      ],
      [
        for (var minute = 20; minute >= 1; minute--) '${400 + minute}',
        '301',
        '302',
        '303',
      ],
    );
  });

  test("Sam's question opens with who shared it, and its answer pays nothing",
      () async {
    final opened = (await questions.loadQuestion('301')).toEntity();

    expect(opened.sharedBy?.nickname, 'Sam');
    expect(opened.sharedWith, isEmpty);
    expect(opened.solution, isNotNull);
    await expectLater(questions.revealAnswer('301'), throwsA(isA<Failure>()));
  });

  test("the student's own question says who it is shared with", () async {
    expect(await sharedWith('102'), ['Sam']);
    expect(await sharedWith('101'), isEmpty);
  });

  test('sharing answers everyone the question is now shared with, by nickname',
      () async {
    final first = await sharing.share('101', ['201', '202']);
    final again = await sharing.share('101', ['202']);

    expect([for (final friend in first) friend.nickname], ['Alex', 'Sam']);
    expect([for (final friend in again) friend.nickname], ['Alex', 'Sam']);
    expect(await sharedWith('101'), ['Alex', 'Sam']);
  });

  test('sharing with anyone who is not a friend shares with no one', () async {
    await expectLater(
      sharing.share('101', ['201', '204']),
      _refused(
          404, 'Your friends list changed. Check the ticks and send again.'),
    );

    expect(await sharedWith('101'), isEmpty);
  });

  test("only the student's own question can be shared", () async {
    await sharing.share('103', ['202']);

    await expectLater(
      sharing.share('301', ['202']),
      _refused(
          404, 'Your friends list changed. Check the ticks and send again.'),
    );
    expect(await sharedWith('103'), ['Alex']);
  });

  test("Stop sharing takes it out of every friend's list", () async {
    await sharing.stopSharing('102');

    expect(await sharedWith('102'), isEmpty);
  });

  test('Remove takes a question out of Shared with me', () async {
    await sharing.removeSharedQuestion('302');

    expect(await sharedWithMe(), ['301 Sam', '303 Sam']);
  });

  test('removing a friend ends every share between the two, both ways',
      () async {
    await friends.remove('201');

    expect(await sharedWithMe(), ['302 Alex']);
    expect(await sharedWith('102'), isEmpty);
    await expectLater(questions.loadQuestion('301'), throwsA(isA<Failure>()));
  });

  test('blocking a friend from a question they shared ends the shares too',
      () async {
    await sharing.block('202');

    expect(await sharedWithMe(), ['301 Sam', '303 Sam']);
  });

  test('a report carries a question the student was sent, and only one',
      () async {
    await sharing.report(
      friendId: '201',
      questionId: '301',
      reason: ReportReason.bullying,
      note: '',
    );

    await expectLater(
      sharing.report(
        friendId: '201',
        questionId: '302',
        reason: ReportReason.other,
        note: '',
      ),
      _refused(404, "That question isn't shared with you any more."),
    );
  });

  for (final (ending, endTheShare) in <(String, Future<void> Function())>[
    (
      'he stops sharing it',
      () async {
        // Sam's own Stop sharing, which no request of Kai's can send.
        state.friends.shares.removeWhere(
            (share) => share.questionId == '301' && share.fromId == '201');
      },
    ),
    (
      'Kai removes him, even if they are friends again',
      () async {
        await friends.remove('201');
        // The fake's other students never answer a request.
        state.friends.friendIds.add('201');
      },
    ),
    (
      'Kai blocks him, even if they are friends again',
      () async {
        await friends.block('201');
        await friends.unblock('201');
        state.friends.friendIds.add('201');
      },
    ),
  ]) {
    test(
        "a report about Sam's question is refused, and none is kept, once "
        '$ending', () async {
      await endTheShare();

      await expectLater(
        sharing.report(
          friendId: '201',
          questionId: '301',
          reason: ReportReason.bullying,
          note: '',
        ),
        _refused(404, "That question isn't shared with you any more."),
      );
      expect(state.friends.reports, isEmpty);
    });
  }

  test('before setup, Shared with me is empty, and sharing asks for friends',
      () async {
    await dio.post<Object?>('/v1/signup', data: {
      'email': 'new@example.com',
      'password': 'secret123',
    });

    expect(await sharedWithMe(), isEmpty);
    await expectLater(
      sharing.share('101', ['201']),
      _refused(409, 'Add friends on Profile to share questions with them.'),
    );
  });
}
