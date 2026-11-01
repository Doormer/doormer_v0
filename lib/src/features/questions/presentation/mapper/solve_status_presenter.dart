import 'package:doormer/src/features/questions/presentation/bloc/ask_by_photo_bloc.dart';
import 'package:doormer/src/features/questions/presentation/mapper/daily_limit_presenter.dart';

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

/// Pure function mapping a bloc state to the status-panel display copy. It
/// reads the device clock unless [now] is given. Page-invoked only — no
/// presentational widget imports this.
SolveStatusContent solveStatusContentFor(AskByPhotoState state,
    {DateTime? now}) {
  // A retry needs both a reason to expect a different answer and a photo left
  // to send. `AskByPhotoValidationError` has neither, which is why it is not
  // an `AskByPhotoSolveFailed`.
  final photoOnScreen = state is AskByPhotoSolveFailed && state.hasPhoto;
  final canRetry =
      state is AskByPhotoSolveFailed && state.isRetryable && state.hasPhoto;

  if (state is AskByPhotoUnreadable) {
    return SolveStatusContent(
      title: "Couldn't read that photo",
      body: 'It may be blurry, dark or cut off. '
          'Retake it with the whole question in frame.',
      showActions: true,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoNotAQuestion) {
    return SolveStatusContent(
      title: 'No question found',
      body: 'Retake it with the question clearly in frame.',
      showActions: true,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoTimeout) {
    return SolveStatusContent(
      title: 'That took too long',
      body: canRetry
          ? 'Your photo is still here. Try again, or retake a sharper one.'
          : 'Retake a sharper photo and try again.',
      showActions: true,
      canRetry: canRetry,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoStillSolving) {
    return SolveStatusContent(
      title: 'Still solving your last photo',
      body: canRetry
          ? 'Your photo is still here. Try again in a moment.'
          : 'Try again in a moment.',
      showActions: true,
      canRetry: canRetry,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoLimitReached) {
    final resetsAt = resetMomentLabel(state.dailyLimit.resetsAt, now: now);
    return SolveStatusContent(
      title: "You've used today's questions",
      body: 'Your photo is still here. Send it after they reset $resetsAt.',
      showActions: true,
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
      title: switch (state.cause) {
        SolveErrorCause.network => "Can't connect",
        SolveErrorCause.server => 'Something broke on our side',
        SolveErrorCause.unknown => 'Something went wrong',
      },
      body: canRetry
          ? '${state.message} Your photo is still here.'
          : state.message,
      showActions: true,
      canRetry: canRetry,
      photoOnScreen: photoOnScreen,
    );
  }
  if (state is AskByPhotoLoading) {
    return const SolveStatusContent(
      title: 'Solving your question',
      body: 'Keep this page open. Your solution opens by itself.',
      showActions: false,
    );
  }
  return const SolveStatusContent(
    title: 'Ready when the page is readable',
    body:
        'Use bright light, keep the question flat, and include every line of the problem. JPG, PNG or HEIC.',
    showActions: false,
  );
}
