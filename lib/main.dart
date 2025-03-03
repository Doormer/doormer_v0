import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/routes/app_router.dart';
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/shared/sessions/bloc/global_session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return ScreenUtilInit(
        designSize: const Size(360, 690), // Set base design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MultiBlocProvider(
            providers: [
              // Provide the GlobalSessionBloc for session state management
              //TODO: Checks user session everytime reopens app (CheckSession() event)
              // And fetches user data to be stored in SessionActiveState
              BlocProvider(create: (_) => serviceLocator<GlobalSessionBloc>()),
            ],
            child: ScreenUtilInit(
              designSize: const Size(360, 690), // Set the base design size
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (_, __) {
                return BlocListener<GlobalSessionBloc, GlobalSessionState>(
                  listener: (context, state) {
                    if (state is SessionExpiredState) {
                      AppRouter.router.go('/auth');
                    }
                  },
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData(
                      fontFamily: 'Helvetica',
                      useMaterial3: true,
                      scaffoldBackgroundColor: AppColors.background,
                    ),
                    routerConfig:
                        AppRouter.router, // Use AppRouter as the router
                  ),
                );
              },
            ),
          );
        });
  }
}
