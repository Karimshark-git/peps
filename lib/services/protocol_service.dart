import 'supabase_client.dart';
import '../features/protocol/models/protocol_models.dart';

/// Service for fetching protocol-related data from Supabase
class ProtocolService {
  /// Fetches recommendations with peptide details for the current user
  /// Returns a list of maps containing recommendation and peptide data
  static Future<List<Map<String, dynamic>>> getUserRecommendations() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get user ID from users table
    final userResponse = await supabase
        .from('users')
        .select('id, email')
        .eq('auth_uid', user.id)
        .single();

    final userId = userResponse['id'] as String;

    // Fetch recommendations with peptide details
    final response = await supabase
        .from('recommendations')
        .select('''
          *,
          peptides (
            id,
            name,
            category,
            description,
            summary,
            benefits,
            short_benefits,
            dosage,
            frequency,
            goals_supported
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Gets the current user's email or name
  static Future<String?> getUserEmail() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final userResponse = await supabase
          .from('users')
          .select('email')
          .eq('auth_uid', user.id)
          .maybeSingle();

      return userResponse?['email'] as String? ?? user.email;
    } catch (e) {
      return user.email;
    }
  }

  /// Fetches the latest onboarding response for the current user
  /// Returns null if no onboarding data exists
  static Future<OnboardingSummary?> fetchLatestOnboardingForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get user ID from users table
    final userResponse = await supabase
        .from('users')
        .select('id')
        .eq('auth_uid', user.id)
        .single();

    final userId = userResponse['id'] as String;

    // Fetch the most recent onboarding response
    final response = await supabase
        .from('onboarding_responses')
        .select('goals, lifestyle_factors, medical_conditions')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return OnboardingSummary(
      goals: List<String>.from(response['goals'] as List<dynamic>? ?? []),
      lifestyleFactors: List<String>.from(
        response['lifestyle_factors'] as List<dynamic>? ?? [],
      ),
      medicalConditions: List<String>.from(
        response['medical_conditions'] as List<dynamic>? ?? [],
      ),
    );
  }

  /// Fetches the protocol items (recommendations + peptides) for the current user
  static Future<List<ProtocolItem>> fetchProtocolForCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get user ID from users table
    final userResponse = await supabase
        .from('users')
        .select('id')
        .eq('auth_uid', user.id)
        .single();

    final userId = userResponse['id'] as String;

    // Fetch recommendations with peptide details
    final response = await supabase
        .from('recommendations')
        .select('''
          id,
          reasoning,
          peptides (
            id,
            name,
            category,
            summary,
            short_benefits,
            goals_supported,
            lifestyle_supported
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final recommendations = List<Map<String, dynamic>>.from(response);

    return recommendations.map((rec) {
      final peptide = rec['peptides'] as Map<String, dynamic>?;
      if (peptide == null) {
        throw Exception('Peptide data missing for recommendation');
      }

      return ProtocolItem(
        peptideId: peptide['id'] as String,
        peptideName: peptide['name'] as String? ?? 'Unknown',
        peptideCategory: peptide['category'] as String? ?? '',
        peptideSummary: peptide['summary'] as String? ?? '',
        shortBenefits: List<String>.from(
          peptide['short_benefits'] as List<dynamic>? ?? [],
        ),
        goalsSupported: List<String>.from(
          peptide['goals_supported'] as List<dynamic>? ?? [],
        ),
        lifestyleSupported: List<String>.from(
          peptide['lifestyle_supported'] as List<dynamic>? ?? [],
        ),
        reasoning: rec['reasoning'] as String? ?? '',
      );
    }).toList();
  }

  /// Fetches user profile data including user info and latest onboarding response
  /// Returns a map with 'user' and 'onboarding' keys
  static Future<Map<String, dynamic>> fetchUserProfileData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get user ID from users table
    final userResponse = await supabase
        .from('users')
        .select('id, email, created_at')
        .eq('auth_uid', user.id)
        .single();

    final userId = userResponse['id'] as String;

    // Fetch the most recent onboarding response
    final onboardingResponse = await supabase
        .from('onboarding_responses')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return {
      'user': {
        'id': userId,
        'email': userResponse['email'] as String? ?? user.email,
        'created_at': userResponse['created_at'],
      },
      'onboarding': onboardingResponse,
    };
  }
}


