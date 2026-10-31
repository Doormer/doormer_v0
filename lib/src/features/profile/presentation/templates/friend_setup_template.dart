import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:doormer/src/shared/design/atomic/molecules/error_with_retry_molecule.dart';
import 'package:doormer/src/shared/design/atomic/molecules/page_heading_molecule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/nickname_field_molecule.dart';
import '../organisms/picture_picker_organism.dart';
import '../params/friend_setup_body_params.dart';

/// Setting up friends, or changing the nickname and picture: the nickname,
/// the picture, and above Done, what friends will see. It sits inside the
/// Profile tab, above the nav bar.
class FriendSetupTemplate extends StatelessWidget {
  /// Null until the page knows whether the student is set up, so the heading
  /// never says the wrong one.
  final String? title;
  final FriendSetupBodyParams body;
  final VoidCallback onBack;

  const FriendSetupTemplate({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeadingMolecule(title: title, onBack: onBack),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return switch (body) {
      FriendSetupLoadingParams() => const Center(
          child: CircularProgressIndicator(color: QuestPalette.violet),
        ),
      FriendSetupErrorParams(:final message, :final onRetry) => Center(
          child: ErrorWithRetryMolecule(
            message: message,
            onRetry: onRetry,
            retryLabel: 'Try again',
          ),
        ),
      FriendSetupFormParams form => ListView(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
          children: [
            NicknameFieldMolecule(
              initialNickname: form.initialNickname,
              problem: form.nicknameProblem,
              onChanged: form.onNicknameChanged,
            ),
            SizedBox(height: 20.h),
            PicturePickerOrganism(params: form.picturePicker),
            SizedBox(height: 24.h),
            Text(
              'Friends you accept will see your nickname, picture and cards.',
              style: TextStyle(fontSize: 12.sp, color: QuestPalette.body),
            ),
            SizedBox(height: 12.h),
            AppButtonAtom(
              label: 'Done',
              expand: true,
              isLoading: form.isSaving,
              onPressed: form.onDone,
            ),
          ],
        ),
    };
  }
}
