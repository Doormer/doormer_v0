import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/holding.dart';

class CardDetailParams {
  final Holding holding;
  final String deckName;

  /// The student's quarks. The window doesn't show them: the page's balance
  /// is behind it. A rebuild with a higher balance and one fewer copy is a
  /// shatter, and the difference is what it paid. Null in a friend's
  /// collection.
  final int? quarkBalance;

  /// On the quark dot of the page's balance, behind the window. A shatter's
  /// quark dots fly there. Null in a friend's collection.
  final GlobalKey? quarkDotKey;

  /// A shatter is waiting for the API's answer.
  final bool isShattering;

  /// Why the last shatter in this window failed. Null once the next one is
  /// asked for.
  final String? errorMessage;

  /// Null in a friend's collection: the window then shows no quarks and no
  /// Shatter.
  final void Function(CardVariant variant)? onShatter;

  final VoidCallback onClose;

  const CardDetailParams({
    required this.holding,
    required this.deckName,
    this.quarkBalance,
    this.quarkDotKey,
    this.isShattering = false,
    this.errorMessage,
    this.onShatter,
    required this.onClose,
  });
}
