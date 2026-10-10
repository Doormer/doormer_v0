import 'package:camera/camera.dart' show XFile;
import 'package:doormer/src/core/ads/display_ad_unit.dart';
import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/errors/failure.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/photo_upload_presenter.dart';
import 'package:doormer/src/features/questions/presentation/mapper/solve_status_presenter.dart';
import 'package:doormer/src/features/questions/presentation/organisms/photo_source_sheet_organism.dart';
import 'package:doormer/src/features/questions/presentation/pages/photo_edit_page.dart';
import 'package:doormer/src/features/questions/utils/photo/editable_photo.dart';
import 'package:doormer/src/features/questions/presentation/organisms/why_ads_sheet_organism.dart';
import 'package:doormer/src/features/questions/presentation/params/photo_upload_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solve_status_panel_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_progress_params.dart';
import 'package:doormer/src/features/questions/presentation/params/solving_view_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/ask_by_photo_template.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_file_input.dart';
import 'package:doormer/src/features/questions/utils/photo/photo_preparer.dart';
import 'package:doormer/src/features/questions/utils/photo/picked_photo_file.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/widget/coming_soon_toast.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'camera_page.dart';

/// Passed as the route's `extra` to open Solve with the photo options already
/// up, for buttons that promise to solve a question.
///
/// It is not JSON, so go_router leaves it out of the browser history: back,
/// forward and a refresh show Solve as a plain tab.
class ShowPhotoSourceOptionsOnOpen {
  const ShowPhotoSourceOptionsOnOpen();
}

class AskByPhotoPage extends StatefulWidget {
  /// Whether the camera and gallery options open as soon as the page shows.
  ///
  /// The options, not the file chooser itself: browsers only open a chooser in
  /// response to a tap, and the student's tap on an option is that tap.
  final bool showPhotoSourceOptionsOnOpen;

  /// The ad shown while a photo is being solved, or null when ads are off.
  /// Ads also bring the notice under Submit that says why they show.
  /// Defaults to the build's AdSense settings.
  final DisplayAdUnit? Function() solvingAdUnit;

  /// Opens the crop & rotate screen. Tests swap in a fake.
  final PhotoEditorOpener openPhotoEditor;

  const AskByPhotoPage({
    super.key,
    this.showPhotoSourceOptionsOnOpen = false,
    this.solvingAdUnit = DisplayAdUnit.solvingScreen,
    this.openPhotoEditor = openPhotoEditPage,
  });

  @override
  State<AskByPhotoPage> createState() => _AskByPhotoPageState();
}

