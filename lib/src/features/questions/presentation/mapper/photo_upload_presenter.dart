/// Display copy for the photo-input panel.
///
/// The two labels below change with what the student is holding, and copy that
/// changes with state is decided above the widgets that show it — otherwise a
/// molecule has to know what a retry is in order to name a button.
class PhotoUploadCopy {
  /// Names what pressing the picker will do, which is different once there is
  /// already a photo to replace.
  final String pickLabel;

  /// Names what pressing send will do. A first send and a resend after a
  /// failure are different promises.
  final String submitLabel;

  /// Replaces [submitLabel] beside the spinner while the solve is running. A
  /// solve can take minutes, so a bare spinner is not enough.
  final String solvingLabel;

  const PhotoUploadCopy({
    required this.pickLabel,
    required this.submitLabel,
    required this.solvingLabel,
  });
}

/// Pure function mapping the panel's situation to its display copy.
/// Page-invoked only — no presentational widget calls this.
PhotoUploadCopy photoUploadCopyFor({
  required bool hasPhoto,
  required bool isRetry,
}) {
  return PhotoUploadCopy(
    pickLabel: hasPhoto ? 'Change photo' : 'Choose photo',
    submitLabel: isRetry ? 'Try again' : 'Submit to solver',
    solvingLabel: 'Solving your photo…',
  );
}
