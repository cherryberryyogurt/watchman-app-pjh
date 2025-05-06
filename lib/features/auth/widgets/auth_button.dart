import 'package:flutter/material.dart';
import '../../../core/theme/index.dart';

enum AuthButtonType {
  primary,
  secondary,
  text,
}

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final AuthButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? padding;
  final double? width;
  final double? height;

  const AuthButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = AuthButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AuthButtonType.primary:
        return _buildPrimaryButton(context);
      case AuthButtonType.secondary:
        return _buildSecondaryButton(context);
      case AuthButtonType.text:
        return _buildTextButton(context);
    }
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? Dimensions.buttonLg,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLg),
          ),
          padding: padding ?? EdgeInsets.zero,
          disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
              ? ColorPalette.primary.withOpacity(0.5)
              : ColorPalette.primary.withOpacity(0.7),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: TextStyles.button.copyWith(
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? Dimensions.buttonLg,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? ColorPalette.textPrimaryDark
              : ColorPalette.textPrimaryLight,
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? ColorPalette.borderDark
                : ColorPalette.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusLg),
          ),
          padding: padding ?? EdgeInsets.zero,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).brightness == Brightness.dark
                        ? ColorPalette.textPrimaryDark
                        : ColorPalette.textPrimaryLight,
                  ),
                ),
              )
            : Text(
                text,
                style: TextStyles.button.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ColorPalette.textPrimaryDark
                      : ColorPalette.textPrimaryLight,
                ),
              ),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ColorPalette.primary,
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSm,
          vertical: Dimensions.paddingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorPalette.primary,
                ),
              ),
            )
          : Text(
              text,
              style: TextStyles.button.copyWith(
                color: ColorPalette.primary,
              ),
            ),
    );
  }
} 