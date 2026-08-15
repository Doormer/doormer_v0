import 'dart:convert';
import 'dart:io';

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

    test('parses a schema 3.0 envelope with visual segments and rationale', () {
      final model = PhotoQuestionResponseModel.fromJson({
        'status': 'solved',
        'question_id': '57',
        'note': 'The printed rectangle width is not given directly.',
        'solution': {
          'schema_version': '3.0',
          'approach': {
            'body': [
              {'type': 'text', 'value': 'Frozen question-data ledger.'},
            ],
          },
          'steps': [
            {
              'title': "Find the road's slope",
              'body': [
                {'type': 'text', 'value': 'Let theta be the angle.'},
                {
                  'type': 'visual',
                  'media_type': 'image/png',
                  'url': 'https://example.test/step1.png',
                  'width': 1600,
                  'height': 1067,
                  'caption': 'The 5 m and 4 m measurements determine the angle.',
                  'alt': 'A right triangle.',
                },
                {'type': 'math', 'latex': r'\tan\theta=\frac{3}{4}', 'alt': 'tan'},
              ],
              'rationale': [
                {'type': 'text', 'value': 'The 5 m segment is the hypotenuse.'},
              ],
            },
          ],
          'verification': {
            'body': [
              {'type': 'text', 'value': 'Accepted givens and their roles.'},
            ],
          },
          'final_answer': {
            'body': [
              {'type': 'math', 'latex': r'\boxed{160}', 'alt': '160'},
            ],
          },
        },
      });

      final entity = model.toEntity();
      final step = entity.solution!.steps.single;
      final visual = step.body[1] as VisualSolutionSegment;

      expect(entity.note, 'The printed rectangle width is not given directly.');
      expect(entity.solution!.schemaVersion, '3.0');
      expect(entity.solution!.approach.body.single, isA<TextSolutionSegment>());
      expect(entity.solution!.verification.body.single, isA<TextSolutionSegment>());
      expect(step.rationale.single, isA<TextSolutionSegment>());
      expect(visual.mediaType, 'image/png');
      expect(visual.url, 'https://example.test/step1.png');
      expect(visual.width, 1600);
      expect(visual.height, 1067);
      expect(visual.caption, 'The 5 m and 4 m measurements determine the angle.');
      expect(visual.alt, 'A right triangle.');
    });

    test('skips unknown segment types instead of throwing', () {
      final model = PhotoQuestionResponseModel.fromJson({
        'status': 'solved',
        'question_id': 'q_789',
        'solution': {
          'schema_version': '4.0',
          'steps': [
            {
              'title': 'Forward compatible',
              'body': [
                {'type': 'hologram', 'payload': 'from the future'},
                {'type': 'text', 'value': 'This still renders.'},
              ],
            },
          ],
          'final_answer': {'body': []},
        },
      });

      final body = model.toEntity().solution!.steps.single.body;

      expect(body, hasLength(1));
      expect((body.single as TextSolutionSegment).value, 'This still renders.');
    });

    test('parses the bundled schema 3.0 mock asset end to end', () {
      final raw = File('assets/mock/mock_question_response.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final entity = PhotoQuestionResponseModel.fromJson(json).toEntity();
      final solution = entity.solution!;

      expect(entity.status, PhotoQuestionSolveStatus.solved);
      expect(solution.schemaVersion, '3.0');
      expect(solution.steps, hasLength(3));
      expect(solution.approach.body, isNotEmpty);
      expect(solution.verification.body, isNotEmpty);
      expect(solution.finalAnswer.body.single, isA<MathSolutionSegment>());
      for (final step in solution.steps) {
        expect(step.rationale, isNotEmpty, reason: 'every 3.0 step has rationale');
        expect(
          step.body.whereType<VisualSolutionSegment>(),
          hasLength(1),
          reason: 'every 3.0 step carries exactly one diagram',
        );
      }
    });
  });
}
