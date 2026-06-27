import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/ask_by_photo_template.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

class AskByPhotoPage extends StatelessWidget {
  const AskByPhotoPage({super.key});

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'heif'],
        allowMultiple: false,
        withData: true,
      );

      if (!context.mounted) return;

      if (result == null || result.files.isEmpty) {
        context.read<AskByPhotoBloc>().add(const AskByPhotoPickCancelled());
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        context.read<AskByPhotoBloc>().add(
              const AskByPhotoPickUnavailable(
                'We could not read that photo. Please try again.',
              ),
            );
        return;
      }

      context.read<AskByPhotoBloc>().add(
            AskByPhotoPhotoPicked(
              imageBytes: bytes,
              fileName: file.name,
            ),
          );
    } catch (e, stackTrace) {
      AppLogger.error('Photo picker failed', error: e, stackTrace: stackTrace);
      if (!context.mounted) return;
      context.read<AskByPhotoBloc>().add(
            const AskByPhotoPickUnavailable(
              'Camera or photo picker is unavailable. Please upload a JPEG or PNG instead.',
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AskByPhotoBloc>(
      create: (_) => serviceLocator<AskByPhotoBloc>(),
      child: BlocConsumer<AskByPhotoBloc, AskByPhotoState>(
        listener: (context, state) {
          if (state is AskByPhotoNotice) {
            CustomToast.show(
              context,
              message: state.message,
              type: ToastificationType.info,
            );
          } else if (state is AskByPhotoValidationError) {
            CustomToast.show(
              context,
              message: state.message,
              type: ToastificationType.warning,
            );
          } else if (state is AskByPhotoNetworkError) {
            CustomToast.show(
              context,
              message: state.message,
              type: ToastificationType.error,
            );
          } else if (state is AskByPhotoTypeInstead) {
            CustomToast.show(
              context,
              message: 'Typed question entry is coming soon.',
              type: ToastificationType.info,
            );
          } else if (state is AskByPhotoSolved) {
            final questionId = Uri.encodeComponent(state.questionId);
            GoRouter.of(context).go(
              '/questions/$questionId/solution',
              extra: state,
            );
          }
        },
        builder: (context, state) {
          final selected =
              state is AskByPhotoPhotoSelected ? state : null;
          final isLoading = state is AskByPhotoLoading;

          return AskByPhotoTemplate(
            uploadParams: PhotoUploadPanelParams(
              imageBytes: selected?.imageBytes,
              fileName: selected?.fileName,
              isLoading: isLoading,
              onPickPhoto: () => _pickPhoto(context),
              onSubmit: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoSubmitted()),
              onClear: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoClearRequested()),
            ),
            statusParams: SolveStatusPanelParams(
              content: solveStatusContentFor(state),
              onRetake: () {
                context
                    .read<AskByPhotoBloc>()
                    .add(const AskByPhotoClearRequested());
                _pickPhoto(context);
              },
              onTypeInstead: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoTypeInsteadRequested()),
            ),
          );
        },
      ),
    );
  }
}
