import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../provider/onboarding_provider.dart';

/// Biometrics — step 3/6. Chrome lives in [OnboardingPersonalizationShell].
class BiometricsPersonalizationPage extends StatefulWidget {
  final VoidCallback onContinueToNextStep;
  final VoidCallback onFlowBackStep;

  const BiometricsPersonalizationPage({
    super.key,
    required this.onContinueToNextStep,
    required this.onFlowBackStep,
  });

  @override
  State<BiometricsPersonalizationPage> createState() =>
      BiometricsPersonalizationPageState();
}

class BiometricsPersonalizationPageState
    extends State<BiometricsPersonalizationPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();

  String? _selectedActivityLevel;

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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      final model = provider.model;
      if (model.age != null) {
        _ageController.text = model.age.toString();
      }
      if (model.height != null) {
        _heightController.text = model.height!.toInt().toString();
      }
      if (model.weight != null) {
        _weightController.text = model.weight!.toInt().toString();
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
    FocusScope.of(context).unfocus();

    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (age != null &&
        height != null &&
        weight != null &&
        _selectedActivityLevel != null) {
      onboardingProvider.updateBiometrics(
        age: age,
        height: height,
        weight: weight,
        activity: _selectedActivityLevel!,
      );

      widget.onContinueToNextStep();
    }
  }

  void _saveCurrentData() {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (age != null &&
        height != null &&
        weight != null &&
        _selectedActivityLevel != null) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.updateBiometrics(
        age: age,
        height: height,
        weight: weight,
        activity: _selectedActivityLevel!,
      );
    }
  }

  void persistToProvider() => _saveCurrentData();

  Widget _eyebrowLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF3ECFA0),
        letterSpacing: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStartX = details.globalPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        _dragCurrentX = details.globalPosition.dx;
      },
      onHorizontalDragEnd: (details) {
        final dragDistance = _dragCurrentX - _dragStartX;
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300 &&
            dragDistance > 50) {
          _saveCurrentData();
          widget.onFlowBackStep();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _eyebrowLabel('BODY METRICS'),
            const SizedBox(height: 4),
            Text(
              'Tell us about yourself',
              maxLines: 2,
              style: GoogleFonts.sora(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: const Color(0xE6FFFFFF),
                height: 1.15,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField(
                      controller: _ageController,
                      focusNode: _ageFocusNode,
                      label: 'AGE',
                      hint: 'Enter your age',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _heightController,
                      focusNode: _heightFocusNode,
                      label: 'HEIGHT (CM)',
                      hint: 'Enter your height',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _weightController,
                      focusNode: _weightFocusNode,
                      label: 'WEIGHT (KG)',
                      hint: 'Enter your weight',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _eyebrowLabel('ACTIVITY LEVEL'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _activityLevels.map((level) {
                        final selected = _selectedActivityLevel == level;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedActivityLevel = level;
                            });
                            if (_ageController.text.isNotEmpty &&
                                _heightController.text.isNotEmpty &&
                                _weightController.text.isNotEmpty) {
                              _saveCurrentData();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0x1A3ECFA0)
                                  : const Color(0x0FFFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? const Color(0x663ECFA0)
                                    : const Color(0x1AFFFFFF),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              level,
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                color: selected
                                    ? const Color(0xFF3ECFA0)
                                    : const Color(0x8CFFFFFF),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D3ECFA0),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: 'Next →',
                textColor: const Color(0xFF04201A),
                isEnabled: _isFormValid,
                onPressed: _isFormValid ? _handleNext : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
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
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3ECFA0),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFF3ECFA0)
                  : const Color(0x1AFFFFFF),
              width: isFocused ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  cursorColor: const Color(0xFF3ECFA0),
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xE6FFFFFF),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0x4DFFFFFF),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    if (_isFormValid) {
                      _saveCurrentData();
                    }
                  },
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0x29FFFFFF),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
