import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingAnimationWidget extends StatefulWidget {
  const LoadingAnimationWidget({super.key});

  @override
  State<LoadingAnimationWidget> createState() => _LoadingAnimationWidgetState();
}

class _LoadingAnimationWidgetState extends State<LoadingAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textOpacity;

  final List<String> _loadingMessages = [
    'Analyzing your question...',
    'Detecting question type...',
    'Finding similar questions...',
    'Generating solutions...',
    'Almost ready!',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startMessageRotation();
  }

  void _initAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _textController.forward();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _textController.reset();
        _textController.forward();
        _startMessageRotation();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoadingAnimation(),
          SizedBox(height: 40.h),
          _buildLoadingText(),
          SizedBox(height: 60.h),
          _buildProgressSteps(),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Container(
              width: 120.w,
              height: 120.w,
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
                borderRadius: BorderRadius.circular(60.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 30.r,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 40.sp,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingText() {
    return AnimatedBuilder(
      animation: _textOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacity.value,
          child: Column(
            children: [
              Text(
                'AI Processing',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                _loadingMessages[_currentMessageIndex],
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSteps() {
    return Column(
      children: [
        Text(
          'Processing Steps',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            _buildStepIndicator(
              step: 1,
              title: 'Upload',
              isCompleted: true,
              isActive: false,
            ),
            _buildConnector(isCompleted: true),
            _buildStepIndicator(
              step: 2,
              title: 'Analyze',
              isCompleted: false,
              isActive: true,
            ),
            _buildConnector(isCompleted: false),
            _buildStepIndicator(
              step: 3,
              title: 'Results',
              isCompleted: false,
              isActive: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : isActive
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 10.r,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20.sp,
                    )
                  : isActive
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          step.toString(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color:
                  isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Container(
      height: 2.h,
      width: 40.w,
      margin: EdgeInsets.only(bottom: 32.h),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(1.r),
      ),
    );
  }
}
