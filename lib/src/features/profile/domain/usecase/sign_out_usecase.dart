import 'package:doormer/src/core/services/sessions/session_service.dart';

class SignOutUseCase {
  final SessionService sessionService;

  SignOutUseCase(this.sessionService);

  Future<void> call() => sessionService.logout();
}
