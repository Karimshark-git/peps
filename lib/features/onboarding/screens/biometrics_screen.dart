import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/color_palette.dart';
import '../provider/onboarding_provider.dart';

/// Biometrics screen - Third screen of onboarding
class BiometricsScreen extends StatefulWidget {
  const BiometricsScreen({super.key});

  @override
  State<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();
  
  String? _selectedActivityLevel;
  
  bool _ageFocused = false;
  bool _heightFocused = false;
  bool _weightFocused = false;
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;
  
  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Athlete',
  ];

  @override
  void initState() {
    super.initState();
    // Load saved biometrics from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      final model = provider.model;
      if (model.age != null) {
        _ageController.text = model.age.toString();
      }
      if (model.height != null) {
        _heightController.text = model.height.toString();
      }
      if (model.weight != null) {
        _weightController.text = model.weight.toString();
      }
      if (model.activityLevel != null) {
        setState(() {
          _selectedActivityLevel = model.activityLevel;
        });
      }
    });
    
    _ageFocusNode.addListener(() {
      setState(() {
        _ageFocused = _ageFocusNode.hasFocus;
      });
    });
    _heightFocusNode.addListener(() {
      setState(() {
        _heightFocused = _heightFocusNode.hasFocus;
      });
    });
    _weightFocusNode.addListener(() {
      setState(() {
        _weightFocused = _weightFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _ageController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _weightController.text.isNotEmpty &&
        _selectedActivityLevel != null;
  }

  void _handleNext() {
    if (!_isFormValid) return;

    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (age != null && height != null && weight != null && _selectedActivityLevel != null) {
      onboardingProvider.updateBiometrics(
        age: age,
        height: height,
        weight: weight,
        activity: _selectedActivityLevel!,
      );
      
      Navigator.pushNamed(context, '/lifestyle');
    }
  }

  void _saveCurrentData() {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    
    if (age != null && height != null && weight != null && _selectedActivityLevel != null) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.updateBiometrics(
        age: age,
        height: height,
        weight: weight,
        activity: _selectedActivityLevel!,
      );
    }
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
          _saveCurrentData();
          Navigator.pop(context);
        }
        // Swipe left (from right to left) to go forward
        else if (details.primaryVelocity != null && 
                 details.primaryVelocity! < -300 && 
                 dragDistance < -50 &&
                 _isFormValid) {
          _handleNext();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                child: OnboardingProgressBar(progress: 0.5),
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
                  'Tell us about your body',
                  style: TextStyles.headingMedium,
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'This helps us personalize your protocol.',
                  style: TextStyles.subtitle,
                ),
                const SizedBox(height: 40),
                // Age input
                _buildTextField(
                  controller: _ageController,
                  focusNode: _ageFocusNode,
                  label: 'Age',
                  hint: 'Enter your age',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 20),
                // Height input
                _buildTextField(
                  controller: _heightController,
                  focusNode: _heightFocusNode,
                  label: 'Height (cm)',
                  hint: 'Enter your height',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 20),
                // Weight input
                _buildTextField(
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  label: 'Weight (kg)',
                  hint: 'Enter your weight',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 20),
                // Activity level dropdown
                _buildActivityDropdown(),
                const SizedBox(height: 40),
                // Next button
                PrimaryButton(
                  text: 'Next',
                  isEnabled: _isFormValid,
                  onPressed: _isFormValid ? _handleNext : null,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            bool isFocused = false;
            if (focusNode == _ageFocusNode) {
              isFocused = _ageFocused;
            } else if (focusNode == _heightFocusNode) {
              isFocused = _heightFocused;
            } else if (focusNode == _weightFocusNode) {
              isFocused = _weightFocused;
            }
            
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDE4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFocused ? ColorPalette.gold : Colors.transparent,
                  width: isFocused ? 2 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorPalette.shadowLight,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                style: TextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyles.bodyMedium.copyWith(
                    color: ColorPalette.textSecondary.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                  // Auto-save as user types
                  if (_isFormValid) {
                    _saveCurrentData();
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Level',
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDE4),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedActivityLevel,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              hintText: 'Select activity level',
              hintStyle: TextStyles.bodyMedium.copyWith(
                color: ColorPalette.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            style: TextStyles.bodyMedium,
            dropdownColor: const Color(0xFFF3EDE4),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: ColorPalette.textPrimary,
            ),
            items: _activityLevels.map((level) {
              return DropdownMenuItem<String>(
                value: level,
                child: Text(level),
              );
            }).toList(),
                onChanged: (value) {
              setState(() {
                _selectedActivityLevel = value;
              });
              // Auto-save when activity level changes
              if (value != null && _ageController.text.isNotEmpty &&
                  _heightController.text.isNotEmpty && _weightController.text.isNotEmpty) {
                _saveCurrentData();
              }
            },
          ),
        ),
      ],
    );
  }
}

