import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// A level drawn as QQ draws it: suns, then moons, then stars, in a row. A
/// sun is 16 levels, a moon 4 and a star 1. Stars and suns are amber, moons
/// cream. Level 0 draws nothing.
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

  /// What screen readers hear, such as `Level 6`. Null where words beside
  /// the icons already say it: screen readers then skip them.
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
    if (suns + moons + stars == 0) return const SizedBox.shrink();
    final icons = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < suns; i++)
            Icon(Icons.wb_sunny_rounded, size: size, color: QuestPalette.amber),
          for (var i = 0; i < moons; i++)
            Icon(Icons.nightlight_round, size: size, color: QuestPalette.cream),
          for (var i = 0; i < stars; i++)
            Icon(Icons.star_rounded, size: size, color: QuestPalette.amber),
        ],
      ),
    );
    final label = semanticLabel;
    if (label == null) return icons;
    return Semantics(container: true, label: label, child: icons);
  }
}
