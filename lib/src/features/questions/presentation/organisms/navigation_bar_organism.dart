import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NavigationBarOrganism extends StatefulWidget {
  final BottomActionBarParams params;

  const NavigationBarOrganism({super.key, required this.params});

  @override
  State<NavigationBarOrganism> createState() => _NavigationBarOrganismState();
}

class _NavigationBarOrganismState extends State<NavigationBarOrganism> {
  static const _solveIndex = 2;

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.params.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant NavigationBarOrganism oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params.selectedIndex != widget.params.selectedIndex) {
      _selectedIndex = widget.params.selectedIndex;
    }
  }

  void _onDestinationSelected(int index) {
    final actions = <VoidCallback>[
      widget.params.onCopy,
      widget.params.onAiChat,
      widget.params.onUpload,
      widget.params.onChat,
      widget.params.onProfile,
    ];

    if (index != _solveIndex) {
      setState(() => _selectedIndex = index);
    }
    actions[index]();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dockWidth = constraints.maxWidth.clamp(0.0, 760.0);
        final isWide = dockWidth >= 720;
        final barHeight = isWide ? 84.h : 72.h;
        final iconSize = isWide ? 26.0 : 24.0;

        return Align(
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: dockWidth,
            child: Material(
              color: colorScheme.surfaceContainer,
              elevation: 12,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(isWide ? 28.r : 36.r),
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                height: barHeight,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedIndex: _selectedIndex,
                labelBehavior: isWide
                    ? NavigationDestinationLabelBehavior.alwaysShow
                    : NavigationDestinationLabelBehavior.alwaysHide,
                onDestinationSelected: _onDestinationSelected,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.bookmark_outline,
                      size: iconSize,
                    ),
                    selectedIcon: Icon(
                      Icons.bookmark,
                      size: iconSize,
                    ),
                    label: 'Saved',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.smart_toy_outlined,
                      size: iconSize,
                    ),
                    selectedIcon: Icon(
                      Icons.smart_toy,
                      size: iconSize,
                    ),
                    label: 'AI Tutor',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.document_scanner_outlined,
                      size: iconSize,
                    ),
                    label: 'Solve',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.forum_outlined,
                      size: iconSize,
                    ),
                    selectedIcon: Icon(
                      Icons.forum,
                      size: iconSize,
                    ),
                    label: 'Discuss',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline,
                      size: iconSize,
                    ),
                    selectedIcon: Icon(
                      Icons.person,
                      size: iconSize,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
