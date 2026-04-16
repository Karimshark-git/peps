import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/app_page_transitions.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/peps_ambient_orbs.dart';
import '../../../engine/models/peptide_recommendation.dart';
import '../../../services/protocol_service.dart';
import '../../../services/supabase_client.dart';
import '../../checkin/screens/check_in_screen.dart';
import '../../protocol/screens/peptide_details_screen_new.dart';

// ─── Module-private helpers (mirror protocol_screen.dart) ──────────────────

Color _accentForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('recovery') || c.contains('tissue')) {
    return const Color(0xFF3ECFA0);
  }
  if (c.contains('muscle') ||
      c.contains('performance') ||
      c.contains('gh axis')) {
    return const Color(0xFF6B9FFF);
  }
  if (c.contains('weight') || c.contains('metabolic')) {
    return const Color(0xFFFFB86B);
  }
  if (c.contains('aging') ||
      c.contains('longevity') ||
      c.contains('cellular')) {
    return const Color(0xFFB06BFF);
  }
  if (c.contains('cognitive') || c.contains('focus')) {
    return const Color(0xFF6BFFEF);
  }
  if (c.contains('libido') ||
      c.contains('sexual') ||
      c.contains('bonding')) {
    return const Color(0xFFFF6B9F);
  }
  if (c.contains('immune') || c.contains('skin')) {
    return const Color(0xFF3ECFA0);
  }
  if (c.contains('energy') || c.contains('mitochondr')) {
    return const Color(0xFFFFD700);
  }
  return const Color(0xFF3ECFA0);
}

IconData _iconForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('recovery') || c.contains('tissue')) {
    return Icons.healing_outlined;
  }
  if (c.contains('muscle') ||
      c.contains('gh axis') ||
      c.contains('performance')) {
    return Icons.fitness_center_outlined;
  }
  if (c.contains('weight') || c.contains('metabolic')) {
    return Icons.local_fire_department_outlined;
  }
  if (c.contains('aging') || c.contains('longevity')) {
    return Icons.all_inclusive_outlined;
  }
  if (c.contains('cognitive') || c.contains('focus')) {
    return Icons.psychology_outlined;
  }
  if (c.contains('libido') || c.contains('sexual')) {
    return Icons.favorite_outline;
  }
  if (c.contains('bonding') || c.contains('mood')) {
    return Icons.self_improvement_outlined;
  }
  if (c.contains('immune')) return Icons.shield_outlined;
  if (c.contains('skin')) return Icons.face_retouching_natural_outlined;
  if (c.contains('energy') || c.contains('mitochondr')) {
    return Icons.bolt_outlined;
  }
  return Icons.science_outlined;
}

// ─── Screen ─────────────────────────────────────────────────────────────────

