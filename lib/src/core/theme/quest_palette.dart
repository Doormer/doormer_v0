import 'package:flutter/material.dart';

/// The quest palette, taken verbatim from the approved HTML prototype
/// (`solution-v4.html`).
///
/// These are hand-picked and cannot be derived: `ColorScheme.fromSeed` with the
/// violet seed generates a violet-family tonal palette, so the mint, pink and
/// amber accents that carry the whole progress language — mint means done,
/// pink means here, amber means ready — simply did not exist in the app. That
/// is why the build looked nothing like the prototype.
///
/// Each accent has one meaning. Using them for anything else breaks the
/// language a student learns in the first minute.
class QuestPalette {
  QuestPalette._();

  /// Structure and primary actions.
  static const Color violet = Color(0xFF6C4DFF);

  /// The deep base the quest backdrop settles into.
  static const Color ink = Color(0xFF150F2E);

  /// "You are here", and mathematics.
  static const Color pink = Color(0xFFFFABF3);

  /// "Done", and anything earned.
  static const Color mint = Color(0xFF00E5A0);

  /// "Ready to open", and the streak at stake.
  static const Color amber = Color(0xFFFFD84D);

  static const Color cream = Color(0xFFFFF4FF);

  /// Muted text and inert trail furniture.
  static const Color dim = Color(0xFFB9AEE6);

  /// The outline on a trail bookend that is neither ready nor done — the plan
  /// at the head, and the vault while it is still a long way off.
  static const Color markerLine = Color(0xFF9B82FF);

  /// Body copy on the quest backdrop.
  static const Color body = Color(0xFFE4DCFF);

  /// Captions and secondary lines.
  static const Color muted = Color(0xFF9E93C9);

  /// Page backdrop behind the quest gradient.
  static const Color night = Color(0xFF08060F);

  /// Backdrop gradient stops, top to bottom.
  static const Color glowTop = Color(0xFF3A2170);
  static const Color glowBottom = Color(0xFF0F0A26);

  /// Ink used on top of [mint] fills.
  static const Color onMint = Color(0xFF062B1E);

  /// Ink used on top of [amber] fills.
  static const Color onAmber = Color(0xFF2B2100);

  static const Color card = Color(0xFF1E1640);

  // Levels: stars, moons and suns. These colours mean a level and nothing
  // else, so amber keeps its one meaning. They come from the QQ Gold
  // mockups.

  /// Levels: the top of the gold that fills a star, moon or sun, and the
  /// bright end of the level bar.
  static const Color levelGoldLight = Color(0xFFFFF7C2);

  /// Levels: the middle of that gold, 42% of the way down. It also edges
  /// the level card and the new-level pop-up.
  static const Color levelGold = Color(0xFFFFD54A);

  /// Levels: the bottom of that gold, and the start of the level bar.
  static const Color levelGoldDeep = Color(0xFFF29A0E);

  /// Levels: the soft glow around a star, moon or sun, and around the level
  /// bar's fill.
  static const Color levelGlow = Color(0xFFFFB828);

  /// Levels: the halo behind a level's icons, on the level card and in the
  /// new-level pop-up.
  static const Color levelHalo = Color(0xFFFFCD50);

  /// Levels: the days still to go on the level card, and the pop-up's rays,
  /// flash and sparkles.
  static const Color levelPaleGold = Color(0xFFFFE28A);

  /// Levels: a level's own words, such as "Level 21" and "New moon!", and
  /// the core of the pop-up's flash.
  static const Color levelCream = Color(0xFFFFF4D6);

  /// Levels: the top of the level card's violet.
  static const Color levelCardTop = Color(0xFF2A1D5E);

  /// Levels: the level card's violet 55% of the way down, where the
  /// new-level pop-up's violet ends too.
  static const Color levelCardMiddle = Color(0xFF1B1340);

  /// Levels: the bottom of the level card's violet.
  static const Color levelCardBottom = Color(0xFF160F33);

  /// Levels: the top of the new-level pop-up's violet.
  static const Color levelPopUpTop = Color(0xFF31226B);

  /// Levels: the warm end of the gold on the pop-up's Nice!, which runs to
  /// [levelGold].
  static const Color levelButton = Color(0xFFFFB020);

  /// Levels: ink on the gold of Nice!.
  static const Color onLevelGold = Color(0xFF2B1A00);
}

/// Display face — headings, numerals, anything that should read as a game.
const String kDisplayFont = 'Fredoka';

/// Reading face — body copy and controls.
const String kBodyFont = 'SpaceGrotesk';
