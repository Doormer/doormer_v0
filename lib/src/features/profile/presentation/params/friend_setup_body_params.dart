import 'package:flutter/foundation.dart';

import 'picture_picker_params.dart';

/// What fills the setup page under its heading.
sealed class FriendSetupBodyParams {
  const FriendSetupBodyParams();
}

class FriendSetupLoadingParams extends FriendSetupBodyParams {
  const FriendSetupLoadingParams();
}

class FriendSetupErrorParams extends FriendSetupBodyParams {
  final String message;
  final VoidCallback onRetry;

  const FriendSetupErrorParams({required this.message, required this.onRetry});
}

/// The nickname, the picture, and Done.
class FriendSetupFormParams extends FriendSetupBodyParams {
  final String initialNickname;

  /// Why the nickname can't be saved. Null when nothing is wrong.
  final String? nicknameProblem;

  final ValueChanged<String> onNicknameChanged;
  final PicturePickerParams picturePicker;
  final bool isSaving;
  final VoidCallback onDone;

  const FriendSetupFormParams({
    required this.initialNickname,
    required this.nicknameProblem,
    required this.onNicknameChanged,
    required this.picturePicker,
    required this.isSaving,
    required this.onDone,
  });
}
