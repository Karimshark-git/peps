import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

/// Primary CTA — teal, no elevation
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isLoading;
  final double? width;
  /// When set, overrides [TextStyles.buttonText] color (e.g. dark green on teal).
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.width,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effective = isEnabled && !isLoading;
    final labelStyle = textColor != null
        ? TextStyles.buttonText.copyWith(color: textColor)
        : TextStyles.buttonText;
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: effective ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.gold,
          foregroundColor: ColorPalette.buttonOnAccent,
          disabledBackgroundColor: ColorPalette.gold.withValues(alpha: 0.35),
          disabledForegroundColor:
              ColorPalette.buttonOnAccent.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? ColorPalette.buttonOnAccent,
                  ),
                ),
              )
            : Text(
                text,
                style: labelStyle,
              ),
      ),
    );
  }
}
