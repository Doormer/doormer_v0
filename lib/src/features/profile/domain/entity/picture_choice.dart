import 'package:doormer/src/shared/friends/entity/card_picture.dart';
import 'package:equatable/equatable.dart';

/// A card the student owns, offered as their picture.
class PictureChoice extends Equatable {
  final CardPicture picture;

  /// The card's name, such as "Gnomon".
  final String name;

  const PictureChoice({required this.picture, required this.name});

  @override
  List<Object?> get props => [picture, name];
}
