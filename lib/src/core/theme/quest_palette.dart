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
}

/// Display face — headings, numerals, anything that should read as a game.
const String kDisplayFont = 'Fredoka';

/// Reading face — body copy and controls.
const String kBodyFont = 'SpaceGrotesk';
