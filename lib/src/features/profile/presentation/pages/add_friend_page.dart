import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../../domain/entity/found_student.dart';
import '../../utils/friend_codes.dart';
import '../bloc/add_friend_bloc.dart';
import '../mapper/found_student_presenter.dart';
import '../params/add_friend_body_params.dart';
import '../params/found_student_params.dart';
import '../params/friend_code_params.dart';
import '../templates/add_friend_template.dart';

/// Add a friend, at `/profile/add`, and the check an invite link opens, at
/// `/profile/add/:code`. The only widget on this screen that touches
/// flutter_bloc.
class AddFriendPage extends StatelessWidget {
  /// The friend code of the invite link the page was opened from. Null when
  /// it was opened from Profile.
  final String? inviteCode;

  /// The app's own address, which invite links start with. Null means the
  /// browser's. Tests, which have no browser, set it.
  final Uri? appAddress;

  const AddFriendPage({super.key, this.inviteCode, this.appAddress});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddFriendBloc>(
      create: (_) => serviceLocator<AddFriendBloc>()
        ..add(AddFriendStarted(inviteCode: inviteCode)),
      child: BlocConsumer<AddFriendBloc, AddFriendState>(
        listenWhen: (_, current) =>
            current is AddFriendNeedsSetup ||
            (current is AddFriendReady && current.errorMessage != null),
        listener: (context, state) {
          if (state is AddFriendNeedsSetup) {
            _goToSetup(context, state.inviteCode);
          } else if (state is AddFriendReady) {
            _toast(context, state.errorMessage!, ToastificationType.error);
          }
        },
        builder: (context, state) => AddFriendTemplate(
          body: _bodyFor(context, state),
          onBack: () => context.go('/profile'),
        ),
      ),
    );
  }

  /// Setup comes first. It takes this page's place in the browser's
  /// history, so Back doesn't land here and bounce to setup again.
  void _goToSetup(BuildContext context, String? code) {
    final setup = Uri(
      path: '/profile/setup',
      queryParameters: code == null ? null : {'code': code},
    ).toString();
    Router.neglect(context, () => context.go(setup));
  }

  AddFriendBodyParams _bodyFor(BuildContext context, AddFriendState state) {
    final bloc = context.read<AddFriendBloc>();
    return switch (state) {
      AddFriendLoading() ||
      AddFriendNeedsSetup() =>
        const AddFriendLoadingParams(),
      AddFriendError(:final message) => AddFriendMessageParams(
          message: message,
          onRetry: () => bloc.add(AddFriendStarted(inviteCode: inviteCode)),
        ),
      AddFriendTurnedOff() =>
        const AddFriendMessageParams(message: FriendsMessages.turnedOff),
      AddFriendReady ready => AddFriendFormParams(
          yourCode: FriendCodeParams(
            friendCode: FriendCodes.display(ready.friendCode),
            isResetting: ready.isResettingCode,
            onCopyCode: () => _copy(
              context,
              FriendCodes.display(ready.friendCode),
              'Code copied.',
            ),
            onCopyInviteLink: () => _copy(
              context,
              FriendCodes.inviteLink(
                ready.friendCode,
                appAddress: appAddress ?? Uri.base,
              ),
              'Invite link copied.',
            ),
            onResetCode: () => _confirmReset(context),
          ),
          initialCode:
              inviteCode == null ? '' : FriendCodes.display(inviteCode!),
          isFinding: ready.isFinding,
          onFind: (typed) => bloc.add(FriendCodeSubmitted(typed)),
          findMessage: ready.findMessage,
          found: switch (ready.found) {
            final found? => _foundParams(context, ready, found),
            null => null,
          },
        ),
    };
  }

  FoundStudentParams _foundParams(
    BuildContext context,
    AddFriendReady ready,
    FoundStudent found,
  ) {
    final bloc = context.read<AddFriendBloc>();
    final content = foundStudentContent(found.relation);
    final action = content.action;
    return FoundStudentParams(
      nickname: found.student.nickname,
      artUrl: found.student.picture?.artUrl,
      status: content.status,
      actionLabel: action?.label,
      isActing: ready.isActing,
      onAction: switch (action) {
        FoundStudentAction.sendRequest || FoundStudentAction.accept => () =>
            bloc.add(const FriendRequestSent()),
        FoundStudentAction.unblock => () =>
            bloc.add(const FoundStudentUnblocked()),
        FoundStudentAction.viewCards => () => context.go(
              '/profile/friends/'
              '${Uri.encodeComponent(found.student.friendId)}/cards',
              extra: found.student,
            ),
        null => null,
      },
    );
  }

  Future<void> _copy(BuildContext context, String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) _toast(context, done, ToastificationType.success);
  }

  void _toast(BuildContext context, String message, ToastificationType type) =>
      CustomToast.show(context, message: message, type: type);

  Future<void> _confirmReset(BuildContext context) async {
    final bloc = context.read<AddFriendBloc>();
    final reset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset code?'),
        content:
            const Text('Your old code and invite links will stop working.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset code'),
          ),
        ],
      ),
    );
    if (reset ?? false) bloc.add(const FriendCodeReset());
  }
}
