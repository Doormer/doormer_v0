import 'package:flutter/material.dart';

/// The nickname box, with the hint not to use a full name, and why the
/// nickname can't be saved when it can't.
///
/// Enter only closes the keyboard. Saving is Done's alone, since tapping it,
/// under what friends will see, is the student's agreement.
class NicknameFieldMolecule extends StatelessWidget {
  /// What the box starts with: the saved nickname, or nothing.
  final String initialNickname;

  /// Why the nickname can't be saved. Null when nothing is wrong.
  final String? problem;

  final ValueChanged<String> onChanged;

  const NicknameFieldMolecule({
    super.key,
    required this.initialNickname,
    required this.problem,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('nickname_field'),
      initialValue: initialNickname,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: 'Nickname',
        helperText: "Don't use your full name.",
        errorText: problem,
      ),
    );
  }
}
