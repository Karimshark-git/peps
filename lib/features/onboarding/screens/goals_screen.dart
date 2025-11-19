import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/text_styles.dart';
import '../widgets/goal_option_card.dart';
import '../provider/onboarding_provider.dart';

/// Goals screen - Second screen of onboarding
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<String> _availableGoals = [
    'Weight Loss',
    'Muscle Growth',
    'Anti-Aging',
    'Longevity',
    'Skin & Beauty',
    'Cognitive Performance',
    'Energy & Vitality',
    'Recovery & Healing',
    'Libido & Performance',
  ];

  final Set<String> _selectedGoals = {};
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  void initState() {
    super.initState();
    // Load saved goals from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      if (provider.model.goals.isNotEmpty) {
        setState(() {
          _selectedGoals.addAll(provider.model.goals);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final hasSelection = _selectedGoals.isNotEmpty;

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
        // Swipe left (from right to left) to go forward
        else if (details.primaryVelocity != null && 
                 details.primaryVelocity! < -300 && 
                 dragDistance < -50 &&
                 hasSelection) {
          onboardingProvider.updateGoals(_selectedGoals.toList());
          Navigator.pushNamed(context, '/biometrics');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                child: OnboardingProgressBar(progress: 0.25),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
              // Title
              Text(
                'What are your goals?',
                style: TextStyles.headingMedium,
              ),
              const SizedBox(height: 12),
              // Subtext
              Text(
                'Select all that apply.',
                style: TextStyles.subtitle,
              ),
              const SizedBox(height: 32),
              // Goals list
              Expanded(
                child: ListView.separated(
                  itemCount: _availableGoals.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = _availableGoals[index];
                    final isSelected = _selectedGoals.contains(goal);
                    return GoalOptionCard(
                      title: goal,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedGoals.remove(goal);
                          } else {
                            _selectedGoals.add(goal);
                          }
                        });
                        // Auto-save on selection change
                        onboardingProvider.updateGoals(_selectedGoals.toList());
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Next button
              PrimaryButton(
                text: 'Next',
                isEnabled: hasSelection,
                onPressed: hasSelection
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

