import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/holding.dart';

class CardDetailParams {
  final Holding holding;
  final String deckName;

  /// The student's quarks. The window doesn't show them: the page's balance
  /// is behind it. A rebuild with a higher balance and one fewer copy is a
  /// shatter, and the difference is what it paid.
  final int quarkBalance;

  /// On the quark dot of the page's balance, behind the window. A shatter's
  /// quark dots fly there.
  final GlobalKey quarkDotKey;

  /// A shatter is waiting for the API's answer.
  final bool isShattering;

  /// Why the last shatter in this window failed. Null once the next one is
  /// asked for.
  final String? errorMessage;

  final void Function(CardVariant variant) onShatter;
  final VoidCallback onClose;

  const CardDetailParams({
    required this.holding,
    required this.deckName,
    required this.quarkBalance,
    required this.quarkDotKey,
    required this.isShattering,
    this.errorMessage,
    required this.onShatter,
    required this.onClose,
  });
}
