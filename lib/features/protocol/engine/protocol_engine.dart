import '../../onboarding/models/onboarding_model.dart';
import '../data/peptides.dart';

/// Protocol recommendation engine
class ProtocolEngine {
  /// Generate personalized peptide protocol based on user onboarding data
  static List<Peptide> generate(OnboardingModel model) {
    // 1. Start with empty list
    List<Peptide> recommendedPeptides = [];

    // 2. Add peptides based on goals
    for (String goal in model.goals) {
      for (Peptide peptide in peptideDatabase) {
        if (peptide.idealGoals.contains(goal)) {
          recommendedPeptides.add(peptide);
        }
      }
    }

    // 3. Filter out contraindications based on medical conditions
    List<String> medicalConditions = [];
    if (model.medical['conditions'] != null) {
      medicalConditions = List<String>.from(model.medical['conditions']);
    }

    recommendedPeptides = recommendedPeptides.where((peptide) {
      // Check if peptide should be avoided for any medical condition
      for (String condition in medicalConditions) {
        if (peptide.avoidForMedical.contains(condition)) {
          return false;
        }
      }
      return true;
    }).toList();

    // 4. Modify based on biometrics
    if (model.age != null && model.age! < 30) {
      // Prioritize performance peptides for younger users
      recommendedPeptides.sort((a, b) {
        bool aIsPerformance = a.idealGoals.contains('Muscle Growth') ||
            a.idealGoals.contains('Cognitive Performance');
        bool bIsPerformance = b.idealGoals.contains('Muscle Growth') ||
            b.idealGoals.contains('Cognitive Performance');
        if (aIsPerformance && !bIsPerformance) return -1;
        if (!aIsPerformance && bIsPerformance) return 1;
        return 0;
      });
    }

    if (model.activityLevel == 'Very Active' || model.activityLevel == 'Athlete') {
      // Add MOTS-C for high activity levels if not already included
      Peptide motsC = peptideDatabase.firstWhere(
        (p) => p.name == 'MOTS-C',
        orElse: () => peptideDatabase.first,
      );
      if (!recommendedPeptides.contains(motsC) && motsC.name == 'MOTS-C') {
        recommendedPeptides.add(motsC);
      }
    }

    // Calculate BMI if height and weight are available
    if (model.height != null && model.weight != null && model.height! > 0) {
      double heightInMeters = model.height! / 100;
      double bmi = model.weight! / (heightInMeters * heightInMeters);
      
      if (bmi > 27) {
        // Emphasize weight-loss peptides
        Peptide aod9604 = peptideDatabase.firstWhere(
          (p) => p.name == 'AOD-9604',
          orElse: () => peptideDatabase.first,
        );
        if (!recommendedPeptides.contains(aod9604) && aod9604.name == 'AOD-9604') {
          recommendedPeptides.insert(0, aod9604); // Add at beginning
        }
      }
    }

    // 5. Modify based on lifestyle
    List<String> lifestyleFactors = [];
    if (model.lifestyle['factors'] != null) {
      lifestyleFactors = List<String>.from(model.lifestyle['factors']);
    }

    if (lifestyleFactors.contains('High Stress Levels')) {
      // Add cognitive peptides for stress
      Peptide semax = peptideDatabase.firstWhere(
        (p) => p.name == 'Semax',
        orElse: () => peptideDatabase.first,
      );
      Peptide selank = peptideDatabase.firstWhere(
        (p) => p.name == 'Selank',
        orElse: () => peptideDatabase.first,
      );
      
      if (!recommendedPeptides.contains(semax) && semax.name == 'Semax') {
        recommendedPeptides.add(semax);
      }
      if (!recommendedPeptides.contains(selank) && selank.name == 'Selank') {
        recommendedPeptides.add(selank);
      }
    }

    if (lifestyleFactors.contains('Sleep Quality Issues')) {
      // Prioritize CJC-1295 + Ipamorelin for sleep
      Peptide cjcIpamorelin = peptideDatabase.firstWhere(
        (p) => p.name == 'CJC-1295 + Ipamorelin',
        orElse: () => peptideDatabase.first,
      );
      if (!recommendedPeptides.contains(cjcIpamorelin) && 
          cjcIpamorelin.name == 'CJC-1295 + Ipamorelin') {
        recommendedPeptides.insert(0, cjcIpamorelin);
      }
      
      // Also add DSIP for sleep
      Peptide dsip = peptideDatabase.firstWhere(
        (p) => p.name == 'DSIP (Delta Sleep Inducing Peptide)',
        orElse: () => peptideDatabase.first,
      );
      if (!recommendedPeptides.contains(dsip) && dsip.name == 'DSIP (Delta Sleep Inducing Peptide)') {
        recommendedPeptides.add(dsip);
      }
    }

    if (lifestyleFactors.contains('Irregular Meal Times')) {
      // Strengthen weight-loss stack
      Peptide motsC = peptideDatabase.firstWhere(
        (p) => p.name == 'MOTS-C',
        orElse: () => peptideDatabase.first,
      );
      if (!recommendedPeptides.contains(motsC) && motsC.name == 'MOTS-C') {
        recommendedPeptides.add(motsC);
      }
    }

    // 6. Remove duplicates (by name)
    final Map<String, Peptide> uniquePeptides = {};
    for (Peptide peptide in recommendedPeptides) {
      uniquePeptides[peptide.name] = peptide;
    }
    recommendedPeptides = uniquePeptides.values.toList();

    // 7. Return final list
    return recommendedPeptides;
  }

  /// Get why a peptide was recommended based on user goals
  static String getWhyRecommended(Peptide peptide, OnboardingModel model) {
    List<String> reasons = [];
    
    // Check which goals match
    for (String goal in model.goals) {
      if (peptide.idealGoals.contains(goal)) {
        reasons.add(goal);
      }
    }
    
    // Check lifestyle factors
    List<String> lifestyleFactors = [];
    if (model.lifestyle['factors'] != null) {
      lifestyleFactors = List<String>.from(model.lifestyle['factors']);
    }
    
    if (lifestyleFactors.contains('High Stress Levels') && 
        (peptide.name == 'Semax' || peptide.name == 'Selank')) {
      reasons.add('High stress management');
    }
    
    if (lifestyleFactors.contains('Sleep Quality Issues') && 
        (peptide.name == 'CJC-1295 + Ipamorelin' || peptide.name == 'DSIP (Delta Sleep Inducing Peptide)')) {
      reasons.add('Sleep optimization');
    }
    
    if (model.activityLevel == 'Very Active' || model.activityLevel == 'Athlete') {
      if (peptide.name == 'MOTS-C') {
        reasons.add('High activity support');
      }
    }
    
    if (reasons.isEmpty) {
      return 'Recommended based on your profile';
    }
    
    return 'Recommended for: ${reasons.join(', ')}';
  }
}

