import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/molecules/page_heading_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../organisms/friend_list_organism.dart';
import '../organisms/friend_request_list_organism.dart';
import '../organisms/profile_header_organism.dart';
import '../params/profile_body_params.dart';

/// Profile, the home for friends: its heading, whatever [body] holds, and
/// Sign out, which works whatever state friends are in.
///
/// On a wide screen, friends and requests sit two to a line, as tiles, so
/// each one's actions stay beside their name, and the buttons keep their
/// own width instead of stretching across the column.
class ProfileTemplate extends StatelessWidget {
  /// From this width up, the screen is wide.
  ///
  /// Measured against the content column, not the window: see
  /// `CollectionTemplate.railBreakpoint`. The column is at most 760 wide.
  static const double wideBreakpoint = 600;

  /// The narrowest Add a friend and Sign out get on a wide screen.
  static const double minWideButtonWidth = 240;

  final ProfileBodyParams body;
  final bool isSigningOut;
  final VoidCallback onSignOut;

  const ProfileTemplate({
    super.key,
    required this.body,
    required this.isSigningOut,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeadingMolecule(title: 'Profile'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                children: [
                  ..._content(isWide: isWide),
                  SizedBox(height: 24.h),
                  _keepOwnWidthWhenWide(
                    AppButtonAtom(
                      label: 'Sign out',
                      variant: AppButtonVariant.outlined,
                      expand: !isWide,
                      isLoading: isSigningOut,
                      onPressed: isSigningOut ? null : onSignOut,
                    ),
                    isWide: isWide,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// On a wide screen, [button] keeps its own width, but no narrower than
  /// [minWideButtonWidth], on the left. On a phone it stays as wide as the
  /// column.
  Widget _keepOwnWidthWhenWide(AppButtonAtom button, {required bool isWide}) {
    if (!isWide) return button;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: minWideButtonWidth),
        child: button,
      ),
    );
  }

  List<Widget> _content({required bool isWide}) {
    final messageStyle = TextStyle(fontSize: 13.sp, color: QuestPalette.body);
    final columns = isWide ? 2 : 1;
    return switch (body) {
      ProfileLoadingParams() => [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: const Center(
              child: CircularProgressIndicator(color: QuestPalette.violet),
            ),
          ),
        ],
      ProfileErrorParams(:final message, :final onRetry) => [
          ErrorWithRetryMolecule(
            message: message,
            onRetry: onRetry,
            retryLabel: 'Try again',
          ),
        ],
      ProfileNotSetUpParams(:final onSetUp) => [
          AppButtonAtom(
            label: 'Set up friends',
            expand: true,
            onPressed: onSetUp,
          ),
        ],
      ProfileTurnedOffParams(:final message) => [
          Text(message, textAlign: TextAlign.center, style: messageStyle),
        ],
      ProfileFriendsParams friends => [
          ProfileHeaderOrganism(params: friends.header),
          SizedBox(height: 16.h),
          _keepOwnWidthWhenWide(
            AppButtonAtom(
              label: 'Add a friend',
              icon: Icons.person_add_alt_1,
              expand: !isWide,
              onPressed: friends.onAddFriend,
            ),
            isWide: isWide,
          ),
          if (friends.requests.isNotEmpty) ...[
            SizedBox(height: 24.h),
            FriendRequestListOrganism(
              requests: friends.requests,
              columns: columns,
            ),
          ],
          SizedBox(height: 24.h),
          FriendListOrganism(friends: friends.friends, columns: columns),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: friends.onOpenBlocked,
              icon: const Icon(Icons.block),
              label: const Text('Blocked students'),
            ),
          ),
        ],
    };
  }
}
