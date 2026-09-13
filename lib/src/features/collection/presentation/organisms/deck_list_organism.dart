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

  /// True in the desktop rail, where 190px has no room for a status flag.
  final bool isRail;

  const DeckListOrganism({
    super.key,
    required this.rows,
    required this.isRail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: rows.length,
      separatorBuilder: (_, __) => SizedBox(height: 2.h),
      itemBuilder: (context, index) =>
          DeckRowMolecule(params: rows[index]),
    );
  }
}
