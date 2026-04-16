import 'package:flutter/material.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/onboarding_personalization_shell.dart';
import 'features/protocol/screens/protocol_screen.dart';
import 'features/protocol/screens/protocol_building_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/create_account_email_screen.dart';
import 'features/auth/screens/email_verification_pending_screen.dart';
import 'features/navigation/main_navigation.dart';
import 'features/checkin/screens/check_in_screen.dart';
import 'core/navigation/app_page_transitions.dart';

/// App router with named routes and premium transitions
class AppRouter {
  static const String welcome = '/';
  static const String name = '/name';
  static const String goals = '/goals';
  static const String biometrics = '/biometrics';
  static const String lifestyle = '/lifestyle';
  static const String medical = '/medical';
  static const String protocol = '/protocol';
  static const String protocolBuilding = '/protocol-building';
  static const String login = '/login';
  static const String createAccountEmail = '/create-account-email';
  static const String emailVerificationPending = '/email-verification-pending';
  static const String home = '/home';
  static const String checkIn = '/check-in';
  static const String nextScreenPlaceholder = '/next_screen_placeholder';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return AppPageTransitions.onboardingRoute(
          const WelcomeScreen(),
          settings: settings,
        );
      case name:
        return AppPageTransitions.onboardingRoute(
          const OnboardingPersonalizationShell(initialPage: 0),
          settings: settings,
        );
      case goals:
        return AppPageTransitions.onboardingRoute(
          const OnboardingPersonalizationShell(initialPage: 1),
          settings: settings,
        );
      case biometrics:
        return AppPageTransitions.onboardingRoute(
          const OnboardingPersonalizationShell(initialPage: 2),
          settings: settings,
        );
      case lifestyle:
        return AppPageTransitions.onboardingRoute(
          const OnboardingPersonalizationShell(initialPage: 3),
          settings: settings,
        );
      case medical:
        return AppPageTransitions.onboardingRoute(
          const OnboardingPersonalizationShell(initialPage: 4),
          settings: settings,
        );
      case protocol:
        return AppPageTransitions.onboardingRoute(
          const ProtocolScreen(),
          settings: settings,
        );
      case protocolBuilding:
        return AppPageTransitions.onboardingRoute(
          const ProtocolBuildingScreen(),
          settings: settings,
        );
      case login:
        return AppPageTransitions.onboardingRoute(
          const LoginScreen(),
          settings: settings,
        );
      case createAccountEmail:
        return AppPageTransitions.onboardingRoute(
          const CreateAccountEmailScreen(),
          settings: settings,
        );
      case emailVerificationPending:
        return AppPageTransitions.onboardingRoute(
          const EmailVerificationPendingScreen(),
          settings: settings,
        );
      case home:
        return AppPageTransitions.onboardingRoute(
          const MainNavigation(),
          settings: settings,
        );
      case checkIn:
        return AppPageTransitions.cardPushRoute(
          const CheckInScreen(),
          settings: settings,
        );
      case nextScreenPlaceholder:
        return AppPageTransitions.onboardingRoute(
          _NextScreenPlaceholder(),
          settings: settings,
        );
      default:
        return AppPageTransitions.onboardingRoute(
          const WelcomeScreen(),
          settings: settings,
        );
    }
  }
}

/// Placeholder screen for next onboarding step
// TODO: Replace with actual next screen
class _NextScreenPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Screen'),
      ),
      body: const Center(
        child: Text('Next screen placeholder - TODO: Implement'),
      ),
    );
  }
}

