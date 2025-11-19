import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';

/// Data model for lifestyle factor information
class LifestyleData {
  final String title;
  final IconData icon;

  LifestyleData({
    required this.title,
    required this.icon,
  });
}

/// Premium lifestyle card with animations and luxury styling
class LifestyleCard extends StatefulWidget {
  final LifestyleData lifestyle;
  final bool isSelected;
  final Duration animationDelay;
  final VoidCallback onTap;

  const LifestyleCard({
    super.key,
    required this.lifestyle,
    required this.isSelected,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  State<LifestyleCard> createState() => _LifestyleCardState();
}

class _LifestyleCardState extends State<LifestyleCard>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _selectionController;
  late Animation<double> _entranceAnimation;
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance animation (fade + slide)
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Selection animation (background, border, elevation)
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _selectionAnimation = CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeOutCubic,
    );

    // Start entrance animation with delay
    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });

    // Set initial selection state
    if (widget.isSelected) {
      _selectionController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LifestyleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceAnimation, _selectionAnimation]),
      builder: (context, child) {
        // Gold color from requirements
        const goldColor = Color(0xFFD1A057);
        
        // Interpolate colors and values
        final backgroundColor = Color.lerp(
          Colors.white,
          const Color(0xFFF6EDE0), // Light gold tint
          _selectionAnimation.value,
        ) ?? Colors.white;

        final borderColor = Color.lerp(
          const Color(0xFFE5E5E5).withValues(alpha: 0.3),
          goldColor,
          _selectionAnimation.value,
        ) ?? const Color(0xFFE5E5E5).withValues(alpha: 0.3);

        final borderWidth = 1.0 + (_selectionAnimation.value * 0.4); // 1px to 1.4px (within 1.3-1.5px range when selected)

        final elevation = _selectionAnimation.value * 2.0; // 0 to 2

        return Opacity(
          opacity: _entranceAnimation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _entranceAnimation.value) * 10),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05 + (_selectionAnimation.value * 0.05),
                    ),
                    blurRadius: 8 + (_selectionAnimation.value * 4),
                    offset: Offset(0, 2 + elevation),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Icon badge (left side)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: goldColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.lifestyle.icon,
                            color: Color.lerp(
                              ColorPalette.textSecondary,
                              goldColor,
                              _selectionAnimation.value,
                            ) ?? ColorPalette.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title (middle)
                        Expanded(
                          child: Text(
                            widget.lifestyle.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.lerp(
                                FontWeight.w400,
                                FontWeight.w600,
                                _selectionAnimation.value,
                              ) ?? FontWeight.w400,
                              color: Color.lerp(
                                ColorPalette.textPrimary,
                                goldColor,
                                _selectionAnimation.value,
                              ) ?? ColorPalette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Checkmark (right side) - animated
                        AnimatedOpacity(
                          opacity: _selectionAnimation.value,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: goldColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

