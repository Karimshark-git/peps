import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

/// Dark glass surface with 1px border and top shine line
class PepsGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool selected;
  final Color? backgroundColor;

  const PepsGlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 16,
    this.selected = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (selected
            ? ColorPalette.gold.withValues(alpha: 0.08)
            : ColorPalette.cardBackground);
    final borderColor =
        selected ? ColorPalette.accentBorder : ColorPalette.cardBorder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.shadowLight,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(padding: padding, child: child),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
