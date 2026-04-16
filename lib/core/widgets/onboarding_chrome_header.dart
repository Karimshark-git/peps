import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/color_palette.dart';

/// Shared “peps” wordmark — middle **p** in teal (onboarding steps 1–3).
class PepsOnboardingLogo extends StatelessWidget {
  const PepsOnboardingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.sora(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xE6FFFFFF),
    );
    final teal = GoogleFonts.sora(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF3ECFA0),
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'pe', style: base),
          TextSpan(text: 'p', style: teal),
          TextSpan(text: 's', style: base),
        ],
      ),
    );
  }
}

/// Thin track whose fill follows [progress] continuously (0.0 → 1.0).
class OnboardingFlowProgressTrack extends StatelessWidget {
  final double progress;

  const OnboardingFlowProgressTrack({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: ColorPalette.progressBackground,
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: p,
        child: Container(
          decoration: BoxDecoration(
            color: ColorPalette.progressFill,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}

/// Back + continuous progress + logo — identical on name / goals / biometrics.
class OnboardingChromeHeader extends StatelessWidget {
  final VoidCallback onBack;
  final double progress;

  const OnboardingChromeHeader({
    super.key,
    required this.onBack,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Color(0x8CFFFFFF),
              ),
              const SizedBox(width: 6),
              Text(
                'back',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0x8CFFFFFF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OnboardingFlowProgressTrack(progress: progress),
        const SizedBox(height: 20),
        const PepsOnboardingLogo(),
      ],
    );
  }
}
