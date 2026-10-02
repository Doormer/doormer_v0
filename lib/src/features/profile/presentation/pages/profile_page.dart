import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../bloc/profile_bloc.dart';
import '../templates/profile_template.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => serviceLocator<ProfileBloc>(),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSignedOut) {
            context.go('/auth/login');
          } else if (state is ProfileError) {
            CustomToast.show(
              context,
              message: state.message,
              type: ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          return ProfileTemplate(
            isSigningOut: state is ProfileSigningOut,
            onSignOut: () =>
                context.read<ProfileBloc>().add(const SignOutRequested()),
            navigationBarParams: NavigationBarParams(
              current: AppDestination.profile,
              onSaved: () => AppLogger.info('Saved questions'),
              onAiTutor: () => AppLogger.info('AI chat'),
              onSolve: () => context.go('/questions/photo'),
              onCards: () => context.go('/collection'),
              onProfile: () {},
            ),
          );
        },
      ),
    );
  }
}
