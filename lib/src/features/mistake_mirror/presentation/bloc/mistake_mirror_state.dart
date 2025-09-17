part of 'mistake_mirror_bloc.dart';

abstract class MistakeMirrorState extends Equatable {
  const MistakeMirrorState();

  @override
  List<Object?> get props => [];
}

class MistakeMirrorInitial extends MistakeMirrorState {
  const MistakeMirrorInitial();
}

class MistakeMirrorLoading extends MistakeMirrorState {
  final String? loadingMessage;

  const MistakeMirrorLoading({this.loadingMessage});

  @override
  List<Object?> get props => [loadingMessage];
}

class QuestionAnalysisSuccess extends MistakeMirrorState {
  final QuestionAnalysis analysis;

  const QuestionAnalysisSuccess({required this.analysis});

  @override
  List<Object?> get props => [analysis];
}

class QuestionDetailsLoaded extends MistakeMirrorState {
  final Question question;

  const QuestionDetailsLoaded({required this.question});

  @override
  List<Object?> get props => [question];
}

class InteractionRecorded extends MistakeMirrorState {
  final String message;

  const InteractionRecorded({required this.message});

  @override
  List<Object?> get props => [message];
}

class HistoryLoaded extends MistakeMirrorState {
  final List<QuestionAnalysis> history;

  const HistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class BookmarkUpdated extends MistakeMirrorState {
  final bool isBookmarked;
  final String questionId;

  const BookmarkUpdated({
    required this.isBookmarked,
    required this.questionId,
  });

  @override
  List<Object?> get props => [isBookmarked, questionId];
}

class BookmarksLoaded extends MistakeMirrorState {
  final List<Question> bookmarks;

  const BookmarksLoaded({required this.bookmarks});

  @override
  List<Object?> get props => [bookmarks];
}

class AnalysisCleared extends MistakeMirrorState {
  const AnalysisCleared();
}

class QuestionSelected extends MistakeMirrorState {
  final Question question;

  const QuestionSelected({required this.question});

  @override
  List<Object?> get props => [question];
}

class MistakeMirrorError extends MistakeMirrorState {
  final String message;
  final String? details;

  const MistakeMirrorError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}
