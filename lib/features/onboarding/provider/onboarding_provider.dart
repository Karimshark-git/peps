import 'package:flutter/foundation.dart';
import '../models/onboarding_model.dart';

/// Provider for managing onboarding state
class OnboardingProvider extends ChangeNotifier {
  OnboardingModel _model = OnboardingModel();

  OnboardingModel get model => _model;

  /// Update first name
  void updateFirstName(String firstName) {
    _model = _model.copyWith(firstName: firstName);
    notifyListeners();
  }

  /// Update goals list
  void updateGoals(List<String> goals) {
    _model = _model.copyWith(goals: goals);
    notifyListeners();
  }

  /// Update biometrics (age, height, weight, activity level)
  void updateBiometrics({
    required int age,
    required double height,
    required double weight,
    required String activity,
  }) {
    _model = _model.copyWith(
      age: age,
      height: height,
      weight: weight,
      activityLevel: activity,
    );
    notifyListeners();
  }

  /// Update activity level (kept for backward compatibility)
  void updateActivityLevel(String activityLevel) {
    _model = _model.copyWith(activityLevel: activityLevel);
    notifyListeners();
  }

  /// Update lifestyle data
  void updateLifestyle(Map<String, dynamic> lifestyle) {
    _model = _model.copyWith(lifestyle: lifestyle);
    notifyListeners();
  }

  /// Update medical data
  void updateMedical(Map<String, dynamic> medical) {
    _model = _model.copyWith(medical: medical);
    notifyListeners();
  }

  /// Reset all onboarding data
  void reset() {
    _model.reset();
    notifyListeners();
  }
}

