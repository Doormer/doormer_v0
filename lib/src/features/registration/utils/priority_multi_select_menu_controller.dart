import 'package:flutter/widgets.dart';

/// A controller to hold the selected items of a MultiSelectDropdown.
class MultiSelectController extends ValueNotifier<List<String>> {
  MultiSelectController([List<String>? initialValue])
      : super(initialValue ?? []);

  List<String> get selectedItems => value;
  set selectedItems(List<String> items) => value = items;
}
