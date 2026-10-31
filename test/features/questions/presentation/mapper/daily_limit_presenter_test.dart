import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/presentation/bloc/daily_limit_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/daily_limit_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

DailyLimitKnown _known(int questionsLeft, {DateTime? resetsAt}) =>
    DailyLimitKnown(DailyLimit(
      questionsLeft: questionsLeft,
      resetsAt: resetsAt ?? DateTime(2026, 10, 19),
    ));

void main() {
  test('says nothing while the count is unknown', () {
    expect(dailyLimitParamsFor(const DailyLimitUnknown()), isNull);
  });

  test('counts the questions left today', () {
    final params = dailyLimitParamsFor(_known(3))!;

    expect(params.text, '3 questions left today');
    expect(params.isReached, isFalse);
  });

  test('one question left is said in the singular', () {
    expect(dailyLimitParamsFor(_known(1))!.text, '1 question left today');
  });

  test('with none left, says when they come back', () {
    final params = dailyLimitParamsFor(_known(0))!;

    expect(
        params.text, "You've used today's questions. They reset at midnight.");
    expect(params.isReached, isTrue);
  });

  test("the reset is a clock time in the student's own zone", () {
    expect(
        dailyLimitParamsFor(_known(0, resetsAt: DateTime(2026, 10, 18, 22)),
                now: DateTime(2026, 10, 18, 15))!
            .text,
        "You've used today's questions. They reset at 10pm.");
  });

  test('with none left, says the reset is tomorrow when it is', () {
    final params = dailyLimitParamsFor(
      DailyLimitKnown(
          DailyLimit(questionsLeft: 0, resetsAt: DateTime(2026, 10, 19, 22))),
      now: DateTime(2026, 10, 18, 23),
    )!;

    expect(params.text,
        "You've used today's questions. They reset tomorrow at 10pm.");
  });

  group('resetMomentLabel', () {
    test('a reset later today needs no day', () {
      expect(
          resetMomentLabel(DateTime(2026, 10, 18, 22),
              now: DateTime(2026, 10, 18, 15)),
          'at 10pm');
    });

    test('a reset on the next day says tomorrow', () {
      expect(
          resetMomentLabel(DateTime(2026, 10, 19, 22),
              now: DateTime(2026, 10, 18, 23)),
          'tomorrow at 10pm');
    });

    test('midnight is midnight, without a day', () {
      expect(
          resetMomentLabel(DateTime(2026, 10, 19),
              now: DateTime(2026, 10, 18, 23)),
          'at midnight');
    });
  });

  group('resetTimeLabel', () {
    test('says a time as a student would', () {
      expect(resetTimeLabel(DateTime(2026, 10, 19)), 'midnight');
      expect(resetTimeLabel(DateTime(2026, 10, 19, 12)), 'noon');
      expect(resetTimeLabel(DateTime(2026, 10, 18, 22)), '10pm');
      expect(resetTimeLabel(DateTime(2026, 10, 19, 9, 30)), '9:30am');
      expect(resetTimeLabel(DateTime(2026, 10, 19, 0, 5)), '12:05am');
      expect(resetTimeLabel(DateTime(2026, 10, 19, 12, 45)), '12:45pm');
    });
  });
}
