import 'package:dio/dio.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:doormer/src/features/levels/data/datasource/levels_remote_datasource.dart';
import 'package:doormer/src/features/levels/domain/entity/active_day_outcome.dart';
import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(AppLogger.disable);

  // The fake's day ends at the device's next midnight, so the next day is
  // built in the device's zone, and the tests pass in any zone.
  final start = DateTime.utc(2026, 11, 2, 9);
  final local = start.toLocal();
  final nextDay = DateTime(local.year, local.month, local.day + 1, 0, 1);

  late DateTime now;
  late Dio dio;
  late LevelsRemoteDataSource levels;

  setUp(() {
    now = start;
    dio = Dio(BaseOptions(
      baseUrl: 'https://api.test',
      headers: {'Authorization': 'Bearer test-token'},
    ))
      ..httpClientAdapter = fakeBackend(
        delay: Duration.zero,
        solveDelay: Duration.zero,
        clock: () => now,
      );
    levels = LevelsRemoteDataSourceImpl(dio: dio);
  });

  Future<ActiveDayOutcome> countActiveDay() async =>
      (await levels.countActiveDay()).toEntity();

  test('the first count after a reload makes the 32nd active day: a new moon',
      () async {
    expect(
      await countActiveDay(),
      const ActiveDayOutcome(
        counted: true,
        newIcon: LevelIcon.moon,
        progress: LevelProgress(
          activeDays: 32,
          level: Level(number: 4, suns: 0, moons: 1, stars: 0),
          activeDaysToNextLevel: 13,
          nextLevelIcon: LevelIcon.star,
        ),
      ),
    );
  });

  test('counting again the same day changes nothing', () async {
    await countActiveDay();

    final again = await countActiveDay();

    expect(again.counted, isFalse);
    expect(again.newIcon, isNull);
    expect(again.progress.activeDays, 32);
  });

  test('the next day counts again', () async {
    await countActiveDay();
    now = nextDay;

    final tomorrow = await countActiveDay();

    expect(tomorrow.counted, isTrue);
    expect(tomorrow.newIcon, isNull, reason: 'the 33rd day is still level 4');
    expect(tomorrow.progress.activeDays, 33);
  });

  test('a student who signs up starts at 0, so their first count makes 1',
      () async {
    await countActiveDay();
    await dio.post('/v1/signup',
        data: {'email': 'mere@example.test', 'password': 'secret'});

    expect(
      await countActiveDay(),
      const ActiveDayOutcome(
        counted: true,
        progress: LevelProgress(
          activeDays: 1,
          level: Level(number: 0, suns: 0, moons: 0, stars: 0),
          activeDaysToNextLevel: 4,
          nextLevelIcon: LevelIcon.star,
        ),
      ),
    );
  });
}
