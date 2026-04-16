import 'package:flutter/foundation.dart';

import '../features/onboarding/models/onboarding_model.dart';
import '../services/supabase_client.dart';
import 'ai_protocol_engine.dart';
import 'models/peptide_recommendation.dart';

/// Configuration constant for protocol size
const int kProtocolSize = 5;

/// Recommendation engine that generates personalized peptide protocols
class RecommendationEngine {
  static Future<List<Map<String, dynamic>>> _loadPeptides() async {
    final peptidesResponse = await supabase.from('peptides').select('*');
    return List<Map<String, dynamic>>.from(peptidesResponse);
  }

  static OnboardingResponse _onboardingModelToResponse(OnboardingModel model) {
    final lifestyleFactors = <String>[];
    if (model.lifestyle.isNotEmpty) {
      final factors = model.lifestyle['factors'] as List<dynamic>?;
      if (factors != null) {
        lifestyleFactors.addAll(factors.cast<String>());
      }
    }

    final medicalConditions = <String>[];
    if (model.medical.isNotEmpty) {
      final conditions = model.medical['conditions'] as List<dynamic>?;
      if (conditions != null) {
        medicalConditions.addAll(conditions.cast<String>());
      }
    }

    return OnboardingResponse(
      goals: model.goals,
      age: model.age,
      height: model.height,
      weight: model.weight,
      activityLevel: model.activityLevel,
      lifestyleFactors: lifestyleFactors,
      medicalConditions: medicalConditions,
    );
  }

  /// Generates a protocol based on onboarding data (AI first, rule-based fallback).
  static Future<List<PeptideRecommendation>> generateProtocol(
    OnboardingModel model,
  ) async {
    final peptides = await _loadPeptides();

    try {
      final aiResults = await AiProtocolEngine.generateProtocol(
        onboarding: model,
        peptideCatalog: peptides,
        maxRecommendations: _maxRecommendations(model),
      );
      if (aiResults.isNotEmpty) return aiResults;
    } catch (e) {
      debugPrint('[RecommendationEngine] AI engine failed: $e');
      debugPrint(
        '[RecommendationEngine] Falling back to rule-based scoring',
      );
    }

    return _ruleBasedScore(peptides, _onboardingModelToResponse(model));
  }

  static int _maxRecommendations(OnboardingModel model) {
    if (model.goals.length >= 3) return 3;
    if (model.goals.length == 2) return 2;
    return 1;
  }

  static List<PeptideRecommendation> _ruleBasedScore(
    List<Map<String, dynamic>> peptides,
    OnboardingResponse response,
  ) {
    final scoredPeptides = <_ScoredPeptide>[];

    for (final peptide in peptides) {
      final medicalFlags = List<String>.from(
        peptide['medical_flags'] as List<dynamic>? ?? [],
      );

      bool shouldSkip = false;
      for (final condition in response.medicalConditions) {
        if (medicalFlags.contains(condition)) {
          shouldSkip = true;
          break;
        }
      }
      if (shouldSkip) continue;

      double score = 0.0;

      final goalsSupported = List<String>.from(
        peptide['goals_supported'] as List<dynamic>? ?? [],
      );
      for (final goal in response.goals) {
        if (goalsSupported.contains(goal)) {
          score += 3;
        }
      }

      final lifestyleSupported = List<String>.from(
        peptide['lifestyle_supported'] as List<dynamic>? ?? [],
      );
      for (final lifestyle in response.lifestyleFactors) {
        if (lifestyleSupported.contains(lifestyle)) {
          score += 2;
        }
      }

      final category = peptide['category'] as String? ?? '';
      if (response.activityLevel == 'Very Active' &&
          (category.toLowerCase().contains('muscle') ||
              category.toLowerCase().contains('recovery') ||
              category.toLowerCase().contains('body composition'))) {
        score += 1;
      }

      if (response.age != null &&
          response.age! > 35 &&
          (category.toLowerCase().contains('anti-aging') ||
              category.toLowerCase().contains('longevity'))) {
        score += 1;
      }

      final contraindications = List<String>.from(
        peptide['contraindications'] as List<dynamic>? ?? [],
      );
      for (final condition in response.medicalConditions) {
        if (contraindications.any((contra) =>
            contra.toLowerCase().contains(condition.toLowerCase()))) {
          score -= 3;
        }
      }

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

    scoredPeptides.sort((a, b) => b.score.compareTo(a.score));
    final topPeptides = scoredPeptides
        .where((sp) => sp.score >= 3)
        .take(kProtocolSize)
        .toList();

    final recommendations = <PeptideRecommendation>[];

    var rank = 0;
    for (final scoredPeptide in topPeptides) {
      rank++;
      final peptide = scoredPeptide.peptide;
      final reasoningTemplate =
          peptide['reasoning_template'] as String? ?? '';

      String reasoning = reasoningTemplate;

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

      if (reasoning.contains('{age}')) {
        reasoning = reasoning.replaceAll(
          '{age}',
          response.age?.toString() ?? '',
        );
      }

      if (reasoning.isEmpty) {
        reasoning =
            'Selected based on your goals and profile to support your personalized health journey.';
      }

      final shortBenefits = List<String>.from(
        peptide['short_benefits'] as List<dynamic>? ?? [],
      );

      final dosage = peptide['dosage'] as String? ?? '';
      final frequency = peptide['frequency'] as String? ?? '';
      final cycleLength = peptide['cycle_length'] as String? ?? '';

      recommendations.add(PeptideRecommendation(
        peptideId: peptide['id'] as String,
        name: peptide['name'] as String,
        summary: peptide['summary'] as String? ?? '',
        reasoning: reasoning,
        score: scoredPeptide.score,
        category: peptide['category'] as String? ?? '',
        shortBenefits: shortBenefits,
        patientSummary: '',
        confidence: '',
        rank: rank,
        primaryGoalMatch: '',
        contraindictionFlags: const [],
        dosage: dosage,
        frequency: frequency,
        cycleLength: cycleLength,
        stackNote: '',
      ));
    }

    return recommendations;
  }
}

class _ScoredPeptide {
  final Map<String, dynamic> peptide;
  final double score;

  _ScoredPeptide({
    required this.peptide,
    required this.score,
  });
}
