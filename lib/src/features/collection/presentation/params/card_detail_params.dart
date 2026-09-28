import 'package:flutter/widgets.dart';

import '../../domain/entity/card_rarity.dart';
import '../../domain/entity/holding.dart';

class CardDetailParams {
  final Holding holding;
  final void Function(CardVariant variant) onShatter;
  final VoidCallback onClose;

  const CardDetailParams({
    required this.holding,
    required this.onShatter,
    required this.onClose,
  });
}
