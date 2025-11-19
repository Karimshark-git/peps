import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/color_palette.dart';
import '../provider/onboarding_provider.dart';

/// Premium Medical Information screen with global PEPS design system
class MedicalScreen extends StatefulWidget {
  const MedicalScreen({super.key});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen>
    with TickerProviderStateMixin {
  final List<MedicalCondition> _medicalConditions = [
    MedicalCondition(
      title: 'Diabetes',
      icon: Icons.bloodtype,
    ),
    MedicalCondition(
      title: 'Hypertension',
      icon: Icons.favorite,
    ),
    MedicalCondition(
      title: 'Heart Conditions',
      icon: Icons.favorite_border,
    ),
    MedicalCondition(
      title: 'Autoimmune Disorders',
      icon: Icons.health_and_safety,
    ),
    MedicalCondition(
      title: 'Thyroid Issues',
      icon: Icons.medical_services,
    ),
    MedicalCondition(
      title: 'Hormonal Imbalances',
      icon: Icons.balance,
    ),
    MedicalCondition(
      title: 'Chronic Pain',
      icon: Icons.healing,
    ),
    MedicalCondition(
      title: 'Digestive Issues',
      icon: Icons.restaurant,
    ),
    MedicalCondition(
      title: 'Kidney or Liver Conditions',
      icon: Icons.medical_information,
    ),
    MedicalCondition(
      title: 'Blood Clotting Issues',
      icon: Icons.water_drop,
    ),
    MedicalCondition(
      title: 'None of the above',
      icon: Icons.check_circle_outline,
    ),
  ];

  final Set<String> _selectedMedical = {};
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;
  late AnimationController _pageAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Page entrance animation
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _pageSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start page animation
    _pageAnimationController.forward();

    // Load saved medical data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      final savedMedical = provider.model.medical['conditions'] as List<dynamic>?;
      if (savedMedical != null) {
        setState(() {
          _selectedMedical.addAll(savedMedical.cast<String>());
        });
      }
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  void _saveMedical() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.updateMedical({
      'conditions': _selectedMedical.toList(),
    });
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedMedical.contains(condition)) {
        _selectedMedical.remove(condition);
      } else {
        // If "None of the above" is selected, clear others
        if (condition == 'None of the above') {
          _selectedMedical.clear();
          _selectedMedical.add(condition);
        } else {
          // Remove "None of the above" if selecting something else
          _selectedMedical.remove('None of the above');
          _selectedMedical.add(condition);
        }
      }
    });
    // Auto-save on selection change
    _saveMedical();
  }

  bool get _hasSelection => _selectedMedical.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStartX = details.globalPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        _dragCurrentX = details.globalPosition.dx;
      },
      onHorizontalDragEnd: (details) {
        final dragDistance = _dragCurrentX - _dragStartX;
        // Swipe right (from left to right) to go back
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300 &&
            dragDistance > 50) {
          _saveMedical();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: ColorPalette.background,
        body: SafeArea(
          child: FadeTransition(
            opacity: _pageFadeAnimation,
            child: SlideTransition(
              position: _pageSlideAnimation,
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                    child: OnboardingProgressBar(stepIndex: 5),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          // Title - Premium serif
                          Text(
                            'Medical Information',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Subtitle - Soft gray
                          Text(
                            'Select any conditions that apply. This helps us create a safe protocol.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: ColorPalette.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Medical conditions list
                          Expanded(
                            child: ListView.builder(
                              itemCount: _medicalConditions.length,
                              itemBuilder: (context, index) {
                                final condition = _medicalConditions[index];
                                final isSelected = _selectedMedical.contains(condition.title);
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _medicalConditions.length - 1 ? 12 : 0,
                                  ),
                                  child: _MedicalConditionCard(
                                    condition: condition,
                                    isSelected: isSelected,
                                    animationDelay: Duration(milliseconds: 50 * index),
                                    onTap: () => _toggleCondition(condition.title),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Complete button
                          PrimaryButton(
                            text: 'Complete',
                            isEnabled: _hasSelection,
                            onPressed: _hasSelection
                                ? () {
                                    _saveMedical();
                                    // Navigate to protocol building screen
                                    Navigator.pushNamed(context, '/protocol-building');
                                  }
                                : null,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data model for medical condition
class MedicalCondition {
  final String title;
  final IconData icon;

  MedicalCondition({
    required this.title,
    required this.icon,
  });
}

/// Premium medical condition card with animations
class _MedicalConditionCard extends StatefulWidget {
  final MedicalCondition condition;
  final bool isSelected;
  final Duration animationDelay;
  final VoidCallback onTap;

  const _MedicalConditionCard({
    required this.condition,
    required this.isSelected,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  State<_MedicalConditionCard> createState() => _MedicalConditionCardState();
}

class _MedicalConditionCardState extends State<_MedicalConditionCard>
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
  void didUpdateWidget(_MedicalConditionCard oldWidget) {
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
          const Color(0xFFEFE7DA), // Active state fill color
          _selectionAnimation.value,
        ) ?? Colors.white;

        final borderColor = Color.lerp(
          const Color(0xFFE5E5E5).withValues(alpha: 0.3),
          const Color(0xFFC8A96A), // Gold accent
          _selectionAnimation.value,
        ) ?? const Color(0xFFE5E5E5).withValues(alpha: 0.3);

        final borderWidth = 1.0 + (_selectionAnimation.value * 1.5); // 1px to 2.5px

        final elevation = _selectionAnimation.value * 2.0; // 0 to 2

        return Opacity(
          opacity: _entranceAnimation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _entranceAnimation.value) * 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24), // 24-28px radius
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
                            color: const Color(0xFFC8A96A)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.condition.icon,
                            color: Color.lerp(
                              ColorPalette.textSecondary,
                              const Color(0xFFC8A96A),
                              _selectionAnimation.value,
                            ) ?? ColorPalette.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title (middle)
                        Expanded(
                          child: Text(
                            widget.condition.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.textPrimary,
                            ),
                          ),
                        ),
                        // Checkmark (right side) - animated
                        AnimatedOpacity(
                          opacity: _selectionAnimation.value,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFFC8A96A),
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
