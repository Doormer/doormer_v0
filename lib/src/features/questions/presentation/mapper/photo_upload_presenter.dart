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

  const PhotoUploadCopy({required this.pickLabel, required this.submitLabel});
}

/// Pure function mapping the panel's situation to its display copy.
/// Page-invoked only — no presentational widget calls this.
PhotoUploadCopy photoUploadCopyFor({
  required bool hasPhoto,
  required bool isRetry,
}) {
  return PhotoUploadCopy(
    pickLabel: hasPhoto ? 'Retake' : 'Choose photo',
    submitLabel: isRetry ? 'Try again' : 'Submit to solver',
  );
}
