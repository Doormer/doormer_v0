import 'package:flutter/widgets.dart';

/// How far along the camera is.
enum CameraCaptureStatus {
  /// Still coming up. Also covers the moment before a controller exists.
  starting,

  /// Live, with a preview to show.
  ready,

  /// It will not open. The reason travels in [CameraCaptureParams.failureMessage].
  failed,
}

/// Plain holder — deliberately not Equatable, because it carries callbacks
/// which compare by reference.
class CameraCaptureParams {
  final CameraCaptureStatus status;

  /// The live preview, supplied by the page because only the page holds the
  /// camera controller. Null unless [status] is [CameraCaptureStatus.ready].
  final Widget? preview;

  final String title;

  /// Shown when the camera will not open. Worded above this layer, because it
  /// depends on what the camera actually said.
  final String failureMessage;

  final VoidCallback onCapture;

  const CameraCaptureParams({
    required this.status,
    required this.preview,
    required this.title,
    required this.failureMessage,
    required this.onCapture,
  });
}
