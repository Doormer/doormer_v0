import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// A utility class to show customizable toast notifications using the
/// [toastification] package. This can be used across the whole app.
class CustomToast {
  /// Displays a toast notification with customizable parameters.
  ///
  /// [context]: BuildContext where the toast will be shown.
  /// [message]: The message text displayed inside the toast.
  /// [type]: The [ToastificationType] of the toast (e.g., success, error, info, warning).
  /// [alignment]: The screen alignment for the toast (default is [Alignment.bottomCenter]).
  /// [autoCloseDuration]: The duration the toast remains visible before closing (default is 2 seconds).
  /// [style]: The toast style (default is [ToastificationStyle.flat]).
  /// [showProgressBar]: Whether a progress bar is displayed (default is false).
  static void show(
    BuildContext context, {
    required String message,
    required ToastificationType type,
    Alignment alignment = Alignment.bottomCenter,
    Duration autoCloseDuration = const Duration(seconds: 2),
    ToastificationStyle style = ToastificationStyle.minimal,
    bool showProgressBar = false,
  }) {
    toastification.show(
      context: context,
      title: message,
      autoCloseDuration: autoCloseDuration,
      type: type,
      style: style,
      alignment: alignment,
      showProgressBar: showProgressBar,
    );
  }
}
