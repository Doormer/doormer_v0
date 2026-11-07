part of 'shared_questions_bloc.dart';

sealed class SharedQuestionsEvent extends Equatable {
  const SharedQuestionsEvent();

  @override
  List<Object?> get props => const [];
}

/// The student opened Shared with me for the first time.
class SharedQuestionsStarted extends SharedQuestionsEvent {
  const SharedQuestionsStarted();
}

/// The student scrolled near the end of the rows.
class SharedQuestionsMoreRequested extends SharedQuestionsEvent {
  const SharedQuestionsMoreRequested();
}

/// The student tapped Try again.
class SharedQuestionsRetried extends SharedQuestionsEvent {
  const SharedQuestionsRetried();
}

/// The student came back to Shared with me, from a question it opened or
/// from another page. Meanwhile a friend may have shared a question, or
/// stopped sharing one, and the student may have removed one.
class SharedQuestionsRefreshRequested extends SharedQuestionsEvent {
  const SharedQuestionsRefreshRequested();
}
