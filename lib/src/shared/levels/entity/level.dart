import 'package:equatable/equatable.dart';

/// How far a student has come, from their active days. It starts at 0 and
/// never goes down. Not an NCEA level, and not a step of a solution.
///
/// It is drawn as suns, moons and stars: a sun is 16 levels, a moon 4 and a
/// star 1, so level 21 is a sun, a moon and a star.
class Level extends Equatable {
  final int number;
  final int suns;
  final int moons;
  final int stars;

  const Level({
    required this.number,
    required this.suns,
    required this.moons,
    required this.stars,
  });

  @override
  List<Object?> get props => [number, suns, moons, stars];
}
