import 'package:bloc/bloc.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entity/picture_choice.dart';
import '../../domain/usecase/load_friend_profile_usecase.dart';
import '../../domain/usecase/load_picture_choices_usecase.dart';
import '../../domain/usecase/save_friend_profile_usecase.dart';
import '../../utils/nickname_rules.dart';

part 'friend_setup_event.dart';
part 'friend_setup_state.dart';

/// Setting up friends the first time, and changing the nickname and picture
/// later: the nickname, the picture, and saving them. Saving the first time
/// is the student's agreement to be seen by the friends they accept.
class FriendSetupBloc extends Bloc<FriendSetupEvent, FriendSetupState> {
  static const _somethingWentWrong = 'Something went wrong. Try again.';

  final LoadFriendProfileUseCase loadProfile;
  final LoadPictureChoicesUseCase loadPictureChoices;
  final SaveFriendProfileUseCase saveProfile;

  FriendSetupBloc({
    required this.loadProfile,
    required this.loadPictureChoices,
    required this.saveProfile,
  }) : super(const FriendSetupLoading()) {
    on<FriendSetupStarted>(_onStarted);
    on<FriendSetupRetried>(_onRetried);
    on<NicknameChanged>(_onNicknameChanged);
    on<PictureChosen>(_onPictureChosen);
    on<FriendSetupDone>(_onDone);
  }

  Future<void> _onStarted(
    FriendSetupStarted event,
    Emitter<FriendSetupState> emit,
  ) =>
      _load(emit);

  Future<void> _onRetried(
    FriendSetupRetried event,
    Emitter<FriendSetupState> emit,
  ) =>
      _load(emit);

  /// The profile, to start from what is saved, and the cards to pick from.
  Future<void> _load(Emitter<FriendSetupState> emit) async {
    // Kept from a load before, so Try again goes on telling setup from Edit.
    var isFirstTime = state.isFirstTime;
    if (state is! FriendSetupLoading) {
      emit(FriendSetupLoading(isFirstTime: isFirstTime));
    }
    try {
      final profile = await loadProfile();
      isFirstTime = !profile.hasProfile;
      final choices = await loadPictureChoices();
      emit(FriendSetupReady(
        isFirstTime: !profile.hasProfile,
        nickname: profile.nickname,
        picture: profile.picture,
        choices: choices,
      ));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Friend setup failed to load',
          error: f, stackTrace: stackTrace);
      emit(FriendSetupError(f.message, isFirstTime: isFirstTime));
    } catch (e, stackTrace) {
      AppLogger.error('Friend setup failed to load unexpectedly',
          error: e, stackTrace: stackTrace);
      emit(FriendSetupError(
        FriendsMessages.couldNotLoadPictures,
        isFirstTime: isFirstTime,
      ));
    }
  }

  void _onNicknameChanged(
    NicknameChanged event,
    Emitter<FriendSetupState> emit,
  ) {
    final ready = state;
    if (ready is! FriendSetupReady) return;
    emit(ready.copyWith(nickname: event.nickname));
  }

  void _onPictureChosen(PictureChosen event, Emitter<FriendSetupState> emit) {
    final ready = state;
    if (ready is! FriendSetupReady) return;
    emit(ready.copyWith(picture: event.picture, clearPicture: true));
  }

  /// Checks the nickname by the API's rules first, so the only refusal the
  /// API normally gives is its word list.
  Future<void> _onDone(
    FriendSetupDone event,
    Emitter<FriendSetupState> emit,
  ) async {
    final ready = state;
    if (ready is! FriendSetupReady || ready.isSaving) return;
    final problem = NicknameRules.problemWith(ready.nickname);
    if (problem != null) {
      emit(ready.copyWith(nicknameProblem: problem));
      return;
    }

    emit(ready.copyWith(isSaving: true));
    try {
      await saveProfile(
        nickname: NicknameRules.tidy(ready.nickname),
        picture: ready.picture,
      );
      emit(FriendSetupSaved(isFirstTime: ready.isFirstTime));
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Saving the friend profile failed',
          error: f, stackTrace: stackTrace);
      // A 422 is the word list: the app has already checked every other
      // rule.
      final isAboutNickname = f is RefusedFailure && f.statusCode == 422;
      _emitNotSaved(
        emit,
        nicknameProblem: isAboutNickname ? f.message : null,
        errorMessage: isAboutNickname ? null : f.message,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Saving the friend profile failed unexpectedly',
          error: e, stackTrace: stackTrace);
      _emitNotSaved(emit, errorMessage: _somethingWentWrong);
    }
  }

  void _emitNotSaved(
    Emitter<FriendSetupState> emit, {
    String? nicknameProblem,
    String? errorMessage,
  }) {
    final latest = state;
    if (latest is! FriendSetupReady) return;
    emit(latest.copyWith(
      isSaving: false,
      nicknameProblem: nicknameProblem,
      errorMessage: errorMessage,
    ));
  }
}
