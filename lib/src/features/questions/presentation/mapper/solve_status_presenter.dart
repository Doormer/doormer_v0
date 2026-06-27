import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';

class SolveStatusContent {
  final String title;
  final String body;
  final bool showActions;

  const SolveStatusContent({
    required this.title,
    required this.body,
    required this.showActions,
  });
}

/// Pure function mapping a bloc state to the status-panel display copy.
/// Page-invoked only — no presentational widget imports this.
SolveStatusContent solveStatusContentFor(AskByPhotoState state) {
  if (state is AskByPhotoUnreadable) {
    return const SolveStatusContent(
      title: 'We could not read it',
      body:
          'The photo was accepted, but the question was too blurry, cropped, or dark to solve. Retake it with the whole question in frame.',
      showActions: true,
    );
  }
  if (state is AskByPhotoNotAQuestion) {
    return const SolveStatusContent(
      title: 'This does not look like a question',
      body:
          'The image was received, but it did not contain a question we can solve. Retake with the question visible or type it manually.',
      showActions: true,
    );
  }
  if (state is AskByPhotoTimeout) {
    return const SolveStatusContent(
      title: 'Solver timed out',
      body:
          'The solver took too long on this photo. You can retake a sharper image or type the question instead.',
      showActions: true,
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
      body: state.message,
      showActions: true,
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
