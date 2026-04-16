import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/app_page_transitions.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/peps_ambient_orbs.dart';
import '../../../engine/models/peptide_recommendation.dart';
import '../../../services/protocol_service.dart';
import '../../../services/supabase_client.dart';
import '../../checkin/screens/check_in_screen.dart';
import '../../protocol/screens/peptide_details_screen_new.dart';

// ─── Module-private helpers ──────────────────────────────────────────────────

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

// ─── Per-peptide cycle data ─────────────────────────────────────────────────

class _PeptideCycle {
  final String peptideId;
  final String peptideName;
  final String category;
  final int cycleDay;
  final int cycleTotalDays;
  final double progress;

  const _PeptideCycle({
    required this.peptideId,
    required this.peptideName,
    required this.category,
    required this.cycleDay,
    required this.cycleTotalDays,
    required this.progress,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  // ── Existing state (preserved) ────────────────────────────────────────────
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String? _error;
  String? _userEmail;
  String? _userFirstName;

  // ── Per-peptide cycle + insight data ──────────────────────────────────────
  List<_PeptideCycle> _peptideCycles = [];
  Map<String, String> _peptideInsights = {};
  int _checkInStreak = 0;

  // Currently visible ring page (drives insight card + accent shifts)
  int _currentRingPage = 0;
  late PageController _ringPageController;

  // ── Animation controllers ─────────────────────────────────────────────────
  // Existing page-entry animation
  late AnimationController _pageAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;

  // Cycle ring fill on first paint
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  // Continuously rotating ambient arc glow
  late AnimationController _arcController;

  // Section stagger entrance (6 sections)
  late AnimationController _staggerController;
  late List<Animation<double>> _staggerFades;
  late List<Animation<Offset>> _staggerSlides;

  // Pulsing streak flame
  late AnimationController _flameController;
  late Animation<double> _flameScale;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _ringPageController = PageController(viewportFraction: 1.0);

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

    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );

    _arcController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();

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

    _flameController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _flameScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _ringPageController.dispose();
    _pageAnimationController.dispose();
    _ringController.dispose();
    _arcController.dispose();
    _staggerController.dispose();
    _flameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data loading — existing queries preserved; new bulk peptide-meta query
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final email = await ProtocolService.getUserEmail();
      final recommendations = await ProtocolService.getUserRecommendations();

      // [EXISTING] First name
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

      // Onboarding start date + check-in streak (per user)
      DateTime? startDate;
      int checkInStreak = 0;
      final user = supabase.auth.currentUser;
      if (user != null) {
        try {
          final onboardingRow = await supabase
              .from('onboarding_responses')
              .select('created_at')
              .eq('user_id', user.id)
              .order('created_at', ascending: true)
              .limit(1)
              .maybeSingle();
          if (onboardingRow != null) {
            startDate = DateTime.parse(
              onboardingRow['created_at'] as String,
            );
          }
        } catch (e) {
          debugPrint('Failed to fetch onboarding date: $e');
        }

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

      // Bulk-fetch cycle_length + reasoning_template for all recommended peptides
      final peptideCycles = <_PeptideCycle>[];
      final peptideInsights = <String, String>{};
      if (recommendations.isNotEmpty) {
        final peptideIds = recommendations
            .map((r) =>
                (r['peptides'] as Map<String, dynamic>?)?['id'] as String?)
            .whereType<String>()
            .toList();

        final metaById = <String, Map<String, dynamic>>{};
        try {
          final metaRows = await supabase
              .from('peptides')
              .select('id, cycle_length, reasoning_template')
              .inFilter('id', peptideIds);
          for (final row in metaRows) {
            metaById[row['id'] as String] = row;
          }
        } catch (e) {
          debugPrint('Failed to fetch peptide metadata: $e');
        }

        for (final rec in recommendations) {
          final p = rec['peptides'] as Map<String, dynamic>?;
          final pid = p?['id'] as String? ?? '';
          final pname = p?['name'] as String? ?? '';
          final pcat = p?['category'] as String? ?? '';

          final meta = metaById[pid];
          final cycleTotalDays =
              _parseCycleDays(meta?['cycle_length'] as String?);
          final template = meta?['reasoning_template'] as String? ?? '';
          peptideInsights[pid] = template.length > 140
              ? '${template.substring(0, 137)}...'
              : template;

          int cycleDay = 1;
          double progress = 0.0;
          if (startDate != null) {
            final daysSince =
                DateTime.now().difference(startDate).inDays + 1;
            cycleDay = daysSince.clamp(1, cycleTotalDays);
            progress = cycleDay / cycleTotalDays;
          }

          peptideCycles.add(_PeptideCycle(
            peptideId: pid,
            peptideName: pname,
            category: pcat,
            cycleDay: cycleDay,
            cycleTotalDays: cycleTotalDays,
            progress: progress,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _userEmail = email;
        _userFirstName = firstName;
        _recommendations = recommendations;
        _peptideCycles = peptideCycles;
        _peptideInsights = peptideInsights;
        _checkInStreak = checkInStreak;
        _isLoading = false;
        _currentRingPage = 0;
      });

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

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    _ringController.reset();
    _staggerController.reset();
    await _loadData();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
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
    return goalsSet.toList();
  }

  String _getUserGreeting() {
    if (_userEmail == null || _userEmail!.isEmpty) return '';
    final parts = _userEmail!.split('@');
    return parts.isNotEmpty ? parts[0] : '';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
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

  Color _currentAccentColor() {
    if (_peptideCycles.isEmpty) return const Color(0xFF3ECFA0);
    final i = _currentRingPage.clamp(0, _peptideCycles.length - 1);
    return _accentForCategory(_peptideCycles[i].category);
  }

  String _currentInsight() {
    if (_peptideCycles.isEmpty) return '';
    final i = _currentRingPage.clamp(0, _peptideCycles.length - 1);
    final pid = _peptideCycles[i].peptideId;
    return _peptideInsights[pid] ?? '';
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
    return RefreshIndicator(
      onRefresh: _refresh,
      color: ColorPalette.gold,
      backgroundColor: ColorPalette.background,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
            const SizedBox(height: 28),
            _staggerWrap(1, _buildCycleRingPager()),
            const SizedBox(height: 28),
            _staggerWrap(
              2,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTodayInsightCard(),
              ),
            ),
            const SizedBox(height: 18),
            _staggerWrap(3, _buildPeptideRow()),
            const SizedBox(height: 18),
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
      ),
    );
  }

  Widget _staggerWrap(int index, Widget child) {
    return FadeTransition(
      opacity: _staggerFades[index],
      child: SlideTransition(
        position: _staggerSlides[index],
        child: child,
      ),
    );
  }

  // ─── Section: Top bar ────────────────────────────────────────────────

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
        Text.rich(
          TextSpan(children: [
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
          ]),
        ),
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

  // ─── Section: Cycle ring pager ──────────────────────────────────────

  Widget _buildCycleRingPager() {
    if (_peptideCycles.isEmpty) {
      // Empty-state placeholder ring
      return SizedBox(
        height: 280,
        child: Center(
          child: _buildSingleRing(
            const _PeptideCycle(
              peptideId: '',
              peptideName: '',
              category: '',
              cycleDay: 1,
              cycleTotalDays: 56,
              progress: 0.0,
            ),
            isPlaceholder: true,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 285,
          child: PageView.builder(
            controller: _ringPageController,
            itemCount: _peptideCycles.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentRingPage = index);
            },
            itemBuilder: (context, index) {
              return Center(child: _buildSingleRing(_peptideCycles[index]));
            },
          ),
        ),
        const SizedBox(height: 16),
        // Page indicator dots
        if (_peptideCycles.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_peptideCycles.length, (i) {
              final isActive = i == _currentRingPage;
              final accent = _accentForCategory(_peptideCycles[i].category);
              return GestureDetector(
                onTap: () {
                  _ringPageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        isActive ? accent : const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildSingleRing(_PeptideCycle cycle, {bool isPlaceholder = false}) {
    final accent = _accentForCategory(cycle.category);
    final percent = (cycle.progress * 100).round();

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
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
                // Animated progress ring
                AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (context, _) {
                    return SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _RingPainter(
                          progress: cycle.progress * _ringAnimation.value,
                          color: accent,
                        ),
                      ),
                    );
                  },
                ),
                // Continuously rotating ambient arc
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
                // Center stack
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
                    ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFFFFFFF),
                            accent.withValues(alpha: 0.85),
                          ],
                        ).createShader(rect);
                      },
                      child: Text(
                        '${cycle.cycleDay}',
                        style: GoogleFonts.sora(
                          fontSize: 56,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -2.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of ${cycle.cycleTotalDays}',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: const Color(0x4DFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!isPlaceholder && cycle.peptideName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          cycle.peptideName,
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
          const SizedBox(height: 14),
          Text(
            isPlaceholder
                ? 'Generate a protocol to track your cycle'
                : '$percent% through your cycle',
            style: GoogleFonts.sora(
              fontSize: 13,
              color: const Color(0x66FFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section: Today's insight ────────────────────────────────────────

  Widget _buildTodayInsightCard() {
    final accent = _currentAccentColor();
    final insight = _currentInsight();
    final activeName = _peptideCycles.isEmpty
        ? ''
        : _peptideCycles[_currentRingPage.clamp(
            0,
            _peptideCycles.length - 1,
          )].peptideName;

    return _GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      borderColor: accent.withValues(alpha: 0.18),
      tintColor: accent.withValues(alpha: 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  activeName.isEmpty
                      ? "TODAY'S INSIGHT"
                      : "${activeName.toUpperCase()} · INSIGHT",
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: accent,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: Text(
              insight.isEmpty
                  ? 'Your protocol is being prepared. Pull to refresh once recommendations are ready.'
                  : insight,
              key: ValueKey('insight_${_currentRingPage}_${insight.hashCode}'),
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xCCFFFFFF),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section: Peptide chip row ───────────────────────────────────────

  Widget _buildPeptideRow() {
    if (_peptideCycles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _peptideCycles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cycle = _peptideCycles[i];
          final isActive = i == _currentRingPage;
          final accent = _accentForCategory(cycle.category);
          final rec = _recommendations[i];
          final peptide = rec['peptides'] as Map<String, dynamic>?;

          return GestureDetector(
            onTap: () {
              // Sync ring pager + lightly haptic, then navigate to details
              if (i != _currentRingPage) {
                _ringPageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              }
              final recommendation = PeptideRecommendation(
                peptideId: cycle.peptideId,
                name: cycle.peptideName,
                summary: peptide?['summary'] as String? ?? '',
                reasoning: rec['reasoning'] as String? ?? '',
                score: (rec['score'] as num?)?.toDouble() ?? 0.0,
                category: cycle.category,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 145,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: isActive ? 0.20 : 0.08),
                    accent.withValues(alpha: isActive ? 0.05 : 0.02),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: isActive ? 0.55 : 0.20),
                  width: isActive ? 1.4 : 1,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconForCategory(cycle.category),
                          size: 14,
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'D${cycle.cycleDay}',
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: accent.withValues(alpha: 0.85),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    cycle.peptideName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xE6FFFFFF),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cycle.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: accent.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: cycle.progress,
                      minHeight: 3,
                      backgroundColor: const Color(0x14FFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Section: Check-in card ──────────────────────────────────────────

  Widget _buildCheckInCard() {
    const flameOrange = Color(0xFFFF9500);
    const totalWeeks = 8;
    final filled = _checkInStreak.clamp(0, totalWeeks);

    return _GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderColor: _checkInStreak > 0
          ? flameOrange.withValues(alpha: 0.30)
          : const Color(0x1AFFFFFF),
      tintColor: _checkInStreak > 0
          ? flameOrange.withValues(alpha: 0.05)
          : const Color(0x05FFFFFF),
      onTap: () => Navigator.of(context).push(
        AppPageTransitions.cardPushRoute(const CheckInScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pulsing flame badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x33FF9500),
                      Color(0x14FF5E00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0x55FF9500),
                    width: 1,
                  ),
                  boxShadow: _checkInStreak > 0
                      ? const [
                          BoxShadow(
                            color: Color(0x33FF9500),
                            blurRadius: 14,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _flameScale,
                    child: const Text(
                      '🔥',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
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
                          : 'Week $_checkInStreak streak — keep it alive',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: _checkInStreak > 0
                            ? flameOrange
                            : const Color(0x66FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: _checkInStreak > 0
                    ? flameOrange.withValues(alpha: 0.7)
                    : const Color(0x4DFFFFFF),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 8-week progress segments
          Row(
            children: List.generate(totalWeeks, (i) {
              final isFilled = i < filled;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == totalWeeks - 1 ? 0 : 4,
                  ),
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: isFilled
                          ? const LinearGradient(
                              colors: [
                                Color(0xFFFF9500),
                                Color(0xFFFF5E00),
                              ],
                            )
                          : null,
                      color:
                          isFilled ? null : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isFilled
                          ? const [
                              BoxShadow(
                                color: Color(0x33FF9500),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '$filled / $totalWeeks weeks',
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: const Color(0x66FFFFFF),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section: Quick stats ────────────────────────────────────────────

  Widget _buildQuickStats() {
    final goalsCount = _getUniqueGoals().length;
    final categories = _uniqueCategoryCount();
    final hasProtocol = _recommendations.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 1,
              color: const Color(0xFF3ECFA0),
            ),
            const SizedBox(width: 8),
            Text(
              'QUICK STATS',
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3ECFA0),
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _buildStatCard(
              label: 'PEPTIDES',
              targetValue: _recommendations.length,
              sublabel: 'in protocol',
              icon: Icons.science_outlined,
              accent: const Color(0xFF3ECFA0),
            ),
            _buildStatCard(
              label: 'FOCUS AREAS',
              targetValue: goalsCount,
              sublabel: 'goals',
              icon: Icons.gps_fixed,
              accent: const Color(0xFF6B9FFF),
            ),
            _buildStatCard(
              label: 'CATEGORIES',
              targetValue: categories,
              sublabel: 'covered',
              icon: Icons.dashboard_outlined,
              accent: const Color(0xFFB06BFF),
            ),
            _buildStatLiteralCard(
              label: 'STATUS',
              value: hasProtocol ? 'Active' : '—',
              sublabel: hasProtocol ? 'protocol' : 'no protocol',
              icon: hasProtocol
                  ? Icons.bolt_outlined
                  : Icons.hourglass_empty,
              accent: hasProtocol
                  ? const Color(0xFFFFB86B)
                  : const Color(0x66FFFFFF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required int targetValue,
    required String sublabel,
    required IconData icon,
    required Color accent,
  }) {
    return _GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderColor: accent.withValues(alpha: 0.18),
      tintColor: accent.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accent.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: accent.withValues(alpha: 0.75),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: targetValue.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              return Text(
                v.round().toString(),
                style: GoogleFonts.sora(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xE6FFFFFF),
                  height: 1.0,
                ),
              );
            },
          ),
          Text(
            sublabel,
            style: GoogleFonts.sora(
              fontSize: 10,
              color: const Color(0x66FFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLiteralCard({
    required String label,
    required String value,
    required String sublabel,
    required IconData icon,
    required Color accent,
  }) {
    return _GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      borderColor: accent.withValues(alpha: 0.18),
      tintColor: accent.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accent.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: accent.withValues(alpha: 0.75),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xE6FFFFFF),
              height: 1.0,
            ),
          ),
          Text(
            sublabel,
            style: GoogleFonts.sora(
              fontSize: 10,
              color: const Color(0x66FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable frosted glass card ─────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? borderColor;
  final Color? tintColor;
  final VoidCallback? onTap;

  const _GlassCard({
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.tintColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor ?? const Color(0x0AFFFFFF),
            border: Border.all(
              color: borderColor ?? const Color(0x1AFFFFFF),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─── Custom Painters ────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
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
        colors: [color.withValues(alpha: 0.4), color],
        tileMode: TileMode.clamp,
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

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
