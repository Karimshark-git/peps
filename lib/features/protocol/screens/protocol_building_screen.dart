import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/theme/color_palette.dart';
import '../../../engine/recommendation_engine.dart';
import '../../../engine/models/peptide_recommendation.dart';
import '../../../providers/protocol_provider.dart';
import '../../onboarding/provider/onboarding_provider.dart';

/// Premium protocol building loading screen with animated DNA helix
class ProtocolBuildingScreen extends StatefulWidget {
  const ProtocolBuildingScreen({super.key});

  @override
  State<ProtocolBuildingScreen> createState() => _ProtocolBuildingScreenState();
}

class _ProtocolBuildingScreenState extends State<ProtocolBuildingScreen>
    with TickerProviderStateMixin {
  late AnimationController _textFadeController;
  late AnimationController _glowController;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Text fade-in animation
    _textFadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _textFadeController,
      curve: Curves.easeOutCubic,
    );

    // Glow pulsing animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    // Start text fade after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _textFadeController.forward();
      }
    });

    // Run engine and navigate
    _generateProtocol();
  }

  Future<void> _generateProtocol() async {
    // Get onboarding data
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    final model = onboardingProvider.model;

    // Extract lifestyle factors
    final lifestyleFactors = <String>[];
    if (model.lifestyle.isNotEmpty) {
      final factors = model.lifestyle['factors'] as List<dynamic>?;
      if (factors != null) {
        lifestyleFactors.addAll(factors.cast<String>());
      }
    }

    // Extract medical conditions
    final medicalConditions = <String>[];
    if (model.medical.isNotEmpty) {
      final conditions = model.medical['conditions'] as List<dynamic>?;
      if (conditions != null) {
        medicalConditions.addAll(conditions.cast<String>());
      }
    }

    // Build onboarding response
    final response = OnboardingResponse(
      goals: model.goals,
      age: model.age,
      height: model.height,
      weight: model.weight,
      activityLevel: model.activityLevel,
      lifestyleFactors: lifestyleFactors,
      medicalConditions: medicalConditions,
    );

    // Run engine (with minimum 5 second delay)
    final engineStartTime = DateTime.now();
    final recommendations =
        await RecommendationEngine.generateProtocol(response);
    final engineDuration = DateTime.now().difference(engineStartTime);

    // Save to provider
    final protocolProvider =
        Provider.of<ProtocolProvider>(context, listen: false);
    protocolProvider.saveProtocol(recommendations);

    // Ensure minimum 5 seconds total
    final remainingTime = const Duration(seconds: 5) - engineDuration;
    if (remainingTime.inMilliseconds > 0) {
      await Future.delayed(remainingTime);
    }

    // Navigate to protocol ready screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/protocol');
    }
  }

  @override
  void dispose() {
    _textFadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back navigation
      child: Scaffold(
        backgroundColor: ColorPalette.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated DNA helix
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle glow behind helix
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFC8A96A).withValues(
                                  alpha: 0.1 + (_glowAnimation.value * 0.1),
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // DNA helix (vertical, no rotation)
                        _DNAHelix(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 60),
                // Text content
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'Building your personalized protocol…',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.textPrimary,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: Text(
                          'Analyzing your goals, biometrics, lifestyle, and medical background.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: ColorPalette.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated DNA helix with rotating bezier curves and moving dots
class _DNAHelix extends StatefulWidget {
  @override
  State<_DNAHelix> createState() => _DNAHelixState();
}

class _DNAHelixState extends State<_DNAHelix>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _dotAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dotController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 200,
      child: AnimatedBuilder(
        animation: _dotAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _DNAHelixPainter(
              dotProgress: _dotAnimation.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Custom painter for DNA helix with bezier curves and moving dots
class _DNAHelixPainter extends CustomPainter {
  final double dotProgress;

  _DNAHelixPainter({required this.dotProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final helixRadius = 30.0;
    final helixHeight = size.height * 0.8;

    // Paint for curves
    final curvePaint = Paint()
      ..color = const Color(0xFFC8A96A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Paint for dots
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    // Draw two rotating bezier curves (double helix)
    for (int helix = 0; helix < 2; helix++) {
      final offset = helix * math.pi; // 180 degrees offset for second helix
      final path = Path();

      // Create bezier curve for helix strand
      for (double t = 0; t <= 1.0; t += 0.01) {
        final y = centerY - (helixHeight / 2) + (t * helixHeight);
        final angle = (t * 4 * math.pi) + offset; // Multiple rotations
        final x = centerX + helixRadius * math.cos(angle);

        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, curvePaint);

      // Draw moving dots along the curve
      final numDots = 8;
      for (int i = 0; i < numDots; i++) {
        final dotT = (dotProgress + (i / numDots)) % 1.0;
        final y = centerY - (helixHeight / 2) + (dotT * helixHeight);
        final angle = (dotT * 4 * math.pi) + offset;
        final x = centerX + helixRadius * math.cos(angle);

        // Vary dot size and opacity for depth
        final dotSize = 4.0 + (math.sin(dotT * math.pi * 2) * 2);
        final opacity = 0.6 + (math.sin(dotT * math.pi * 2) * 0.4);

        dotPaint.color = const Color(0xFFC8A96A).withValues(alpha: opacity);
        canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
      }
    }

    // Draw connecting lines between helixes (rungs of the ladder)
    final numRungs = 12;
    for (int i = 0; i < numRungs; i++) {
      final t = i / (numRungs - 1);
      final y = centerY - (helixHeight / 2) + (t * helixHeight);
      final angle = t * 4 * math.pi;

      final x1 = centerX + helixRadius * math.cos(angle);
      final x2 = centerX + helixRadius * math.cos(angle + math.pi);

      final rungPaint = Paint()
        ..color = const Color(0xFFC8A96A).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawLine(Offset(x1, y), Offset(x2, y), rungPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DNAHelixPainter oldDelegate) {
    return oldDelegate.dotProgress != dotProgress;
  }
}

