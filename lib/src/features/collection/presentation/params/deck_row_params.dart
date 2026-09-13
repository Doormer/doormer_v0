import 'package:flutter/widgets.dart';

/// Plain holder for one row of the deck list. Not Equatable — it carries a
/// callback, and comparing those is meaningless.
class DeckRowParams {
  final String deckId;
  final String name;
  final int held;
  final int total;
  final bool isSelected;

  /// False on the 190px rail, where there is no room. The ring still carries
  /// completion, so nothing is lost — only emphasis.
  final bool showFlag;

  final VoidCallback onTap;

  const DeckRowParams({
    required this.deckId,
    required this.name,
    required this.held,
    required this.total,
    required this.isSelected,
    required this.showFlag,
    required this.onTap,
  });

  bool get isComplete => total > 0 && held >= total;

  bool get isUntouched => held == 0;
}
