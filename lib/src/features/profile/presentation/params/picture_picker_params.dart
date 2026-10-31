import 'package:flutter/foundation.dart';

/// The pictures a student can pick from: their nickname's first letter, and
/// every card they own.
class PicturePickerParams {
  /// The nickname as typed so far, for the first-letter tile.
  final String nickname;

  /// The first letter is picked, which means no card.
  final bool isFirstLetterChosen;

  final VoidCallback onChooseFirstLetter;

  /// One per card the student owns, in catalog order. None before their
  /// first card.
  final List<PictureOptionParams> cards;

  const PicturePickerParams({
    required this.nickname,
    required this.isFirstLetterChosen,
    required this.onChooseFirstLetter,
    required this.cards,
  });
}

/// One card to pick.
class PictureOptionParams {
  /// The card's name, such as "Gnomon".
  final String name;
  final String artUrl;
  final bool isChosen;
  final VoidCallback onChoose;

  const PictureOptionParams({
    required this.name,
    required this.artUrl,
    required this.isChosen,
    required this.onChoose,
  });
}
