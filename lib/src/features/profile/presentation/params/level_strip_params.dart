import 'package:doormer/src/shared/levels/entity/level.dart';
import 'package:flutter/foundation.dart';

/// The student's own level, at the top of Profile.
class LevelStripParams {
  /// Drawn as icons before [title]. Level 0 has none.
  final Level level;

  /// Such as `Level 21`.
  final String title;

  /// Such as `540 active days · 32 to your next star`.
  final String activeDaysLine;

  /// Opens How levels work.
  final VoidCallback onExplain;

  const LevelStripParams({
    required this.level,
    required this.title,
    required this.activeDaysLine,
    required this.onExplain,
  });
}
