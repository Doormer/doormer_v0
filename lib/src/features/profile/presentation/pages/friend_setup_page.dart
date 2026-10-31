import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../bloc/friend_setup_bloc.dart';
import '../params/friend_setup_body_params.dart';
import '../params/picture_picker_params.dart';
import '../templates/friend_setup_template.dart';

/// Setup, at `/profile/setup`: the first time a student opens friends, and
/// whenever they edit their nickname and picture. The only widget on this
/// screen that touches flutter_bloc.
class FriendSetupPage extends StatelessWidget {
  /// The friend code of an invite link the student opened before setting
  /// up. Its check opens once setup is done.
  final String? inviteCode;

  const FriendSetupPage({super.key, this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FriendSetupBloc>(
      create: (_) =>
          serviceLocator<FriendSetupBloc>()..add(const FriendSetupStarted()),
      child: BlocConsumer<FriendSetupBloc, FriendSetupState>(
        listenWhen: (_, current) =>
            current is FriendSetupSaved ||
            (current is FriendSetupReady && current.errorMessage != null),
        listener: (context, state) {
          if (state is FriendSetupSaved) {
            final code = inviteCode;
            context.go(code == null
                ? '/profile'
                : '/profile/add/${Uri.encodeComponent(code)}');
          } else if (state is FriendSetupReady) {
            CustomToast.show(
              context,
              message: state.errorMessage!,
              type: ToastificationType.error,
            );
          }
        },
        builder: (context, state) => FriendSetupTemplate(
          title: state is FriendSetupReady && !state.isFirstTime
              ? 'Edit nickname and picture'
              : 'Set up friends',
          body: _bodyFor(context, state),
          onBack: () => context.go('/profile'),
        ),
      ),
    );
  }

  FriendSetupBodyParams _bodyFor(BuildContext context, FriendSetupState state) {
    final bloc = context.read<FriendSetupBloc>();
    return switch (state) {
      FriendSetupLoading() ||
      FriendSetupSaved() =>
        const FriendSetupLoadingParams(),
      FriendSetupError(:final message) => FriendSetupErrorParams(
          message: message,
          onRetry: () => bloc.add(const FriendSetupRetried()),
        ),
      FriendSetupReady ready => FriendSetupFormParams(
          initialNickname: ready.nickname,
          nicknameProblem: ready.nicknameProblem,
          onNicknameChanged: (nickname) => bloc.add(NicknameChanged(nickname)),
          picturePicker: PicturePickerParams(
            nickname: ready.nickname,
            isFirstLetterChosen: ready.picture == null,
            onChooseFirstLetter: () => bloc.add(const PictureChosen(null)),
            cards: [
              for (final choice in ready.choices)
                PictureOptionParams(
                  name: choice.name,
                  artUrl: choice.picture.artUrl,
                  isChosen: choice.picture == ready.picture,
                  onChoose: () => bloc.add(PictureChosen(choice.picture)),
                ),
            ],
          ),
          isSaving: ready.isSaving,
          onDone: () => bloc.add(const FriendSetupDone()),
        ),
    };
  }
}
