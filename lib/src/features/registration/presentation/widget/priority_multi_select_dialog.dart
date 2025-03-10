import 'package:flutter/material.dart';
import 'package:doormer/src/core/theme/app_colors.dart';
import 'package:doormer/src/core/theme/app_text_styles.dart';

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
    Key? key,
    required this.options,
    required this.initialSelected,
    this.maxSelection = 3,
    this.dialogTitle = 'Select options',
    this.buttonColor = AppColors.primary,
    this.badgeColor = AppColors.primary,
    this.circularAvatarTextColor = AppColors.surface,
  }) : super(key: key);

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
