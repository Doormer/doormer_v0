import 'package:doormer/src/core/utils/invite_code_storage/invite_code_storage.dart';

/// Forgets the code of an invite link the student opened, once its check
/// has been shown, so it isn't shown again.
class ForgetInviteCodeUseCase {
  final InviteCodeStorage storage;

  const ForgetInviteCodeUseCase(this.storage);

  Future<void> call() => storage.forget();
}
