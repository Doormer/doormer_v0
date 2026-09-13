import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../molecules/deck_row_molecule.dart';
import '../params/deck_row_params.dart';

/// Every deck, always. The list is the home of the collection.
///
/// **Vertical scrolling only.** There is no horizontal shelf, no overflow menu
/// and no "all decks" button, because a deck a student cannot see is a deck
/// they believe they have lost. The rail is complete by construction, which is
/// also why nothing needs to lead anywhere else.
class DeckListOrganism extends StatelessWidget {
  final List<DeckRowParams> rows;

  const DeckListOrganism({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    // Deliberately NOT a ListView. The template already wraps this in a
    // SingleChildScrollView, and nesting a second vertical scrollable inside
    // one is both a scroll-ownership bug and the slow shrink-wrap layout path.
    // Whoever mounts this list owns the scrolling.
    //
    // Rail behaviour is not a parameter here: it lives entirely in
    // DeckRowParams.showFlag, so there is one source of truth rather than two.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: 2.h),
          DeckRowMolecule(params: rows[i]),
        ],
      ],
    );
  }
}
