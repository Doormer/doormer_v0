import 'package:doormer/src/core/routes/shown_destination.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/design/atomic/templates/destination_shell_template.dart';
import 'package:doormer/src/shared/widget/coming_soon_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The frame around the nav bar's pages: one nav bar, and the page of the
/// destination it has lit.
///
/// Every page stays alive once opened, so switching back to one shows it as
/// it was left, with no reload and no spinner. [DestinationShellTemplate]
/// lays the pages out with the bar and cross-fades them; this connects it to
/// go_router, as a page connects its template to a bloc.
class DestinationShell extends StatefulWidget {
  /// The destinations with a page, in the order of the shell route's branches.
  /// AI Tutor has no page yet.
  static const List<AppDestination> destinations = [
    AppDestination.saved,
    AppDestination.solve,
    AppDestination.cards,
    AppDestination.profile,
  ];

  /// The shell's route, around [branches]: one per entry of [destinations],
  /// in the same order.
  static StatefulShellRoute route({
    required List<StatefulShellBranch> branches,
  }) {
    return StatefulShellRoute(
      builder: (context, state, navigationShell) => navigationShell,
      navigatorContainerBuilder: (context, navigationShell, pages) =>
          DestinationShell(navigationShell: navigationShell, pages: pages),
      branches: branches,
    );
  }

  final StatefulNavigationShell navigationShell;

  /// The pages of the branches, in the order of [destinations].
  final List<Widget> pages;

  const DestinationShell({
    super.key,
    required this.navigationShell,
    required this.pages,
  });

  @override
  State<DestinationShell> createState() => _DestinationShellState();
}

class _DestinationShellState extends State<DestinationShell> {
  int _reselections = 0;

  AppDestination get _current =>
      DestinationShell.destinations[widget.navigationShell.currentIndex];

  void _open(AppDestination destination) {
    if (destination == _current) {
      setState(() => _reselections++);
      return;
    }
    widget.navigationShell
        .goBranch(DestinationShell.destinations.indexOf(destination));
  }

  @override
  Widget build(BuildContext context) {
    return ShownDestination(
      destination: _current,
      reselections: _reselections,
      child: DestinationShellTemplate(
        navigationBar: NavigationBarParams(
          current: _current,
          onSaved: () => _open(AppDestination.saved),
          onAiTutor: () => showComingSoon(context),
          onSolve: () => _open(AppDestination.solve),
          onCards: () => _open(AppDestination.cards),
          onProfile: () => _open(AppDestination.profile),
        ),
        pages: widget.pages,
        shownPageIndex: widget.navigationShell.currentIndex,
      ),
    );
  }
}
