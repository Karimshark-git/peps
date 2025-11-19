import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/color_palette.dart';
import '../provider/onboarding_provider.dart';

/// Premium Body Information screen with global PEPS design system
class BiometricsScreen extends StatefulWidget {
  const BiometricsScreen({super.key});

  @override
  State<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();

  String? _selectedActivityLevel;
  bool _isDropdownOpen = false;

  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
    'Athlete',
  ];

  late AnimationController _dropdownArrowController;

  @override
  void initState() {
    super.initState();

    _dropdownArrowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

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

    _ageFocusNode.addListener(_onFocusChange);
    _heightFocusNode.addListener(_onFocusChange);
    _weightFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _dropdownArrowController.dispose();
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
      },
      child: Scaffold(
        backgroundColor: ColorPalette.background,
        body: SafeArea(
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                child: OnboardingProgressBar(stepIndex: 3),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      // Title - Premium serif
                      Text(
                        'Tell us about your body',
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
                        'This helps us personalize your protocol.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: ColorPalette.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Age input
                      _buildAnimatedTextField(
                        controller: _ageController,
                        focusNode: _ageFocusNode,
                        label: 'Age',
                        hint: 'Enter your age',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 20),
                      // Height input
                      _buildAnimatedTextField(
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
                      _buildAnimatedTextField(
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
                      _buildAnimatedDropdown(),
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

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        // Animated input container
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: ColorPalette.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFocused ? ColorPalette.gold : Colors.transparent,
              width: isFocused ? 2 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: isFocused
                    ? ColorPalette.gold.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isFocused ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Transform.scale(
            scale: isFocused ? 1.02 : 1.0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: ColorPalette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.textPlaceholder,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
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
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Activity Level',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        // Premium dropdown container
        Container(
          decoration: BoxDecoration(
            color: ColorPalette.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedActivityLevel,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              hintText: 'Select activity level',
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: ColorPalette.textPlaceholder,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textPrimary,
            ),
            dropdownColor: ColorPalette.cardBackground,
            borderRadius: BorderRadius.circular(20),
            icon: AnimatedBuilder(
              animation: _dropdownArrowController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _dropdownArrowController.value * 3.14159, // 180 degrees
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ColorPalette.textPrimary,
                    size: 24,
                  ),
                );
              },
            ),
            items: _activityLevels.map((level) {
              final isSelected = _selectedActivityLevel == level;
              return DropdownMenuItem<String>(
                value: level,
                child: Text(
                  level,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? ColorPalette.textPrimary
                        : ColorPalette.textSecondary,
                  ),
                ),
              );
            }).toList(),
            menuMaxHeight: 280,
            onChanged: (value) {
              setState(() {
                _selectedActivityLevel = value;
                _isDropdownOpen = false;
              });
              _dropdownArrowController.reverse();

              // Auto-save when activity level changes
              if (value != null &&
                  _ageController.text.isNotEmpty &&
                  _heightController.text.isNotEmpty &&
                  _weightController.text.isNotEmpty) {
                _saveCurrentData();
              }
            },
            onTap: () {
              setState(() {
                _isDropdownOpen = !_isDropdownOpen;
              });
              if (_isDropdownOpen) {
                _dropdownArrowController.forward();
              } else {
                _dropdownArrowController.reverse();
              }
            },
          ),
        ),
      ],
    );
  }
}

