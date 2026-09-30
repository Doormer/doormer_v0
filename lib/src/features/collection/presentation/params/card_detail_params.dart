import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/holding.dart';

class CardDetailParams {
  final Holding holding;

  /// The page's balance is behind the window, so the window shows its own.
  final int quarkBalance;

  /// A shatter is waiting for the API's answer.
  final bool isShattering;

  /// Why the last shatter in this window failed. Null once the next one is
  /// asked for.
  final String? errorMessage;

  final void Function(CardVariant variant) onShatter;
  final VoidCallback onClose;

  const CardDetailParams({
    required this.holding,
    required this.quarkBalance,
    required this.isShattering,
    this.errorMessage,
    required this.onShatter,
    required this.onClose,
  });
}
