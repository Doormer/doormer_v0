import 'package:doormer/src/features/questions/data/model/solved_questions_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_questions_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SolvedQuestionsResponseModel', () {
    test('reads every row and the next cursor', () {
      final page = SolvedQuestionsResponseModel.fromJson({
        'questions': [
          {
            'question_id': '42',
            'topic': 'Geometry - Area',
            'method': 'Area by decomposition',
            'question_text': 'Find the area of the paddock.',
            'asked_at': '2026-10-06T07:05:00Z',
            'thumbnail_url': 'https://example.test/thumbnail/42.jpg?sig=t',
            'photo_url': 'https://example.test/photo/42.jpg?sig=p',
          },
        ],
        'next_cursor': '42',
      }).toEntity();

      expect(
        page,
        SolvedQuestionsPage(
          questions: [
            SolvedQuestionSummary(
              questionId: '42',
              topic: 'Geometry - Area',
              method: 'Area by decomposition',
              questionText: 'Find the area of the paddock.',
              askedAt: DateTime.utc(2026, 10, 6, 7, 5),
              thumbnailUrl: 'https://example.test/thumbnail/42.jpg?sig=t',
              photoUrl: 'https://example.test/photo/42.jpg?sig=p',
            ),
          ],
          nextCursor: '42',
        ),
      );
    });

    test('a missing or empty link and missing details read as none', () {
      final summary = SolvedQuestionsResponseModel.fromJson({
        'questions': [
          {
            'question_id': '7',
            'asked_at': '2026-10-06T07:05:00Z',
            'photo_url': '',
          },
        ],
      }).toEntity().questions.single;

      expect(summary.thumbnailUrl, isNull);
      expect(summary.photoUrl, isNull);
      expect(summary.topic, '');
      expect(summary.method, '');
      expect(summary.questionText, '');
    });

    test('the last page has no next cursor', () {
      final page =
          SolvedQuestionsResponseModel.fromJson({'questions': []}).toEntity();

      expect(page.questions, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('a body with no list of questions cannot be read', () {
      expect(
        () => SolvedQuestionsResponseModel.fromJson({'questions': null}),
        throwsFormatException,
      );
    });

    test('a row with no question id cannot be read', () {
      expect(
        () => SolvedQuestionsResponseModel.fromJson({
          'questions': [
            {'asked_at': '2026-10-06T07:05:00Z'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('a row with no readable time cannot be read', () {
      expect(
        () => SolvedQuestionsResponseModel.fromJson({
          'questions': [
            {'question_id': '7', 'asked_at': 'yesterday'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
