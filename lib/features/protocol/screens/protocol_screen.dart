import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/navigation/app_page_transitions.dart';
import '../../onboarding/provider/onboarding_provider.dart';
import '../../onboarding/models/onboarding_model.dart';
import '../engine/protocol_engine.dart';
import '../data/peptides.dart';
import 'peptide_details_screen.dart';

/// Premium Protocol screen with 3D carousel and wellness-style design
class ProtocolScreen extends StatefulWidget {
  const ProtocolScreen({super.key});

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends State<ProtocolScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  List<Peptide> _recommendedPeptides = [];
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _cardScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);

    // Header entrance animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03), // 12px down
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Card entrance animation
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _cardAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final model = onboardingProvider.model;

    // Generate protocol
    _recommendedPeptides = ProtocolEngine.generate(model);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle radial glow behind carousel
            if (_recommendedPeptides.isNotEmpty)
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 - 150,
                top: MediaQuery.of(context).size.height * 0.4 - 150,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFC8A96A).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            // Main content
            Column(
              children: [
                // Progress bar (100% complete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                  child: OnboardingProgressBar(stepIndex: 6),
                ),
                // Hero header with chips
                FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title - Premium serif
                          Text(
                            'Your Personalized Protocol Is Ready',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Subtitle - Narrower max width, softer color
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: Text(
                              'Designed based on your goals, biometrics, and lifestyle.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: ColorPalette.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Carousel
                Expanded(
                  child: _recommendedPeptides.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No peptides recommended at this time.\nPlease complete your onboarding.',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: ColorPalette.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: AnimatedBuilder(
                            animation: _cardAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _cardScaleAnimation.value,
                                child: PageView.builder(
                                  controller: _pageController,
                                  physics: const BouncingScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemCount: _recommendedPeptides.length,
                                  itemBuilder: (context, index) {
                                    return AnimatedBuilder(
                                      animation: _pageController,
                                      builder: (context, child) {
                                        double pageOffset = 0;
                                        if (_pageController.position.haveDimensions) {
                                          pageOffset = _pageController.page! - index;
                                        }
                                        final absOffset = pageOffset.abs();
                                        final isActive = absOffset < 0.5;
                                        final scale = (1.0 - (absOffset * 0.07)).clamp(0.93, 1.0);
                                        final translation = absOffset * 10.0;
                                        final shadowOpacity = (1.0 - (absOffset * 0.5)).clamp(0.5, 1.0);

                                        return Transform.scale(
                                          scale: scale,
                                          child: Transform.translate(
                                            offset: Offset(0, translation),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                                vertical: 4.0,
                                              ),
                                              child: PeptideProtocolCard(
                                                peptide: _recommendedPeptides[index],
                                                model: model,
                                                isActive: isActive,
                                                shadowOpacity: shadowOpacity,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  AppPageTransitions.cardPushRoute(
                                                    PeptideDetailsScreen(
                                                      peptide:
                                                          _recommendedPeptides[index],
                                                      model: model,
                                                    ),
                                                  ),
                                                );
                                              },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
                // Page indicators
                if (_recommendedPeptides.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _PremiumPageIndicators(
                    currentPage: _currentPage,
                    totalPages: _recommendedPeptides.length,
                  ),
                  const SizedBox(height: 20),
                ],
                // Book consultation button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
                  child: _PremiumConsultationButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Consultation booking coming soon!',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: ColorPalette.gold,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium animated page indicators
class _PremiumPageIndicators extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _PremiumPageIndicators({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: isActive ? 20 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFC8A96A)
                : ColorPalette.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Premium consultation button with gradient
class _PremiumConsultationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PremiumConsultationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFC8A96A),
            const Color(0xFFC8A96A).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Book Doctor Consultation',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Required to confirm and finalize your protocol.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium 3D peptide protocol card
class PeptideProtocolCard extends StatelessWidget {
  final Peptide peptide;
  final OnboardingModel model;
  final bool isActive;
  final double shadowOpacity;
  final VoidCallback onTap;

  const PeptideProtocolCard({
    super.key,
    required this.peptide,
    required this.model,
    required this.isActive,
    required this.shadowOpacity,
    required this.onTap,
  });

  String _getDeliveryMethod() {
    if (peptide.frequency.contains('subcutaneously')) {
      return 'Subcutaneous';
    } else if (peptide.frequency.contains('topically')) {
      return 'Topical';
    } else if (peptide.frequency.contains('intranasally')) {
      return 'Intranasal';
    } else if (peptide.frequency.contains('orally')) {
      return 'Oral';
    }
    return 'Subcutaneous';
  }

  String _getProtocolInfo() {
    final weeks = '12'; // Placeholder - can be extracted from peptide data
    final route = _getDeliveryMethod();
    return '$weeks weeks • $route';
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD1A057);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 0,
            maxHeight: double.infinity,
          ),
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.05 + (shadowOpacity * 0.05),
                ),
                blurRadius: 8 + (shadowOpacity * 4),
                offset: Offset(0, 2 + (shadowOpacity * 2)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title: Peptide name in bold serif
              Text(
                peptide.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle: Category pill-style label (optional)
              if (peptide.category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    peptide.category,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ),
              if (peptide.category.isNotEmpty) const SizedBox(height: 14),
              // Description: 2-3 lines, auto-truncated
              Text(
                peptide.description,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.textPrimary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Benefits: bullet list with golden bullets
              ...peptide.benefits
                  .split(',')
                  .take(2)
                  .map((benefit) {
                final trimmed = benefit.trim();
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
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: ColorPalette.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              // Footer: Estimated protocol length • Delivery method
              Text(
                _getProtocolInfo(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              // Right-aligned CTA: View Details →
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: goldColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: goldColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
