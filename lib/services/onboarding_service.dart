import '../services/supabase_client.dart';
import '../features/onboarding/models/onboarding_model.dart';

/// Service for saving onboarding responses to Supabase
class OnboardingService {
  /// Saves onboarding response for a user
  /// Extracts data from OnboardingProvider and saves to onboarding_responses table
  static Future<void> saveOnboardingResponseForUser(String userId) async {
    try {
      // Get onboarding provider from context
      // Note: This requires a BuildContext, so we'll need to pass it or use a different approach
      // For now, we'll make this method accept the model directly
      throw UnimplementedError(
        'Use saveOnboardingResponseForUserWithModel instead',
      );
    } catch (e) {
      throw Exception('Failed to save onboarding response: $e');
    }
  }

  /// Saves onboarding response for a user with the model passed directly
  static Future<void> saveOnboardingResponseForUserWithModel(
    String userId,
    OnboardingModel model,
  ) async {
    try {
      // Check if onboarding data exists
      if (!_hasOnboardingData(model)) {
        // No onboarding data to save, skip
        return;
      }

      // Extract lifestyle factors from model
      final lifestyleFactors = <String>[];
      if (model.lifestyle.containsKey('factors')) {
        final factors = model.lifestyle['factors'];
        if (factors is List) {
          lifestyleFactors.addAll(
            factors.whereType<String>().toList(),
          );
        }
      }

      // Extract medical conditions from model
      final medicalConditions = <String>[];
      if (model.medical.containsKey('conditions')) {
        final conditions = model.medical['conditions'];
        if (conditions is List) {
          medicalConditions.addAll(
            conditions.whereType<String>().toList(),
          );
        }
      }

      // Prepare data for insertion
      final onboardingData = {
        'user_id': userId,
        'first_name': model.firstName,
        'goals': model.goals.isNotEmpty ? model.goals : null,
        'age': model.age,
        'height_cm': model.height?.toInt(),
        'weight_kg': model.weight?.toInt(),
        'activity_level': model.activityLevel,
        'lifestyle_factors': lifestyleFactors.isNotEmpty
            ? lifestyleFactors
            : null,
        'medical_conditions': medicalConditions.isNotEmpty
            ? medicalConditions
            : null,
      };

      // Remove null values
      onboardingData.removeWhere((key, value) => value == null);

      // Insert into onboarding_responses table
      await supabase.from('onboarding_responses').insert(onboardingData);
    } catch (e) {
      throw Exception('Failed to save onboarding response: $e');
    }
  }

  /// Helper method to check if onboarding data exists
  static bool _hasOnboardingData(OnboardingModel model) {
    return model.firstName != null ||
        model.goals.isNotEmpty ||
        model.age != null ||
        model.height != null ||
        model.weight != null ||
        model.activityLevel != null ||
        model.lifestyle.isNotEmpty ||
        model.medical.isNotEmpty;
  }
}

