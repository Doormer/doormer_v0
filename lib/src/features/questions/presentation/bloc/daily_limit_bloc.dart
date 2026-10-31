import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/domain/entity/daily_limit.dart';
import 'package:doormer/src/features/questions/domain/usecase/load_daily_limit_usecase.dart';
import 'package:equatable/equatable.dart';

part 'daily_limit_event.dart';
part 'daily_limit_state.dart';

/// How many questions the student has left today, for Solve to show.
///
/// The count only guides: the API enforces the limit whatever the app shows.
/// So a read that fails is logged and the count stays as it was, rather than
/// becoming an error on screen, and asking stays open.
class DailyLimitBloc extends Bloc<DailyLimitEvent, DailyLimitState> {
  final LoadDailyLimitUseCase loadDailyLimitUseCase;

  /// Goes up with every read and every report. A read whose answer arrives
  /// after a newer read or report started is out of date, so it is dropped.
  int _generation = 0;

  DailyLimitBloc({required this.loadDailyLimitUseCase})
      : super(const DailyLimitUnknown()) {
    on<DailyLimitRequested>(_onRequested);
    on<DailyLimitReported>(_onReported);
  }

  Future<void> _onRequested(
    DailyLimitRequested event,
    Emitter<DailyLimitState> emit,
  ) async {
    final generation = ++_generation;
    try {
      final dailyLimit = await loadDailyLimitUseCase();
      if (generation != _generation) return;
      emit(DailyLimitKnown(dailyLimit));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Daily limit could not be read',
          error: f, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      AppLogger.error('Daily limit read failed unexpectedly',
          error: e, stackTrace: stackTrace);
    }
  }

  void _onReported(DailyLimitReported event, Emitter<DailyLimitState> emit) {
    _generation++;
    emit(DailyLimitKnown(event.dailyLimit));
  }
}
