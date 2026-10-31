import 'package:doormer/src/core/theme/quest_palette.dart';
import 'package:flutter/material.dart';

/// Builds the image for a card's art. Tests swap in images that load or fail.
typedef CardArtImageProviderBuilder = ImageProvider Function(String url);

ImageProvider networkCardArtImageProvider(String url) => NetworkImage(url);

/// A student's picture: their card's art as a small rounded square, or the
/// first letter of their nickname on a plain tile. The letter also shows
/// while there is no art, and when the art fails to load.
///
/// The name is always written beside it, so screen readers skip it.
class CardPictureAtom extends StatelessWidget {
  /// Whose first letter the plain tile shows: a student's nickname, or a
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

  /// The first letter of [name], in capitals, such as `Ā` for "āwhina".
  static String letterOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

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
    return ColoredBox(
      key: const Key('card_picture_letter'),
      color: QuestPalette.card,
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