class _AskByPhotoPageState extends State<AskByPhotoPage> {
  /// The screen inside the bloc provider. Picking a photo reads the bloc from
  /// the context it is given, and this page's own context sits above the
  /// provider.
  final _screenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.showPhotoSourceOptionsOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final screen = _screenKey.currentContext;
        if (screen != null) _showPhotoSourceOptions(screen);
      });
    }
  }

  /// Opens the photo library or file chooser, or, with [fromCamera], the
  /// phone's own camera app.
  ///
  /// Called straight from the sheet's tap handler: browsers only open a
  /// chooser in response to a user gesture.
  Future<void> _pickPhoto(
    BuildContext context, {
    bool fromCamera = false,
  }) async {
    final photoBloc = context.read<AskByPhotoBloc>();
    try {
      final file =
          await serviceLocator<PhotoFileInput>().pick(fromCamera: fromCamera);
      if (photoBloc.isClosed) return;
      if (file == null) {
        photoBloc.add(const AskByPhotoPickCancelled());
        return;
      }
      if (!context.mounted) return;
      await _preparePhoto(context, photoBloc, file);
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Photo pick failed', error: f, stackTrace: stackTrace);
      if (!photoBloc.isClosed) {
        photoBloc.add(AskByPhotoPickUnavailable(f.message));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Photo pick failed', error: e, stackTrace: stackTrace);
      if (!photoBloc.isClosed) {
        photoBloc.add(
          const AskByPhotoPickUnavailable(photoPickerUnavailableMessage),
        );
      }
    }
  }

  /// Turns [file] into the upright, scaled-down JPEG the student sees and the
  /// solver gets, shows it, then opens the crop & rotate screen on it.
  ///
  /// Shown before the editor opens, so leaving the editor keeps the whole
  /// photo. Failures propagate to the caller, which reports them.
  Future<void> _preparePhoto(
    BuildContext context,
    AskByPhotoBloc photoBloc,
    PickedPhotoFile file,
  ) async {
    photoBloc.add(const AskByPhotoPreparationStarted());
    final unedited = await serviceLocator<PhotoPreparer>().prepare(file);
    if (photoBloc.isClosed) return;
    final photo = EditablePhoto(original: file, unedited: unedited);
    _showPhoto(photoBloc, photo, unedited);
    if (!context.mounted) return;
    await _applyEditFromEditor(context, photoBloc, photo);
  }

  /// Opens the crop & rotate screen on [photo] and, if the student changed
  /// anything, prepares the original again with their edit.
  ///
  /// Leaving the screen without Use photo changes nothing. Failures propagate
  /// to the caller, which reports them.
  Future<void> _applyEditFromEditor(
    BuildContext context,
    AskByPhotoBloc photoBloc,
    EditablePhoto photo,
  ) async {
    final edit = await widget.openPhotoEditor(context, photo);
    if (edit == null || edit == photo.edit || photoBloc.isClosed) return;
    final edited = photo.withEdit(edit);
    if (edit.isNone) {
      _showPhoto(photoBloc, edited, photo.unedited);
      return;
    }
    photoBloc.add(const AskByPhotoPreparationStarted());
    final prepared = await serviceLocator<PhotoPreparer>()
        .prepare(photo.original, edit: edit);
    if (photoBloc.isClosed) return;
    _showPhoto(photoBloc, edited, prepared);
  }

  void _showPhoto(
    AskByPhotoBloc photoBloc,
    EditablePhoto photo,
    PreparedPhoto prepared,
  ) {
    photoBloc.add(
      AskByPhotoPhotoPicked(
        imageBytes: prepared.bytes,
        fileName: prepared.fileName,
        mimeType: prepared.mimeType,
        editablePhoto: photo,
      ),
    );
  }

  /// Reopens the crop & rotate screen on the photo on screen.
  Future<void> _editPhoto(BuildContext context, EditablePhoto photo) async {
    final photoBloc = context.read<AskByPhotoBloc>();
    try {
      await _applyEditFromEditor(context, photoBloc, photo);
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Edited photo could not be prepared',
          error: f, stackTrace: stackTrace);
      if (!photoBloc.isClosed) {
        photoBloc.add(AskByPhotoPickUnavailable(f.message));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Edited photo could not be prepared',
          error: e, stackTrace: stackTrace);
      if (!photoBloc.isClosed) {
        photoBloc.add(const AskByPhotoPickUnavailable(photoUnreadableMessage));
      }
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
    bool isPreparing = false,
  }) async {
    if (isPreparing) {
      CustomToast.show(
        context,
        message: 'Still preparing your photo. One moment.',
        type: ToastificationType.info,
      );
      return;
    }

    if (isSolving) {
      _showStillSolving(context);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => PhotoSourceSheetOrganism(
        onCamera: () {
          Navigator.of(sheetContext).pop();
          if (serviceLocator<PhotoFileInput>().usesNativeCamera) {
            _pickPhoto(context, fromCamera: true);
          } else {
            _openCamera(context);
          }
        },
        onGallery: () {
          Navigator.of(sheetContext).pop();
          _pickPhoto(context);
        },
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  /// Opens the saved questions, unless a solve is still running.
  ///
  /// Leaving mid-solve would lose the answer, and photographing the same
  /// question again would then count as a repeat and pay nothing.
  void _openSaved(BuildContext context, {required bool isSolving}) {
    if (isSolving) {
      _showStillSolving(context);
      return;
    }
    context.go('/saved');
  }

  /// Opens the card collection, unless a solve is still running.
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

  /// Says a solve is still running, so the tap has to wait. Every nav item
  /// that leaves home uses it, so their wording cannot drift apart.
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

    final photoBloc = context.read<AskByPhotoBloc>();
    try {
      final bytes = await capture.readAsBytes();
      if (photoBloc.isClosed || !context.mounted) return;
      await _preparePhoto(
        context,
        photoBloc,
        PickedPhotoFile(
          bytes: bytes,
          name: capture.name,
          mimeType: capture.mimeType,
        ),
      );
    } on Failure catch (f, stackTrace) {
      AppLogger.error('Camera photo could not be prepared',
          error: f, stackTrace: stackTrace);
      if (!photoBloc.isClosed) {
        photoBloc.add(AskByPhotoPickUnavailable(f.message));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Camera capture failed',
          error: e, stackTrace: stackTrace);
      if (!photoBloc.isClosed) {
        photoBloc.add(const AskByPhotoPickUnavailable(photoUnreadableMessage));
      }
    }
  }

  /// What the screen shows while [state]'s photo is being solved.
  SolvingViewParams _solvingViewFor(
    AskByPhotoLoading state, {
    required DisplayAdUnit? adUnit,
  }) {
    final content = solveStatusContentFor(state);
    final photo = state.imageBytes;
    return SolvingViewParams(
      progress: SolvingProgressParams(
        imageBytes: photo,
        title: content.title,
        body: content.body,
      ),
      adUnit: adUnit,
    );
  }

  /// Explains, for students and the parents helping them, why ads show while
  /// a photo is being solved.
  Future<void> _showWhyAds(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => WhyAdsSheetOrganism(
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adUnit = widget.solvingAdUnit();

    return BlocProvider<AskByPhotoBloc>(
      create: (_) => serviceLocator<AskByPhotoBloc>(),
      child: BlocConsumer<AskByPhotoBloc, AskByPhotoState>(
        key: _screenKey,
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
          // Kept through a solve so the button holds its place, disabled,
          // and comes back after a failure.
          final editablePhoto = selected?.editablePhoto ??
              loading?.editablePhoto ??
              failed?.editablePhoto;
          final isLoading = loading != null;
          final imageBytes =
              selected?.imageBytes ?? loading?.imageBytes ?? failed?.imageBytes;
          final isRetry = failed?.isRetryable ?? false;
          final isPreparing = state is AskByPhotoPreparingPhoto;
          final showEmptyUploadPanel = state is AskByPhotoNotice &&
              (state.message == photoUnreadableMessage ||
                  state.message == heicConverterUnavailableMessage);

          return AskByPhotoTemplate(
            uploadParams: PhotoUploadPanelParams(
              imageBytes: imageBytes,
              fileName:
                  selected?.fileName ?? loading?.fileName ?? failed?.fileName,
              isLoading: isLoading,
              showWhenEmpty: showEmptyUploadPanel,
              isPreparing: isPreparing,
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
              onEditPhoto: editablePhoto == null
                  ? null
                  : () => _editPhoto(context, editablePhoto),
              onWhyAds: adUnit == null ? null : () => _showWhyAds(context),
            ),
            statusParams: SolveStatusPanelParams(
              content: solveStatusContentFor(state),
              // Same chooser as every other photo entry point. The recovery
              // copy asks the student to retake the shot, so this must be able
              // to reach the camera; the picked photo replaces the selection
              // outright, so there is nothing to clear first.
              onRetake: () => _showPhotoSourceOptions(context),
            ),
            solving: loading == null
                ? null
                : _solvingViewFor(loading, adUnit: adUnit),
            navigationBarParams: NavigationBarParams(
              current: AppDestination.solve,
              onSaved: () => _openSaved(context, isSolving: isLoading),
              onAiTutor: () => showComingSoon(context),
              onSolve: () => _showPhotoSourceOptions(
                context,
                isSolving: isLoading,
                isPreparing: isPreparing,
              ),
              onCards: () => _openCards(context, isSolving: isLoading),
              onProfile: () => _openProfile(context, isSolving: isLoading),
            ),
          );
        },
      ),
    );
  }
}
