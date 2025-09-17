import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/bloc/mistake_mirror_bloc.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/widget/analysis_results_widget.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/widget/file_upload_widget.dart';
import 'package:doormer/src/features/mistake_mirror/presentation/widget/loading_animation_widget.dart';
import 'package:doormer/src/shared/widget/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';

class MistakeMirrorPage extends StatelessWidget {
  const MistakeMirrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => serviceLocator<MistakeMirrorBloc>(),
      child: const MistakeMirrorPageContent(),
    );
  }
}

class MistakeMirrorPageContent extends StatefulWidget {
  const MistakeMirrorPageContent({super.key});

  @override
  State<MistakeMirrorPageContent> createState() =>
      _MistakeMirrorPageContentState();
}

class _MistakeMirrorPageContentState extends State<MistakeMirrorPageContent>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFE8F0FE),
              Color(0xFFF3E8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocListener<MistakeMirrorBloc, MistakeMirrorState>(
            listener: (context, state) {
              if (state is MistakeMirrorError) {
                CustomToast.showErrorToast(
                  context: context,
                  title: 'Error',
                  description: state.message,
                  type: ToastificationType.error,
                );
              } else if (state is BookmarkUpdated) {
                CustomToast.showSuccessToast(
                  context: context,
                  title: 'Success',
                  description: state.isBookmarked
                      ? 'Question bookmarked successfully'
                      : 'Bookmark removed successfully',
                  type: ToastificationType.success,
                );
              }
            },
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: BlocBuilder<MistakeMirrorBloc, MistakeMirrorState>(
                    builder: (context, state) {
                      if (state is MistakeMirrorLoading) {
                        return const LoadingAnimationWidget();
                      } else if (state is QuestionAnalysisSuccess) {
                        return AnalysisResultsWidget(analysis: state.analysis);
                      } else if (state is QuestionSelected) {
                        return AnalysisResultsWidget.withSelectedQuestion(
                          selectedQuestion: state.question,
                        );
                      } else {
                        return _buildUploadSection();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Row(
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
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 12.r,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 8.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Mistake Mirror',
                        style: AppTextStyles.headingLarge.copyWith(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'AI-powered question analysis & practice',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHistoryButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<MistakeMirrorBloc>().add(const LoadHistoryEvent());
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Icon(
              Icons.history,
              color: const Color(0xFF6366F1),
              size: 8.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 1.h),
              _buildWelcomeCard(),
              SizedBox(height: 32.h),
              const FileUploadWidget(),
              SizedBox(height: 32.h),
              // _buildFeaturesGrid(),
              // SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20.r,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🎯 Upload Your Question',
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Take a photo of any math, physics, or text question and get instant AI-powered analysis with step-by-step solutions!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 5.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final features = [
      {
        'icon': Icons.camera_alt,
        'title': 'Smart Analysis',
        'description': 'AI detects question type and difficulty',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.psychology,
        'title': 'Similar Questions',
        'description': 'Get 3+ related practice questions',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.route,
        'title': 'Step-by-Step',
        'description': 'Detailed solution breakdowns',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.bookmark,
        'title': 'Save Progress',
        'description': 'Bookmark questions for later',
        'color': const Color(0xFFEF4444),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: AppTextStyles.headingMedium.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.2,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return _buildFeatureCard(
              icon: feature['icon'] as IconData,
              title: feature['title'] as String,
              description: feature['description'] as String,
              color: feature['color'] as Color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF64748B),
              fontSize: 12.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
