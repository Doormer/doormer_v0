import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:doormer/src/core/theme/app_colors.dart';

class CustomTextFieldWeb extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  // New configuration parameters for border styling.
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
    final Color effectiveBorderColor = borderColor ?? AppColors.borders;
    final double effectiveBorderThickness = borderThickness ?? 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium,
        ),
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
            cursorColor: AppColors.primary,
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.hintText,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: effectiveBorderColor,
                  width: effectiveBorderThickness,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: effectiveBorderColor,
                  width: effectiveBorderThickness,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: effectiveBorderColor,
                  width: effectiveBorderThickness,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
