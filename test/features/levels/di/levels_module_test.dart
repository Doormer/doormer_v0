import 'package:dio/dio.dart';
import 'package:doormer/src/features/levels/di/levels_module.dart';
import 'package:doormer/src/features/levels/domain/usecase/count_active_day_usecase.dart';
import 'package:doormer/src/features/levels/presentation/bloc/active_day_bloc.dart';
import 'package:doormer/src/shared/levels/bloc/level_progress_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  final locator = GetIt.instance;

  setUp(() {
    locator.registerSingleton<Dio>(Dio());
    locator.registerSingleton(LevelProgressBloc());
    initLevelsModule();
  });

  tearDown(() => locator.reset());

  test('counting the day resolves, from its use case to one bloc for the app',
      () {
    expect(locator<CountActiveDayUseCase>(), isNotNull);
    expect(locator<ActiveDayBloc>(), same(locator<ActiveDayBloc>()));
  });

  test('the bloc tells its progress to the app-wide LevelProgressBloc', () {
    expect(
      locator<ActiveDayBloc>().levelProgress,
      same(locator<LevelProgressBloc>()),
    );
  });
}
