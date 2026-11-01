import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_levels.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';

/// Counting active days, by `taka-api`'s rules: the first count each day
/// adds one, and the answer names the icon a new level added.
class LevelsRoutes {
  final FakeBackendState _state;
  final DateTime Function() _clock;

  LevelsRoutes(this._state, {required DateTime Function() clock})
      : _clock = clock;

  List<FakeRoute> get routes => [
        FakeRoute('POST', '/v1/levels/active-day', _countActiveDay),
      ];

  FakeResponse _countActiveDay(FakeRequest request) {
    _state.startNewDayIfDue(_clock());
    final levelBefore = fakeLevelFor(_state.activeDays);
    final counted = !_state.countedToday;
    if (counted) {
      _state.activeDays++;
      _state.countedToday = true;
    }
    final level = fakeLevelFor(_state.activeDays);
    return FakeResponse.ok({
      'counted': counted,
      if (level > levelBefore) 'new_icon': fakeNewestIconOf(level),
      'progress': fakeLevelProgressJson(_state.activeDays),
    });
  }
}
