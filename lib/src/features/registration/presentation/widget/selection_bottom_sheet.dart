import 'package:flutter/material.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/core/theme/app_colors.dart';

class SelectionBottomSheet extends StatefulWidget {
  final List<String> initialSelection;
  final List<String> options;
  final Function(List<String>) onSubmit;
  final VoidCallback onClose;

  // Configurable properties.
  final String title;
  final int maxSelection;
  final String confirmButtonText;
  final String cancelButtonText;
  final double? sheetHeight;

  // New parameters for styling.
  final Color borderColor;
  final double borderThickness;
  final Color mainColor;
  final Color confirmTextColor;
  final TextStyle? titleTextStyle;
  // New parameter: unified button height.
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
    this.borderColor = Colors.black,
    this.borderThickness = 1.0,
    this.mainColor = Colors.black,
    this.confirmTextColor = Colors.white,
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
    final double height =
        widget.sheetHeight ?? MediaQuery.of(context).size.height * 0.8;
    return Container(
      height: height,
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.zero, // Remove round edges on top.
      ),
      child: Column(
        children: [
          // Header with title using AppTextStyles.titleMedium.
          Text(
            widget.title,
            style: widget.titleTextStyle ?? AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Align the selection summary to the left.
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "${selectedItems.length}/${widget.maxSelection} items selected",
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar with updated border and hint style.
          TextField(
            decoration: InputDecoration(
              hintText: "Search...",
              hintStyle: AppTextStyles.hintText,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.black,
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
          // Scrollable list with one row per option.
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
                        color:
                            isSelected ? widget.mainColor : widget.borderColor,
                        width: widget.borderThickness,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? widget.mainColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            softWrap: true,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: widget.mainColor,
                              child: Text(
                                (selectionIndex + 1).toString(),
                                style: TextStyle(
                                  color: widget.confirmTextColor,
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
          // Footer with cancel and confirm buttons.
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: widget.buttonHeight,
                  child: OutlinedButton.icon(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close, color: widget.mainColor),
                    label: Text(
                      widget.cancelButtonText,
                      style: TextStyle(color: widget.mainColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, widget.buttonHeight),
                      side: BorderSide(
                        color: widget.borderColor,
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
                    icon: Icon(Icons.check, color: widget.confirmTextColor),
                    label: Text(
                      widget.confirmButtonText,
                      style: TextStyle(color: widget.confirmTextColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, widget.buttonHeight),
                      backgroundColor: widget.mainColor,
                      foregroundColor: widget.confirmTextColor,
                      side: BorderSide(
                        color: widget.mainColor,
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
          )
        ],
      ),
    );
  }
}
