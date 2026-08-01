import 'package:flutter/material.dart';

class MultiSelectBottomSheet extends StatefulWidget {
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
  final ValueChanged<List<String>>? onSelectionChanged;

  const MultiSelectBottomSheet({
    super.key,
    required this.options,
    required this.initialSelected,
    this.maxSelection = 3,
    this.dialogTitle = 'Select options',
    this.buttonColor,
    this.badgeColor,
    this.circularAvatarTextColor,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resolvedBadgeColor = widget.badgeColor ?? cs.primaryContainer;
    final resolvedAvatarTextColor =
        widget.circularAvatarTextColor ?? cs.onPrimaryContainer;
    final resolvedButtonColor = widget.buttonColor ?? cs.primary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(widget.dialogTitle, style: tt.titleMedium),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: _buildOptionsList(
                    tt: tt,
                    badgeColor: resolvedBadgeColor,
                    avatarTextColor: resolvedAvatarTextColor,
                    buttonColor: resolvedButtonColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionsList({
    required TextTheme tt,
    required Color badgeColor,
    required Color avatarTextColor,
    required Color buttonColor,
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
    // Notify parent immediately of the updated selection.
    widget.onSelectionChanged?.call(tempSelected);
  }
}
