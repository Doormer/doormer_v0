import 'package:doormer/src/shared/design/atomic/atoms/cross_fade_indexed_stack_atom.dart';
import 'package:doormer/src/shared/design/atomic/organisms/navigation_bar_organism.dart';
import 'package:doormer/src/shared/design/atomic/params/navigation_bar_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The layout of the nav bar's pages: the page on screen, with the nav bar
/// under it, clear of the screen edge.
///
/// Every page is kept, and switching pages cross-fades them while the bar
/// stays put.
class DestinationShellTemplate extends StatelessWidget {
  final NavigationBarParams navigationBar;

  /// Every page, shown or not.
  final List<Widget> pages;

  /// The index in [pages] of the page on screen.
  final int shownPageIndex;

  const DestinationShellTemplate({
    super.key,
    required this.navigationBar,
    required this.pages,
    required this.shownPageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CrossFadeIndexedStackAtom(index: shownPageIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          child: NavigationBarOrganism(params: navigationBar),
        ),
      ),
    );
  }
}
