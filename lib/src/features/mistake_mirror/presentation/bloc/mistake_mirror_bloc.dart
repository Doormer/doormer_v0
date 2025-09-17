import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doormer/src/core/utils/app_logger.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question_analysis.dart';
import 'package:doormer/src/features/mistake_mirror/domain/usecase/mistake_mirror_usecase.dart';
import 'package:equatable/equatable.dart';

part 'mistake_mirror_event.dart';
part 'mistake_mirror_state.dart';

class MistakeMirrorBloc extends Bloc<MistakeMirrorEvent, MistakeMirrorState> {
  final MistakeMirrorUseCase mistakeMirrorUseCase;

  MistakeMirrorBloc({
    required this.mistakeMirrorUseCase,
  }) : super(const MistakeMirrorInitial()) {
    on<AnalyzeQuestionEvent>(_onAnalyzeQuestion);
    on<GetQuestionDetailsEvent>(_onGetQuestionDetails);
    on<RecordInteractionEvent>(_onRecordInteraction);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<BookmarkQuestionEvent>(_onBookmarkQuestion);
    on<LoadBookmarksEvent>(_onLoadBookmarks);
    on<ClearAnalysisEvent>(_onClearAnalysis);
    on<SelectQuestionEvent>(_onSelectQuestion);
  }

  Future<void> _onAnalyzeQuestion(
    AnalyzeQuestionEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    try {
      emit(const MistakeMirrorLoading(loadingMessage: 'Analyzing question...'));

      final analysis = await mistakeMirrorUseCase.analyzeQuestion(
        imageBytes: event.imageBytes,
        fileName: event.fileName,
      );

      emit(QuestionAnalysisSuccess(analysis: analysis));
    } catch (e) {
      AppLogger.error('Error analyzing question', e);
      emit(MistakeMirrorError(message: 'Failed to analyze question: $e'));
    }
  }

  Future<void> _onGetQuestionDetails(
    GetQuestionDetailsEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    try {
      emit(const MistakeMirrorLoading(
          loadingMessage: 'Loading question details...'));

      final question =
          await mistakeMirrorUseCase.getQuestionDetails(event.questionId);
      emit(QuestionDetailsLoaded(question: question));
    } catch (e) {
      AppLogger.error('Error loading question details', e);
      emit(MistakeMirrorError(message: 'Failed to load question details: $e'));
    }
  }

  Future<void> _onRecordInteraction(
    RecordInteractionEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    try {
      await mistakeMirrorUseCase.recordInteraction(
        questionId: event.questionId,
        interactionType: event.interactionType,
      );
      emit(const InteractionRecorded(
          message: 'Interaction recorded successfully'));
    } catch (e) {
      AppLogger.error('Error recording interaction', e);
      emit(MistakeMirrorError(message: 'Failed to record interaction: $e'));
    }
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    try {
      emit(const MistakeMirrorLoading(loadingMessage: 'Loading history...'));

      final history = await mistakeMirrorUseCase.getQuestionHistory();
      emit(HistoryLoaded(history: history));
    } catch (e) {
      AppLogger.error('Error loading history', e);
      emit(MistakeMirrorError(message: 'Failed to load history: $e'));
    }
  }

  Future<void> _onBookmarkQuestion(
    BookmarkQuestionEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    try {
      if (event.isBookmarked) {
        await mistakeMirrorUseCase.bookmarkQuestion(event.questionId);
      }
      emit(BookmarkUpdated(
        isBookmarked: event.isBookmarked,
        questionId: event.questionId,
      ));
    } catch (e) {
      AppLogger.error('Error bookmarking question', e);
      emit(MistakeMirrorError(message: 'Failed to bookmark question: $e'));
    }
  }

  Future<void> _onLoadBookmarks(
    LoadBookmarksEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    try {
      emit(const MistakeMirrorLoading(loadingMessage: 'Loading bookmarks...'));

      final bookmarks = await mistakeMirrorUseCase.getBookmarkedQuestions();
      emit(BookmarksLoaded(bookmarks: bookmarks));
    } catch (e) {
      AppLogger.error('Error loading bookmarks', e);
      emit(MistakeMirrorError(message: 'Failed to load bookmarks: $e'));
    }
  }

  Future<void> _onClearAnalysis(
    ClearAnalysisEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    emit(const AnalysisCleared());
  }

  Future<void> _onSelectQuestion(
    SelectQuestionEvent event,
    Emitter<MistakeMirrorState> emit,
  ) async {
    emit(QuestionSelected(question: event.question));

    // Record the interaction
    add(RecordInteractionEvent(
      questionId: event.question.id,
      interactionType: 'view_solution',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'question_type': event.question.questionType,
      },
    ));
  }
}
