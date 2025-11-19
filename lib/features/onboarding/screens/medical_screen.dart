import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/color_palette.dart';
import '../widgets/goal_option_card.dart';
import '../provider/onboarding_provider.dart';

/// Medical screen - Fifth screen of onboarding
class MedicalScreen extends StatefulWidget {
  const MedicalScreen({super.key});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  final List<String> _medicalOptions = [
    'Diabetes',
    'Hypertension',
    'Heart Conditions',
    'Autoimmune Disorders',
    'Thyroid Issues',
    'Hormonal Imbalances',
    'Chronic Pain',
    'Digestive Issues',
    'None of the above',
  ];

  final Set<String> _selectedMedical = {};
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  void initState() {
    super.initState();
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

  void _saveMedical() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.updateMedical({
      'conditions': _selectedMedical.toList(),
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
          _saveMedical();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                child: OnboardingProgressBar(progress: 1.0),
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
                  'Medical Information',
                  style: TextStyles.headingMedium,
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Select any conditions that apply. This helps us create a safe protocol.',
                  style: TextStyles.subtitle,
                ),
                const SizedBox(height: 32),
                // Medical options list
                ..._medicalOptions.map((option) {
                  final isSelected = _selectedMedical.contains(option);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalOptionCard(
                      title: option,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMedical.remove(option);
                          } else {
                            // If "None of the above" is selected, clear others
                            if (option == 'None of the above') {
                              _selectedMedical.clear();
                              _selectedMedical.add(option);
                            } else {
                              // Remove "None of the above" if selecting something else
                              _selectedMedical.remove('None of the above');
                              _selectedMedical.add(option);
                            }
                          }
                        });
                        // Auto-save on selection change
                        _saveMedical();
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                // Complete button
                PrimaryButton(
                  text: 'Complete',
                  isEnabled: true,
                  onPressed: () {
                    _saveMedical();
                    // Navigate to protocol screen
                    Navigator.pushNamed(context, '/protocol');
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

