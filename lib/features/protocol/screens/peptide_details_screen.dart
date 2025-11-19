import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../onboarding/models/onboarding_model.dart';
import '../data/peptides.dart';
import '../engine/protocol_engine.dart';

/// Premium Peptide Details screen with luxury wellness aesthetic
class PeptideDetailsScreen extends StatefulWidget {
  final Peptide peptide;
  final OnboardingModel model;

  const PeptideDetailsScreen({
    super.key,
    required this.peptide,
    required this.model,
  });

  @override
  State<PeptideDetailsScreen> createState() => _PeptideDetailsScreenState();
}

class _PeptideDetailsScreenState extends State<PeptideDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;
  final List<AnimationController> _cardControllers = [];

  @override
  void initState() {
    super.initState();

    // Page entrance animation
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    _pageSlideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    // Card entrance animations (staggered)
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create individual controllers for each card
    for (int i = 0; i < 6; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _cardControllers.add(controller);
    }

    // Start animations
    _pageAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _cardAnimationController.forward();
        for (int i = 0; i < _cardControllers.length; i++) {
          Future.delayed(
            Duration(milliseconds: 50 * i),
            () {
              if (mounted && i < _cardControllers.length) {
                _cardControllers[i].forward();
              }
            },
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _cardAnimationController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final whyRecommended = ProtocolEngine.getWhyRecommended(
      widget.peptide,
      widget.model,
    );
    const goldColor = Color(0xFFC9A568);
    const softBeige = Color(0xFFF7F2E9);

    return Scaffold(
      backgroundColor: softBeige,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle radial gradient behind header
            Positioned(
              left: MediaQuery.of(context).size.width * 0.5 - 100,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      goldColor.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            FadeTransition(
              opacity: _pageFadeAnimation,
              child: SlideTransition(
                position: _pageSlideAnimation,
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: ColorPalette.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _HeaderSection(
                              peptide: widget.peptide,
                              animationDelay: Duration.zero,
                            ),
                            const SizedBox(height: 32),
                            // Why Recommended Card
                            _InfoCard(
                              title: 'Why Recommended',
                              content: whyRecommended,
                              animationController: _cardControllers[0],
                              animationDelay: const Duration(milliseconds: 0),
                            ),
                            const SizedBox(height: 20),
                            // Description Card
                            _InfoCard(
                              title: 'Description',
                              content: widget.peptide.description,
                              animationController: _cardControllers[1],
                              animationDelay: const Duration(milliseconds: 50),
                            ),
                            const SizedBox(height: 20),
                            // How It Works Card
                            _InfoCard(
                              title: 'How It Works',
                              content: widget.peptide.mechanism,
                              isList: false,
                              animationController: _cardControllers[2],
                              animationDelay: const Duration(milliseconds: 100),
                            ),
                            const SizedBox(height: 20),
                            // Benefits Card
                            _InfoCard(
                              title: 'Benefits',
                              content: widget.peptide.benefits,
                              isList: true,
                              animationController: _cardControllers[3],
                              animationDelay: const Duration(milliseconds: 150),
                            ),
                            const SizedBox(height: 20),
                            // Dosage + Frequency Card
                            _DosageFrequencyCard(
                              peptide: widget.peptide,
                              animationController: _cardControllers[4],
                              animationDelay: const Duration(milliseconds: 200),
                            ),
                            const SizedBox(height: 20),
                            // Safety Disclaimer Card
                            _SafetyDisclaimerCard(
                              animationController: _cardControllers[5],
                              animationDelay: const Duration(milliseconds: 250),
                            ),
                          ],
                        ),
                      ),
                    ),
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

/// Premium header section with title and category badge
class _HeaderSection extends StatelessWidget {
  final Peptide peptide;
  final Duration animationDelay;

  const _HeaderSection({
    required this.peptide,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC9A568);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: Peptide name in serif
        Text(
          peptide.name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        // Category tag as soft gold badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: goldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            peptide.category,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: goldColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable info card component
class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isList;
  final AnimationController animationController;
  final Duration animationDelay;

  const _InfoCard({
    required this.title,
    required this.content,
    this.isList = false,
    required this.animationController,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC9A568);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Opacity(
          opacity: animationController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animationController.value) * 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFF8F3EC),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Content
                  if (isList)
                    ...content.split(',').map((item) {
                      final trimmed = item.trim();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: goldColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                trimmed,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: ColorPalette.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  else
                    Text(
                      content,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textPrimary,
                        height: 1.6,
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

/// Dosage and Frequency combined card
class _DosageFrequencyCard extends StatelessWidget {
  final Peptide peptide;
  final AnimationController animationController;
  final Duration animationDelay;

  const _DosageFrequencyCard({
    required this.peptide,
    required this.animationController,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFC9A568);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Opacity(
          opacity: animationController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animationController.value) * 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFF8F3EC),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Dosage & Frequency',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Dosage section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.medication_liquid_rounded,
                        size: 20,
                        color: goldColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dosage',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              peptide.dosage,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: ColorPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          ColorPalette.cardBackground,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Frequency section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 20,
                        color: goldColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Frequency',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ColorPalette.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              peptide.frequency,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: ColorPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

/// Safety disclaimer card
class _SafetyDisclaimerCard extends StatelessWidget {
  final AnimationController animationController;
  final Duration animationDelay;

  const _SafetyDisclaimerCard({
    required this.animationController,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Opacity(
          opacity: animationController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animationController.value) * 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDE4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: ColorPalette.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Important: This protocol is for informational purposes only. Please consult with a qualified healthcare provider before starting any peptide protocol.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textSecondary,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
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
