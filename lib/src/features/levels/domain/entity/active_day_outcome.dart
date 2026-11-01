import 'package:doormer/src/shared/levels/entity/level_icon.dart';
import 'package:doormer/src/shared/levels/entity/level_progress.dart';
import 'package:equatable/equatable.dart';

/// What counting today as an active day did.
class ActiveDayOutcome extends Equatable {
  /// Whether today was new. False when it had already counted.
  final bool counted;

  /// The icon the new level added, when today raised the level. Null
  /// otherwise.
  final LevelIcon? newIcon;

  /// The student's progress, today included.
  final LevelProgress progress;

  const ActiveDayOutcome({
    required this.counted,
    this.newIcon,
    required this.progress,
  });

  /// Whether today raised the level.
  bool get raisedLevel => newIcon != null;

  @override
  List<Object?> get props => [counted, newIcon, progress];
}
