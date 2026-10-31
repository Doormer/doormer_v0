import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/routes/shown_destination.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/friends/entity/friend_summary.dart';
import 'package:doormer/src/shared/friends/friends_messages.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/friend_codes.dart';
import '../bloc/friends_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../organisms/report_sheet_organism.dart';
import '../params/friend_request_row_params.dart';
import '../params/friend_row_params.dart';
import '../params/profile_body_params.dart';
import '../params/profile_header_params.dart';
import '../params/report_sheet_params.dart';
import '../templates/profile_template.dart';

/// The Profile tab: friends, and Sign out. The only widget on this screen
/// that touches flutter_bloc.
class ProfilePage extends StatelessWidget {
  /// Whether a page under Profile, such as Add a friend, covers it. When
  /// that page goes, Profile reads friends again, quietly: the student may
  /// have changed something there.
  final bool isCovered;

  const ProfilePage({super.key, this.isCovered = false});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>(create: (_) => serviceLocator<ProfileBloc>()),
        BlocProvider<FriendsBloc>(
          create: (_) =>
              serviceLocator<FriendsBloc>()..add(const FriendsStarted()),
        ),
      ],
      child: _ProfileView(isCovered: isCovered),
    );
  }
}

class _ProfileView extends StatefulWidget {
  final bool isCovered;

  const _ProfileView({required this.isCovered});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  @override
  void didUpdateWidget(_ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCovered && !widget.isCovered) _refresh();
  }

  void _refresh() =>
      context.read<FriendsBloc>().add(const FriendsRefreshRequested());

  @override
  Widget build(BuildContext context) {
    return DestinationListener(
      destination: AppDestination.profile,
      // The page stays alive while the student is on other pages, and
      // requests may arrive meanwhile.
      onReturnedTo: _refresh,
      // From a page under Profile, the nav item leads back to Profile.
      onReselected: () => context.go('/profile'),
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileSignedOut) {
                context.go('/auth/login');
              } else if (state is ProfileError) {
                _toast(context, state.message);
              }
            },
          ),
          BlocListener<FriendsBloc, FriendsState>(
            listenWhen: (_, current) =>
                current is FriendsReady && current.errorMessage != null,
            listener: (context, state) =>
                _toast(context, (state as FriendsReady).errorMessage!),
          ),
        ],
        child: Builder(
          builder: (context) {
            final profileState = context.watch<ProfileBloc>().state;
            final friendsState = context.watch<FriendsBloc>().state;
            return ProfileTemplate(
              body: _bodyFor(context, friendsState),
              isSigningOut: profileState is ProfileSigningOut,
              onSignOut: () =>
                  context.read<ProfileBloc>().add(const SignOutRequested()),
            );
          },
        ),
      ),
    );
  }

  void _toast(BuildContext context, String message) => CustomToast.show(
        context,
        message: message,
        type: ToastificationType.error,
      );

  ProfileBodyParams _bodyFor(BuildContext context, FriendsState state) {
    final bloc = context.read<FriendsBloc>();
    return switch (state) {
      FriendsLoading() => const ProfileLoadingParams(),
      FriendsError(:final message) => ProfileErrorParams(
          message: message,
          onRetry: () => bloc.add(const FriendsRetried()),
        ),
      FriendsNotSetUp() => ProfileNotSetUpParams(
          onSetUp: () => context.go('/profile/setup'),
        ),
      FriendsTurnedOff() =>
        const ProfileTurnedOffParams(message: FriendsMessages.turnedOff),
      FriendsReady ready => ProfileFriendsParams(
          header: ProfileHeaderParams(
            nickname: ready.profile.nickname,
            artUrl: ready.profile.picture?.artUrl,
            friendCode: FriendCodes.display(ready.profile.friendCode),
            onEdit: () => context.go('/profile/setup'),
          ),
          onAddFriend: () => context.go('/profile/add'),
          requests: [
            for (final request in ready.requests)
              FriendRequestRowParams(
                nickname: request.from.nickname,
                artUrl: request.from.picture?.artUrl,
                isBusy: ready.answeringRequestIds.contains(request.requestId) ||
                    ready.changingFriendIds.contains(request.from.friendId),
                onAccept: () =>
                    bloc.add(FriendRequestAccepted(request.requestId)),
                onDecline: () =>
                    bloc.add(FriendRequestDeclined(request.requestId)),
                onBlock: () => bloc.add(StudentBlocked(request.from.friendId)),
                onReport: () => _openReport(context, request.from),
              ),
          ],
          friends: [
            for (final friend in ready.friends)
              FriendRowParams(
                nickname: friend.nickname,
                artUrl: friend.picture?.artUrl,
                isBusy: ready.changingFriendIds.contains(friend.friendId),
                onOpen: () => context.go(
                  '/profile/friends/${Uri.encodeComponent(friend.friendId)}'
                  '/cards',
                  extra: friend,
                ),
                onRemove: () => bloc.add(FriendRemoved(friend.friendId)),
                onBlock: () => bloc.add(StudentBlocked(friend.friendId)),
                onReport: () => _openReport(context, friend),
              ),
          ],
          onOpenBlocked: () => context.go('/profile/blocked'),
        ),
    };
  }

  /// The report sheet for [student], over the whole screen, nav bar
  /// included. It sits on the root navigator, outside this page's
  /// providers, so the bloc is handed in.
  void _openReport(BuildContext context, FriendSummary student) {
    final bloc = context.read<FriendsBloc>()
      ..add(ReportOpened(student.friendId));
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocBuilder<FriendsBloc, FriendsState>(
        bloc: bloc,
        buildWhen: (_, current) => current is FriendsReady,
        builder: (_, state) {
          final status = state is FriendsReady
              ? state.reportStatusOf(student.friendId)
              : ReportStatus.unsent;
          return ReportSheetOrganism(
            params: ReportSheetParams(
              title: 'Report ${student.nickname}',
              isSending: status == ReportStatus.sending,
              isSent: status == ReportStatus.sent,
              onSend: (reason, note) => bloc.add(StudentReported(
                friendId: student.friendId,
                reason: reason,
                note: note,
              )),
              onBlock: () {
                bloc.add(StudentBlocked(student.friendId));
                Navigator.of(sheetContext).pop();
              },
              onClose: () => Navigator.of(sheetContext).pop(),
              onOpenLink: (link) =>
                  launchUrl(link, webOnlyWindowName: '_blank'),
            ),
          );
        },
      ),
    );
  }
}
