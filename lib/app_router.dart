import 'package:flutter/material.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/onboarding/screens/goals_screen.dart';
import 'features/onboarding/screens/biometrics_screen.dart';
import 'features/onboarding/screens/lifestyle_screen.dart';
import 'features/onboarding/screens/medical_screen.dart';
import 'features/protocol/screens/protocol_screen.dart';

/// App router with named routes and custom transitions
class AppRouter {
  static const String welcome = '/';
  static const String goals = '/goals';
  static const String biometrics = '/biometrics';
  static const String lifestyle = '/lifestyle';
  static const String medical = '/medical';
  static const String protocol = '/protocol';
  static const String nextScreenPlaceholder = '/next_screen_placeholder';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return _buildRoute(
          const WelcomeScreen(),
          settings: settings,
        );
      case goals:
        return _buildRoute(
          const GoalsScreen(),
          settings: settings,
        );
      case biometrics:
        return _buildRoute(
          const BiometricsScreen(),
          settings: settings,
        );
      case lifestyle:
        return _buildRoute(
          const LifestyleScreen(),
          settings: settings,
        );
      case medical:
        return _buildRoute(
          const MedicalScreen(),
          settings: settings,
        );
      case protocol:
        return _buildRoute(
          const ProtocolScreen(),
          settings: settings,
        );
      case nextScreenPlaceholder:
        return _buildRoute(
          _NextScreenPlaceholder(),
          settings: settings,
        );
      default:
        return _buildRoute(
          const WelcomeScreen(),
          settings: settings,
        );
    }
  }

  /// Build route with fade + slide transition
  static PageRouteBuilder<dynamic> _buildRoute(
    Widget page, {
    required RouteSettings settings,
  }) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var slideAnimation = Tween(begin: begin, end: end).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
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

