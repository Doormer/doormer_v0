import 'package:doormer/src/core/di/service_locator.dart';
import 'package:doormer/src/core/routes/shown_destination.dart';
import 'package:doormer/src/features/levels/presentation/bloc/active_day_bloc.dart';
import 'package:doormer/src/features/levels/presentation/mapper/level_up_presenter.dart';
import 'package:doormer/src/features/levels/presentation/organisms/new_level_pop_up_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/design/atomic/templates/destination_shell_template.dart';
import 'package:doormer/src/shared/friends/bloc/waiting_friend_requests_bloc.dart';
import 'package:doormer/src/shared/widget/coming_soon_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The frame around the nav bar's pages: one nav bar, and the page of the
/// destination it has lit.
///
/// Every page stays alive once opened, so switching back to one shows it as
/// it was left, with no reload and no spinner. [DestinationShellTemplate]
/// lays the pages out with the bar and cross-fades them; this connects it to
/// go_router, as a page connects its template to a bloc, and Profile's dot to
/// [WaitingFriendRequestsBloc].
///
/// It also has [ActiveDayBloc] count the student's active day: when it first
/// shows, which is when the signed-in app opens, and each time the browser
/// tab comes back into view. A count that raises the level opens the
/// new-level pop-up, once.
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

  /// Counts the day again whenever the browser tab comes back into view. On
  /// the web, `onShow` fires when a hidden tab shows again, not when the
  /// window only gets focus back.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onShow: _countActiveDay);
    _countActiveDay();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Tells the API the student is here. It counts each day once, so asking
  /// again the same day changes nothing.
  void _countActiveDay() =>
      serviceLocator<ActiveDayBloc>().add(const ActiveDayCountRequested());

  /// The pop-up for a count that raised the level. Any other count says
  /// nothing.
  void _celebrateNewLevel(BuildContext context, ActiveDayState state) {
    final popUp = LevelUpPresenter.popUpFor(state);
    if (popUp == null) return;
    showNewLevelPopUp(context, popUp);
  }

  AppDestination get _current =>
      DestinationShell.destinations[widget.navigationShell.currentIndex];

  void _open(AppDestination destination) {
    if (destination == _current) {
      setState(() => _reselections++);
      return;
    }
    // The tab's own address, not the one it was left at: under a solution
    // that is the solution's, which would come back with the tab. The page
    // is kept either way.
    widget.navigationShell.goBranch(
      DestinationShell.destinations.indexOf(destination),
      initialLocation: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveDayBloc, ActiveDayState>(
      bloc: serviceLocator<ActiveDayBloc>(),
      listener: _celebrateNewLevel,
      child: BlocBuilder<WaitingFriendRequestsBloc, WaitingFriendRequestsState>(
        bloc: serviceLocator<WaitingFriendRequestsBloc>(),
        builder: (context, waitingRequests) => ShownDestination(
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
              profileHasDot: waitingRequests.hasWaiting,
            ),
            pages: widget.pages,
            shownPageIndex: widget.navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
