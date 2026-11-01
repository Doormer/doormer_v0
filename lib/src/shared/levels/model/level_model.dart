import '../entity/level.dart';

/// The API's `Level`: `{number, suns, moons, stars}`.
class LevelModel {
  final int number;
  final int suns;
  final int moons;
  final int stars;

  const LevelModel({
    required this.number,
    required this.suns,
    required this.moons,
    required this.stars,
  });

  /// Throws when a field is missing or has the wrong type.
  factory LevelModel.fromJson(Map<String, dynamic> json) => LevelModel(
        number: json['number'] as int,
        suns: json['suns'] as int,
        moons: json['moons'] as int,
        stars: json['stars'] as int,
      );

  /// A level, or null where the API leaves it out, as it does for a friend
  /// below level 1.
  static LevelModel? maybeFromJson(Object? json) =>
      json == null ? null : LevelModel.fromJson(json as Map<String, dynamic>);

  Level toEntity() =>
      Level(number: number, suns: suns, moons: moons, stars: stars);
}
