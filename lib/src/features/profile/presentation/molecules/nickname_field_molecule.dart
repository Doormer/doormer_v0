import 'package:flutter/material.dart';

/// The nickname box, with the hint not to use a full name, and why the
/// nickname can't be saved when it can't.
class NicknameFieldMolecule extends StatelessWidget {
  /// What the box starts with: the saved nickname, or nothing.
  final String initialNickname;

  /// Why the nickname can't be saved. Null when nothing is wrong.
  final String? problem;

  final ValueChanged<String> onChanged;

  /// The student pressed Enter.
  final VoidCallback onSubmitted;

  const NicknameFieldMolecule({
    super.key,
    required this.initialNickname,
    required this.problem,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('nickname_field'),
      initialValue: initialNickname,
      onChanged: onChanged,
      onFieldSubmitted: (_) => onSubmitted(),
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
