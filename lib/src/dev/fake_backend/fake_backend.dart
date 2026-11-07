import 'dart:math';

import 'package:doormer/src/dev/fake_backend/fake_backend_adapter.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/routes/auth_routes.dart';
import 'package:doormer/src/dev/fake_backend/routes/collection_routes.dart';
import 'package:doormer/src/dev/fake_backend/routes/friends_routes.dart';
import 'package:doormer/src/dev/fake_backend/routes/levels_routes.dart';
import 'package:doormer/src/dev/fake_backend/routes/questions_routes.dart';
import 'package:doormer/src/dev/fake_backend/routes/sharing_routes.dart';
import 'package:flutter/services.dart';

/// A fake `taka-api`: one student's data, kept in memory, and an answer to
/// every request the app makes. Set it as the app's `Dio` adapter.
///
/// Every answer takes [delay], and a photo solve [solveDelay] more, so
/// loading states show. Draws use [random]; the default seed draws the same
/// cards every run. [clock] dates the saved questions, friend requests and
/// shared questions, and the daily limits and the active day start over when
/// it passes the device's midnight.
///
/// The data starts as [FakeBackendState.starting] has it at [clock]'s time,
/// unless a test passes its own [state], to arrange what no request can,
/// such as a friend sharing a question.
FakeBackendAdapter fakeBackend({
  Random? random,
  AssetBundle? bundle,
  DateTime Function()? clock,
  FakeBackendState? state,
  Duration delay = const Duration(milliseconds: 400),
  Duration solveDelay = const Duration(seconds: 3),
}) {
  final now = clock ?? DateTime.now;
  state ??= FakeBackendState.starting(now: now());
  return FakeBackendAdapter(
    [
      ...AuthRoutes(state).routes,
      ...CollectionRoutes(state, random ?? Random(7)).routes,
      ...FriendsRoutes(state).routes,
      ...LevelsRoutes(state, clock: now).routes,
      ...SharingRoutes(state, clock: now).routes,
      ...QuestionsRoutes(
        state,
        bundle: bundle ?? rootBundle,
        clock: now,
        solveDelay: solveDelay,
      ).routes,
    ],
    delay: delay,
  );
}
