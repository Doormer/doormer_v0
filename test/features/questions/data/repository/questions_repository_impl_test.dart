import 'dart:typed_data';

import 'package:doormer/src/features/questions/data/datasource/questions_local_datasource.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_remote_datasource.dart';
import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/data/repository/questions_repository_impl.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:doormer/src/features/questions/domain/entity/quest_profile.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestionsRemoteDataSource implements QuestionsRemoteDataSource {
  int callCount = 0;
  Uint8List? imageBytes;
  String? contentType;
  String? idempotencyKey;

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

  @override
  Future<QuestProfile> loadQuestProfile() async => const QuestProfile(
        bankedXp: 120,
        streakDays: 3,
        topic: 'Geometry - Area',
        questionTitle: 'Road through a field',
      );
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
}
