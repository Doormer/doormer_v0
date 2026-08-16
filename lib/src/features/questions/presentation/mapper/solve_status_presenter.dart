import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';

class SolveStatusContent {
  final String title;
  final String body;
  final bool showActions;

  /// Whether resubmitting the photo already in hand could plausibly succeed.
  /// A blurry photo reads as blurry every time; a dropped connection does not.
  final bool canRetry;

  /// Whether the failed photo is still displayed above this panel.
  ///
  /// When it is, the upload panel is already showing Retake and Clear directly
  /// under the photo, so repeating Retake here would put the same button on
  /// screen twice.
  final bool photoOnScreen;

  const SolveStatusContent({
    required this.title,
    required this.body,
    required this.showActions,
    this.canRetry = false,
    this.photoOnScreen = false,
  });

  /// Retake lives with the photo when there is one, and only falls back to
  /// this panel when there is nothing above to attach it to.
  bool get showRetake => showActions && !photoOnScreen;
}

/// Pure function mapping a bloc state to the status-panel display copy.
/// Page-invoked only — no presentational widget imports this.
SolveStatusContent solveStatusContentFor(AskByPhotoState state) {
  // A retry needs both a reason to expect a different answer and a photo left
  // to send. `AskByPhotoValidationError` has neither, which is why it is not
  // an `AskByPhotoSolveFailed`.
  final photoOnScreen = state is AskByPhotoSolveFailed && state.hasPhoto;
  final canRetry =
      state is AskByPhotoSolveFailed && state.isRetryable && state.hasPhoto;

  if (state is AskByPhotoUnreadable) {
    return SolveStatusContent(
      title: 'We could not read it',
      body:
          'The photo was accepted, but the question was too blurry, cropped, or dark to solve. Retake it with the whole question in frame.',
      showActions: true,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoNotAQuestion) {
    return SolveStatusContent(
      title: 'This does not look like a question',
      body:
          'The image was received, but it did not contain a question we can solve. Retake with the question visible or type it manually.',
      showActions: true,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoTimeout) {
    return SolveStatusContent(
      title: 'Solver timed out',
      body: canRetry
          ? 'The solver took too long on this photo. Your photo is still here — try again, or retake a sharper image.'
          : 'The solver took too long on this photo. You can retake a sharper image or type the question instead.',
      showActions: true,
      canRetry: canRetry,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoValidationError) {
    return SolveStatusContent(
      title: 'Photo needs a quick fix',
      body: state.message,
      showActions: true,
    );
  }
  if (state is AskByPhotoNetworkError) {
    return SolveStatusContent(
      title: 'Could not reach the solver',
      body: canRetry
          ? '${state.message} Your photo is still here, so you can send it again.'
          : state.message,
      showActions: true,
      canRetry: canRetry,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoLoading) {
    return const SolveStatusContent(
      title: 'Solving your photo',
      body:
          'Uploading raw image bytes securely and waiting for the solver response.',
      showActions: false,
    );
  }
  return const SolveStatusContent(
    title: 'Ready when the page is readable',
    body:
        'Use bright light, keep the question flat, and include every line of the problem. HEIC is not supported for this MVP.',
    showActions: false,
  );
}
