import 'package:doormer/src/shared/design/atomic/atoms/app_button_atom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A box to type a friend's code, and Find.
class FindFriendMolecule extends StatefulWidget {
  /// What the box starts with: an invite's code, or nothing.
  final String initialCode;

  final bool isFinding;

  /// Takes the code as typed.
  final ValueChanged<String> onFind;

  const FindFriendMolecule({
    super.key,
    required this.initialCode,
    required this.isFinding,
    required this.onFind,
  });

  @override
  State<FindFriendMolecule> createState() => _FindFriendMoleculeState();
}

class _FindFriendMoleculeState extends State<FindFriendMolecule> {
  late final _code = TextEditingController(text: widget.initialCode);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _find() => widget.onFind(_code.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: const Key('friend_code_field'),
            controller: _code,
            onSubmitted: (_) => _find(),
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: "A friend's code"),
          ),
        ),
        SizedBox(width: 8.w),
        AppButtonAtom(
          label: 'Find',
          isLoading: widget.isFinding,
          onPressed: _find,
        ),
      ],
    );
  }
}
