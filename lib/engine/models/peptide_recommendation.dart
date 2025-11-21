/// Model for a peptide recommendation from the engine
class PeptideRecommendation {
  final String peptideId;
  final String name;
  final String summary;
  final String reasoning;
  final double score;
  final String category;
  final List<String> shortBenefits;

  PeptideRecommendation({
    required this.peptideId,
    required this.name,
    required this.summary,
    required this.reasoning,
    required this.score,
    required this.category,
    required this.shortBenefits,
  });
}

/// Model for onboarding response data used by the engine
class OnboardingResponse {
  final List<String> goals;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final List<String> lifestyleFactors;
  final List<String> medicalConditions;

  OnboardingResponse({
    required this.goals,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    required this.lifestyleFactors,
    required this.medicalConditions,
  });
}

