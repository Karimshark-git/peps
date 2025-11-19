/// Model for onboarding data
class OnboardingModel {
  List<String> goals;
  int? age;
  double? height;
  double? weight;
  String? activityLevel;
  Map<String, dynamic> lifestyle;
  Map<String, dynamic> medical;

  OnboardingModel({
    this.goals = const [],
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    Map<String, dynamic>? lifestyle,
    Map<String, dynamic>? medical,
  })  : lifestyle = lifestyle ?? {},
        medical = medical ?? {};

  /// Create a copy with updated fields
  OnboardingModel copyWith({
    List<String>? goals,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    Map<String, dynamic>? lifestyle,
    Map<String, dynamic>? medical,
  }) {
    return OnboardingModel(
      goals: goals ?? this.goals,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      lifestyle: lifestyle ?? this.lifestyle,
      medical: medical ?? this.medical,
    );
  }

  /// Reset all fields to initial state
  void reset() {
    goals = [];
    age = null;
    height = null;
    weight = null;
    activityLevel = null;
    lifestyle = {};
    medical = {};
  }
}

