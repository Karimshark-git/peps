import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_router.dart';
import '../../../core/widgets/peps_min_height_scroll_view.dart';
import '../../../core/widgets/primary_button.dart';

/// Welcome — dark glass entry
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08101E),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          const _WelcomeOrbs(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PepsMinHeightScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _PepsLogoMark(),
                              const SizedBox(height: 12),
                              Text(
                                'PEPTIDE PROTOCOLS · UAE',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0x4DFFFFFF),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        const _WelcomeHeroCard(),
                        const SizedBox(height: 20),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _WelcomeInfoChip(
                                title: '23 peptides',
                                subtitle: 'UAE-legal catalog',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _WelcomeInfoChip(
                                title: 'Door delivery',
                                subtitle: 'Monthly subscription',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x4D3ECFA0),
                                blurRadius: 20,
                                spreadRadius: -2,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: PrimaryButton(
                            text: 'Get my protocol →',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRouter.name);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0x8CFFFFFF),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRouter.login);
                            },
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0x8CFFFFFF),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeOrbs extends StatelessWidget {
  const _WelcomeOrbs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -160,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: 400,
                height: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x1A3ECFA0),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: -80,
          bottom: 120,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x146496FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -60,
          top: 160,
          child: IgnorePointer(
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x0D3ECFA0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PepsLogoMark extends StatelessWidget {
  const _PepsLogoMark();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.sora(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: const Color(0xE6FFFFFF),
    );
    final teal = GoogleFonts.sora(
      fontSize: 32,
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
      textAlign: TextAlign.center,
    );
  }
}

class _WelcomeHeroCard extends StatelessWidget {
  const _WelcomeHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F3ECFA0),
            blurRadius: 32,
            spreadRadius: -4,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            border: Border.all(
              color: const Color(0x29FFFFFF),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 1,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Color(0x3DFFFFFF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Text(
                  'AI-powered protocols.\nPhysician-reviewed.\nDelivered monthly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xE6FFFFFF),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeInfoChip extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WelcomeInfoChip({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Color(0x3DFFFFFF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3ECFA0),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x663ECFA0),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xE6FFFFFF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0x4DFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
