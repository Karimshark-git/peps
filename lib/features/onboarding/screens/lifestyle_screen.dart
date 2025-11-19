import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../provider/onboarding_provider.dart';
import '../widgets/lifestyle_card.dart';

/// Premium Lifestyle screen with luxury wellness aesthetic
class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen>
    with TickerProviderStateMixin {
  final List<LifestyleData> _lifestyleOptions = [
    LifestyleData(
      title: 'Sleep Quality Issues',
      icon: Icons.bedtime,
    ),
    LifestyleData(
      title: 'High Stress Levels',
      icon: Icons.psychology,
    ),
    LifestyleData(
      title: 'Irregular Meal Times',
      icon: Icons.restaurant,
    ),
    LifestyleData(
      title: 'Limited Sun Exposure',
      icon: Icons.wb_sunny,
    ),
    LifestyleData(
      title: 'Sedentary Job',
      icon: Icons.chair,
    ),
    LifestyleData(
      title: 'Shift Work',
      icon: Icons.schedule,
    ),
    LifestyleData(
      title: 'Travel Frequently',
      icon: Icons.flight,
    ),
    LifestyleData(
      title: 'High-Intensity Training',
      icon: Icons.fitness_center,
    ),
    LifestyleData(
      title: 'Low Motivation / Low Energy',
      icon: Icons.battery_alert,
    ),
    LifestyleData(
      title: 'Difficulty Building Muscle / Slow Recovery',
      icon: Icons.healing,
    ),
    LifestyleData(
      title: 'Cravings / Appetite Control Issues',
      icon: Icons.fastfood,
    ),
    LifestyleData(
      title: 'Poor Gut Health',
      icon: Icons.medical_services,
    ),
    LifestyleData(
      title: 'Low Libido / Low Drive',
      icon: Icons.favorite_border,
    ),
    LifestyleData(
      title: 'Chronic Fatigue / Burnout',
      icon: Icons.battery_0_bar,
    ),
    LifestyleData(
      title: 'Inconsistent Exercise Routine',
      icon: Icons.calendar_today,
    ),
  ];

  final Set<String> _selectedLifestyle = {};
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  bool _hasSelection = false;
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Button animation controller
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Load saved lifestyle data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      final savedLifestyle = provider.model.lifestyle['factors'] as List<dynamic>?;
      if (savedLifestyle != null) {
        setState(() {
          _selectedLifestyle.addAll(savedLifestyle.cast<String>());
          _updateSelectionState();
        });
      }
    });
  }

  void _updateSelectionState() {
    final newHasSelection = _selectedLifestyle.isNotEmpty;
    if (newHasSelection != _hasSelection) {
      setState(() {
        _hasSelection = newHasSelection;
      });
      if (_hasSelection) {
        _buttonAnimationController.forward();
      } else {
        _buttonAnimationController.reverse();
      }
    }
  }

  void _toggleLifestyle(String title) {
    setState(() {
      if (_selectedLifestyle.contains(title)) {
        _selectedLifestyle.remove(title);
      } else {
        _selectedLifestyle.add(title);
      }
    });
    _updateSelectionState();
    
    // Auto-save on selection change
    _saveLifestyle();
  }

  void _saveLifestyle() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.updateLifestyle({
      'factors': _selectedLifestyle.toList(),
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

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
          _saveLifestyle();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F3EC), // Ultra-soft warm cream
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                child: OnboardingProgressBar(stepIndex: 4),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      // Title
                      Text(
                        'Tell us about your lifestyle',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A), // Deep charcoal
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      Text(
                        'Select factors that apply to you.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6F6F6F), // Muted gray
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Lifestyle options list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _lifestyleOptions.length,
                          itemBuilder: (context, index) {
                            final lifestyle = _lifestyleOptions[index];
                            final isSelected = _selectedLifestyle.contains(lifestyle.title);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < _lifestyleOptions.length - 1 ? 16 : 0,
                              ),
                              child: LifestyleCard(
                                key: ValueKey(lifestyle.title),
                                lifestyle: lifestyle,
                                isSelected: isSelected,
                                animationDelay: Duration(milliseconds: 60 * index),
                                onTap: () => _toggleLifestyle(lifestyle.title),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Next button
                      _AnimatedNextButton(
                        isEnabled: _hasSelection,
                        animation: _buttonScaleAnimation,
                        onPressed: _hasSelection
                            ? () {
                                // Save lifestyle to provider
                                _saveLifestyle();
                                
                                // Navigate to medical screen
                                Navigator.pushNamed(context, '/medical');
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
    );
  }
}

/// Animated Next button with premium styling
class _AnimatedNextButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onPressed;
  final Animation<double> animation;

  const _AnimatedNextButton({
    required this.isEnabled,
    required this.onPressed,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD1A057);
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: isEnabled ? animation.value : 0.98,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled
                  ? goldColor
                  : goldColor.withValues(alpha: 0.5), // Pale gold when disabled
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    'Next',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
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
