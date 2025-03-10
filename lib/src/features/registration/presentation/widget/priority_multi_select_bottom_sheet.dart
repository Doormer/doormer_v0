import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class MultiSelectBottomSheet extends StatefulWidget {
  final List<String> options;
  final List<String> initialSelected;
  final int maxSelection;
  final String dialogTitle;
  final Color buttonColor;
  final Color badgeColor;
  final Color circularAvatarTextColor;
  final ValueChanged<List<String>>? onSelectionChanged;

  const MultiSelectBottomSheet({
    super.key,
    required this.options,
    required this.initialSelected,
    this.maxSelection = 3,
    this.dialogTitle = 'Select options',
    this.buttonColor = Colors.blue,
    this.badgeColor = Colors.blue,
    this.circularAvatarTextColor = Colors.white,
    this.onSelectionChanged,
  });

  @override
  MultiSelectBottomSheetState createState() => MultiSelectBottomSheetState();
}

class MultiSelectBottomSheetState extends State<MultiSelectBottomSheet> {
  late List<String> tempSelected;

  @override
  void initState() {
    super.initState();
    tempSelected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensures full width.
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          // Adjust padding for any viewInsets (e.g., keyboard).
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            children: [
              // Header with title and a close icon.
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(widget.dialogTitle, style: AppTextStyles.titleMedium),
                    // The close icon dismisses the bottom sheet.
                    // IconButton(
                    //   icon: const Icon(Icons.close),
                    //   onPressed: () => Navigator.pop(context, tempSelected),
                    // ),
                  ],
                ),
              ),
              const Divider(),
              // Options list.
              Expanded(
                child: ListView(
                  children: _buildOptionsList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionsList() {
    return widget.options.map((option) {
      final int selectedIndex = tempSelected.indexOf(option);
      return ListTile(
        title: Text(option),
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
    // Notify parent immediately of the updated selection.
    widget.onSelectionChanged?.call(tempSelected);
  }
}
