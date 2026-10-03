import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.label,
    this.hintText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.onSubmitted,
    required this.controller,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  bool _obscured = true;
  bool _hasError = false;
  bool _isClearingErrorOnEdit = false;

  String? _validate(String? value) {
    if (_isClearingErrorOnEdit) {
      _updateErrorModeAfterBuild(false);
      return null;
    }

    final error = widget.validator?.call(value);
    _updateErrorModeAfterBuild(error != null);
    return error;
  }

  void _updateErrorModeAfterBuild(bool hasError) {
    if (_hasError == hasError) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasError != hasError) {
        setState(() {
          _hasError = hasError;
        });
      }
    });
  }

  void _handleChanged(String value) {
    if (!_hasError) {
      return;
    }

    _isClearingErrorOnEdit = true;
    _fieldKey.currentState?.validate();
    _isClearingErrorOnEdit = false;

    if (mounted && _hasError) {
      setState(() {
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    return Semantics(
      label: widget.label,
      child: TextFormField(
        key: _fieldKey,
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onSubmitted,
        onChanged: _handleChanged,
        autovalidateMode: AutovalidateMode.disabled,
        obscureText: widget.isPassword && _obscured,
        cursorColor: colorScheme.primary,
        style: textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _obscured = !_obscured;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2.0,
            ),
          ),
        ),
        validator: _validate,
      ),
    );
  }
}
