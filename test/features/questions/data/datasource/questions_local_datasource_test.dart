import 'dart:convert';

import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/features/questions/data/datasource/questions_local_datasource.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBundle extends CachingAssetBundle {
  final Map<String, String> files;

  _FakeBundle(this.files);

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) {
      throw FlutterError('Asset not found: $key');
    }
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and parses the bundled mock solution', () async {
    final bundle = _FakeBundle({
      QuestionsLocalDataSourceImpl.mockAssetPath: jsonEncode({
        'status': 'solved',
        'question_id': '57',
        'note': 'derived width',
        'solution': {
          'schema_version': '3.0',
          'steps': [
            {'title': 'Step one', 'body': [], 'rationale': []},
          ],
          'final_answer': {'body': []},
        },
      }),
    });

    final datasource = QuestionsLocalDataSourceImpl(bundle: bundle);
    final outcome = await datasource.loadSampleSolution();

    expect(outcome.status, PhotoQuestionSolveStatus.solved);
    expect(outcome.questionId, '57');
    expect(outcome.solution!.steps.single.title, 'Step one');
  });

  test('throws DatabaseFailure with a user-facing message when the asset is missing',
      () async {
    final datasource = QuestionsLocalDataSourceImpl(bundle: _FakeBundle({}));

    await expectLater(
      datasource.loadSampleSolution(),
      throwsA(
        isA<DatabaseFailure>().having(
          (f) => f.message,
          'message',
          'We could not open the sample solution.',
        ),
      ),
    );
  });
}
