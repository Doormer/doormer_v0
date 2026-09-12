import 'package:flutter/material.dart';

class SelectionBottomSheet extends StatefulWidget {
  final List<String> initialSelection;
  final List<String> options;
  final Function(List<String>) onSubmit;
  final VoidCallback onClose;

  final String title;
  final int maxSelection;
  final String confirmButtonText;
  final String cancelButtonText;
  final double? sheetHeight;

  /// Defaults to [ColorScheme.outlineVariant] when null.
  final Color? borderColor;
  final double borderThickness;
  /// Defaults to [ColorScheme.primary] when null.
  /// Also controls the selection-indicator badge when explicitly provided;
  /// otherwise [ColorScheme.primaryContainer] is used for the badge.
  final Color? mainColor;
  /// Defaults to [ColorScheme.onPrimary] when null.
  final Color? confirmTextColor;
  final TextStyle? titleTextStyle;
  final double buttonHeight;

  const SelectionBottomSheet({
    super.key,
    this.initialSelection = const [],
    required this.options,
    required this.onSubmit,
    required this.onClose,
    this.title = "Select Items",
    this.maxSelection = 3,
    this.confirmButtonText = "Confirm",
    this.cancelButtonText = "Cancel",
    this.sheetHeight,
    this.borderColor,
    this.borderThickness = 1.0,
    this.mainColor,
    this.confirmTextColor,
    this.titleTextStyle,
    this.buttonHeight = 40.0,
  });

  @override
  SelectionBottomSheetState createState() => SelectionBottomSheetState();
}

class SelectionBottomSheetState extends State<SelectionBottomSheet> {
  late List<String> selectedItems;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.initialSelection);
  }

  @override
  void didUpdateWidget(covariant SelectionBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelection != widget.initialSelection) {
      setState(() {
        selectedItems = List.from(widget.initialSelection);
      });
    }
  }

  void handleItemToggle(String item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        // If maximum selection reached, remove the last selected item before adding new.
        if (selectedItems.length >= widget.maxSelection) {
          selectedItems = selectedItems.sublist(0, widget.maxSelection - 1);
        }
        selectedItems.add(item);
      }
    });
  }

  List<String> get displayedOptions {
    if (searchQuery.isEmpty) return widget.options;
    return widget.options
        .where((option) =>
            option.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resolvedBorderColor = widget.borderColor ?? cs.outlineVariant;
    final resolvedMainColor = widget.mainColor ?? cs.primary;
    final resolvedConfirmTextColor = widget.confirmTextColor ?? cs.onPrimary;
    // Selection-indicator badge uses primaryContainer/onPrimaryContainer unless
    // an explicit mainColor is provided.
    final badgeColor =
        widget.mainColor != null ? resolvedMainColor : cs.primaryContainer;
    final badgeTextColor = widget.mainColor != null
        ? resolvedConfirmTextColor
        : cs.onPrimaryContainer;

    final double height =
        widget.sheetHeight ?? MediaQuery.of(context).size.height * 0.8;
    return Container(
      height: height,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: widget.titleTextStyle ?? tt.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "${selectedItems.length}/${widget.maxSelection} items selected",
              style: tt.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: "Search...",
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: cs.outlineVariant,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: cs.primary,
                  width: 2.0,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: displayedOptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = displayedOptions[index];
                final isSelected = selectedItems.contains(item);
                final selectionIndex = selectedItems.indexOf(item);
                return InkWell(
                  onTap: () => handleItemToggle(item),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? resolvedMainColor
                            : resolvedBorderColor,
                        width: widget.borderThickness,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? badgeColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item, softWrap: true, style: tt.bodyMedium),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: badgeColor,
                              child: Text(
                                (selectionIndex + 1).toString(),
                                style: TextStyle(
                                  color: badgeTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          _buildFooterButtons(
            resolvedMainColor: resolvedMainColor,
            resolvedBorderColor: resolvedBorderColor,
            resolvedConfirmTextColor: resolvedConfirmTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons({
    required Color resolvedMainColor,
    required Color resolvedBorderColor,
    required Color resolvedConfirmTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: widget.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: widget.onClose,
              icon: Icon(Icons.close, color: resolvedMainColor),
              label: Text(
                widget.cancelButtonText,
                style: TextStyle(color: resolvedMainColor),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, widget.buttonHeight),
                side: BorderSide(
                  color: resolvedBorderColor,
                  width: widget.borderThickness,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: widget.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: selectedItems.isEmpty
                  ? null
                  : () => widget.onSubmit(selectedItems),
              icon: Icon(Icons.check, color: resolvedConfirmTextColor),
              label: Text(
                widget.confirmButtonText,
                style: TextStyle(color: resolvedConfirmTextColor),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, widget.buttonHeight),
                backgroundColor: resolvedMainColor,
                foregroundColor: resolvedConfirmTextColor,
                side: BorderSide(
                  color: resolvedMainColor,
                  width: widget.borderThickness,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
