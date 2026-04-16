import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/peps_glass_card.dart';
import '../../../core/widgets/peps_section_label.dart';
import '../../../services/protocol_service.dart';
import '../../../services/supabase_client.dart';
import '../../../app_router.dart';
import '../../../core/navigation/app_page_transitions.dart';
import '../../checkin/screens/check_in_screen.dart';
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
              .eq('id', user.id)
              .maybeSingle();

          if (userResponse != null) {
            firstName = userResponse['first_name'] as String?;
          }
        }
      } catch (e) {
        // If fetching firstName fails, continue without it
        debugPrint('Failed to fetch first name: $e');
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

  String _timeOfDayGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _uniqueCategoryCount() {
    final s = <String>{};
    for (final r in _recommendations) {
      final p = r['peptides'] as Map<String, dynamic>?;
      final c = p?['category'] as String?;
      if (c != null && c.isNotEmpty) s.add(c);
    }
    return s.length;
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
                            style: GoogleFonts.sora(
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
                            const SizedBox(height: 20),
                            _DashboardTopBar(
                              greetingPrefix: _timeOfDayGreeting(),
                              userFirstName: _userFirstName,
                              userGreeting: _getUserGreeting(),
                            ),
                            const SizedBox(height: 24),
                            _ProtocolHeroCard(
                              recommendations: _recommendations,
                              uniqueGoals: _getUniqueGoals(),
                            ),
                            if (_recommendations.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              const PepsSectionLabel(text: 'protocol snapshot'),
                              const SizedBox(height: 12),
                              _ProtocolSnapshotRow(
                                recommendations: _recommendations,
                              ),
                              const SizedBox(height: 16),
                              _WeeklyCheckInCard(
                                onTap: () {
                                  Navigator.of(context).push(
                                    AppPageTransitions.cardPushRoute(
                                      const CheckInScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final mainNavState = context
                                        .findAncestorStateOfType<
                                            MainNavigationState>();
                                    mainNavState?.setCurrentIndex(1);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorPalette.gold,
                                    foregroundColor:
                                        ColorPalette.buttonOnAccent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'View full protocol',
                                        style: GoogleFonts.sora(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: ColorPalette.buttonOnAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            const PepsSectionLabel(text: 'QUICK STATS'),
                            _QuickStatsGrid(
                              peptideCount: _recommendations.length,
                              focusCount: _getUniqueGoals().length,
                              categoryCount: _uniqueCategoryCount(),
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

class _PepsLogoMark extends StatelessWidget {
  const _PepsLogoMark();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.sora(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: ColorPalette.textPrimary,
    );
    final teal = GoogleFonts.sora(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: ColorPalette.gold,
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

class _DashboardTopBar extends StatelessWidget {
  final String greetingPrefix;
  final String? userFirstName;
  final String userGreeting;

  const _DashboardTopBar({
    required this.greetingPrefix,
    this.userFirstName,
    required this.userGreeting,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userFirstName?.isNotEmpty == true
        ? userFirstName!
        : (userGreeting.isNotEmpty ? userGreeting.split('.').first : 'there');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PepsLogoMark(),
        const Spacer(),
        Flexible(
          child: Text(
            '$greetingPrefix, $displayName',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textSecondary,
              height: 1.35,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ProtocolHeroCard extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final List<String> uniqueGoals;

  const _ProtocolHeroCard({
    required this.recommendations,
    required this.uniqueGoals,
  });

  @override
  Widget build(BuildContext context) {
    final active = recommendations.isNotEmpty;

    return PepsGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Your protocol is active',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ColorPalette.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textTeal,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${recommendations.length} peptides',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
            ),
            if (uniqueGoals.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uniqueGoals.map((goal) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ColorPalette.accentDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ColorPalette.accentBorder),
                    ),
                    child: Text(
                      goal,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ColorPalette.gold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            Text(
              'No protocol yet',
              style: TextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete onboarding to generate your personalized protocol.',
              style: TextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.name);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.gold,
                  foregroundColor: ColorPalette.buttonOnAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Go to onboarding',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.buttonOnAccent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyCheckInCard extends StatelessWidget {
  final VoidCallback onTap;

  const _WeeklyCheckInCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: PepsGlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Icon(
                Icons.track_changes_outlined,
                color: ColorPalette.gold,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Check-in',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorPalette.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your progress',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: ColorPalette.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolSnapshotRow extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;

  const _ProtocolSnapshotRow({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          final peptide = rec['peptides'] as Map<String, dynamic>?;
          if (peptide == null) return const SizedBox.shrink();
          return _PeptideMiniCard(peptide: peptide);
        },
      ),
    );
  }
}

class _PeptideMiniCard extends StatelessWidget {
  final Map<String, dynamic> peptide;

  const _PeptideMiniCard({required this.peptide});

  @override
  Widget build(BuildContext context) {
    final name = peptide['name'] as String? ?? 'Unknown';
    final category = peptide['category'] as String? ?? '';

    return SizedBox(
      width: 168,
      child: PepsGlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
                height: 1.25,
              ),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ColorPalette.accentDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorPalette.accentBorder),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.dmMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: ColorPalette.textTeal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  final int peptideCount;
  final int focusCount;
  final int categoryCount;

  const _QuickStatsGrid({
    required this.peptideCount,
    required this.focusCount,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = peptideCount > 0 ? 'Active' : '—';
    final statusUnit = peptideCount > 0 ? 'protocol' : '';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _StatTile(
            label: 'PEPTIDES',
            value: '$peptideCount',
            unit: 'in protocol',
          ),
          _StatTile(
            label: 'FOCUS AREAS',
            value: '$focusCount',
            unit: 'goals',
          ),
          _StatTile(
            label: 'CATEGORIES',
            value: '$categoryCount',
            unit: 'covered',
          ),
          _StatTile(
            label: 'STATUS',
            value: statusLabel,
            unit: statusUnit,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return PepsGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.dmMono(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
              height: 1.1,
            ),
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              unit,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: ColorPalette.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
