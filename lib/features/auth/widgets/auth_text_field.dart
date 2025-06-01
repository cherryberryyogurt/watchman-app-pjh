import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final EdgeInsets? contentPadding;

  const AuthTextField({
    super.key,
    required this.label,
    this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.labelLarge.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? ColorPalette.textPrimaryDark
                : ColorPalette.textPrimaryLight,
          ),
        ),
        const SizedBox(height: Dimensions.spacingSm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          focusNode: focusNode,
          autofocus: autofocus,
          style: TextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? ColorPalette.textPrimaryDark
                : ColorPalette.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyles.bodyMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ColorPalette.textTertiaryDark
                  : ColorPalette.textTertiaryLight,
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            contentPadding: contentPadding ?? const EdgeInsets.all(Dimensions.padding),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? ColorPalette.surfaceVariantDark
                : ColorPalette.surfaceVariantLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radius),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radius),
              borderSide: BorderSide(
                color: ColorPalette.primary,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radius),
              borderSide: BorderSide(
                color: ColorPalette.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radius),
              borderSide: BorderSide(
                color: ColorPalette.error,
                width: 1,
              ),
            ),
            errorStyle: TextStyles.labelSmall.copyWith(
              color: ColorPalette.error,
            ),
          ),
        ),
      ],
    );
  }
} 