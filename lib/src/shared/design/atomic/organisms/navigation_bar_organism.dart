import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// At this width, the dock gets its roomier desktop shape and icon scale.
const double _wideDockBreakpoint = 520;

/// One place in the dock.
class _Destination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const _Destination(this.icon, this.label, {this.selectedIcon});
}

/// How each item looks. Solve has no selected icon, so its lit state keeps the
/// scanner outline.
_Destination _destinationOf(AppDestination destination) {
  switch (destination) {
    case AppDestination.saved:
      return const _Destination(Icons.bookmark_outline, 'Saved',
          selectedIcon: Icons.bookmark);
    case AppDestination.aiTutor:
      return const _Destination(Icons.smart_toy_outlined, 'AI Tutor',
          selectedIcon: Icons.smart_toy);
    case AppDestination.solve:
      return const _Destination(Icons.document_scanner_outlined, 'Solve');
    case AppDestination.cards:
      return const _Destination(Icons.style_outlined, 'Cards',
          selectedIcon: Icons.style);
    case AppDestination.profile:
      return const _Destination(Icons.person_outline, 'Profile',
          selectedIcon: Icons.person);
  }
}

class NavigationBarOrganism extends StatelessWidget {
  final NavigationBarParams params;

  const NavigationBarOrganism({super.key, required this.params});

  VoidCallback _actionFor(AppDestination tapped) => switch (tapped) {
        AppDestination.saved => params.onSaved,
        AppDestination.aiTutor => params.onAiTutor,
        AppDestination.solve => params.onSolve,
        AppDestination.cards => params.onCards,
        AppDestination.profile => params.onProfile,
      };

  void _onDestinationSelected(int index) {
    final tapped = AppDestination.values[index];
    _actionFor(tapped)();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dockWidth =
            constraints.maxWidth.clamp(0.0, AppLayout.maxContentWidth);
        final isWide = dockWidth >= _wideDockBreakpoint;
        final barHeight = isWide ? 84.h : 80.h;
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
                selectedIndex: params.current.index,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: _onDestinationSelected,
                destinations: [
                  for (final destination
                      in AppDestination.values.map(_destinationOf))
                    NavigationDestination(
                      icon: Icon(destination.icon, size: iconSize),
                      selectedIcon: destination.selectedIcon == null
                          ? null
                          : Icon(destination.selectedIcon, size: iconSize),
                      label: destination.label,
                      tooltip: '',
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
