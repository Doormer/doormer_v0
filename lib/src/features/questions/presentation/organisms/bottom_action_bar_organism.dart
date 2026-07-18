import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomActionBarOrganism extends StatelessWidget {
  final BottomActionBarParams params;

  const BottomActionBarOrganism({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final containerHeight = isSmallScreen ? 60.h : 74.h;
        final baseIconSize = isSmallScreen ? 24.0 : 30.0;
        final largeIconSize = isSmallScreen ? 28.0 : 36.0;

        return Container(
          height: containerHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF9B7BDD),
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.copy, size: baseIconSize, color: Colors.black),
                onPressed: params.onCopy,
              ),
              IconButton(
                icon: Icon(Icons.smart_toy_outlined,
                    size: baseIconSize, color: Colors.black),
                onPressed: params.onAiChat,
              ),
              IconButton(
                icon: Icon(Icons.camera_alt_outlined,
                    size: largeIconSize, color: const Color(0xE6B4EF2B)),
                onPressed: params.onUpload,
              ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline,
                    size: baseIconSize, color: Colors.black),
                onPressed: params.onChat,
              ),
              IconButton(
                icon: Icon(Icons.person_outline,
                    size: baseIconSize, color: Colors.black),
                onPressed: params.onProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
