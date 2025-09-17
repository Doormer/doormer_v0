import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';
import 'package:doormer/src/features/mistake_mirror/domain/entity/question_analysis.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/bloc/mistake_mirror_bloc.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/widget/question_card_widget.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/widget/question_solution_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnalysisResultsWidget extends StatefulWidget {
  final QuestionAnalysis? analysis;
  final Question? selectedQuestion;

  const AnalysisResultsWidget({
    super.key,
    required this.analysis,
  }) : selectedQuestion = null;

  const AnalysisResultsWidget.withSelectedQuestion({
    super.key,
    required this.selectedQuestion,
  }) : analysis = null;

  @override
  State<AnalysisResultsWidget> createState() => _AnalysisResultsWidgetState();
}

class _AnalysisResultsWidgetState extends State<AnalysisResultsWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedQuestion != null) {
      return QuestionSolutionWidget(question: widget.selectedQuestion!);
    }

    if (widget.analysis == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 24.h),
              _buildAnalysisOverview(),
              SizedBox(height: 32.h),
              _buildSimilarQuestions(),
              SizedBox(height: 32.h),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Complete!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Found ${widget.analysis!.similarQuestions.length} similar questions',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            context.read<MistakeMirrorBloc>().add(const ClearAnalysisEvent());
          },
          icon: Icon(
            Icons.refresh,
            size: 24.sp,
            color: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisOverview() {
    final analysis = widget.analysis!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Analysis',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildAnalysisItem(
                icon: Icons.category,
                label: 'Type',
                value: analysis.questionType,
                color: const Color(0xFF3B82F6),
              ),
              SizedBox(width: 16.w),
              _buildAnalysisItem(
                icon: Icons.book,
                label: 'Topic',
                value: analysis.detectedTopic,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildAnalysisItem(
                icon: Icons.speed,
                label: 'Difficulty',
                value: analysis.difficulty,
                color: _getDifficultyColor(analysis.difficulty),
              ),
              SizedBox(width: 16.w),
              _buildAnalysisItem(
                icon: Icons.verified,
                label: 'Confidence',
                value: '${(analysis.confidenceScore * 100).toInt()}%',
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outlined,
              color: const Color(0xFFF59E0B),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Similar Practice Questions',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Click on any question to view step-by-step solution',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: 20.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.analysis!.similarQuestions.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final question = widget.analysis!.similarQuestions[index];
            return QuestionCardWidget(
              question: question,
              index: index + 1,
              onTap: () {
                context.read<MistakeMirrorBloc>().add(
                      SelectQuestionEvent(question: question),
                    );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.bookmark_add_outlined,
            label: 'Bookmark All',
            color: const Color(0xFF6366F1),
            onTap: _bookmarkAll,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildActionButton(
            icon: Icons.history,
            label: 'View History',
            color: const Color(0xFF64748B),
            onTap: () {
              context.read<MistakeMirrorBloc>().add(const LoadHistoryEvent());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _bookmarkAll() {
    for (final question in widget.analysis!.similarQuestions) {
      context.read<MistakeMirrorBloc>().add(
            BookmarkQuestionEvent(questionId: question.id, isBookmarked: true),
          );
    }
  }
}
