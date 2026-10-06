part of 'saved_questions_bloc.dart';

sealed class SavedQuestionsEvent extends Equatable {
  const SavedQuestionsEvent();

  @override
  List<Object?> get props => const [];
}

/// The Saved page opened.
class SavedQuestionsStarted extends SavedQuestionsEvent {
  const SavedQuestionsStarted();
}

/// The student scrolled near the end of the rows.
class SavedQuestionsMoreRequested extends SavedQuestionsEvent {
  const SavedQuestionsMoreRequested();
}

/// The student tapped Try again.
class SavedQuestionsRetried extends SavedQuestionsEvent {
  const SavedQuestionsRetried();
}
