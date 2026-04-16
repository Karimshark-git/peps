/// Model for a peptide recommendation from the engine
class PeptideRecommendation {
  final String peptideId;
  final String name;
  final String summary;
  final String reasoning;
  final double score;
  final String category;
  final List<String> shortBenefits;

  final String patientSummary;
  final String confidence;
  final int rank;
  final String primaryGoalMatch;
  final List<String> contraindictionFlags;
  final String dosage;
  final String frequency;
  final String cycleLength;
  final String stackNote;

  PeptideRecommendation({
    required this.peptideId,
    required this.name,
    required this.summary,
    required this.reasoning,
    required this.score,
    required this.category,
    required this.shortBenefits,
    this.patientSummary = '',
    this.confidence = '',
    this.rank = 0,
    this.primaryGoalMatch = '',
    this.contraindictionFlags = const [],
    this.dosage = '',
    this.frequency = '',
    this.cycleLength = '',
    this.stackNote = '',
  });

  PeptideRecommendation copyWith({
    String? peptideId,
    String? name,
    String? summary,
    String? reasoning,
    double? score,
    String? category,
    List<String>? shortBenefits,
    String? patientSummary,
    String? confidence,
    int? rank,
    String? primaryGoalMatch,
    List<String>? contraindictionFlags,
    String? dosage,
    String? frequency,
    String? cycleLength,
    String? stackNote,
  }) {
    return PeptideRecommendation(
      peptideId: peptideId ?? this.peptideId,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      reasoning: reasoning ?? this.reasoning,
      score: score ?? this.score,
      category: category ?? this.category,
      shortBenefits: shortBenefits ?? this.shortBenefits,
      patientSummary: patientSummary ?? this.patientSummary,
      confidence: confidence ?? this.confidence,
      rank: rank ?? this.rank,
      primaryGoalMatch: primaryGoalMatch ?? this.primaryGoalMatch,
      contraindictionFlags:
          contraindictionFlags ?? this.contraindictionFlags,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      cycleLength: cycleLength ?? this.cycleLength,
      stackNote: stackNote ?? this.stackNote,
    );
  }
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
