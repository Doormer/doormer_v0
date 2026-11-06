import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/glow_badge_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/surface_card_atom.dart';
import 'package:doormer/src/shared/design/atomic/atoms/tile_grid_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/molecules/page_heading_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../organisms/friend_list_organism.dart';
import '../organisms/friend_request_list_organism.dart';
import '../organisms/level_card_organism.dart';
import '../organisms/profile_header_organism.dart';
import '../params/level_card_params.dart';
import '../params/profile_body_params.dart';

/// Profile, the home for friends: its heading, the student's level, whatever
/// [body] holds, and Sign out, which works whatever state friends are in.
///
/// On a wide screen, friends and requests sit two to a line, as tiles, so
/// each one's actions stay beside their name. The level card sits beside the
/// header, the two splitting the line as two tiles would. The buttons keep
/// their own width instead of stretching across the column.
class ProfileTemplate extends StatelessWidget {
  /// From this width up, the screen is wide.
  ///
  /// Measured against the content column, not the window: see
  /// `CollectionTemplate.railBreakpoint`. The column is at most 760 wide.
  static const double wideBreakpoint = 600;

  /// The narrowest Add a friend and Sign out get on a wide screen.
  static const double minWideButtonWidth = 240;

  final ProfileBodyParams body;

  /// The student's level card. Once friends is set up it goes under the
  /// header, or beside it on a wide screen, and before that at the top. Null
  /// until a count of the day brings it, and then Profile shows no card.
  final LevelCardParams? levelCard;

  final bool isSigningOut;
  final VoidCallback onSignOut;

  const ProfileTemplate({
    super.key,
    required this.body,
    this.levelCard,
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
    final levelCard = this.levelCard;
    // The level, with room under it, for every student who has one.
    final card = [
      if (levelCard != null) ...[
        LevelCardOrganism(params: levelCard),
        SizedBox(height: 16.h),
      ],
    ];
    return switch (body) {
      ProfileLoadingParams() => [
          ...card,
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: const Center(
              child: CircularProgressIndicator(color: QuestPalette.violet),
            ),
          ),
        ],
      ProfileErrorParams(:final message, :final onRetry) => [
          ...card,
          ErrorWithRetryMolecule(
            message: message,
            onRetry: onRetry,
            retryLabel: 'Try again',
          ),
        ],
      ProfileNotSetUpParams(:final onSetUp) => [
          ...card,
          SurfaceCardAtom(
            child: Column(
              children: [
                GlowBadgeAtom(
                  icon: Icons.group_add_rounded,
                  color: QuestPalette.violet,
                  size: 44.w,
                  iconSize: 22.w,
                  glowRadius: 16.r,
                ),
                SizedBox(height: 14.h),
                Text(
                  "Add friends with a friend code and see each other's cards.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 14.sp,
                    height: 1.4,
                    color: QuestPalette.body,
                  ),
                ),
                SizedBox(height: 18.h),
                AppButtonAtom(
                  label: 'Set up friends',
                  expand: !isWide,
                  onPressed: onSetUp,
                ),
              ],
            ),
          ),
        ],
      ProfileTurnedOffParams(:final message) => [
          ...card,
          Text(message, textAlign: TextAlign.center, style: messageStyle),
        ],
      ProfileFriendsParams friends => [
          if (isWide && levelCard != null)
            // The header and the card share the line as two tiles would:
            // the header over the friends' left tiles, the card over the
            // right ones.
            Row(
              children: [
                Expanded(
                  child: ProfileHeaderOrganism(params: friends.header),
                ),
                SizedBox(width: TileGridAtom.gap.w),
                Expanded(child: LevelCardOrganism(params: levelCard)),
              ],
            )
          else ...[
            ProfileHeaderOrganism(params: friends.header),
            if (levelCard != null) ...[
              SizedBox(height: 16.h),
              LevelCardOrganism(params: levelCard),
            ],
          ],
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
              label: const Text('Blocked'),
            ),
          ),
        ],
    };
  }
}
