import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_client.dart';
import '../services/onboarding_service.dart';
import '../app_router.dart';
import '../features/onboarding/provider/onboarding_provider.dart';
import '../providers/protocol_provider.dart';

/// Service for handling authentication and post-login operations
class AuthService {
  /// Handles post-login operations:
  /// 1. Gets current user from Supabase auth
  /// 2. Upserts user into users table
  /// 3. Saves onboarding data if available
  /// 4. Redirects to protocol screen
  static Future<void> handlePostLogin(BuildContext context) async {
    try {
      // 1. Get current user from Supabase auth
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final uid = user.id;
      final email = user.email;

      if (email == null) {
        throw Exception('User email not found');
      }

      // 2. Upsert into users table (with first_name if available)
      final onboardingProvider = Provider.of<OnboardingProvider>(
        context,
        listen: false,
      );
      final firstName = onboardingProvider.model.firstName;
      
      final userData = <String, dynamic>{
        'auth_uid': uid,
        'email': email,
      };
      
      // Add first_name if available
      if (firstName != null && firstName.isNotEmpty) {
        userData['first_name'] = firstName;
      }
      
      // Upsert user - this will create the entry if it doesn't exist
      final userResponse = await supabase
          .from('users')
          .upsert(
            userData,
            onConflict: 'auth_uid',
          )
          .select()
          .single();

      final userId = userResponse['id'] as String;

      // 3. Save onboarding data if available
      await OnboardingService.saveOnboardingResponseForUserWithModel(
        userId,
        onboardingProvider.model,
      );

      // 4. Save protocol recommendations to Supabase (only if not already saved)
      final protocolProvider = Provider.of<ProtocolProvider>(
        context,
        listen: false,
      );
      final protocol = protocolProvider.protocol;

      if (protocol.isNotEmpty) {
        // Check if recommendations already exist for this user
        final existingRecommendations = await supabase
            .from('recommendations')
            .select('peptide_id')
            .eq('user_id', userId);

        final existingPeptideIds = (existingRecommendations as List)
            .map((r) => r['peptide_id'] as String)
            .toSet();

        // Insert only new recommendations (prevent duplicates)
        for (final recommendation in protocol) {
          if (!existingPeptideIds.contains(recommendation.peptideId)) {
            await supabase.from('recommendations').insert({
              'user_id': userId,
              'peptide_id': recommendation.peptideId,
              'reasoning': recommendation.reasoning,
            });
          }
        }

        // Clear protocol from provider after saving
        protocolProvider.clearProtocol();
      }

      // 5. Check if user has completed onboarding
      // If they have onboarding data, go to home. Otherwise, start assessment.
      final onboardingResponse = await supabase
          .from('onboarding_responses')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (!context.mounted) return;

      if (onboardingResponse != null) {
        // User has completed onboarding - go to home
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.home,
          (route) => false, // Remove all previous routes
        );
      } else {
        // User hasn't completed onboarding - start with name screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.name,
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Handle errors gracefully
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
}

