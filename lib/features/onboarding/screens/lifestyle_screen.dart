import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/text_styles.dart';
import '../widgets/goal_option_card.dart';
import '../provider/onboarding_provider.dart';

/// Lifestyle screen - Fourth screen of onboarding
class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  final List<String> _lifestyleOptions = [
    'Sleep Quality Issues',
    'High Stress Levels',
    'Irregular Meal Times',
    'Limited Sun Exposure',
    'Travel Frequently',
    'Shift Work',
    'Sedentary Job',
    'High Intensity Training',
  ];

  final Set<String> _selectedLifestyle = {};
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  void initState() {
    super.initState();
    // Load saved lifestyle data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      final savedLifestyle = provider.model.lifestyle['factors'] as List<dynamic>?;
      if (savedLifestyle != null) {
        setState(() {
          _selectedLifestyle.addAll(savedLifestyle.cast<String>());
        });
      }
    });
  }

  void _saveLifestyle() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.updateLifestyle({
      'factors': _selectedLifestyle.toList(),
    });
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
        // Swipe left (from right to left) to go forward
        else if (details.primaryVelocity != null && 
                 details.primaryVelocity! < -300 && 
                 dragDistance < -50) {
          _saveLifestyle();
          Navigator.pushNamed(context, '/medical');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                child: OnboardingProgressBar(progress: 0.75),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                // Title
                Text(
                  'Tell us about your lifestyle',
                  style: TextStyles.headingMedium,
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Select factors that apply to you.',
                  style: TextStyles.subtitle,
                ),
                const SizedBox(height: 32),
                // Lifestyle options list
                ..._lifestyleOptions.map((option) {
                  final isSelected = _selectedLifestyle.contains(option);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalOptionCard(
                      title: option,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedLifestyle.remove(option);
                          } else {
                            _selectedLifestyle.add(option);
                          }
                        });
                        // Auto-save on selection change
                        _saveLifestyle();
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                // Next button
                PrimaryButton(
                  text: 'Next',
                  isEnabled: true, // Optional selection
                  onPressed: () {
                    _saveLifestyle();
                    Navigator.pushNamed(context, '/medical');
                  },
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
