import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:doormer/src/features/registration/presentation/widget/priority_multi_select_bottom_sheet.dart';
import 'package:doormer/src/features/registration/utils/priority_multi_select_menu_controller.dart';
import 'package:flutter/material.dart';

/// A reusable widget that displays a dropdown for multi-selection.
class PriorityMultiSelectMenu extends StatefulWidget {
  final List<String> options;
  final int maxSelection;
  final String dialogTitle;
  final String hintText;
  final Color mainColor;
  final Color buttonColor;
  final Color badgeColor;
  final Color circularAvatarTextColor;
  final ValueChanged<List<String>>? onSelectionChanged;
  final MultiSelectController? controller; // New controller parameter

  const PriorityMultiSelectMenu({
    super.key,
    required this.options,
    this.controller,
    this.maxSelection = 3,
    this.dialogTitle = 'Select options',
    this.hintText = 'Select options',
    this.mainColor = Colors.white,
    this.buttonColor = Colors.blue,
    this.badgeColor = Colors.blue,
    this.circularAvatarTextColor = Colors.white,
    this.onSelectionChanged,
  });

  @override
  PriorityMultiSelectMenuState createState() => PriorityMultiSelectMenuState();
}

class PriorityMultiSelectMenuState extends State<PriorityMultiSelectMenu> {
  List<String> selectedItems = [];

  @override
  void initState() {
    super.initState();
    // If a controller is provided, initialize the local state and listen for updates.
    if (widget.controller != null) {
      selectedItems = widget.controller!.value;
      widget.controller!.addListener(_updateFromController);
    }
  }

  void _updateFromController() {
    setState(() {
      selectedItems = widget.controller!.value;
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updateFromController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openMultiSelectBottomSheet,
      child: _buildDropdownContainer(),
    );
  }

  // Updated UI to match the TextFormField look and adjust text styles.
  Widget _buildDropdownContainer() {
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.borders),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.borders),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.borders, width: 2.0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: selectedItems.isEmpty
                ? Text(
                    widget.hintText,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.hintText,
                  )
                : RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: selectedItems.asMap().entries.map((entry) {
                        return TextSpan(
                          text: '${entry.key + 1}. ',
                          style:
                              AppTextStyles.selectedText, // Style for numbering
                          children: [
                            TextSpan(
                              text: entry.value +
                                  (entry.key < selectedItems.length - 1
                                      ? ', '
                                      : ''),
                              style: AppTextStyles
                                  .selectedText, // Style for selected text
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.hintIcon,
          ),
        ],
      ),
    );
  }

  Future<void> _openMultiSelectBottomSheet() async {
    final List<String>? result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          widthFactor:
              1.0, // Ensures the bottom sheet spans the full window width.
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: MultiSelectBottomSheet(
              options: widget.options,
              initialSelected: selectedItems,
              maxSelection: widget.maxSelection,
              dialogTitle: widget.dialogTitle,
              buttonColor: widget.buttonColor,
              badgeColor: widget.badgeColor,
              circularAvatarTextColor: widget.circularAvatarTextColor,
              // Listener to update as selection changes inside the bottom sheet.
              onSelectionChanged: (updatedSelection) {
                setState(() {
                  selectedItems = updatedSelection;
                });
                if (widget.controller != null) {
                  widget.controller!.value = updatedSelection;
                }
                if (widget.onSelectionChanged != null) {
                  widget.onSelectionChanged!(updatedSelection);
                }
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      // When the bottom sheet is dismissed with a final result,
      // update the local state, controller, and notify listeners.
      setState(() {
        selectedItems = result;
      });
      if (widget.controller != null) {
        widget.controller!.value = result;
      }
      if (widget.onSelectionChanged != null) {
        widget.onSelectionChanged!(result);
      }
    }
  }
}
