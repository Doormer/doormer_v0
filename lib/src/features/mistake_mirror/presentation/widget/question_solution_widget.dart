import 'package:doormer/src/features/mistake_mirror/domain/entity/question.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/bloc/mistake_mirror_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuestionSolutionWidget extends StatefulWidget {
  final Question question;

  const QuestionSolutionWidget({
    super.key,
    required this.question,
  });

  @override
  State<QuestionSolutionWidget> createState() => _QuestionSolutionWidgetState();
}

class _QuestionSolutionWidgetState extends State<QuestionSolutionWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showSteps = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.2),
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
              _buildQuestionDisplay(),
              SizedBox(height: 24.h),
              _buildQuickAnswer(),
              SizedBox(height: 24.h),
              _buildSolutionSection(),
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
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.psychology,
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
                'Step-by-Step Solution',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  _buildDifficultyChip(),
                  SizedBox(width: 8.w),
                  Text(
                    widget.question.questionType,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            context.read<MistakeMirrorBloc>().add(const ClearAnalysisEvent());
          },
          icon: Icon(
            Icons.close,
            size: 24.sp,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionDisplay() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz,
                color: const Color(0xFF3B82F6),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Question',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (widget.question.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                widget.question.imageUrl!,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Color(0xFF9CA3AF),
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
          ],
          Text(
            widget.question.questionText,
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF1E293B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAnswer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Quick Answer',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            widget.question.answer,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.route,
              color: const Color(0xFFF59E0B),
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Solution Steps',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            if (!_showSteps) _buildShowStepsButton() else _buildStepControls(),
          ],
        ),
        SizedBox(height: 20.h),
        if (_showSteps) _buildStepsContent() else _buildStepsPreview(),
      ],
    );
  }

  Widget _buildShowStepsButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _showSteps = true;
            });
            _recordInteraction('view_steps');
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Show Steps',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _currentStep > 0
              ? () {
                  setState(() {
                    _currentStep--;
                  });
                }
              : null,
          icon: Icon(
            Icons.keyboard_arrow_left,
            size: 24.sp,
            color: _currentStep > 0
                ? const Color(0xFF6366F1)
                : const Color(0xFF9CA3AF),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '${_currentStep + 1}/${widget.question.stepByStepSolution.length}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
        IconButton(
          onPressed:
              _currentStep < widget.question.stepByStepSolution.length - 1
                  ? () {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  : null,
          icon: Icon(
            Icons.keyboard_arrow_right,
            size: 24.sp,
            color: _currentStep < widget.question.stepByStepSolution.length - 1
                ? const Color(0xFF6366F1)
                : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsContent() {
    if (widget.question.stepByStepSolution.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          'No detailed steps available for this question.',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF64748B),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentStep),
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child: Text(
                      '${_currentStep + 1}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Step ${_currentStep + 1}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              widget.question.stepByStepSolution[_currentStep],
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF1E293B),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsPreview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock,
            size: 32.sp,
            color: const Color(0xFF94A3B8),
          ),
          SizedBox(height: 12.h),
          Text(
            'Detailed solution with ${widget.question.stepByStepSolution.length} steps',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Click "Show Steps" to reveal the complete solution',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.bookmark_add_outlined,
            label: 'Bookmark',
            color: const Color(0xFF6366F1),
            onTap: () {
              context.read<MistakeMirrorBloc>().add(
                    BookmarkQuestionEvent(
                        questionId: widget.question.id, isBookmarked: true),
                  );
            },
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildActionButton(
            icon: Icons.arrow_back,
            label: 'Back to Questions',
            color: const Color(0xFF64748B),
            onTap: () {
              context.read<MistakeMirrorBloc>().add(const ClearAnalysisEvent());
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

  Widget _buildDifficultyChip() {
    final difficulty = widget.question.difficulty;
    Color color = _getDifficultyColor(difficulty);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
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

  void _recordInteraction(String type) {
    context.read<MistakeMirrorBloc>().add(
          RecordInteractionEvent(
            questionId: widget.question.id,
            interactionType: type,
          ),
        );
  }
}
