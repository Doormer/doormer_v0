import 'package:doormer/src/features/questions/data/model/shared_questions_response_model.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_question_summary.dart';
import 'package:doormer/src/features/questions/domain/entity/shared_questions_page.dart';
import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// A row as the API sends it: a solved question's fields, and who shared it
/// and when, all at one level.
Map<String, Object?> _row({Object? sharedBy, Object? sharedAt}) => {
      'question_id': '501',
      'topic': 'Algebra - Linear equations',
      'method': 'Inverse operations',
      'question_text': 'Solve x + 3 = 7',
      'asked_at': '2026-10-30T08:12:09Z',
      'thumbnail_url': 'https://example.test/thumbnail/501.jpg?sig=t',
      'photo_url': 'https://example.test/photo/501.jpg?sig=p',
      'shared_by': sharedBy ?? {'friend_id': '7', 'nickname': 'Sam'},
      'shared_at': sharedAt ?? '2026-11-01T05:30:00Z',
    };

void main() {
  test('reads each question, who shared it and when, and the next cursor', () {
    final page = SharedQuestionsResponseModel.fromJson({
      'questions': [_row()],
      'next_cursor': '9001',
    }).toEntity();

    expect(
      page,
      SharedQuestionsPage(
        questions: [
          SharedQuestionSummary(
            question: SolvedQuestionSummary(
              questionId: '501',
              topic: 'Algebra - Linear equations',
              method: 'Inverse operations',
              questionText: 'Solve x + 3 = 7',
              askedAt: DateTime.utc(2026, 10, 30, 8, 12, 9),
              thumbnailUrl: 'https://example.test/thumbnail/501.jpg?sig=t',
              photoUrl: 'https://example.test/photo/501.jpg?sig=p',
            ),
            sharedBy: const FriendSummary(friendId: '7', nickname: 'Sam'),
            sharedAt: DateTime.utc(2026, 11, 1, 5, 30),
          ),
        ],
        nextCursor: '9001',
      ),
    );
  });

  test('the last page has no next cursor', () {
    final page =
        SharedQuestionsResponseModel.fromJson({'questions': []}).toEntity();

    expect(page.questions, isEmpty);
    expect(page.nextCursor, isNull);
  });

  test('a body with no list of questions cannot be read', () {
    expect(
      () => SharedQuestionsResponseModel.fromJson({'questions': null}),
      throwsFormatException,
    );
  });

  test('a row that says nothing of who shared it, or when, cannot be read', () {
    expect(
      () => SharedQuestionsResponseModel.fromJson({
        'questions': [
          {..._row(), 'shared_by': null},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => SharedQuestionsResponseModel.fromJson({
        'questions': [_row(sharedAt: 'yesterday')],
      }),
      throwsFormatException,
    );
  });
}
