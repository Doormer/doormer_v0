import 'dart:math';

import 'package:doormer/src/dev/fake_backend/fake_backend_adapter.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/routes/auth_routes.dart';
import 'package:flutter/services.dart';

/// A fake `taka-api`: one student's data, kept in memory, and an answer to
/// every request the app makes. Set it as the app's `Dio` adapter.
///
/// Every answer takes [delay], and a photo solve [solveDelay] more, so
/// loading states show. Draws use [random]; the default seed draws the same
/// cards every run. [clock] dates the saved questions.
FakeBackendAdapter fakeBackend({
  Random? random,
  AssetBundle? bundle,
  DateTime Function()? clock,
  Duration delay = const Duration(milliseconds: 400),
  Duration solveDelay = const Duration(seconds: 3),
}) {
  final now = clock ?? DateTime.now;
  final state = FakeBackendState.starting(now: now());
  return FakeBackendAdapter(
    [
      ...AuthRoutes(state).routes,
    ],
    delay: delay,
  );
}
