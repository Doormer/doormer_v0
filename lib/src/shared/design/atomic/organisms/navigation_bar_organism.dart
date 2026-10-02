import 'package:doormer/src/core/responsive/responsive_app_shell.dart';
import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One place in the dock.
class _Destination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const _Destination(this.icon, this.label, {this.selectedIcon});
}

/// How each item looks. Solve has no selected form: it opens the camera rather
/// than switching to a section, so it never stays lit.
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

  final NavigationBarParams params;

  const NavigationBarOrganism({super.key, required this.params});

  @override
  State<NavigationBarOrganism> createState() => _NavigationBarOrganismState();
}

class _NavigationBarOrganismState extends State<NavigationBarOrganism> {
  late AppDestination _lit;

  @override
  void initState() {
    super.initState();
    _lit = widget.params.current;
  }

  @override
  void didUpdateWidget(covariant NavigationBarOrganism oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params.current != widget.params.current) {
      _lit = widget.params.current;
    }
  }

  /// Whether a tap on [tapped] lights it.
  ///
  /// Solve never does: it opens the camera, not a page. Cards does only on the
  /// Cards page. Anywhere else it opens that page, whose own bar lights it, so
  /// a tap refused mid-solve does not leave Cards lit on home.
  bool _lightsUp(AppDestination tapped) => switch (tapped) {
        AppDestination.solve => false,
        AppDestination.cards => widget.params.current == AppDestination.cards,
        AppDestination.saved ||
        AppDestination.aiTutor ||
        AppDestination.profile =>
          true,
      };

  VoidCallback _actionFor(AppDestination tapped) => switch (tapped) {
        AppDestination.saved => widget.params.onSaved,
        AppDestination.aiTutor => widget.params.onAiTutor,
        AppDestination.solve => widget.params.onSolve,
        AppDestination.cards => widget.params.onCards,
        AppDestination.profile => widget.params.onProfile,
      };

  void _onDestinationSelected(int index) {
    final tapped = AppDestination.values[index];
    if (_lightsUp(tapped)) {
      setState(() => _lit = tapped);
    }
    _actionFor(tapped)();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dockWidth =
            constraints.maxWidth.clamp(0.0, AppLayout.maxContentWidth);
        final isWide = dockWidth / AppDestination.values.length >=
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
                selectedIndex: _lit.index,
                labelBehavior: isWide
                    ? NavigationDestinationLabelBehavior.alwaysShow
                    : NavigationDestinationLabelBehavior.alwaysHide,
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
