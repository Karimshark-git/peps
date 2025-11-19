import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/color_palette.dart';
import '../../onboarding/provider/onboarding_provider.dart';
import '../../onboarding/models/onboarding_model.dart';
import '../engine/protocol_engine.dart';
import '../data/peptides.dart';
import 'peptide_details_screen.dart';

/// Protocol screen - Displays personalized peptide recommendations
class ProtocolScreen extends StatefulWidget {
  const ProtocolScreen({super.key});

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends State<ProtocolScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  List<Peptide> _recommendedPeptides = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final model = onboardingProvider.model;
    
    // Generate protocol
    _recommendedPeptides = ProtocolEngine.generate(model);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar (100% complete)
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
              child: OnboardingProgressBar(progress: 1.0),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Your Personalized Protocol Is Ready',
                    style: TextStyles.headingMedium,
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Designed based on your goals, biometrics, and lifestyle.',
                    style: TextStyles.subtitle,
                  ),
                ],
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
                          style: TextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _recommendedPeptides.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _PeptideCard(
                            peptide: _recommendedPeptides[index],
                            model: model,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PeptideDetailsScreen(
                                    peptide: _recommendedPeptides[index],
                                    model: model,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            // Page indicators
            if (_recommendedPeptides.isNotEmpty) ...[
              const SizedBox(height: 16),
              _PageIndicators(
                currentPage: _currentPage,
                totalPages: _recommendedPeptides.length,
              ),
              const SizedBox(height: 16),
            ],
            // Book consultation button
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
              child: PrimaryButton(
                text: 'Book Doctor Consultation',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Consultation booking coming soon!',
                        style: TextStyles.bodyMedium.copyWith(color: Colors.white),
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
      ),
    );
  }
}

/// Page indicators widget with smooth animation
class _PageIndicators extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _PageIndicators({
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? ColorPalette.gold
                : ColorPalette.softBeige,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Premium peptide card widget
class _PeptideCard extends StatelessWidget {
  final Peptide peptide;
  final OnboardingModel model;
  final VoidCallback onTap;

  const _PeptideCard({
    required this.peptide,
    required this.model,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorPalette.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorPalette.cardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorPalette.shadowMedium,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    peptide.name,
                    style: TextStyles.headingSmall,
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    peptide.description,
                    style: TextStyles.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // Benefits (1-2 bullet points)
                  ...peptide.benefits.split(',').take(2).map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyles.bodyMedium.copyWith(
                              color: ColorPalette.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              benefit.trim(),
                              style: TextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // View Details CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Details',
                  style: TextStyles.bodyMedium.copyWith(
                    color: ColorPalette.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: ColorPalette.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

