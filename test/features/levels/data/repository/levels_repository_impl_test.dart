import 'package:doormer/src/features/levels/data/datasource/levels_remote_datasource.dart';
import 'package:doormer/src/features/levels/data/model/count_active_day_response_model.dart';
import 'package:doormer/src/features/levels/data/repository/levels_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_levels_repository.dart';

/// Answers with the API's words for the 32nd active day.
class _NewMoonDataSource implements LevelsRemoteDataSource {
  @override
  Future<CountActiveDayResponseModel> countActiveDay() async =>
      CountActiveDayResponseModel.fromJson({
        'counted': true,
        'new_icon': 'moon',
        'progress': {
          'active_days': 32,
          'level': {'number': 4, 'suns': 0, 'moons': 1, 'stars': 0},
          'active_days_to_next_level': 13,
          'next_level_icon': 'star',
        },
      });
}

void main() {
  test('counts the day and answers with what counting it did', () async {
    final repository =
        LevelsRepositoryImpl(remoteDataSource: _NewMoonDataSource());

    expect(await repository.countActiveDay(), newMoonAt32);
  });
}
