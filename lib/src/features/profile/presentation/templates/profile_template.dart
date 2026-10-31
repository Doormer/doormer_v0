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
class ProfileTemplate extends StatelessWidget {
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
                  ..._content(),
                  SizedBox(height: 24.h),
                  AppButtonAtom(
                    label: 'Sign out',
                    variant: AppButtonVariant.outlined,
                    expand: true,
                    isLoading: isSigningOut,
                    onPressed: isSigningOut ? null : onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content() {
    final messageStyle = TextStyle(fontSize: 13.sp, color: QuestPalette.body);
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
          AppButtonAtom(
            label: 'Add a friend',
            icon: Icons.person_add_alt_1,
            expand: true,
            onPressed: friends.onAddFriend,
          ),
          if (friends.requests.isNotEmpty) ...[
            SizedBox(height: 24.h),
            FriendRequestListOrganism(requests: friends.requests),
          ],
          SizedBox(height: 24.h),
          FriendListOrganism(friends: friends.friends),
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
