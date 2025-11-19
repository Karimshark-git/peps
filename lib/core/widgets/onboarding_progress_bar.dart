import 'package:flutter/material.dart';
import '../theme/color_palette.dart';

/// Animated progress bar for onboarding screens using step indices
class OnboardingProgressBar extends StatefulWidget {
  /// Current step index (1-based: 1 = Welcome, 2 = Goals, etc.)
  final int stepIndex;
  
  /// Total number of steps (default: 6)
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.stepIndex,
    this.totalSteps = 6,
  }) : assert(stepIndex >= 1 && stepIndex <= totalSteps,
           'stepIndex must be between 1 and $totalSteps');

  /// Calculate progress from step index (0.0 to 1.0)
  double get progress => (stepIndex - 1) / (totalSteps - 1);

  @override
  State<OnboardingProgressBar> createState() => _OnboardingProgressBarState();
}

class _OnboardingProgressBarState extends State<OnboardingProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  static double _lastProgress = 0.0; // Track last progress across instances

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    final targetProgress = widget.progress;
    
    // Start from last progress value for smooth transitions
    _animation = Tween<double>(
      begin: _lastProgress,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
    
    // Start animation from last value to target value when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void didUpdateWidget(OnboardingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepIndex != widget.stepIndex) {
      _lastProgress = _animation.value;
      final targetProgress = widget.progress;
      _animation = Tween<double>(
        begin: _lastProgress,
        end: targetProgress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    // Update last progress before disposing
    _lastProgress = _animation.value;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            color: ColorPalette.progressBackground,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: ColorPalette.progressFill,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

