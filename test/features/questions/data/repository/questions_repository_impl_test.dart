import 'dart:typed_data';

import 'package:doormer/src/features/questions/data/datasource/questions_local_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/model/answer_reward_model.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/data/model/quark_balance_model.dart';
import 'package:doormer/src/features/questions/data/model/solved_questions_response_model.dart';
import 'package:doormer/src/features/questions/data/repository/questions_repository_impl.dart';
import 'package:doormer/src/features/questions/domain/entity/answer_reward.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestionsRemoteDataSource implements QuestionsRemoteDataSource {
  int callCount = 0;
  Uint8List? imageBytes;
  String? contentType;
  String? idempotencyKey;
  String? revealedQuestionId;
  String? loadedQuestionId;
  String? solvedCursor;
  int balanceCalls = 0;

  @override
  Future<PhotoQuestionResponseModel> submitPhotoQuestion({
    required Uint8List imageBytes,
    required String contentType,
    required String idempotencyKey,
  }) async {
    callCount++;
    this.imageBytes = imageBytes;
    this.contentType = contentType;
    this.idempotencyKey = idempotencyKey;
    return PhotoQuestionResponseModel.fromJson({
      'status': 'timeout',
      'question_id': 'q_timeout',
    });
  }

  @override
  Future<AnswerRewardModel> revealAnswer(String questionId) async {
    revealedQuestionId = questionId;
    return const AnswerRewardModel(quarksEarned: 3, quarkBalance: 131);
  }

  @override
  Future<PhotoQuestionResponseModel> loadQuestion(String questionId) async {
    loadedQuestionId = questionId;
    return PhotoQuestionResponseModel.fromJson({
      'status': 'solved',
      'question_id': questionId,
      'note': 'The width is derived.',
      'topic': 'Geometry - Area',
      'method': 'Trigonometry and parallelogram area',
      'solution': {
        'schema_version': '3.0',
        'steps': [
          {'title': 'Find the width', 'body': []},
        ],
        'final_answer': {'body': []},
      },
    });
  }

  @override
  Future<SolvedQuestionsResponseModel> loadSolvedQuestions(
      {String? cursor}) async {
    solvedCursor = cursor;
    return SolvedQuestionsResponseModel.fromJson({
      'questions': [
        {
          'question_id': '41',
          'topic': 'Geometry - Area',
          'asked_at': '2026-10-06T07:05:00Z',
        },
      ],
      'next_cursor': '41',
    });
  }

  @override
  Future<QuarkBalanceModel> loadQuarkBalance() async {
    balanceCalls++;
    return const QuarkBalanceModel(quarkBalance: 128);
  }
}

class _FakeQuestionsLocalDataSource implements QuestionsLocalDataSource {
  int callCount = 0;

  @override
  Future<PhotoQuestionSolveOutcome> loadSampleSolution() async {
    callCount++;
    return const PhotoQuestionSolveOutcome(
      status: PhotoQuestionSolveStatus.solved,
      questionId: 'sample',
      solution: SolutionDocument(
        schemaVersion: '3.0',
        steps: [],
        finalAnswer: FinalAnswer(body: []),
      ),
    );
  }
}

void main() {
  test('sends raw bytes with content type and a fresh idempotency key',
      () async {
    final remoteDataSource = _FakeQuestionsRemoteDataSource();
    final repository = QuestionsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: _FakeQuestionsLocalDataSource(),
      idempotencyKeyFactory: () => 'uuid-1',
    );
    final bytes = Uint8List.fromList([9, 8, 7]);

    final outcome = await repository.submitPhotoQuestion(
      imageBytes: bytes,
      contentType: 'image/png',
    );

    expect(outcome.status, PhotoQuestionSolveStatus.timeout);
    expect(remoteDataSource.callCount, 1);
    expect(remoteDataSource.imageBytes, same(bytes));
    expect(remoteDataSource.contentType, 'image/png');
    expect(remoteDataSource.idempotencyKey, 'uuid-1');
  });

  test('loadSampleSolution delegates to the local datasource', () async {
    final local = _FakeQuestionsLocalDataSource();
    final repository = QuestionsRepositoryImpl(
      remoteDataSource: _FakeQuestionsRemoteDataSource(),
      localDataSource: local,
    );

    final outcome = await repository.loadSampleSolution();

    expect(local.callCount, 1);
    expect(outcome.questionId, 'sample');
  });

  test('loadQuestion delegates to the remote datasource and maps the outcome',
      () async {
    final remote = _FakeQuestionsRemoteDataSource();
    final repository = QuestionsRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _FakeQuestionsLocalDataSource(),
    );

    final outcome = await repository.loadQuestion('57');

    expect(remote.loadedQuestionId, '57');
    expect(outcome.questionId, '57');
    expect(outcome.note, 'The width is derived.');
    expect(outcome.topic, 'Geometry - Area');
    expect(outcome.method, 'Trigonometry and parallelogram area');
    expect(outcome.solution, isNotNull);
  });

  test('revealAnswer delegates to the remote datasource and maps the reward',
      () async {
    final remote = _FakeQuestionsRemoteDataSource();
    final repository = QuestionsRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _FakeQuestionsLocalDataSource(),
    );

    final reward = await repository.revealAnswer('123');

    expect(remote.revealedQuestionId, '123');
    expect(
      reward,
      const AnswerReward(quarksEarned: 3, quarkBalance: 131),
    );
  });

  test('loadQuarkBalance delegates to the remote datasource', () async {
    final remote = _FakeQuestionsRemoteDataSource();
    final repository = QuestionsRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _FakeQuestionsLocalDataSource(),
    );

    final balance = await repository.loadQuarkBalance();

    expect(remote.balanceCalls, 1);
    expect(balance, 128);
  });

  test('loadSolvedQuestions passes the cursor and reads the page', () async {
    final remote = _FakeQuestionsRemoteDataSource();
    final repository = QuestionsRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _FakeQuestionsLocalDataSource(),
    );

    final page = await repository.loadSolvedQuestions(cursor: '42');

    expect(remote.solvedCursor, '42');
    expect(page.questions.single.questionId, '41');
    expect(page.questions.single.topic, 'Geometry - Area');
    expect(page.nextCursor, '41');
  });
}
