import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';

/// Data model for goal information
class GoalData {
  final String title;
  final String subtitle;
  final IconData icon;

  GoalData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Premium goal card with icon, animations, and luxury styling
class GoalCard extends StatefulWidget {
  final GoalData goal;
  final bool isSelected;
  final Duration animationDelay;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.isSelected,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
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
  void didUpdateWidget(GoalCard oldWidget) {
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
        // Interpolate colors and values
        final backgroundColor = Color.lerp(
          Colors.white,
          const Color(0xFFF6EDE0), // Light gold tint
          _selectionAnimation.value,
        ) ?? Colors.white;

        final borderColor = Color.lerp(
          const Color(0xFFE5E5E5).withValues(alpha: 0.3),
          const Color(0xFFC7A572), // Gold
          _selectionAnimation.value,
        ) ?? const Color(0xFFE5E5E5).withValues(alpha: 0.3);

        final borderWidth = 1.0 + (_selectionAnimation.value * 1.0); // 1px to 2px

        final elevation = _selectionAnimation.value * 2.0; // 0 to 2

        return Opacity(
          opacity: _entranceAnimation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _entranceAnimation.value) * 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(19),
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
                  borderRadius: BorderRadius.circular(19),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Icon badge (left side)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7A572)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.goal.icon,
                            color: Color.lerp(
                              ColorPalette.textSecondary,
                              const Color(0xFFC7A572),
                              _selectionAnimation.value,
                            ) ?? ColorPalette.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title and subtitle (middle)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.goal.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ColorPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.goal.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: ColorPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkmark (right side) - animated
                        AnimatedOpacity(
                          opacity: _selectionAnimation.value,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFFC7A572),
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

