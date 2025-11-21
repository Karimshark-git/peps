import '../services/supabase_client.dart';
import 'models/peptide_recommendation.dart';

/// Configuration constant for protocol size
const int kProtocolSize = 5;

/// Recommendation engine that generates personalized peptide protocols
class RecommendationEngine {
  /// Generates a protocol based on onboarding response
  static Future<List<PeptideRecommendation>> generateProtocol(
    OnboardingResponse response,
  ) async {
    // 1. Load all peptides from Supabase
    final peptidesResponse = await supabase.from('peptides').select('*');
    final peptides = List<Map<String, dynamic>>.from(peptidesResponse);

    // 2. Apply safety filtering and scoring
    final scoredPeptides = <_ScoredPeptide>[];

    for (final peptide in peptides) {
      final medicalFlags = List<String>.from(
        peptide['medical_flags'] as List<dynamic>? ?? [],
      );

      // Safety filter: skip if user has medical condition in medical_flags
      bool shouldSkip = false;
      for (final condition in response.medicalConditions) {
        if (medicalFlags.contains(condition)) {
          shouldSkip = true;
          break;
        }
      }
      if (shouldSkip) continue;

      // 3. Calculate score
      double score = 0.0;

      // +3 points for each matching goal
      final goalsSupported = List<String>.from(
        peptide['goals_supported'] as List<dynamic>? ?? [],
      );
      for (final goal in response.goals) {
        if (goalsSupported.contains(goal)) {
          score += 3;
        }
      }

      // +2 points for each matching lifestyle factor
      final lifestyleSupported = List<String>.from(
        peptide['lifestyle_supported'] as List<dynamic>? ?? [],
      );
      for (final lifestyle in response.lifestyleFactors) {
        if (lifestyleSupported.contains(lifestyle)) {
          score += 2;
        }
      }

      // +1 bonus if activity level is "Very Active" AND peptide category is muscle/recovery
      final category = peptide['category'] as String? ?? '';
      if (response.activityLevel == 'Very Active' &&
          (category.toLowerCase().contains('muscle') ||
              category.toLowerCase().contains('recovery') ||
              category.toLowerCase().contains('body composition'))) {
        score += 1;
      }

      // +1 bonus if age > 35 AND peptide category is anti-aging/longevity
      if (response.age != null &&
          response.age! > 35 &&
          (category.toLowerCase().contains('anti-aging') ||
              category.toLowerCase().contains('longevity'))) {
        score += 1;
      }

      // -3 penalty if contraindications include any user medical condition
      final contraindications = List<String>.from(
        peptide['contraindications'] as List<dynamic>? ?? [],
      );
      for (final condition in response.medicalConditions) {
        if (contraindications.any((contra) =>
            contra.toLowerCase().contains(condition.toLowerCase()))) {
          score -= 3;
        }
      }

      // -5 penalty if medical_flags contains high-risk conditions
      // (Heart Conditions, Cancer history, Diabetes are considered high-risk)
      final highRiskConditions = [
        'Heart Conditions',
        'Cancer history',
        'Diabetes',
      ];
      for (final condition in response.medicalConditions) {
        if (highRiskConditions.contains(condition) &&
            medicalFlags.contains(condition)) {
          score -= 5;
        }
      }

      scoredPeptides.add(_ScoredPeptide(
        peptide: peptide,
        score: score,
      ));
    }

    // 4. Filter for top picks (score >= 3) and sort by score
    scoredPeptides.sort((a, b) => b.score.compareTo(a.score));
    final topPeptides = scoredPeptides
        .where((sp) => sp.score >= 3)
        .take(kProtocolSize)
        .toList();

    // 5. Build recommendations with reasoning
    final recommendations = <PeptideRecommendation>[];

    for (final scoredPeptide in topPeptides) {
      final peptide = scoredPeptide.peptide;
      final reasoningTemplate =
          peptide['reasoning_template'] as String? ?? '';

      // Build reasoning text by replacing placeholders
      String reasoning = reasoningTemplate;
      
      // Replace {goal} with first matching goal
      if (reasoning.contains('{goal}')) {
        final matchingGoal = response.goals.firstWhere(
          (goal) {
            final goalsSupported = List<String>.from(
              peptide['goals_supported'] as List<dynamic>? ?? [],
            );
            return goalsSupported.contains(goal);
          },
          orElse: () => response.goals.isNotEmpty ? response.goals.first : '',
        );
        reasoning = reasoning.replaceAll('{goal}', matchingGoal);
      }

      // Replace {lifestyle} with first matching lifestyle factor
      if (reasoning.contains('{lifestyle}')) {
        final matchingLifestyle = response.lifestyleFactors.firstWhere(
          (lifestyle) {
            final lifestyleSupported = List<String>.from(
              peptide['lifestyle_supported'] as List<dynamic>? ?? [],
            );
            return lifestyleSupported.contains(lifestyle);
          },
          orElse: () => response.lifestyleFactors.isNotEmpty
              ? response.lifestyleFactors.first
              : '',
        );
        reasoning = reasoning.replaceAll('{lifestyle}', matchingLifestyle);
      }

      // Replace {age} with user's age
      if (reasoning.contains('{age}')) {
        reasoning = reasoning.replaceAll(
          '{age}',
          response.age?.toString() ?? '',
        );
      }

      // If no template, use a default reasoning
      if (reasoning.isEmpty) {
        reasoning =
            'Selected based on your goals and profile to support your personalized health journey.';
      }

      final shortBenefits = List<String>.from(
        peptide['short_benefits'] as List<dynamic>? ?? [],
      );

      recommendations.add(PeptideRecommendation(
        peptideId: peptide['id'] as String,
        name: peptide['name'] as String,
        summary: peptide['summary'] as String? ?? '',
        reasoning: reasoning,
        score: scoredPeptide.score,
        category: peptide['category'] as String? ?? '',
        shortBenefits: shortBenefits,
      ));
    }

    return recommendations;
  }
}

/// Internal helper class for scoring peptides
class _ScoredPeptide {
  final Map<String, dynamic> peptide;
  final double score;

  _ScoredPeptide({
    required this.peptide,
    required this.score,
  });
}

