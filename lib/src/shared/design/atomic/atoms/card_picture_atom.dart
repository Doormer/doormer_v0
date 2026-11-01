import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// Builds the image for a card's art. Tests swap in images that load or fail.
typedef CardArtImageProviderBuilder = ImageProvider Function(String url);

ImageProvider networkCardArtImageProvider(String url) => NetworkImage(url);

/// A student's picture: their card's art as a small rounded square, or the
/// first letter of their nickname on an edged, violet-tinted tile. The
/// letter also shows while there is no art, and when the art fails to load.
///
/// The name is always written beside it, so screen readers skip it.
class CardPictureAtom extends StatelessWidget {
  /// Whose first letter the letter tile shows: a student's nickname, or a
  /// card's name in the picture picker.
  final String name;

  /// The card's art. Null when the student has no picture.
  final String? artUrl;

  /// The side of the square, in logical pixels.
  final double size;

  final CardArtImageProviderBuilder imageProviderBuilder;

  const CardPictureAtom({
    super.key,
    required this.name,
    required this.artUrl,
    required this.size,
    this.imageProviderBuilder = networkCardArtImageProvider,
  });

  /// A character that starts with a Unicode letter, as `é` does even when it
  /// is written as `e` and a combining accent.
  static final _letter = RegExp(r'^\p{L}', unicode: true);

  /// The first character of [name] that is a Unicode letter, in capitals, or
  /// `?` when [name] has no letter, a blank name included. For example, `Ā`
  /// for "āwhina" and `K` for "_kai".
  static String letterOf(String name) => name.characters
      .firstWhere(_letter.hasMatch, orElse: () => '?')
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final url = artUrl;
    final letterTile = _LetterTile(letter: letterOf(name), size: size);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: SizedBox.square(
          dimension: size,
          child: url == null || url.isEmpty
              ? letterTile
              : ColoredBox(
                  color: QuestPalette.card,
                  child: Image(
                    image: imageProviderBuilder(url),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => letterTile,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  final String letter;
  final double size;

  const _LetterTile({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    // Tinted violet and edged, so the tile still shows on a card of
    // QuestPalette.card, such as a found student's.
    return DecoratedBox(
      key: const Key('card_picture_letter'),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          QuestPalette.violet.withValues(alpha: 0.30),
          QuestPalette.card,
        ),
        border: Border.all(
          color: QuestPalette.markerLine.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: kDisplayFont,
            fontSize: size * 0.46,
            fontWeight: FontWeight.w600,
            color: QuestPalette.cream,
          ),
        ),
      ),
    );
  }
}
