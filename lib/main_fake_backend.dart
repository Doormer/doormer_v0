import 'package:dio/dio.dart';
import 'package:doormer/main.dart' show MyApp;
import 'package:doormer/src/core/config/app_config.dart';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/dev/fake_backend/fake_backend.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

/// Runs the app with a fake backend in memory instead of `taka-api`:
/// `flutter run -d chrome -t lib/main_fake_backend.dart`.
///
/// Starts the app as `main.dart` does, so keep the two in step. Only the
/// network is fake: everything above `Dio` runs for real.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.enableSemantics) WidgetsBinding.instance.ensureSemantics();

  // Not const, for the reason given in main.dart.
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());
  await initDependencies();

  // Every request goes through this one Dio, token renewal included.
  serviceLocator<Dio>().httpClientAdapter = fakeBackend();
  AppLogger.warn('Running on the fake backend: no API request leaves the app.');

  runApp(const MyApp());
}
