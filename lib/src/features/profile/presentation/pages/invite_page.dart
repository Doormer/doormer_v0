import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../templates/invite_template.dart';

/// An invite link, `/add/<code>`, opened by a student who isn't signed in.
/// The router has kept the code; once the student has signed in and reaches
/// the app, its check opens.
class InvitePage extends StatelessWidget {
  const InvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return InviteTemplate(
      onSignUp: () => context.go('/auth/signup'),
      onLogIn: () => context.go('/auth/login'),
    );
  }
}
