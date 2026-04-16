import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

/// Teal (top-right) + blue (bottom-left) radial glow — auth & welcome-style backgrounds.
class PepsAmbientOrbs extends StatelessWidget {
  const PepsAmbientOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -size.width * 0.15,
            top: -size.height * 0.05,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorPalette.gold.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -size.width * 0.2,
            bottom: -size.height * 0.08,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorPalette.blueAccent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
