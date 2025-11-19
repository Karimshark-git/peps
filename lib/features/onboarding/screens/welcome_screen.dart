import 'package:flutter/material.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/text_styles.dart';

/// Welcome screen - First screen of onboarding
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
              child: OnboardingProgressBar(progress: 0.0),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Headline
                    Text(
                      'Welcome to PEPS',
                      style: TextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Subtext
                    Text(
                      'Your personalized peptide optimization journey begins here.',
                      style: TextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(flex: 3),
                    // Start button
                    PrimaryButton(
                      text: 'Start',
                      onPressed: () {
                        Navigator.pushNamed(context, '/goals');
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

