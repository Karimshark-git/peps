import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../services/protocol_service.dart';
import '../../../services/supabase_client.dart';
import '../../../app_router.dart';
import '../../navigation/main_navigation.dart';

/// Home Dashboard screen for authenticated users
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String? _error;
  String? _userEmail;
  String? _userFirstName;
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
      final email = await ProtocolService.getUserEmail();
      final recommendations = await ProtocolService.getUserRecommendations();
      
      // Fetch user's first name from database
      String? firstName;
      try {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final userResponse = await supabase
              .from('users')
              .select('first_name')
              .eq('auth_uid', user.id)
              .maybeSingle();
          
          if (userResponse != null) {
            firstName = userResponse['first_name'] as String?;
          }
        }
      } catch (e) {
        // If fetching firstName fails, continue without it
        print('Failed to fetch first name: $e');
      }

      setState(() {
        _userEmail = email;
        _userFirstName = firstName;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Extracts unique goals from recommendations
  List<String> _getUniqueGoals() {
    final goalsSet = <String>{};
    for (final rec in _recommendations) {
      final peptide = rec['peptides'] as Map<String, dynamic>?;
      if (peptide != null) {
        final goalsSupported = List<String>.from(
          peptide['goals_supported'] as List<dynamic>? ?? [],
        );
        goalsSet.addAll(goalsSupported);
      }
    }
    return goalsSet.take(3).toList();
  }

  /// Gets the first part of email before @
  String _getUserGreeting() {
    if (_userEmail == null || _userEmail!.isEmpty) {
      return '';
    }
    final parts = _userEmail!.split('@');
    return parts.isNotEmpty ? parts[0] : '';
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
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorPalette.gold,
                      ),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _error!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            // Header section
                            _HeaderSection(
                              userFirstName: _userFirstName,
                              userGreeting: _getUserGreeting(),
                            ),
                            const SizedBox(height: 32),
                            // Today's Overview card
                            _TodaysOverviewCard(
                              recommendations: _recommendations,
                              uniqueGoals: _getUniqueGoals(),
                            ),
                            const SizedBox(height: 20),
                            // Today's Plan card
                            const _TodaysPlanCard(),
                            const SizedBox(height: 32),
                            // Protocol Snapshot section
                            _ProtocolSnapshotSection(
                              recommendations: _recommendations,
                              onViewFullProtocol: () {
                                // Navigate to My Protocol tab (index 1)
                                final mainNavState = context
                                    .findAncestorStateOfType<MainNavigationState>();
                                mainNavState?.setCurrentIndex(1);
                              },
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

/// Header section with welcome message
class _HeaderSection extends StatelessWidget {
  final String? userFirstName;
  final String userGreeting;

  const _HeaderSection({
    this.userFirstName,
    required this.userGreeting,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer firstName from database, fallback to email greeting
    final displayName = userFirstName?.isNotEmpty == true
        ? userFirstName!
        : (userGreeting.isNotEmpty ? userGreeting.split('.').first : null);

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
          if (displayName != null) ...[
            Text(
              'Hi, $displayName',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Welcome back to Peps',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Here's your protocol snapshot.",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's Overview card
class _TodaysOverviewCard extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final List<String> uniqueGoals;

  const _TodaysOverviewCard({
    required this.recommendations,
    required this.uniqueGoals,
  });

  @override
  Widget build(BuildContext context) {
    final hasRecommendations = recommendations.isNotEmpty;

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
      child: hasRecommendations
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Overview",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Active peptides: ${recommendations.length}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                if (uniqueGoals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Primary focus:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: uniqueGoals.map((goal) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ColorPalette.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          goal,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: ColorPalette.gold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No protocol generated yet',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your onboarding and book a consultation to get your personalized protocol.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorPalette.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRouter.name);
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
                    'Go to onboarding',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Today's Plan card (placeholder)
class _TodaysPlanCard extends StatelessWidget {
  const _TodaysPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's plan",
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow the dosing and timing provided by your clinician for your current protocol.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _BulletPoint(
            text: 'Stay consistent with your daily protocol.',
          ),
          const SizedBox(height: 8),
          _BulletPoint(
            text: 'Reach out to your clinician if you have any concerns.',
          ),
        ],
      ),
    );
  }
}

/// Bullet point widget
class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: ColorPalette.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Protocol Snapshot section
class _ProtocolSnapshotSection extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final VoidCallback onViewFullProtocol;

  const _ProtocolSnapshotSection({
    required this.recommendations,
    required this.onViewFullProtocol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your protocol',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        if (recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorPalette.cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'No recommendations yet. Complete your onboarding to get personalized recommendations.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          ...recommendations.take(4).map((rec) {
            final peptide = rec['peptides'] as Map<String, dynamic>?;
            if (peptide == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PeptideSnapshotCard(peptide: peptide),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewFullProtocol,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View full protocol',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small peptide card for snapshot
class _PeptideSnapshotCard extends StatelessWidget {
  final Map<String, dynamic> peptide;

  const _PeptideSnapshotCard({required this.peptide});

  @override
  Widget build(BuildContext context) {
    final name = peptide['name'] as String? ?? 'Unknown';
    final category = peptide['category'] as String? ?? '';
    final shortBenefits = List<String>.from(
      peptide['short_benefits'] as List<dynamic>? ?? [],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: ColorPalette.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gold,
                ),
              ),
            ),
          ],
          if (shortBenefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shortBenefits.take(2).map((benefit) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    benefit,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textSecondary,
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