/// Home Dashboard — redesigned with cycle ring hero, insight card,
/// peptide chip row, streak check-in, and compact quick-stats grid.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  // ── Existing state (unchanged) ────────────────────────────────────────────
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String? _error;
  String? _userEmail;
  String? _userFirstName;

  // ── New state ─────────────────────────────────────────────────────────────
  int _cycleDay = 1;
  int _cycleTotalDays = 56;
  double _cycleProgress = 0.0;
  String _todayInsight = '';
  int _checkInStreak = 0;

  // ── Existing animation (unchanged) ────────────────────────────────────────
  late AnimationController _pageAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;

  // ── New animations ────────────────────────────────────────────────────────
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;
  late AnimationController _arcController;
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerFades;
  late List<Animation<Offset>> _staggerSlides;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Existing page-entry animation
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _pageSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _pageAnimationController.forward();

    // Cycle ring — fired after data loads
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );

    // Continuously rotating ambient arc
    _arcController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();

    // Section stagger: 6 sections × 250ms each, offset by 100ms
    // Total controller duration 800ms; section i starts at i*100ms.
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggerFades = List.generate(6, (i) {
      final start = (i * 100) / 800.0;
      final end = math.min((i * 100 + 250) / 800.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _staggerSlides = List.generate(6, (i) {
      final start = (i * 100) / 800.0;
      final end = math.min((i * 100 + 250) / 800.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _loadData();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _ringController.dispose();
    _arcController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data loading — keeps all existing queries; adds cycle/insight/streak
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final email = await ProtocolService.getUserEmail();
      final recommendations = await ProtocolService.getUserRecommendations();

      // [EXISTING] Fetch first name from users table
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
        debugPrint('Failed to fetch first name: $e');
      }

      // [NEW] Cycle day + insight + streak
      int cycleDay = 1;
      int cycleTotalDays = 56;
      double cycleProgress = 0.0;
      String todayInsight = '';
      int checkInStreak = 0;

      final user = supabase.auth.currentUser;
      if (user != null && recommendations.isNotEmpty) {
        final firstPeptide =
            recommendations.first['peptides'] as Map<String, dynamic>?;
        final peptideId = firstPeptide?['id'] as String?;

        // Fetch cycle_length + reasoning_template for primary peptide
        if (peptideId != null) {
          try {
            final peptideData = await supabase
                .from('peptides')
                .select('reasoning_template, cycle_length')
                .eq('id', peptideId)
                .maybeSingle();
            if (peptideData != null) {
              cycleTotalDays =
                  _parseCycleDays(peptideData['cycle_length'] as String?);
              final template =
                  peptideData['reasoning_template'] as String? ?? '';
              todayInsight = template.length > 120
                  ? '${template.substring(0, 117)}...'
                  : template;
            }
          } catch (e) {
            debugPrint('Failed to fetch peptide metadata: $e');
          }
        }

        // Derive cycle day from onboarding created_at
        try {
          final onboardingRow = await supabase
              .from('onboarding_responses')
              .select('created_at')
              .eq('user_id', user.id)
              .order('created_at', ascending: true)
              .limit(1)
              .maybeSingle();
          if (onboardingRow != null) {
            final onboardingDate =
                DateTime.parse(onboardingRow['created_at'] as String);
            final daysSince =
                DateTime.now().difference(onboardingDate).inDays + 1;
            cycleDay = daysSince.clamp(1, cycleTotalDays);
            cycleProgress = cycleDay / cycleTotalDays;
          }
        } catch (e) {
          debugPrint('Failed to fetch onboarding date: $e');
        }

        // Fetch check-in streak (count of completed check-ins)
        try {
          final checkInsData = await supabase
              .from('check_ins')
              .select('week_number, created_at')
              .eq('user_id', user.id)
              .order('week_number', ascending: false);
          checkInStreak = checkInsData.length;
        } catch (e) {
          debugPrint('Failed to fetch check-ins: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _userEmail = email;
        _userFirstName = firstName;
        _recommendations = recommendations;
        _cycleDay = cycleDay;
        _cycleTotalDays = cycleTotalDays;
        _cycleProgress = cycleProgress;
        _todayInsight = todayInsight;
        _checkInStreak = checkInStreak;
        _isLoading = false;
      });

      // Start section entrance + ring fill after data is ready
      _staggerController.forward();
      _ringController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers (all existing helpers preserved; new helpers added below)
  // ─────────────────────────────────────────────────────────────────────────

  int _parseCycleDays(String? cycleLength) {
    if (cycleLength == null) return 56;
    final cl = cycleLength.toLowerCase();
    if (cl.contains('ongoing')) return 90;
    final weeksMatch = RegExp(r'(\d+)\s*week').firstMatch(cl);
    if (weeksMatch != null) return int.parse(weeksMatch.group(1)!) * 7;
    final daysMatch = RegExp(r'(\d+)\s*day').firstMatch(cl);
    if (daysMatch != null) return int.parse(daysMatch.group(1)!);
    return 56;
  }

  /// [EXISTING] Extracts unique goals from recommendations (capped at 3)
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

  /// [EXISTING] Gets the local-part of the user's email
  String _getUserGreeting() {
    if (_userEmail == null || _userEmail!.isEmpty) return '';
    final parts = _userEmail!.split('@');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Returns time-of-day greeting with trailing comma
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  /// [EXISTING] Counts distinct peptide categories in recommendations
  int _uniqueCategoryCount() {
    final s = <String>{};
    for (final r in _recommendations) {
      final p = r['peptides'] as Map<String, dynamic>?;
      final c = p?['category'] as String?;
      if (c != null && c.isNotEmpty) s.add(c);
    }
    return s.length;
  }

  Color _primaryAccentColor() {
    if (_recommendations.isEmpty) return const Color(0xFF3ECFA0);
    final peptide =
        _recommendations.first['peptides'] as Map<String, dynamic>?;
    return _accentForCategory(peptide?['category'] as String? ?? '');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: Stack(
        children: [
          const PepsAmbientOrbs(),
          SafeArea(
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
                        : _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _staggerWrap(
            0,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTopBar(),
            ),
          ),
          const SizedBox(height: 24),
          _staggerWrap(
            1,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCycleRing(),
            ),
          ),
          const SizedBox(height: 24),
          _staggerWrap(
            2,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTodayInsightCard(),
            ),
          ),
          const SizedBox(height: 16),
          // _PeptideRow manages its own horizontal padding
          _staggerWrap(3, _buildPeptideRow()),
          const SizedBox(height: 16),
          _staggerWrap(
            4,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCheckInCard(),
            ),
          ),
          const SizedBox(height: 32),
          _staggerWrap(
            5,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildQuickStats(),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Wraps a section widget with its staggered fade + slide entrance.
  Widget _staggerWrap(int index, Widget child) {
    return FadeTransition(
      opacity: _staggerFades[index],
      child: SlideTransition(
        position: _staggerSlides[index],
        child: child,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section builders
  // ─────────────────────────────────────────────────────────────────────────

  // 1. Top bar ────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final displayName = _userFirstName?.isNotEmpty == true
        ? _userFirstName!
        : (_getUserGreeting().isNotEmpty
            ? _getUserGreeting().split('.').first
            : 'there');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "peps" logo mark — middle 'p' in teal
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'pe',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xE6FFFFFF),
                ),
              ),
              TextSpan(
                text: 'p',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3ECFA0),
                ),
              ),
              TextSpan(
                text: 's',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xE6FFFFFF),
                ),
              ),
            ],
          ),
        ),
        // Time-based greeting + name
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _greeting(),
              style: GoogleFonts.sora(
                fontSize: 12,
                color: const Color(0x4DFFFFFF),
              ),
            ),
            Text(
              displayName,
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xE6FFFFFF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Cycle ring hero ────────────────────────────────────────────────────

  Widget _buildCycleRing() {
    final accent = _primaryAccentColor();
    final percent = (_cycleProgress * 100).round();
    final firstPeptide = _recommendations.isNotEmpty
        ? _recommendations.first['peptides'] as Map<String, dynamic>?
        : null;
    final primaryPeptideName = firstPeptide?['name'] as String? ?? '';

    return Column(
      children: [
        Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Track ring (always-full background)
                  const SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      backgroundColor: Color(0x1AFFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.transparent,
                      ),
                    ),
                  ),

                  // Animated progress ring (sweeps in on data load)
                  AnimatedBuilder(
                    animation: _ringAnimation,
                    builder: (context, _) {
                      return SizedBox(
                        width: 220,
                        height: 220,
                        child: CustomPaint(
                          painter: _RingPainter(
                            progress: _cycleProgress * _ringAnimation.value,
                            color: accent,
                          ),
                        ),
                      );
                    },
                  ),

                  // Continuously rotating ambient arc glow
                  AnimatedBuilder(
                    animation: _arcController,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _arcController.value * 2 * math.pi,
                        child: SizedBox(
                          width: 236,
                          height: 236,
                          child: CustomPaint(
                            painter: _ArcGlowPainter(color: accent),
                          ),
                        ),
                      );
                    },
                  ),

                  // Center: DAY / number / of total / peptide chip
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DAY',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0x4DFFFFFF),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_cycleDay',
                        style: GoogleFonts.sora(
                          fontSize: 52,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xE6FFFFFF),
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of $_cycleTotalDays',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: const Color(0x4DFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (primaryPeptideName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            primaryPeptideName,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '$percent% through your cycle',
            style: GoogleFonts.sora(
              fontSize: 13,
              color: const Color(0x4DFFFFFF),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Today's insight card ───────────────────────────────────────────────

  Widget _buildTodayInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Top edge shine
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x29FFFFFF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 14,
                    color: Color(0xFF3ECFA0),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "TODAY'S INSIGHT",
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3ECFA0),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _todayInsight.isEmpty
                    ? 'Your protocol is being prepared...'
                    : _todayInsight,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0x8CFFFFFF),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Peptide chip row ──────────────────────────────────────────────────

  Widget _buildPeptideRow() {
    if (_recommendations.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final rec = _recommendations[i];
          final peptide = rec['peptides'] as Map<String, dynamic>?;
          final name = peptide?['name'] as String? ?? '';
          final category = peptide?['category'] as String? ?? '';
          final peptideId = peptide?['id'] as String? ?? '';
          final accent = _accentForCategory(category);

          return GestureDetector(
            onTap: () {
              final recommendation = PeptideRecommendation(
                peptideId: peptideId,
                name: name,
                summary: peptide?['summary'] as String? ?? '',
                reasoning: rec['reasoning'] as String? ?? '',
                score: (rec['score'] as num?)?.toDouble() ?? 0.0,
                category: category,
                shortBenefits: List<String>.from(
                  peptide?['short_benefits'] as List<dynamic>? ?? [],
                ),
                dosage: peptide?['dosage'] as String? ?? '',
                frequency: peptide?['frequency'] as String? ?? '',
              );
              Navigator.of(context).push(
                AppPageTransitions.cardPushRoute(
                  PeptideDetailsScreenNew(recommendation: recommendation),
                ),
              );
            },
            child: Container(
              width: 130,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                border: Border.all(
                  color: accent.withValues(alpha: 0.20),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForCategory(category),
                      size: 14,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xE6FFFFFF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category,
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      color: accent.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 5. Check-in card with streak ─────────────────────────────────────────

  Widget _buildCheckInCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        AppPageTransitions.cardPushRoute(const CheckInScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Streak flame badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x1AFF9500),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0x33FF9500),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 16)),
              ),
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
                      color: const Color(0xE6FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _checkInStreak == 0
                        ? 'Start your streak today'
                        : 'Week $_checkInStreak streak 🔥',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: _checkInStreak > 0
                          ? const Color(0xFFFF9500)
                          : const Color(0x4DFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0x4DFFFFFF),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Quick stats 2×2 grid ──────────────────────────────────────────────

  Widget _buildQuickStats() {
    final goals = _getUniqueGoals();
    final categories = _uniqueCategoryCount();
    final statusLabel = _recommendations.isNotEmpty ? 'Active' : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK STATS',
          style: GoogleFonts.sora(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3ECFA0),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard('PEPTIDES', '${_recommendations.length}',
                'in protocol'),
            _buildStatCard('FOCUS AREAS', '${goals.length}', 'goals'),
            _buildStatCard('CATEGORIES', '$categories', 'covered'),
            _buildStatCard('STATUS', statusLabel, 'protocol'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String sublabel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 9,
              color: const Color(0x4DFFFFFF),
              letterSpacing: 0.6,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xE6FFFFFF),
              height: 1.0,
            ),
          ),
          Text(
            sublabel,
            style: GoogleFonts.sora(
              fontSize: 10,
              color: const Color(0x4DFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Painters ────────────────────────────────────────────────────────

/// Draws the progress ring with a sweep gradient from dim → solid.
class _RingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final sweepAngle = progress * 2 * math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: [color.withValues(alpha: 0.5), color],
        tileMode: TileMode.clamp,
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Draws a short ~15° arc that creates a subtle ambient glow at the ring tip.
/// Rendered inside a [Transform.rotate] that spins continuously.
class _ArcGlowPainter extends CustomPainter {
  final Color color;

  const _ArcGlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.4);

    // ~15° (π/12 rad) arc — kept at top; rotation applied by parent
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi / 12,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcGlowPainter old) => true;
}
