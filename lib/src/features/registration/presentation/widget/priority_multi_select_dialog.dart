import 'package:flutter/material.dart';

/// Dialog for selecting multiple options.
class MultiSelectDialog extends StatefulWidget {
  final List<String> options;
  final List<String> initialSelected;
  final int maxSelection;
  final String dialogTitle;
  /// Defaults to [ColorScheme.primary] when null.
  final Color? buttonColor;
  /// Defaults to [ColorScheme.primaryContainer] when null.
  final Color? badgeColor;
  /// Defaults to [ColorScheme.onPrimaryContainer] when null.
  final Color? circularAvatarTextColor;

  const MultiSelectDialog({
    super.key,
    required this.options,
    required this.initialSelected,
    this.maxSelection = 3,
    this.dialogTitle = 'Select options',
    this.buttonColor,
    this.badgeColor,
    this.circularAvatarTextColor,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resolvedButtonColor = widget.buttonColor ?? cs.primary;
    final resolvedBadgeColor = widget.badgeColor ?? cs.primaryContainer;
    final resolvedAvatarTextColor =
        widget.circularAvatarTextColor ?? cs.onPrimaryContainer;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double dialogWidth = constraints.maxWidth * 0.8 > _maxDialogWidth
            ? _maxDialogWidth
            : constraints.maxWidth * 0.8;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          title: Text(widget.dialogTitle, style: tt.titleMedium),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: ListBody(
                children: _buildOptionsList(
                  tt: tt,
                  badgeColor: resolvedBadgeColor,
                  avatarTextColor: resolvedAvatarTextColor,
                ),
              ),
            ),
          ),
          actions: _buildDialogActions(buttonColor: resolvedButtonColor),
        );
      },
    );
  }

  List<Widget> _buildOptionsList({
    required TextTheme tt,
    required Color badgeColor,
    required Color avatarTextColor,
  }) {
    return widget.options.map((option) {
      final int selectedIndex = tempSelected.indexOf(option);
      return ListTile(
        title: Text(option, style: tt.bodyMedium),
        trailing: selectedIndex != -1
            ? _buildSelectionBadge(
                selectedIndex,
                badgeColor: badgeColor,
                avatarTextColor: avatarTextColor,
              )
            : null,
        onTap: () => _toggleOption(option, selectedIndex),
      );
    }).toList();
  }

  Widget _buildSelectionBadge(
    int selectedIndex, {
    required Color badgeColor,
    required Color avatarTextColor,
  }) {
    return CircleAvatar(
      backgroundColor: badgeColor,
      radius: 14,
      child: Text(
        '${selectedIndex + 1}',
        style: TextStyle(color: avatarTextColor, fontSize: 12),
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

  List<Widget> _buildDialogActions({required Color buttonColor}) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel', style: TextStyle(color: buttonColor)),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, tempSelected),
        child: Text('OK', style: TextStyle(color: buttonColor)),
      ),
    ];
  }
}
