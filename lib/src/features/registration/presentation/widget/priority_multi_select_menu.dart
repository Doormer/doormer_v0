import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:doormer/src/features/registration/presentation/widget/priority_multi_select_bottom_sheet.dart';
import 'package:doormer/src/features/registration/utils/priority_multi_select_menu_controller.dart';
import 'package:flutter/material.dart';

/// A reusable widget that displays a dropdown for multi-selection.
class PriorityMultiSelectMenu extends StatefulWidget {
  final List<String> options;
  final int maxSelection;
  final String dialogTitle;
  final String hintText;
  /// Unused internally; kept for API compatibility. Defaults null.
  final Color? mainColor;
  /// Defaults to [ColorScheme.primary] when null.
  final Color? buttonColor;
  /// Defaults to [ColorScheme.primaryContainer] when null.
  final Color? badgeColor;
  /// Defaults to [ColorScheme.onPrimaryContainer] when null.
  final Color? circularAvatarTextColor;
  final ValueChanged<List<String>>? onSelectionChanged;
  final MultiSelectController? controller;

  const PriorityMultiSelectMenu({
    super.key,
    required this.options,
    this.controller,
    this.maxSelection = 3,
    this.dialogTitle = 'Select options',
    this.hintText = 'Select options',
    this.mainColor,
    this.buttonColor,
    this.badgeColor,
    this.circularAvatarTextColor,
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
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return GestureDetector(
      onTap: _openMultiSelectBottomSheet,
      child: _buildDropdownContainer(cs: cs, tt: tt),
    );
  }

  Widget _buildDropdownContainer({
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: cs.outlineVariant),
    );
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        border: normalBorder,
        enabledBorder: normalBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: cs.primary, width: 2.0),
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
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  )
                : RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: selectedItems.asMap().entries.map((entry) {
                        return TextSpan(
                          text: '${entry.key + 1}. ',
                          style: tt.bodyMedium,
                          children: [
                            TextSpan(
                              text: entry.value +
                                  (entry.key < selectedItems.length - 1
                                      ? ', '
                                      : ''),
                              style: tt.bodyMedium,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
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
        final surface = Theme.of(context).colorScheme.surface;
        return FractionallySizedBox(
          widthFactor: 1.0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: MultiSelectBottomSheet(
              options: widget.options,
              initialSelected: selectedItems,
              maxSelection: widget.maxSelection,
              dialogTitle: widget.dialogTitle,
              buttonColor: widget.buttonColor,
              badgeColor: widget.badgeColor,
              circularAvatarTextColor: widget.circularAvatarTextColor,
              onSelectionChanged: (updatedSelection) {
                setState(() {
                  selectedItems = updatedSelection;
                });
                if (widget.controller != null) {
                  widget.controller!.value = updatedSelection;
                }
                widget.onSelectionChanged?.call(updatedSelection);
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedItems = result;
      });
      if (widget.controller != null) {
        widget.controller!.value = result;
      }
      widget.onSelectionChanged?.call(result);
    }
  }
}
