import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Controller to hold the selected items of a PriorityMultiSelectMenu.
class MultiSelectController extends ValueNotifier<List<String>> {
  MultiSelectController([List<String>? initialValue])
      : super(initialValue ?? []);

  List<String> get selectedItems => value;
  set selectedItems(List<String> items) => value = items;
}

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
      onTap: _openMultiSelectDialog,
      child: _buildDropdownContainer(),
    );
  }

  // Updated UI to match the TextFormField look and adjust text styles.
  Widget _buildDropdownContainer() {
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
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

  Future<void> _openMultiSelectDialog() async {
    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          options: widget.options,
          initialSelected: selectedItems,
          maxSelection: widget.maxSelection,
          dialogTitle: widget.dialogTitle,
          buttonColor: widget.buttonColor,
          badgeColor: widget.badgeColor,
          circularAvatarTextColor: widget.circularAvatarTextColor,
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
      if (widget.onSelectionChanged != null) {
        widget.onSelectionChanged!(selectedItems);
      }
    }
  }
}

/// Dialog for selecting multiple options.
class MultiSelectDialog extends StatefulWidget {
  final List<String> options;
  final List<String> initialSelected;
  final int maxSelection;
  final String dialogTitle;
  final Color buttonColor;
  final Color badgeColor;
  final Color circularAvatarTextColor;

  const MultiSelectDialog({
    super.key,
    required this.options,
    required this.initialSelected,
    this.maxSelection = 3,
    this.dialogTitle = 'Select options',
    this.buttonColor = AppColors.primary,
    this.badgeColor = AppColors.primary,
    this.circularAvatarTextColor = AppColors.surface,
  });

  @override
  MultiSelectDialogState createState() => MultiSelectDialogState();
}

class MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> tempSelected;
  static const double _maxDialogWidth = 500;

  @override
  void initState() {
    super.initState();
    tempSelected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double dialogWidth = constraints.maxWidth * 0.8 > _maxDialogWidth
            ? _maxDialogWidth
            : constraints.maxWidth * 0.8;
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          title: Text(
            widget.dialogTitle,
            style: AppTextStyles.bodyLarge,
          ),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: ListBody(
                children: _buildOptionsList(),
              ),
            ),
          ),
          actions: _buildDialogActions(),
        );
      },
    );
  }

  List<Widget> _buildOptionsList() {
    return widget.options.map((option) {
      final int selectedIndex = tempSelected.indexOf(option);
      return ListTile(
        title: Text(
          option,
          style: AppTextStyles.bodyMedium,
        ),
        trailing:
            selectedIndex != -1 ? _buildSelectionBadge(selectedIndex) : null,
        onTap: () => _toggleOption(option, selectedIndex),
      );
    }).toList();
  }

  Widget _buildSelectionBadge(int selectedIndex) {
    return CircleAvatar(
      backgroundColor: widget.badgeColor,
      radius: 14,
      child: Text(
        '${selectedIndex + 1}',
        style: TextStyle(
          color: widget.circularAvatarTextColor,
          fontSize: 12,
        ),
      ),
    );
  }

  void _toggleOption(String option, int selectedIndex) {
    setState(() {
      if (selectedIndex != -1) {
        tempSelected.remove(option);
      } else if (tempSelected.length < widget.maxSelection) {
        tempSelected.add(option);
      }
    });
  }

  List<Widget> _buildDialogActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel', style: TextStyle(color: widget.buttonColor)),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, tempSelected),
        child: Text('OK', style: TextStyle(color: widget.buttonColor)),
      ),
    ];
  }
}
