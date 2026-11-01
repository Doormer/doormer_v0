import 'package:doormer/src/features/questions/data/model/daily_limit_model.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the questions left and the reset as an instant', () {
    final model = DailyLimitModel.fromJson({
      'questions_left': 3,
      'resets_at': '2026-10-19T00:00:00+13:00',
    });

    expect(model.questionsLeft, 3);
    expect(model.resetsAt.isAtSameMomentAs(DateTime.utc(2026, 10, 18, 11)),
        isTrue);
  });

  test('a count below zero reads as none left', () {
    final model = DailyLimitModel.fromJson({
      'questions_left': -2,
      'resets_at': '2026-10-19T00:00:00+13:00',
    });

    expect(model.questionsLeft, 0);
  });

  test('a daily limit with a field missing or unreadable is refused', () {
    expect(
      () =>
          DailyLimitModel.fromJson({'resets_at': '2026-10-19T00:00:00+13:00'}),
      throwsFormatException,
    );
    expect(
      () => DailyLimitModel.fromJson(
          {'questions_left': 3, 'resets_at': 'tomorrow'}),
      throwsFormatException,
    );
    expect(
      () => DailyLimitModel.fromJson(
          {'questions_left': 3, 'resets_at': 1760785200}),
      throwsFormatException,
    );
    expect(
      () => DailyLimitModel.fromJson(
          {'questions_left': '3', 'resets_at': '2026-10-19T00:00:00+13:00'}),
      throwsFormatException,
    );
  });

  test('becomes the entity Solve shows, which knows when none are left', () {
    final entity = DailyLimitModel.fromJson({
      'questions_left': 0,
      'resets_at': '2026-10-19T00:00:00+13:00',
    }).toEntity();

    expect(entity,
        DailyLimit(questionsLeft: 0, resetsAt: DateTime.utc(2026, 10, 18, 11)));
    expect(entity.isReached, isTrue);
  });
}
