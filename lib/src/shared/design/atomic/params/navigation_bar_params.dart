import 'package:flutter/foundation.dart';

/// The bar's items, in the order they appear.
enum AppDestination { saved, aiTutor, solve, cards, profile }

class NavigationBarParams {
  /// The page the student is on. Its item is lit.
  final AppDestination current;
  final VoidCallback onSaved;
  final VoidCallback onAiTutor;
  final VoidCallback onSolve;
  final VoidCallback onCards;
  final VoidCallback onProfile;

  const NavigationBarParams({
    required this.current,
    required this.onSaved,
    required this.onAiTutor,
    required this.onSolve,
    required this.onCards,
    required this.onProfile,
  });
}
