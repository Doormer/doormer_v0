import 'package:doormer/src/core/theme/app_theme_context.dart';
import 'package:flutter/material.dart';

class CustomTextFieldWeb extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Color? borderColor;
  final double? borderThickness;

  const CustomTextFieldWeb({
    super.key,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.controller,
    this.validator,
    this.borderColor,
    this.borderThickness,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final Color effectiveBorderColor = borderColor ?? cs.outlineVariant;
    final double effectiveBorderThickness = borderThickness ?? 1.0;

    final borderSide = BorderSide(
      color: effectiveBorderColor,
      width: effectiveBorderThickness,
    );
    final borderRadius = BorderRadius.circular(8.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.bodyMedium),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            cursorColor: cs.primary,
            style: tt.bodyMedium,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: borderSide,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: borderSide,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: borderRadius,
                borderSide: borderSide,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
