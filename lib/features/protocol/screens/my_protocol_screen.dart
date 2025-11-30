import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/navigation/app_page_transitions.dart';
import '../../../services/protocol_service.dart';
import '../../../services/supabase_client.dart';
import '../../../engine/models/peptide_recommendation.dart';
import '../models/protocol_models.dart';
import 'peptide_details_screen_new.dart';
import '../../../app_router.dart';

/// Premium My Protocol screen showing user's personalized protocol
class MyProtocolScreen extends StatefulWidget {
  const MyProtocolScreen({super.key});

  @override
  State<MyProtocolScreen> createState() => _MyProtocolScreenState();
}

class _MyProtocolScreenState extends State<MyProtocolScreen>
    with TickerProviderStateMixin {
  OnboardingSummary? _onboardingSummary;
  List<ProtocolItem> _protocolItems = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _pageAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;

  @override
  void initState() {
    super.initState();

    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _pageSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _pageAnimationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Fetch onboarding summary and protocol items in parallel
      final results = await Future.wait([
        ProtocolService.fetchLatestOnboardingForCurrentUser(),
        ProtocolService.fetchProtocolForCurrentUser(),
      ]);

      setState(() {
        _onboardingSummary = results[0] as OnboardingSummary?;
        _protocolItems = results[1] as List<ProtocolItem>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load protocol: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Gets top 2-3 goals for display
  List<String> _getTopGoals() {
    if (_onboardingSummary == null || _onboardingSummary!.goals.isEmpty) {
      return [];
    }
    return _onboardingSummary!.goals.take(3).toList();
  }

  /// Gets dominant goal (first goal)
  String? _getDominantGoal() {
    final goals = _getTopGoals();
    return goals.isNotEmpty ? goals.first : null;
  }

  /// Gets secondary goal (second goal if exists)
  String? _getSecondaryGoal() {
    final goals = _getTopGoals();
    return goals.length > 1 ? goals[1] : null;
  }

  /// Converts ProtocolItem to PeptideRecommendation for navigation
  PeptideRecommendation _toPeptideRecommendation(ProtocolItem item) {
    return PeptideRecommendation(
      peptideId: item.peptideId,
      name: item.peptideName,
      summary: item.peptideSummary,
      reasoning: item.reasoning,
      score: 0.0, // Not needed for display
      category: item.peptideCategory,
      shortBenefits: item.shortBenefits,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageFadeAnimation,
          child: SlideTransition(
            position: _pageSlideAnimation,
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _protocolItems.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.gold),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your protocol...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: ColorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ColorPalette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              "We couldn't load your protocol right now.",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorPalette.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: ColorPalette.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No protocol found yet.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete onboarding to generate your personalized protocol.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ColorPalette.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.goals);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Start Onboarding',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final topGoals = _getTopGoals();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Header Section
          _HeaderSection(
            topGoals: topGoals,
            onboardingSummary: _onboardingSummary,
          ),
          const SizedBox(height: 32),
          // Protocol Summary Card
          _ProtocolSummaryCard(
            totalPeptides: _protocolItems.length,
            dominantGoal: _getDominantGoal(),
            secondaryGoal: _getSecondaryGoal(),
          ),
          const SizedBox(height: 32),
          // Peptide List
          ..._protocolItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _protocolItems.length - 1 ? 20 : 0,
              ),
              child: _PremiumPeptideCard(
                protocolItem: item,
                onTap: () {
                  Navigator.push(
                    context,
                    AppPageTransitions.cardPushRoute(
                      PeptideDetailsScreenNew(
                        recommendation: _toPeptideRecommendation(item),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Header section with title, subtitle, and goal chips
class _HeaderSection extends StatelessWidget {
  final List<String> topGoals;
  final OnboardingSummary? onboardingSummary;

  const _HeaderSection({
    required this.topGoals,
    this.onboardingSummary,
  });

  @override
  Widget build(BuildContext context) {
    final goalsText = topGoals.isNotEmpty
        ? topGoals.take(2).join(', ')
        : 'your wellness goals';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8F3EC),
            const Color(0xFFF3EDE4),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Personalized Protocol',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Built around your goals: $goalsText.',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textSecondary,
              height: 1.5,
            ),
          ),
          if (topGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topGoals.map((goal) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ColorPalette.gold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    goal,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.gold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Protocol Summary Card
class _ProtocolSummaryCard extends StatelessWidget {
  final int totalPeptides;
  final String? dominantGoal;
  final String? secondaryGoal;

  const _ProtocolSummaryCard({
    required this.totalPeptides,
    this.dominantGoal,
    this.secondaryGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol Summary',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Total peptides in your protocol: $totalPeptides',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          if (dominantGoal != null) ...[
            const SizedBox(height: 8),
            Text(
              'Primary focus: $dominantGoal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorPalette.textSecondary,
              ),
            ),
          ],
          if (secondaryGoal != null) ...[
            const SizedBox(height: 4),
            Text(
              'Secondary focus: $secondaryGoal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorPalette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPalette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: ColorPalette.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This protocol will be reviewed and confirmed by a licensed doctor before any prescriptions or shipments.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textSecondary,
                      height: 1.4,
                    ),
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

/// Premium peptide card matching onboarding style
class _PremiumPeptideCard extends StatelessWidget {
  final ProtocolItem protocolItem;
  final VoidCallback onTap;

  const _PremiumPeptideCard({
    required this.protocolItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD1A057);

    return Container(
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peptide name
          Text(
            protocolItem.peptideName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          // Category badge
          if (protocolItem.peptideCategory.isNotEmpty)
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
                protocolItem.peptideCategory,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorPalette.textSecondary,
                ),
              ),
            ),
          if (protocolItem.peptideCategory.isNotEmpty) const SizedBox(height: 14),
          // Summary
          Text(
            protocolItem.peptideSummary,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textPrimary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Short benefits (1-3 bullet points)
          if (protocolItem.shortBenefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...protocolItem.shortBenefits.take(3).map((benefit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
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
                        benefit,
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
          ],
          // Reasoning
          if (protocolItem.reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorPalette.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: goldColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why this is in your protocol:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          protocolItem.reasoning.length > 150
                              ? '${protocolItem.reasoning.substring(0, 150)}...'
                              : protocolItem.reasoning,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: ColorPalette.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // View Details CTA
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
            ),
          ),
        ],
      ),
    );
  }
}
