import 'package:camera/camera.dart' show XFile;
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/ask_by_photo_template.dart';
import 'package:doormer/src/features/questions/utils/image_readability.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/widget/coming_soon_toast.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'camera_page.dart';

class AskByPhotoPage extends StatelessWidget {
  const AskByPhotoPage({super.key});

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
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

      final photoBloc = context.read<AskByPhotoBloc>();
      final isReadable = await isReadableImage(bytes);
      if (photoBloc.isClosed) return;
      if (!isReadable) {
        photoBloc.add(const AskByPhotoPickUnavailable(unreadableImageMessage));
        return;
      }
      photoBloc.add(
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

  /// Opens the camera/gallery chooser, unless a solve is already running.
  ///
  /// The upload panel disables its own pick button during a solve; without the
  /// same guard here the nav bar could swap the photo mid-flight, and the
  /// earlier photo's solution would then arrive and route the student to a
  /// solution for a photo they had just replaced.
  Future<void> _showPhotoSourceOptions(
    BuildContext context, {
    bool isSolving = false,
  }) async {
    if (isSolving) {
      _showStillSolving(context);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Open camera'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openCamera(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickPhoto(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens the collection, unless a solve is still running.
  ///
  /// Leaving mid-solve would lose the answer, and photographing the same
  /// question again would then count as a repeat and pay nothing.
  void _openCards(BuildContext context, {required bool isSolving}) {
    if (isSolving) {
      _showStillSolving(context);
      return;
    }
    context.go('/collection');
  }

  /// Opens the profile, unless a solve is still running.
  ///
  /// Leaving mid-solve would lose the answer, and photographing the same
  /// question again would then count as a repeat and pay nothing.
  void _openProfile(BuildContext context, {required bool isSolving}) {
    if (isSolving) {
      _showStillSolving(context);
      return;
    }
    context.go('/profile');
  }

  /// Says a solve is still running, so the tap has to wait. Solve and Cards
  /// both use it, so their wording cannot drift apart.
  void _showStillSolving(BuildContext context) {
    CustomToast.show(
      context,
      message: 'Still solving your last photo. One moment.',
      type: ToastificationType.info,
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    final capture = await Navigator.of(context).push<XFile>(
      MaterialPageRoute<XFile>(
        builder: (_) => const CameraPage(),
      ),
    );

    if (!context.mounted || capture == null) return;

    try {
      final bytes = await capture.readAsBytes();
      if (!context.mounted) return;

      context.read<AskByPhotoBloc>().add(
            AskByPhotoPhotoPicked(
              imageBytes: bytes,
              fileName: capture.name,
              mimeType: capture.mimeType,
            ),
          );
    } catch (e, stackTrace) {
      AppLogger.error('Camera capture failed',
          error: e, stackTrace: stackTrace);
      if (!context.mounted) return;
      context.read<AskByPhotoBloc>().add(
            const AskByPhotoPickUnavailable(
              'We could not read that photo. Please try again.',
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
          final selected = state is AskByPhotoPhotoSelected ? state : null;
          final loading = state is AskByPhotoLoading ? state : null;
          // A failure keeps the bytes so the preview does not collapse the
          // moment the solve goes wrong.
          final failed = state is AskByPhotoSolveFailed ? state : null;
          final isLoading = loading != null;
          final imageBytes =
              selected?.imageBytes ?? loading?.imageBytes ?? failed?.imageBytes;
          final isRetry = failed?.isRetryable ?? false;
          final showEmptyUploadPanel = state is AskByPhotoNotice &&
              state.message == unreadableImageMessage;

          return AskByPhotoTemplate(
            uploadParams: PhotoUploadPanelParams(
              imageBytes: imageBytes,
              fileName:
                  selected?.fileName ?? loading?.fileName ?? failed?.fileName,
              isLoading: isLoading,
              showWhenEmpty: showEmptyUploadPanel,
              copy: photoUploadCopyFor(
                hasPhoto: imageBytes != null,
                isRetry: isRetry,
              ),
              onPickPhoto: () => _showPhotoSourceOptions(context),
              onSubmit: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoSubmitted()),
              onClear: () => context
                  .read<AskByPhotoBloc>()
                  .add(const AskByPhotoClearRequested()),
            ),
            statusParams: SolveStatusPanelParams(
              content: solveStatusContentFor(state),
              // Same chooser as every other photo entry point. The recovery
              // copy asks the student to retake the shot, so this must be able
              // to reach the camera; the picked photo replaces the selection
              // outright, so there is nothing to clear first.
              onRetake: () => _showPhotoSourceOptions(context),
            ),
            navigationBarParams: NavigationBarParams(
              current: AppDestination.solve,
              onSaved: () => showComingSoon(context),
              onAiTutor: () => showComingSoon(context),
              onSolve: () =>
                  _showPhotoSourceOptions(context, isSolving: isLoading),
              onCards: () => _openCards(context, isSolving: isLoading),
              onProfile: () => _openProfile(context, isSolving: isLoading),
            ),
          );
        },
      ),
    );
  }
}
