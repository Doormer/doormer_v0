import 'package:flutter/foundation.dart';

/// The two lists Saved shows: the student's own solved questions, and the
/// questions friends shared with them.
enum SavedList { mine, sharedWithMe }

/// Which of Saved's lists shows, and how to show the other.
class SavedListSwitchParams {
  final SavedList selected;
  final ValueChanged<SavedList> onSelect;

  const SavedListSwitchParams({
    required this.selected,
    required this.onSelect,
  });
}
