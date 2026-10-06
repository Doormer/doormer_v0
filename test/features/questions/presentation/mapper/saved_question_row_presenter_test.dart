import 'package:doormer/src/features/questions/domain/entity/solved_question_summary.dart';
import 'package:doormer/src/features/questions/presentation/mapper/saved_question_row_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tuesday 6 October 2026, 8pm, in the device's own time zone. Every time
/// below is local too, so the labels hold in any time zone.
final _now = DateTime(2026, 10, 6, 20);

void main() {
  group('savedQuestionTitle', () {
    test('shows the area and topic with a middle dot', () {
      expect(savedQuestionTitle('Geometry - Area'), 'Geometry · Area');
    });

    test('keeps a topic with no area as it is', () {
      expect(savedQuestionTitle('Photosynthesis'), 'Photosynthesis');
    });

    test('says Question when the solver named no topic', () {
      expect(savedQuestionTitle(''), 'Question');
      expect(savedQuestionTitle('   '), 'Question');
    });
  });

  group('savedQuestionDetail', () {
    test('shows the first line of the question text', () {
      expect(
        savedQuestionDetail(
          questionText: 'Solve 3x + 5 = 20\nShow your working.',
          method: 'Inverse operations',
        ),
        'Solve 3x + 5 = 20',
      );
    });

    test('skips blank lines at the start', () {
      expect(
        savedQuestionDetail(
          questionText: '\n   \n  Find x  ',
          method: 'Angles in a triangle',
        ),
        'Find x',
      );
    });

    test('shows the method when the photo had no text', () {
      expect(
        savedQuestionDetail(questionText: '', method: "Pythagoras' theorem"),
        "Pythagoras' theorem",
      );
      expect(
        savedQuestionDetail(
          questionText: ' \n ',
          method: "Pythagoras' theorem",
        ),
        "Pythagoras' theorem",
      );
    });

    test('is empty when there is neither', () {
      expect(savedQuestionDetail(questionText: '', method: ''), '');
    });
  });

  group('askedLabel', () {
    String label(DateTime askedAt) => askedLabel(askedAt, now: _now);

    test('says Today for earlier the same day', () {
      expect(label(DateTime(2026, 10, 6, 0, 5)), 'Today');
    });

    test('says Today for a time just ahead of the clock', () {
      expect(label(DateTime(2026, 10, 7, 0, 1)), 'Today');
    });

    test('says Yesterday for the day before, however late', () {
      expect(label(DateTime(2026, 10, 5, 23, 59)), 'Yesterday');
    });

    test('names the weekday from two to six days ago', () {
      expect(label(DateTime(2026, 10, 4, 12)), 'Sun');
      expect(label(DateTime(2026, 9, 30, 9)), 'Wed');
    });

    test('gives the day and month from a week ago', () {
      expect(label(DateTime(2026, 9, 29, 9)), '29 Sep');
      expect(label(DateTime(2026, 1, 3)), '3 Jan');
    });

    test('adds the year for an earlier year', () {
      expect(label(DateTime(2025, 12, 30)), '30 Dec 2025');
    });

    test('measures a UTC time in the device time zone', () {
      // The API sends UTC. A question asked late yesterday, local time, may
      // already be today in UTC, and must still read as yesterday.
      expect(label(DateTime(2026, 10, 5, 23, 30).toUtc()), 'Yesterday');
    });
  });

  test('savedQuestionRowContent puts the three together', () {
    final content = savedQuestionRowContent(
      SolvedQuestionSummary(
        questionId: '42',
        topic: 'Geometry - Area',
        method: 'Area by decomposition',
        questionText: 'Find the area of the paddock.',
        askedAt: DateTime(2026, 10, 6, 9),
      ),
      now: _now,
    );

    expect(content.title, 'Geometry · Area');
    expect(content.detail, 'Find the area of the paddock.');
    expect(content.askedLabel, 'Today');
  });
}
