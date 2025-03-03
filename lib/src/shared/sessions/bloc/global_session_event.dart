part of 'global_session_bloc.dart';

abstract class GlobalSessionEvent extends Equatable {
  const GlobalSessionEvent();

  @override
  List<Object?> get props => [];
}

class CheckSession extends GlobalSessionEvent {}

class ExpireSession extends GlobalSessionEvent {}

class RefreshSession extends GlobalSessionEvent {
  final User user;

  const RefreshSession(this.user);

  @override
  List<Object> get props => [user];
}

class SessionStarted extends GlobalSessionEvent {}

class UserInfoUpdated extends GlobalSessionEvent {
  final User updatedUser;

  const UserInfoUpdated(this.updatedUser);
}
