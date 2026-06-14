import 'dart:typed_data';

import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          return _AskByPhotoContent(
            state: state,
            onPickPhoto: () => _pickPhoto(context),
          );
        },
      ),
    );
  }
}

class _AskByPhotoContent extends StatelessWidget {
  final AskByPhotoState state;
  final VoidCallback onPickPhoto;

  const _AskByPhotoContent({
    required this.state,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = state is AskByPhotoLoading;
    final selectedState = state is AskByPhotoPhotoSelected
        ? state as AskByPhotoPhotoSelected
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 980.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  SizedBox(height: 28.h),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 720.w;
                      final uploadPanel = _UploadPanel(
                        selectedState: selectedState,
                        isLoading: isLoading,
                        onPickPhoto: onPickPhoto,
                        onSubmit: () => context
                            .read<AskByPhotoBloc>()
                            .add(const AskByPhotoSubmitted()),
                        onClear: () => context
                            .read<AskByPhotoBloc>()
                            .add(const AskByPhotoClearRequested()),
                      );
                      final statusPanel = _StatusPanel(
                        state: state,
                        onRetake: () {
                          context
                              .read<AskByPhotoBloc>()
                              .add(const AskByPhotoClearRequested());
                          onPickPhoto();
                        },
                        onTypeInstead: () => context
                            .read<AskByPhotoBloc>()
                            .add(const AskByPhotoTypeInsteadRequested()),
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            uploadPanel,
                            SizedBox(height: 20.h),
                            statusPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: uploadPanel),
                          SizedBox(width: 24.w),
                          Expanded(flex: 4, child: statusPanel),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask by Photo',
          style: AppTextStyles.displayMedium.copyWith(fontSize: 32.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          'Snap or upload a clear JPEG or PNG question. We will sort it into solved, unreadable, not-a-question, or timeout.',
          style: AppTextStyles.bodyLarge.copyWith(fontSize: 16.sp),
        ),
      ],
    );
  }
}

class _UploadPanel extends StatelessWidget {
  final AskByPhotoPhotoSelected? selectedState;
  final bool isLoading;
  final VoidCallback onPickPhoto;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const _UploadPanel({
    required this.selectedState,
    required this.isLoading,
    required this.onPickPhoto,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedState;

    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borders),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo input',
            style: AppTextStyles.titleLarge.copyWith(fontSize: 20.sp),
          ),
          SizedBox(height: 16.h),
          _PreviewFrame(selectedState: selected),
          if (selected != null) ...[
            SizedBox(height: 12.h),
            Text(
              selected.fileName,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
            ),
          ],
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onPickPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(selected == null ? 'Choose photo' : 'Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              if (selected != null) ...[
                SizedBox(width: 12.w),
                OutlinedButton(
                  onPressed: isLoading ? null : onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.borders),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected == null || isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.uploadButton,
                foregroundColor: AppColors.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text('Submit to solver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  final AskByPhotoPhotoSelected? selectedState;

  const _PreviewFrame({required this.selectedState});

  @override
  Widget build(BuildContext context) {
    final selected = selectedState;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.focusedBorders),
          borderRadius: BorderRadius.circular(16.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (selected == null)
              _EmptyPreview()
            else
              Image.memory(
                Uint8List.fromList(selected.imageBytes),
                fit: BoxFit.cover,
              ),
            _ViewfinderCorners(),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          size: 44.sp,
          color: AppColors.primary,
        ),
        SizedBox(height: 10.h),
        Text(
          'JPEG or PNG · max 10 MB',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
        ),
      ],
    );
  }
}

class _ViewfinderCorners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _corner(top: 12.h, left: 12.w),
        _corner(top: 12.h, right: 12.w, flipX: true),
        _corner(bottom: 12.h, left: 12.w, flipY: true),
        _corner(bottom: 12.h, right: 12.w, flipX: true, flipY: true),
      ],
    );
  }

  Widget _corner({
    double? top,
    double? right,
    double? bottom,
    double? left,
    bool flipX = false,
    bool flipY = false,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: SizedBox(
        width: 32.w,
        height: 32.h,
        child: Stack(
          children: [
            Positioned(
              top: flipY ? null : 0,
              bottom: flipY ? 0 : null,
              left: 0,
              right: 0,
              child: Container(height: 3.h, color: AppColors.uploadButton),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: flipX ? null : 0,
              right: flipX ? 0 : null,
              child: Container(width: 3.w, color: AppColors.uploadButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final AskByPhotoState state;
  final VoidCallback onRetake;
  final VoidCallback onTypeInstead;

  const _StatusPanel({
    required this.state,
    required this.onRetake,
    required this.onTypeInstead,
  });

  @override
  Widget build(BuildContext context) {
    final content = _contentFor(state);

    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borders),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: AppTextStyles.titleLarge.copyWith(fontSize: 20.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            content.body,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
          ),
          if (content.showActions) ...[
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRetake,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: const Text('Retake'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTypeInstead,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.focusedBorders),
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: const Text('Type instead'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _StatusContent _contentFor(AskByPhotoState state) {
    if (state is AskByPhotoUnreadable) {
      return const _StatusContent(
        title: 'We could not read it',
        body:
            'The photo was accepted, but the question was too blurry, cropped, or dark to solve. Retake it with the whole question in frame.',
        showActions: true,
      );
    }
    if (state is AskByPhotoNotAQuestion) {
      return const _StatusContent(
        title: 'This does not look like a question',
        body:
            'The image was received, but it did not contain a question we can solve. Retake with the question visible or type it manually.',
        showActions: true,
      );
    }
    if (state is AskByPhotoTimeout) {
      return const _StatusContent(
        title: 'Solver timed out',
        body:
            'The solver took too long on this photo. You can retake a sharper image or type the question instead.',
        showActions: true,
      );
    }
    if (state is AskByPhotoValidationError) {
      return _StatusContent(
        title: 'Photo needs a quick fix',
        body: state.message,
        showActions: true,
      );
    }
    if (state is AskByPhotoNetworkError) {
      return _StatusContent(
        title: 'Could not reach the solver',
        body: state.message,
        showActions: true,
      );
    }
    if (state is AskByPhotoLoading) {
      return const _StatusContent(
        title: 'Solving your photo',
        body:
            'Uploading raw image bytes securely and waiting for the solver response.',
        showActions: false,
      );
    }
    return const _StatusContent(
      title: 'Ready when the page is readable',
      body:
          'Use bright light, keep the question flat, and include every line of the problem. HEIC is not supported for this MVP.',
      showActions: false,
    );
  }
}

class _StatusContent {
  final String title;
  final String body;
  final bool showActions;

  const _StatusContent({
    required this.title,
    required this.body,
    required this.showActions,
  });
}
