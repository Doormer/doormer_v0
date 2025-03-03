import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/services/sessions/session_service.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/user/entity/user.dart';
import 'package:equatable/equatable.dart';

part 'global_session_event.dart';
part 'global_session_state.dart';

// Bloc responsible for managing user session status
class GlobalSessionBloc extends Bloc<GlobalSessionEvent, GlobalSessionState> {
  final SessionService _sessionService;

  GlobalSessionBloc({required SessionService sessionService})
      : _sessionService = sessionService,
        super(SessionInitialState()) {
    on<CheckSession>(_onCheckSession);
    on<ExpireSession>(_onExpireSession);
    on<RefreshSession>(_onRefreshSession);
    on<SessionStarted>(_onSessionStarted);
  }

  /// Handles the CheckSession event.
  Future<void> _onCheckSession(
    CheckSession event,
    Emitter<GlobalSessionState> emit,
  ) async {
    // TODO: Implementation
  }

  /// Handles session expiration by emitting SessionExpiredState.
  Future<void> _onExpireSession(
    ExpireSession event,
    Emitter<GlobalSessionState> emit,
  ) async {
    emit(SessionExpiredState());
  }

  /// Handles session refresh by calling the SessionService.
  Future<void> _onRefreshSession(
    RefreshSession event,
    Emitter<GlobalSessionState> emit,
  ) async {
    try {
      emit(SessionLoadingState());
      await _sessionService.refreshToken();
      emit(SessionActiveState());
    } catch (e) {
      emit(SessionExpiredState());
    }
  }

  /// Handles session start by emitting SessionActiveState and logging.
  Future<void> _onSessionStarted(
    SessionStarted event, // Fix the event type here
    Emitter<GlobalSessionState> emit,
  ) async {
    emit(SessionActiveState());
    AppLogger.info('Session Started');
  }
}
