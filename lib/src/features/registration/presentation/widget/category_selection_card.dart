import 'package:doormer/src/features/registration/presentation/widget/selection_bottom_sheet.dart';
import 'package:doormer/src/features/registration/utils/priority_multi_select_menu_controller.dart';
import 'package:flutter/material.dart';

/// A reusable widget that encapsulates an entire category selection field:
/// - Displays a title, description, selected items (as dynamic "chips"), and a button.
/// - When the button is pressed, it opens a bottom sheet for the user to select items.
/// - The widget manages its own selection state and notifies a listener (onSelectionChanged)
///   when selections change, and/or uses a [MultiSelectController] to track selections externally.
/// - It uses an outlined container with a configurable border (color and thickness).
class CategorySelectionCard extends StatefulWidget {
  final String title;
  final String description;
  final List<String> options;
  final List<String> initialSelection;
  final ValueChanged<List<String>>? onSelectionChanged;
  final MultiSelectController? controller;
  final double? cardWidth;
  /// Defaults to [ColorScheme.outlineVariant] when null.
  final Color? borderColor;
  final double borderThickness;
  final double buttonHeight;

  const CategorySelectionCard({
    super.key,
    required this.title,
    required this.description,
    required this.options,
    this.initialSelection = const [],
    this.onSelectionChanged,
    this.controller,
    this.cardWidth,
    this.borderColor,
    this.borderThickness = 1,
    this.buttonHeight = 40.0,
  });

  @override
  CategorySelectionCardState createState() => CategorySelectionCardState();
}

class CategorySelectionCardState extends State<CategorySelectionCard> {
  late List<String> selectedItems;
  MultiSelectController? get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (controller != null) {
      selectedItems = List.from(controller!.selectedItems);
      controller!.addListener(_controllerListener);
    } else {
      selectedItems = List.from(widget.initialSelection);
    }
  }

  void _controllerListener() {
    setState(() {
      selectedItems = List.from(controller!.selectedItems);
    });
  }

  @override
  void dispose() {
    controller?.removeListener(_controllerListener);
    super.dispose();
  }

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SelectionBottomSheet(
          initialSelection: selectedItems,
          options: widget.options,
          title: "Select Your Top 3 ${widget.title}",
          onClose: () => Navigator.of(context).pop(),
          onSubmit: (List<String> newSelection) {
            Navigator.of(context).pop();
            setState(() {
              selectedItems = newSelection;
            });
            if (controller != null) {
              controller!.selectedItems = newSelection;
            }
            widget.onSelectionChanged?.call(newSelection);
          },
          borderColor: widget.borderColor,
          borderThickness: widget.borderThickness,
          buttonHeight: widget.buttonHeight,
        );
      },
    );
  }

  Widget _buildSelectionButton({
    required Color resolvedBorderColor,
    required ColorScheme cs,
  }) {
    final ButtonStyle style = selectedItems.isEmpty
        ? OutlinedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            side: BorderSide(color: cs.primary, width: widget.borderThickness),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            minimumSize: Size(double.infinity, widget.buttonHeight),
          )
        : OutlinedButton.styleFrom(
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,
            side: BorderSide(
                color: resolvedBorderColor, width: widget.borderThickness),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            minimumSize: Size(double.infinity, widget.buttonHeight),
          );

    return OutlinedButton(
      style: style,
      onPressed: _openBottomSheet,
      child: Text(
        selectedItems.isEmpty ? "Select ${widget.title}" : "Change Selection",
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resolvedBorderColor = widget.borderColor ?? cs.outlineVariant;
    final double width = widget.cardWidth ?? double.infinity;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          border:
              Border.all(color: resolvedBorderColor, width: widget.borderThickness),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: ListTile(
                  title: Text(
                    widget.title,
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(widget.description, style: tt.bodyMedium),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: selectedItems.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(selectedItems.length, (index) {
                          final item = selectedItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: resolvedBorderColor,
                                    width: widget.borderThickness),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${index + 1}.",
                                    style: tt.bodyMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      softWrap: true,
                                      style: tt.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "No ${widget.title.toLowerCase()} selected yet",
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSelectionButton(
                  resolvedBorderColor: resolvedBorderColor,
                  cs: cs,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
