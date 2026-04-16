import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/peps_ambient_orbs.dart';
import '../../../core/navigation/app_page_transitions.dart';
import '../../../services/protocol_service.dart';
import '../../../services/supabase_client.dart';
import '../../../engine/models/peptide_recommendation.dart';
import '../models/protocol_models.dart';
import 'peptide_details_screen_new.dart';
import '../../../app_router.dart';

/// My Protocol — daily command center.
/// Frosted-glass cards float over the ambient orbs; the category filter is
/// the only pinned chrome. Header content scrolls naturally with the list.
class MyProtocolScreen extends StatefulWidget {
  const MyProtocolScreen({super.key});

  @override
  State<MyProtocolScreen> createState() => _MyProtocolScreenState();
}

class _MyProtocolScreenState extends State<MyProtocolScreen>
    with TickerProviderStateMixin {
  // ── Existing state — preserved ──────────────────────────────────────────
  OnboardingSummary? _onboardingSummary;
  List<ProtocolItem> _protocol = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoggingOut = false;

  // ── New state ───────────────────────────────────────────────────────────
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  Set<String> _takenTodayIds = {};
  final Map<String, bool> _expandedCards = {};
  DateTime? _onboardingDate;
  static const int _defaultCycleDays = 56;

  // Entrance animation
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Existing fetch logic — kept exactly as is
      final results = await Future.wait([
        ProtocolService.fetchLatestOnboardingForCurrentUser(),
        ProtocolService.fetchProtocolForCurrentUser(),
      ]);

      final onboardingSummary = results[0] as OnboardingSummary?;
      final protocol = results[1] as List<ProtocolItem>;
      final userId = user.id;

      // Today's dose logs
      final today = DateTime.now().toIso8601String().substring(0, 10);
      Set<String> takenTodayIds = {};
      try {
        final doseLogs = await supabase
            .from('dose_logs')
            .select('peptide_id')
            .eq('user_id', userId)
            .eq('date', today);
        takenTodayIds = (doseLogs as List)
            .map((d) => d['peptide_id'] as String)
            .toSet();
      } catch (_) {
        takenTodayIds = {};
      }

      // Onboarding date for cycle calculation
      DateTime? onboardingDate;
      try {
        final onboardingRow = await supabase
            .from('onboarding_responses')
            .select('created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: true)
            .limit(1)
            .maybeSingle();
        if (onboardingRow != null && onboardingRow['created_at'] != null) {
          onboardingDate =
              DateTime.parse(onboardingRow['created_at'] as String);
        }
      } catch (_) {
        onboardingDate = null;
      }

      final cats = protocol
          .map((p) => p.peptideCategory)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();

      if (!mounted) return;
      setState(() {
        _onboardingSummary = onboardingSummary;
        _protocol = protocol;
        _takenTodayIds = takenTodayIds;
        _onboardingDate = onboardingDate;
        _categories = ['All', ...cats];
        _isLoading = false;
      });
      _entranceController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load protocol: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _toggleDose(ProtocolItem item) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final userId = user.id;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    HapticFeedback.lightImpact();
    final wasTaken = _takenTodayIds.contains(item.peptideId);

    setState(() {
      if (wasTaken) {
        _takenTodayIds.remove(item.peptideId);
      } else {
        _takenTodayIds.add(item.peptideId);
      }
    });

    try {
      if (wasTaken) {
        await supabase
            .from('dose_logs')
            .delete()
            .eq('user_id', userId)
            .eq('peptide_id', item.peptideId)
            .eq('date', today);
      } else {
        await supabase.from('dose_logs').insert({
          'user_id': userId,
          'peptide_id': item.peptideId,
          'date': today,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasTaken) {
          _takenTodayIds.add(item.peptideId);
        } else {
          _takenTodayIds.remove(item.peptideId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update dose log: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _parseCycleDays(ProtocolItem item) => _defaultCycleDays;

  int _cycleDay(ProtocolItem item) {
    if (_onboardingDate == null) return 1;
    final days = DateTime.now().difference(_onboardingDate!).inDays + 1;
    return days.clamp(1, _parseCycleDays(item));
  }

  double _cycleProgress(ProtocolItem item) {
    final total = _parseCycleDays(item);
    return total <= 0 ? 0 : _cycleDay(item) / total;
  }

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
    if (c.contains('energy') || c.contains('mitochondr')) {
      return const Color(0xFFFFD700);
    }
    return const Color(0xFF3ECFA0);
  }

  List<ProtocolItem> _filteredProtocol() {
    if (_selectedCategory == 'All') return _protocol;
    return _protocol
        .where((p) => p.peptideCategory == _selectedCategory)
        .toList();
  }

  PeptideRecommendation _toPeptideRecommendation(ProtocolItem item) {
    return PeptideRecommendation(
      peptideId: item.peptideId,
      name: item.peptideName,
      summary: item.peptideSummary,
      reasoning: item.reasoning,
      score: 0.0,
      category: item.peptideCategory,
      shortBenefits: item.shortBenefits,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08101E),
      body: Stack(
        children: [
          const Positioned.fill(child: PepsAmbientOrbs()),
          SafeArea(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _protocol.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3ECFA0)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your protocol…',
            style: GoogleFonts.sora(
              fontSize: 14,
              color: const Color(0x8CFFFFFF),
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
            const Icon(Icons.error_outline,
                size: 56, color: Color(0x8CFFFFFF)),
            const SizedBox(height: 16),
            Text("We couldn't load your protocol right now.",
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xE6FFFFFF),
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: const Color(0x8CFFFFFF),
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoggingOut ? null : _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECFA0),
                foregroundColor: const Color(0xFF08101E),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: Text('Retry',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoggingOut ? null : _handleLogout,
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF3ECFA0)),
                      ),
                    )
                  : Text('Sign out',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3ECFA0),
                      )),
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
            const Icon(Icons.medical_services_outlined,
                size: 56, color: Color(0x8CFFFFFF)),
            const SizedBox(height: 16),
            Text('No protocol found yet.',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xE6FFFFFF),
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Complete onboarding to generate your personalized protocol.',
              style: GoogleFonts.sora(
                fontSize: 13,
                color: const Color(0x8CFFFFFF),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.goals),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECFA0),
                foregroundColor: const Color(0xFF08101E),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: Text('Start Onboarding',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _filteredProtocol();
    final goalCount = _onboardingSummary?.goals.length ?? 0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Top section (scrolls naturally) ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          sliver: SliverToBoxAdapter(
            child: _TopSection(
              peptideCount: _protocol.length,
              goalCount: goalCount,
            ),
          ),
        ),

        // ── Pinned glass filter bar ────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedFilterDelegate(
            categories: _categories,
            selected: _selectedCategory,
            onSelect: (cat) {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
          ),
        ),

        // ── Cards ──────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (i >= filtered.length) return null;
                final item = filtered[i];
                return _StaggeredEntrance(
                  controller: _entranceController,
                  index: i,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == filtered.length - 1 ? 0 : 14,
                    ),
                    child: _PeptideDetailCard(
                      item: item,
                      accent: _accentForCategory(item.peptideCategory),
                      isTaken: _takenTodayIds.contains(item.peptideId),
                      isExpanded:
                          _expandedCards[item.peptideId] ?? false,
                      cycleDay: _cycleDay(item),
                      cycleDays: _parseCycleDays(item),
                      progress: _cycleProgress(item),
                      onToggleExpand: () => setState(() {
                        _expandedCards[item.peptideId] =
                            !(_expandedCards[item.peptideId] ?? false);
                      }),
                      onToggleDose: () => _toggleDose(item),
                      onViewDetails: () {
                        Navigator.push(
                          context,
                          AppPageTransitions.cardPushRoute(
                            PeptideDetailsScreenNew(
                              recommendation:
                                  _toPeptideRecommendation(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Top section — title, badge, meta line ────────────────────────────────────

class _TopSection extends StatelessWidget {
  final int peptideCount;
  final int goalCount;

  const _TopSection({
    required this.peptideCount,
    required this.goalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'My Protocol',
                style: GoogleFonts.sora(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xF2FFFFFF),
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            const _PhysicianBadge(),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$peptideCount peptides · $goalCount goals',
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0x66FFFFFF),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─── Physician badge with pulsing dot ────────────────────────────────────────

class _PhysicianBadge extends StatefulWidget {
  const _PhysicianBadge();

  @override
  State<_PhysicianBadge> createState() => _PhysicianBadgeState();
}

class _PhysicianBadgeState extends State<_PhysicianBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            border: Border.all(color: const Color(0x26FFFFFF), width: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final t = _pulse.value;
                  final opacity = 1.0 - (t * 0.6);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3ECFA0)
                              .withValues(alpha: 0.15 * (1 - t)),
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3ECFA0)
                              .withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                'Pending review',
                style: GoogleFonts.sora(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xCCFFFFFF),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Pinned filter bar (frosted glass) ───────────────────────────────────────

class _PinnedFilterDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  _PinnedFilterDelegate({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scrolled = shrinkOffset > 1 || overlapsContent;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: scrolled
                ? const Color(0xCC050B16)
                : const Color(0x66050B16),
            border: Border(
              bottom: BorderSide(
                color: scrolled
                    ? const Color(0x1FFFFFFF)
                    : const Color(0x0FFFFFFF),
                width: 0.5,
              ),
            ),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final isSelected = cat == selected;
              return _CategoryPill(
                label: cat,
                isSelected: isSelected,
                onTap: () => onSelect(cat),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedFilterDelegate oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.selected != selected;
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0x333ECFA0),
                    Color(0x1F3ECFA0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0x0DFFFFFF),
          border: Border.all(
            color: isSelected
                ? const Color(0x803ECFA0)
                : const Color(0x1FFFFFFF),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3ECFA0).withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: -4,
                  ),
                ]
              : const [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? const Color(0xFFB6F5DB)
                  : const Color(0x99FFFFFF),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Staggered entrance wrapper ──────────────────────────────────────────────

class _StaggeredEntrance extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggeredEntrance({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const totalMs = 700;
    final startMs = (index * 90).clamp(0, totalMs - 1);
    const durationMs = 380;
    final endMs = (startMs + durationMs).clamp(0, totalMs);
    final start = startMs / totalMs;
    final end = endMs / totalMs;

    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, _) {
        final t = curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
    );
  }
}

// ─── Frosted-glass peptide card ──────────────────────────────────────────────

class _PeptideDetailCard extends StatelessWidget {
  final ProtocolItem item;
  final Color accent;
  final bool isTaken;
  final bool isExpanded;
  final int cycleDay;
  final int cycleDays;
  final double progress;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleDose;
  final VoidCallback onViewDetails;

  const _PeptideDetailCard({
    required this.item,
    required this.accent,
    required this.isTaken,
    required this.isExpanded,
    required this.cycleDay,
    required this.cycleDays,
    required this.progress,
    required this.onToggleExpand,
    required this.onToggleDose,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (isTaken)
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: -6,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isTaken
                    ? [
                        accent.withValues(alpha: 0.10),
                        const Color(0x0AFFFFFF),
                      ]
                    : const [
                        Color(0x14FFFFFF),
                        Color(0x08FFFFFF),
                      ],
              ),
              border: Border.all(
                color: isTaken
                    ? accent.withValues(alpha: 0.32)
                    : const Color(0x1FFFFFFF),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                // Top shine line — like PepsGlassCard
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white
                                .withValues(alpha: isTaken ? 0.28 : 0.20),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    _CardHeader(
                      item: item,
                      accent: accent,
                      isExpanded: isExpanded,
                      cycleDay: cycleDay,
                      progress: progress,
                      isTaken: isTaken,
                      onTap: onToggleExpand,
                    ),
                    _DoseToggle(
                      accent: accent,
                      isTaken: isTaken,
                      onTap: onToggleDose,
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 280),
                      sizeCurve: Curves.easeOutCubic,
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: _ExpandedDetail(
                        item: item,
                        accent: accent,
                        cycleDay: cycleDay,
                        cycleDays: cycleDays,
                        progress: progress,
                        onViewDetails: onViewDetails,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Card header (always visible) ────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final ProtocolItem item;
  final Color accent;
  final bool isExpanded;
  final int cycleDay;
  final double progress;
  final bool isTaken;
  final VoidCallback onTap;

  const _CardHeader({
    required this.item,
    required this.accent,
    required this.isExpanded,
    required this.cycleDay,
    required this.progress,
    required this.isTaken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProgressRing(
              progress: progress,
              accent: accent,
              cycleDay: cycleDay,
              isTaken: isTaken,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.peptideName,
                    style: GoogleFonts.sora(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xF2FFFFFF),
                      height: 1.15,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.peptideCategory.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _CategoryChip(
                      label: item.peptideCategory,
                      accent: accent,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0x1FFFFFFF), width: 0.8),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0x99FFFFFF),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _CategoryChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 0.8),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.sora(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: accent,
          letterSpacing: 0.6,
          height: 1.1,
        ),
      ),
    );
  }
}

// ─── Polished progress ring with gradient stroke ─────────────────────────────

class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color accent;
  final int cycleDay;
  final bool isTaken;

  const _ProgressRing({
    required this.progress,
    required this.accent,
    required this.cycleDay,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(50, 50),
            painter: _RingPainter(
              progress: progress,
              accent: accent,
              isTaken: isTaken,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$cycleDay',
                style: GoogleFonts.sora(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xF2FFFFFF),
                  height: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'DAY',
                style: GoogleFonts.sora(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0x66FFFFFF),
                  letterSpacing: 0.6,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final bool isTaken;

  _RingPainter({
    required this.progress,
    required this.accent,
    required this.isTaken,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Foreground arc with sweep gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [
        accent.withValues(alpha: 0.55),
        accent,
        accent.withValues(alpha: 0.95),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    final fgPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      fgPaint,
    );

    // Soft outer glow when taken
    if (isTaken) {
      final glow = Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress ||
        old.accent != accent ||
        old.isTaken != isTaken;
  }
}

// ─── Dose toggle ─────────────────────────────────────────────────────────────

class _DoseToggle extends StatelessWidget {
  final Color accent;
  final bool isTaken;
  final VoidCallback onTap;

  const _DoseToggle({
    required this.accent,
    required this.isTaken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: isTaken
                ? LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isTaken ? null : const Color(0x0AFFFFFF),
            border: Border.all(
              color: isTaken
                  ? accent.withValues(alpha: 0.42)
                  : const Color(0x1FFFFFFF),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  isTaken
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  key: ValueKey(isTaken),
                  size: 17,
                  color: isTaken ? accent : const Color(0x66FFFFFF),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isTaken ? 'Taken today' : 'Mark as taken today',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight:
                      isTaken ? FontWeight.w600 : FontWeight.w500,
                  color: isTaken ? accent : const Color(0x99FFFFFF),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expanded detail block ───────────────────────────────────────────────────

class _ExpandedDetail extends StatelessWidget {
  final ProtocolItem item;
  final Color accent;
  final int cycleDay;
  final int cycleDays;
  final double progress;
  final VoidCallback onViewDetails;

  const _ExpandedDetail({
    required this.item,
    required this.accent,
    required this.cycleDay,
    required this.cycleDays,
    required this.progress,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 0.5, color: const Color(0x14FFFFFF)),
          const SizedBox(height: 18),

          // Cycle progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CYCLE PROGRESS',
                style: GoogleFonts.sora(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: const Color(0x66FFFFFF),
                  letterSpacing: 0.7,
                ),
              ),
              Text(
                'Day $cycleDay of $cycleDays',
                style: GoogleFonts.sora(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.6),
                          accent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Dosing info row
          Row(
            children: [
              _InfoTile(
                icon: Icons.science_outlined,
                label: 'DOSE',
                value: item.shortBenefits.isNotEmpty
                    ? item.shortBenefits.first
                    : '—',
              ),
              const SizedBox(width: 8),
              const _InfoTile(
                icon: Icons.schedule_rounded,
                label: 'FREQUENCY',
                value: 'Once daily',
              ),
              const SizedBox(width: 8),
              _InfoTile(
                icon: Icons.repeat_rounded,
                label: 'CYCLE',
                value: '${cycleDays}d',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Benefits
          if (item.shortBenefits.isNotEmpty) ...[
            Text(
              'BENEFITS',
              style: GoogleFonts.sora(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0x66FFFFFF),
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 12),
            ...item.shortBenefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xCCFFFFFF),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Reasoning
          if (item.reasoning.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                border: Border(
                  left: BorderSide(
                    color: accent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                item.reasoning,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: const Color(0x99FFFFFF),
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // View full details
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onViewDetails,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View full details',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.arrow_forward_rounded, size: 13, color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x14FFFFFF), width: 1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: const Color(0x80FFFFFF)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.sora(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0x66FFFFFF),
                      letterSpacing: 0.6,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xE6FFFFFF),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
