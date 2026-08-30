import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/questions/presentation/params/bottom_action_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One place in the dock.
class _Destination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const _Destination(this.icon, this.label, {this.selectedIcon});
}

/// Solve has no selected form: it opens the camera rather than switching to a
/// section, so it never stays lit.
const _destinations = <_Destination>[
  _Destination(Icons.bookmark_outline, 'Saved', selectedIcon: Icons.bookmark),
  _Destination(Icons.smart_toy_outlined, 'AI Tutor',
      selectedIcon: Icons.smart_toy),
  _Destination(Icons.document_scanner_outlined, 'Solve'),
  _Destination(Icons.forum_outlined, 'Discuss', selectedIcon: Icons.forum),
  _Destination(Icons.person_outline, 'Profile', selectedIcon: Icons.person),
];

class NavigationBarOrganism extends StatefulWidget {
  /// How much room one destination needs before its name is worth showing.
  ///
  /// Measured per destination rather than across the whole dock, because that
  /// is the actual question: five icons sharing a phone get about 65 pixels
  /// each, which is not enough to say 'AI Tutor' legibly, while the same five
  /// sharing the capped column get about 140, which is ample. This sits well
  /// clear of both, so neither a large phone nor a short laptop lands on the
  /// boundary.
  static const double labelRoom = 104;

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
        final dockWidth =
            constraints.maxWidth.clamp(0.0, AppLayout.maxContentWidth);
        final isWide = dockWidth / _destinations.length >=
            NavigationBarOrganism.labelRoom;
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
                  for (final destination in _destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon, size: iconSize),
                      selectedIcon: destination.selectedIcon == null
                          ? null
                          : Icon(destination.selectedIcon, size: iconSize),
                      label: destination.label,
                      // Empty suppresses it; null falls back to the label,
                      // which is the only name a bare icon has to offer.
                      tooltip: isWide ? '' : null,
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
