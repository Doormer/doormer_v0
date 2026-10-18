import 'package:doormer/src/core/routes/shown_destination.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:doormer/src/shared/widget/coming_soon_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The frame around the nav bar's pages: one nav bar, and the page of the
/// destination it has lit.
///
/// Every page stays alive once opened, so switching back to one shows it as
/// it was left, with no reload and no spinner.
class DestinationShell extends StatefulWidget {
  /// The destinations with a page, in the order of the shell route's branches.
  /// AI Tutor has no page yet.
  static const List<AppDestination> branches = [
    AppDestination.saved,
    AppDestination.solve,
    AppDestination.cards,
    AppDestination.profile,
  ];

  final StatefulNavigationShell navigationShell;

  const DestinationShell({super.key, required this.navigationShell});

  @override
  State<DestinationShell> createState() => _DestinationShellState();
}

class _DestinationShellState extends State<DestinationShell> {
  int _reselections = 0;

  AppDestination get _current =>
      DestinationShell.branches[widget.navigationShell.currentIndex];

  void _open(AppDestination destination) {
    if (destination == _current) {
      setState(() => _reselections++);
      return;
    }
    widget.navigationShell
        .goBranch(DestinationShell.branches.indexOf(destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ShownDestination(
        destination: _current,
        reselections: _reselections,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          child: NavigationBarOrganism(
            params: NavigationBarParams(
              current: _current,
              onSaved: () => _open(AppDestination.saved),
              onAiTutor: () => showComingSoon(context),
              onSolve: () => _open(AppDestination.solve),
              onCards: () => _open(AppDestination.cards),
              onProfile: () => _open(AppDestination.profile),
            ),
          ),
        ),
      ),
    );
  }
}
