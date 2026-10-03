import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// For destinations on the nav bar that have no page yet.
void showComingSoon(BuildContext context) {
  CustomToast.show(
    context,
    message: 'Coming soon.',
    type: ToastificationType.info,
  );
}
