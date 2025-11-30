import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/color_palette.dart';
import '../provider/onboarding_provider.dart';
import '../widgets/goal_card.dart';

/// Premium Goals screen with luxury wellness aesthetic
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with TickerProviderStateMixin {
  final List<GoalData> _availableGoals = [
    GoalData(
      title: 'Weight Loss',
      subtitle: 'Fat loss and metabolic health',
      icon: Icons.monitor_weight,
    ),
    GoalData(
      title: 'Muscle Growth',
      subtitle: 'Strength and lean mass',
      icon: Icons.fitness_center,
    ),
    GoalData(
      title: 'Anti-Aging',
      subtitle: 'Cellular rejuvenation',
      icon: Icons.hourglass_empty,
    ),
    GoalData(
      title: 'Longevity',
      subtitle: 'Extend healthspan',
      icon: Icons.all_inclusive,
    ),
    GoalData(
      title: 'Skin & Beauty',
      subtitle: 'Radiant complexion',
      icon: Icons.face,
    ),
    GoalData(
      title: 'Cognitive Performance',
      subtitle: 'Mental clarity and focus',
      icon: Icons.psychology,
    ),
    GoalData(
      title: 'Energy & Vitality',
      subtitle: 'Sustained daily energy',
      icon: Icons.flash_on,
    ),
    GoalData(
      title: 'Recovery & Healing',
      subtitle: 'Faster recovery',
      icon: Icons.healing,
    ),
    GoalData(
      title: 'Libido & Performance',
      subtitle: 'Enhanced vitality',
      icon: Icons.favorite,
    ),
  ];

  final Set<String> _selectedGoals = {};
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

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Load saved goals from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      if (provider.model.goals.isNotEmpty) {
        setState(() {
          _selectedGoals.addAll(provider.model.goals);
          _updateSelectionState();
        });
      }
    });
  }

  void _updateSelectionState() {
    final newHasSelection = _selectedGoals.isNotEmpty;
    if (newHasSelection != _hasSelection) {
      setState(() {
        _hasSelection = newHasSelection;
      });
      if (_hasSelection) {
        _buttonAnimationController.repeat(reverse: true);
      } else {
        _buttonAnimationController.stop();
        _buttonAnimationController.reset();
      }
    }
  }

  void _toggleGoal(String goalTitle) {
    setState(() {
      if (_selectedGoals.contains(goalTitle)) {
        _selectedGoals.remove(goalTitle);
      } else {
        _selectedGoals.add(goalTitle);
      }
    });
    _updateSelectionState();
    
    // Auto-save on selection change
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.updateGoals(_selectedGoals.toList());
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);

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
          // Save current selection before going back
          onboardingProvider.updateGoals(_selectedGoals.toList());
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F1), // Cream background
        body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
              child: OnboardingProgressBar(stepIndex: 2, totalSteps: 6),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Title - personalized
                    Builder(
                      builder: (context) {
                        final provider = Provider.of<OnboardingProvider>(context);
                        final firstName = provider.model.firstName ?? '';
                        final greeting = firstName.isNotEmpty ? '$firstName, ' : '';
                        return Text(
                          '$greeting${greeting.isNotEmpty ? 'w' : 'W'}hat are your goals?',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.textPrimary,
                            height: 1.2,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      'Select all that apply so we can tailor your protocol.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Goals list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availableGoals.length,
                        itemBuilder: (context, index) {
                          final goal = _availableGoals[index];
                          final isSelected = _selectedGoals.contains(goal.title);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _availableGoals.length - 1 ? 12 : 0,
                            ),
                            child: GoalCard(
                              key: ValueKey(goal.title),
                              goal: goal,
                              isSelected: isSelected,
                              animationDelay: Duration(milliseconds: 50 * index),
                              onTap: () => _toggleGoal(goal.title),
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
                              // Save goals to provider
                              onboardingProvider.updateGoals(_selectedGoals.toList());
                              
                              // Print to console
                              print('Selected goals: ${_selectedGoals.toList()}');
                              
                              // Navigate to biometrics screen
                              Navigator.pushNamed(context, '/biometrics');
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
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: isEnabled ? animation.value : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled
                  ? const Color(0xFFC7A572) // Gold color
                  : const Color(0xFFE8DCC4).withValues(alpha: 0.5), // Muted beige
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
