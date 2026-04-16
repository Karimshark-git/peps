import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/peps_ambient_orbs.dart';
import '../../../engine/recommendation_engine.dart';
import '../../../providers/protocol_provider.dart';
import '../../onboarding/provider/onboarding_provider.dart';

/// Protocol building — loading (engine + min 5s delay unchanged)
class ProtocolBuildingScreen extends StatefulWidget {
  const ProtocolBuildingScreen({super.key});

  @override
  State<ProtocolBuildingScreen> createState() => _ProtocolBuildingScreenState();
}

class _ProtocolBuildingScreenState extends State<ProtocolBuildingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _rippleController;
  late AnimationController _item0Controller;
  late AnimationController _item1Controller;
  late AnimationController _item2Controller;
  late Animation<double> _item0Anim;
  late Animation<double> _item1Anim;
  late Animation<double> _item2Anim;
  late AnimationController _dotsBlinkController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();

    _item0Controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _item1Controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _item2Controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _item0Anim = CurvedAnimation(
      parent: _item0Controller,
      curve: Curves.easeOutCubic,
    );
    _item1Anim = CurvedAnimation(
      parent: _item1Controller,
      curve: Curves.easeOutCubic,
    );
    _item2Anim = CurvedAnimation(
      parent: _item2Controller,
      curve: Curves.easeOutCubic,
    );

    _dotsBlinkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _generateProtocol();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _item0Controller.forward();
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _item1Controller.forward();
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _item2Controller.forward();
    });
  }

  Future<void> _generateProtocol() async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    final model = onboardingProvider.model;

    final engineStartTime = DateTime.now();
    final recommendations =
        await RecommendationEngine.generateProtocol(model);
    final engineDuration = DateTime.now().difference(engineStartTime);

    if (!mounted) return;
    final protocolProvider =
        Provider.of<ProtocolProvider>(context, listen: false);
    protocolProvider.saveProtocol(recommendations);

    final remainingTime = const Duration(seconds: 5) - engineDuration;
    if (remainingTime.inMilliseconds > 0) {
      await Future.delayed(remainingTime);
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/protocol');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _rippleController.dispose();
    _item0Controller.dispose();
    _item1Controller.dispose();
    _item2Controller.dispose();
    _dotsBlinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF08101E);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            const PepsAmbientOrbs(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Center(
                    child: _AnimatedOrb(
                      pulseController: _pulseController,
                      rotateController: _rotateController,
                      rippleController: _rippleController,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: _HeadingWithDots(
                      dotsBlinkController: _dotsBlinkController,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildCheckItem(
                        _item0Anim,
                        'Goals & biometrics analyzed',
                      ),
                      _buildCheckItem(
                        _item1Anim,
                        'Lifestyle factors weighted',
                      ),
                      _buildCheckItem(
                        _item2Anim,
                        'Medical safety filters applied',
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(Animation<double> anim, String label) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - anim.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x1A3ECFA0),
                      border: Border.all(
                        color: const Color(0xFF3ECFA0),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Color(0xFF3ECFA0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0x8CFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedOrb extends StatelessWidget {
  final AnimationController pulseController;
  final AnimationController rotateController;
  final AnimationController rippleController;

  const _AnimatedOrb({
    required this.pulseController,
    required this.rotateController,
    required this.rippleController,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF3ECFA0);
    const centerFill = Color(0xFF0D1825);

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: rippleController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(220, 220),
                painter: _RipplePainter(rippleController.value),
              );
            },
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x12FFFFFF), width: 1),
            ),
          ),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x0AFFFFFF), width: 1),
            ),
          ),
          AnimatedBuilder(
            animation: rotateController,
            builder: (context, _) {
              return Transform.rotate(
                angle: rotateController.value * 2 * math.pi,
                child: const CustomPaint(
                  size: Size(220, 220),
                  painter: _ArcPainter(),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, _) {
              final t = pulseController.value;
              final scale = 1.0 + math.sin(t * math.pi) * 0.06;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: centerFill,
                    border: Border.all(
                      color: teal.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x333ECFA0),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: Color(0x1A3ECFA0),
                        blurRadius: 48,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.biotech_outlined,
                    size: 28,
                    color: teal,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.value);

  final double value;

  static const _teal = Color(0xFF3ECFA0);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < 3; i++) {
      final phase = (value + i * 0.33) % 1.0;
      final radius = 60.0 + phase * 90.0;
      final opacity = (1.0 - phase) * 0.15;
      paint.color = _teal.withValues(alpha: opacity);
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 95.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const sweep = 1.2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: sweep,
        colors: [
          const Color(0xFF3ECFA0),
          const Color(0xFF3ECFA0).withValues(alpha: 0.0),
        ],
      ).createShader(rect);

    canvas.drawArc(rect, 0, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _HeadingWithDots extends StatelessWidget {
  final AnimationController dotsBlinkController;

  const _HeadingWithDots({required this.dotsBlinkController});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Building your protocol',
          style: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: const Color(0xE6FFFFFF),
            height: 1.25,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Analyzing your responses',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0x8CFFFFFF),
              ),
            ),
            const SizedBox(width: 8),
            _AnimatedDots(controller: dotsBlinkController),
          ],
        ),
      ],
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  static const _intervals = [
    Interval(0.0, 0.33, curve: Curves.easeInOut),
    Interval(0.2, 0.53, curve: Curves.easeInOut),
    Interval(0.4, 0.73, curve: Curves.easeInOut),
  ];

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF3ECFA0);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final dots = <Widget>[];
        for (var i = 0; i < 3; i++) {
          if (i > 0) dots.add(const SizedBox(width: 5));
          final u = _intervals[i].transform(t);
          final wave = math.sin(u * math.pi);
          final scale = 0.4 + 0.6 * wave;
          final opacity = 0.3 + 0.7 * wave;
          dots.add(
            Transform.scale(
              scale: scale.clamp(0.4, 1.0),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: teal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: dots,
        );
      },
    );
  }
}
