import 'package:doormer/src/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:doormer/src/core/theme/app_colors.dart';

class CustomTextFieldWeb extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CustomTextFieldWeb({
    super.key,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 8),
        // Wrap the TextFormField in a Theme widget to override hover effects.
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
            style: AppTextStyles.inputText, // Your text style
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.hintText, // Your hint style
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppColors.borders),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppColors.borders),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppColors.focusedBorders),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
