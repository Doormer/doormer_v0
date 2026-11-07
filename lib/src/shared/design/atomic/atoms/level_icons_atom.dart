import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'level_icon_atom.dart';

/// A level drawn as QQ draws it: golden suns, then moons, then stars, in a
/// row. A sun is 16 levels, a moon 4 and a star 1. Icons of one kind sit
/// close together and a wider gap separates the kinds, so the row reads as
/// groups. Level 0 draws nothing.
///
/// It takes plain counts, so it can also draw a few icons on their own, as
/// How levels work does.
class LevelIconsAtom extends StatelessWidget {
  final int suns;
  final int moons;
  final int stars;

  /// Each icon's size, in logical pixels, so callers pass `16.w` and the
  /// like.
  final double size;

  /// What screen readers hear, such as `Level 6`. Null where something else
  /// already says it, such as words beside the icons or a label around them:
  /// screen readers then skip the icons.
  final String? semanticLabel;

  const LevelIconsAtom({
    super.key,
    required this.suns,
    required this.moons,
    required this.stars,
    required this.size,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final groups = [
      if (suns > 0) _group(LevelIcon.sun, suns),
      if (moons > 0) _group(LevelIcon.moon, moons),
      if (stars > 0) _group(LevelIcon.star, stars),
    ];
    if (groups.isEmpty) return const SizedBox.shrink();
    final icons = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, group) in groups.indexed) ...[
            if (index > 0) SizedBox(width: 5.w),
            ...group,
          ],
        ],
      ),
    );
    final label = semanticLabel;
    if (label == null) return icons;
    return Semantics(container: true, label: label, child: icons);
  }

  /// [count] of [icon], a small gap apart.
  List<Widget> _group(LevelIcon icon, int count) => [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(width: 1.w),
          LevelIconAtom(icon: icon, size: size),
        ],
      ];
}
