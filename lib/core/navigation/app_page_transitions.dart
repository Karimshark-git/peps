import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Premium page transitions for onboarding screens with iOS swipe-back support
class AppPageTransitions {
  /// Creates a premium onboarding route with:
  /// - Fade in animation
  /// - Subtle upward motion (10-14px)
  /// - Scale from 0.98 → 1.0
  /// - Smooth easeOutCubic curve
  /// - iOS swipe-back gesture support
  static PageRoute<T> onboardingRoute<T extends Object?>(
    Widget child, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 450),
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Forward animation (entering screen)
        final forwardCurve = Curves.easeOutCubic;
        final forwardAnimation = CurvedAnimation(
          parent: animation,
          curve: forwardCurve,
        );

        // Fade animation for new page
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(forwardAnimation);

        // Slide up animation (10-14px upward motion)
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.012), // ~14px on typical screen
          end: Offset.zero,
        ).animate(forwardAnimation);

        // Scale animation (0.98 → 1.0)
        final scaleAnimation = Tween<double>(
          begin: 0.98,
          end: 1.0,
        ).animate(forwardAnimation);

        // Combine all animations for the new page
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Creates a premium card push route with:
  /// - Right-to-left slide animation (iOS-like)
  /// - Fade in animation
  /// - Smooth easeInOutCubic curve
  /// - 150-220ms duration
  static PageRoute<T> cardPushRoute<T extends Object?>(
    Widget child, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Forward animation (entering screen)
        final forwardCurve = Curves.easeInOutCubic;
        final forwardAnimation = CurvedAnimation(
          parent: animation,
          curve: forwardCurve,
        );

        // Fade animation for new page
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(forwardAnimation);

        // Slide from right animation
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.05, 0), // Slide from right
          end: Offset.zero,
        ).animate(forwardAnimation);

        // Combine fade and slide for new page
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

