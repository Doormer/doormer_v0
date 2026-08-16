import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/routes/app_router.dart';
import 'package:doormer/src/core/theme/app_theme.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Not const, despite what `prefer_const_constructors` claims: the analyzer
  // sees the stub implementation, which has a const constructor, while the web
  // implementation dart2js actually compiles does not. Making this const passes
  // `flutter analyze` and then fails `flutter build web`.
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());
  // Initialize all dependencies
  await initDependencies();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide the GlobalSessionBloc for session state management
        //TODO: Checks user session everytime reopens app (CheckSession() event)
        // And fetches user data to be stored in SessionActiveState
        BlocProvider(create: (_) => serviceLocator<GlobalSessionBloc>()),
      ],
      child: BlocListener<GlobalSessionBloc, GlobalSessionState>(
        listener: (context, state) {
          if (state is SessionExpiredState) {
            AppRouter.router.go('/auth');
          }
        },
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppTheme.themeMode,
          routerConfig: AppRouter.router,
          // Sits inside MaterialApp so every route, dialog and bottom sheet
          // shares one column and one UI scale. This is also what sets up
          // ScreenUtil, so nothing above it may use `.w`/`.sp`/`.h`.
          builder: (context, child) => ResponsiveAppShell(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
