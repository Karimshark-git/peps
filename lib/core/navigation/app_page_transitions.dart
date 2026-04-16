import 'package:flutter/material.dart';

/// Premium page transitions for onboarding screens with iOS swipe-back support
class AppPageTransitions {
  /// Fade through with micro lift (forward) and fade + float up (reverse pop).
  static PageRoute<T> onboardingRoute<T extends Object?>(
    Widget child, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = animation.value.clamp(0.0, 1.0);
            final reverse = animation.status == AnimationStatus.reverse;

            late final double opacity;
            late final Offset translation;

            if (reverse) {
              // ── LEAVING (pop): fade out + float up slightly ──
              final p = 1.0 - t;
              final fadeT =
                  const Interval(0.0, 0.5, curve: Curves.easeIn).transform(p);
              opacity = 1.0 - fadeT;
              final slideT =
                  const Interval(0.0, 0.6, curve: Curves.easeIn).transform(p);
              translation = Offset.lerp(
                Offset.zero,
                const Offset(0, -0.015),
                slideT,
              )!;
            } else {
              // ── ENTERING (push): fade in + micro lift from below ──
              final fadeT = const Interval(0.0, 0.75, curve: Curves.easeOut)
                  .transform(t);
              opacity = fadeT;
              final slideT =
                  const Interval(0.0, 0.85, curve: Curves.easeOutCubic)
                      .transform(t);
              translation = Offset.lerp(
                const Offset(0, 0.025),
                Offset.zero,
                slideT,
              )!;
            }

            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: FractionalTranslation(
                translation: translation,
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  /// Card push: subtle R→L slide + fade (peptide details, email login).
  static PageRoute<T> cardPushRoute<T extends Object?>(
    Widget child, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      maintainState: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        );

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

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
