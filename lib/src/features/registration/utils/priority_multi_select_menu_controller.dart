import 'package:flutter/widgets.dart';

/// Controller to hold the selected items of a PriorityMultiSelectMenu/CategorySelectionCard.
class MultiSelectController extends ValueNotifier<List<String>> {
  MultiSelectController([List<String>? initialValue])
      : super(initialValue ?? []);

  List<String> get selectedItems => value;
  set selectedItems(List<String> items) => value = items;
}
