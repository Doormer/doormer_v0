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
/// So a read that fails is logged, not shown as an error, and the count stays
/// as it was, unless it has passed its reset. Then it is out of date, so it
/// becomes unknown and asking opens again.
class DailyLimitBloc extends Bloc<DailyLimitEvent, DailyLimitState> {
  final LoadDailyLimitUseCase loadDailyLimitUseCase;

  /// Reads the time, to tell when the count shown has passed its reset. Tests
  /// pass their own clock.
  final DateTime Function() now;

  /// Goes up with every read and every report, so a higher one is newer.
  int _generation = 0;

  /// The generation of the count on screen. A read's answer shows only if the
  /// read is newer than that count, so an answer older than the count on
  /// screen is dropped. An older read's answer still shows while a newer read
  /// is waiting, so it stays if that read fails.
  int _shownGeneration = 0;

  DailyLimitBloc({
    required this.loadDailyLimitUseCase,
    DateTime Function()? now,
  })  : now = now ?? DateTime.now,
        super(const DailyLimitUnknown()) {
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
      if (generation <= _shownGeneration) return;
      _shownGeneration = generation;
      emit(DailyLimitKnown(dailyLimit));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Daily limit could not be read',
          error: f, stackTrace: stackTrace);
      _forgetCountPastItsReset(emit);
    } catch (e, stackTrace) {
      AppLogger.error('Daily limit read failed unexpectedly',
          error: e, stackTrace: stackTrace);
      _forgetCountPastItsReset(emit);
    }
  }

  void _onReported(DailyLimitReported event, Emitter<DailyLimitState> emit) {
    _shownGeneration = ++_generation;
    emit(DailyLimitKnown(event.dailyLimit));
  }

  /// From the moment its reset comes, the count shown is out of date: the
  /// questions are back by then.
  void _forgetCountPastItsReset(Emitter<DailyLimitState> emit) {
    final shown = state;
    if (shown is! DailyLimitKnown) return;
    final hasReset = !now().isBefore(shown.dailyLimit.resetsAt);
    if (hasReset) emit(const DailyLimitUnknown());
  }
}
