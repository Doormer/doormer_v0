import 'package:doormer/src/features/questions/data/model/photo_question_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/photo_question_solve_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoQuestionResponseModel', () {
    test('parses solved envelope with solution document', () {
      final model = PhotoQuestionResponseModel.fromJson({
        'status': 'solved',
        'question_id': 'q_123',
        'solution': {
          'schema_version': '1.0',
          'steps': [
            {
              'title': 'Differentiate',
              'body': [
                {'type': 'text', 'value': 'Use the power rule.'},
                {'type': 'math', 'latex': '2x', 'alt': 'two x'},
              ],
            },
          ],
          'final_answer': {
            'body': [
              {'type': 'math', 'latex': '2x', 'alt': 'two x'},
            ],
          },
        },
      });

      final entity = model.toEntity();

      expect(entity.status, PhotoQuestionSolveStatus.solved);
      expect(entity.questionId, 'q_123');
      expect(entity.solution, isNotNull);
      expect(entity.solution!.schemaVersion, '1.0');
      expect(entity.solution!.steps.single.title, 'Differentiate');
      expect(
          entity.solution!.steps.single.body.first, isA<TextSolutionSegment>());
      expect(
          entity.solution!.steps.single.body.last, isA<MathSolutionSegment>());
      expect(
          entity.solution!.finalAnswer.body.single, isA<MathSolutionSegment>());
    });

    test('parses non-solved envelope with null solution', () {
      final model = PhotoQuestionResponseModel.fromJson({
        'status': 'unreadable',
        'question_id': 'q_456',
      });

      final entity = model.toEntity();

      expect(entity.status, PhotoQuestionSolveStatus.unreadable);
      expect(entity.questionId, 'q_456');
      expect(entity.solution, isNull);
    });
  });
}
