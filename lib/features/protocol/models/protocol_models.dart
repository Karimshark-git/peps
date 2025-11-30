/// Model for onboarding summary data
class OnboardingSummary {
  final List<String> goals;
  final List<String> lifestyleFactors;
  final List<String> medicalConditions;

  OnboardingSummary({
    required this.goals,
    required this.lifestyleFactors,
    required this.medicalConditions,
  });
}

/// Model for a protocol item (recommendation + peptide data)
class ProtocolItem {
  final String peptideId;
  final String peptideName;
  final String peptideCategory;
  final String peptideSummary;
  final List<String> shortBenefits;
  final List<String> goalsSupported;
  final List<String> lifestyleSupported;
  final String reasoning;

  ProtocolItem({
    required this.peptideId,
    required this.peptideName,
    required this.peptideCategory,
    required this.peptideSummary,
    required this.shortBenefits,
    required this.goalsSupported,
    required this.lifestyleSupported,
    required this.reasoning,
  });
}

