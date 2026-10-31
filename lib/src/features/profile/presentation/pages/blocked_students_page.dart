import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../bloc/blocked_students_bloc.dart';
import '../params/blocked_student_row_params.dart';
import '../params/blocked_students_body_params.dart';
import '../templates/blocked_students_template.dart';

/// The students the student has blocked, at `/profile/blocked`, with Unblock
/// on each. The only widget on this screen that touches flutter_bloc.
class BlockedStudentsPage extends StatelessWidget {
  const BlockedStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlockedStudentsBloc>(
      create: (_) => serviceLocator<BlockedStudentsBloc>()
        ..add(const BlockedStudentsStarted()),
      child: BlocConsumer<BlockedStudentsBloc, BlockedStudentsState>(
        listenWhen: (_, current) =>
            current is BlockedStudentsReady && current.errorMessage != null,
        listener: (context, state) => CustomToast.show(
          context,
          message: (state as BlockedStudentsReady).errorMessage!,
          type: ToastificationType.error,
        ),
        builder: (context, state) => BlockedStudentsTemplate(
          body: _bodyFor(context, state),
          onBack: () => context.go('/profile'),
        ),
      ),
    );
  }

  BlockedStudentsBodyParams _bodyFor(
    BuildContext context,
    BlockedStudentsState state,
  ) {
    final bloc = context.read<BlockedStudentsBloc>();
    return switch (state) {
      BlockedStudentsLoading() => const BlockedStudentsLoadingParams(),
      BlockedStudentsError(:final message) => BlockedStudentsErrorParams(
          message: message,
          onRetry: () => bloc.add(const BlockedStudentsRetried()),
        ),
      BlockedStudentsReady ready => BlockedStudentListParams(
          rows: [
            for (final student in ready.students)
              BlockedStudentRowParams(
                nickname: student.nickname,
                artUrl: student.picture?.artUrl,
                isUnblocking: ready.unblockingIds.contains(student.friendId),
                onUnblock: () => bloc.add(StudentUnblocked(student.friendId)),
              ),
          ],
        ),
    };
  }
}
