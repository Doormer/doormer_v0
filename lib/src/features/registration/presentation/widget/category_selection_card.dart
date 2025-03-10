import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/features/registration/presentation/widget/selection_bottom_sheet.dart';
import 'package:doormer/src/features/registration/utils/priority_multi_select_menu_controller.dart';
import 'package:flutter/material.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';

/// A reusable widget that encapsulates an entire category selection field:
/// - Displays a title, description, selected items (as dynamic “chips”), and a button.
/// - When the button is pressed, it opens a bottom sheet for the user to select items.
/// - The widget manages its own selection state and notifies a listener (onSelectionChanged)
///   when selections change, and/or uses a [MultiSelectController] to track selections externally.
/// - It uses an outlined container with a configurable border (color and thickness).
class CategorySelectionCard extends StatefulWidget {
  final String title;
  final String description;
  final List<String> options;
  final List<String> initialSelection;
  // Callback to notify parent of selection changes.
  final ValueChanged<List<String>>? onSelectionChanged;
  // Optional: controller to track selection externally.
  final MultiSelectController? controller;
  // Optional: fixed card width; if not provided, the card fills the available width.
  final double? cardWidth;
  // Optional: border color and thickness applied to container and selection chips.
  final Color borderColor;
  final double borderThickness;
  // New parameter: unified button height for the selection button.
  final double buttonHeight;

  const CategorySelectionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.options,
    this.initialSelection = const [],
    this.onSelectionChanged,
    this.controller,
    this.cardWidth,
    this.borderColor = Colors.grey,
    this.borderThickness = 1,
    this.buttonHeight = 40.0,
  }) : super(key: key);

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
            if (widget.onSelectionChanged != null) {
              widget.onSelectionChanged!(newSelection);
            }
          },
          borderColor: widget.borderColor,
          borderThickness: widget.borderThickness,
          buttonHeight: widget.buttonHeight,
        );
      },
    );
  }

  Widget _buildSelectionButton() {
    final ButtonStyle style = selectedItems.isEmpty
        ? OutlinedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side:
                BorderSide(color: Colors.black, width: widget.borderThickness),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            minimumSize: Size(double.infinity, widget.buttonHeight),
            textStyle: AppTextStyles.buttonText,
          )
        : OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: BorderSide(
                color: widget.borderColor, width: widget.borderThickness),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            minimumSize: Size(double.infinity, widget.buttonHeight),
            textStyle: AppTextStyles.buttonText,
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
    // Use provided cardWidth if given, otherwise fill the available width.
    final double width = widget.cardWidth ?? double.infinity;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: widget.borderColor, width: widget.borderThickness),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Added padding on top of the title.
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: ListTile(
                  title: Text(
                    widget.title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      Text(widget.description, style: AppTextStyles.bodyMedium),
                ),
              ),
              // Content: display selected items as chips.
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
                                    color: widget.borderColor,
                                    width: widget.borderThickness),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${index + 1}.",
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      softWrap: true,
                                      style: AppTextStyles.bodyMedium,
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
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.hintText),
                          ),
                        ),
                      ),
              ),
              // Footer: button to open bottom sheet.
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSelectionButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
