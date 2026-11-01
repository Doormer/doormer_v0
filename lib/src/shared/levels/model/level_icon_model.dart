import '../entity/level_icon.dart';

/// The API's names for the icons: `star`, `moon` and `sun`.
abstract final class LevelIconModel {
  /// Throws a [FormatException] for any other name. The data source reports
  /// that as an answer it cannot read.
  static LevelIcon fromJson(Object? json) => switch (json) {
        'star' => LevelIcon.star,
        'moon' => LevelIcon.moon,
        'sun' => LevelIcon.sun,
        _ => throw FormatException('Not a level icon: $json'),
      };
}
