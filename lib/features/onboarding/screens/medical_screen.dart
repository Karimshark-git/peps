import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/peps_section_label.dart';
import '../../../core/widgets/primary_button.dart';
import '../provider/onboarding_provider.dart';

/// Medical history — step 5/6. Chrome lives in [OnboardingPersonalizationShell].
class MedicalPersonalizationPage extends StatefulWidget {
  final VoidCallback onFlowBackStep;

  const MedicalPersonalizationPage({
    super.key,
    required this.onFlowBackStep,
  });

  @override
  State<MedicalPersonalizationPage> createState() =>
      MedicalPersonalizationPageState();
}

class MedicalPersonalizationPageState extends State<MedicalPersonalizationPage>
    with AutomaticKeepAliveClientMixin {
  final List<MedicalCondition> _medicalConditions = [
    MedicalCondition(title: 'Diabetes', icon: Icons.bloodtype),
    MedicalCondition(title: 'Hypertension', icon: Icons.favorite),
    MedicalCondition(title: 'Heart Conditions', icon: Icons.favorite_border),
    MedicalCondition(
        title: 'Autoimmune Disorders', icon: Icons.health_and_safety),
    MedicalCondition(title: 'Thyroid Issues', icon: Icons.medical_services),
    MedicalCondition(title: 'Hormonal Imbalances', icon: Icons.balance),
    MedicalCondition(title: 'Chronic Pain', icon: Icons.healing),
    MedicalCondition(title: 'Digestive Issues', icon: Icons.restaurant),
    MedicalCondition(
        title: 'Kidney or Liver Conditions', icon: Icons.medical_information),
    MedicalCondition(title: 'Blood Clotting Issues', icon: Icons.water_drop),
    MedicalCondition(
        title: 'None of the above', icon: Icons.check_circle_outline),
  ];

  final Set<String> _selectedMedical = {};
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      final savedMedical =
          provider.model.medical['conditions'] as List<dynamic>?;
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

  void persistToProvider() => _saveMedical();

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedMedical.contains(condition)) {
        _selectedMedical.remove(condition);
      } else {
        if (condition == 'None of the above') {
          _selectedMedical.clear();
          _selectedMedical.add(condition);
        } else {
          _selectedMedical.remove('None of the above');
          _selectedMedical.add(condition);
        }
      }
    });
    _saveMedical();
  }

  bool get _hasSelection => _selectedMedical.isNotEmpty;

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
          _saveMedical();
          widget.onFlowBackStep();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const PepsSectionLabel(text: 'Health history'),
                  const SizedBox(height: 8),
                  Text(
                    'Any conditions we should know about?',
                    style: GoogleFonts.sora(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us flag contraindications.',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: _medicalConditions.map((c) {
                      final isSelected = _selectedMedical.contains(c.title);
                      return GestureDetector(
                        onTap: () => _toggleCondition(c.title),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ColorPalette.accentDim
                                : ColorPalette.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? ColorPalette.accentBorder
                                  : ColorPalette.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                c.icon,
                                size: 16,
                                color: isSelected
                                    ? ColorPalette.gold
                                    : ColorPalette.textSecondary,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  c.title,
                                  style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                    color: isSelected
                                        ? ColorPalette.gold
                                        : ColorPalette.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4D3ECFA0),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: 'Complete →',
                textColor: const Color(0xFF04201A),
                isEnabled: _hasSelection,
                onPressed: _hasSelection
                    ? () {
                        _saveMedical();
                        Navigator.pushNamed(
                          context,
                          '/protocol-building',
                        );
                      }
                    : null,
              ),
            ),
          ),
        ],
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
