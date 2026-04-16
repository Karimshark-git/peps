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

/// My Protocol — deep-dive command center for managing daily peptide use.
class MyProtocolScreen extends StatefulWidget {
  const MyProtocolScreen({super.key});

  @override
  State<MyProtocolScreen> createState() => _MyProtocolScreenState();
}

class _MyProtocolScreenState extends State<MyProtocolScreen>
    with TickerProviderStateMixin {
  // Existing state — preserved
  OnboardingSummary? _onboardingSummary;
  List<ProtocolItem> _protocol = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoggingOut = false;

  // New state
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  Set<String> _takenTodayIds = {};
  final Map<String, bool> _expandedCards = {};

  // Cycle calculation
  DateTime? _onboardingDate;
  static const int _defaultCycleDays = 56;

  // Entrance animation
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

      // users.id IS the auth uid — no auth_uid lookup needed.
      final userId = user.id;

      // Today's dose logs.
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
        // Table may not yet exist in dev — gracefully degrade.
        takenTodayIds = {};
      }

      // Onboarding date for cycle calculation.
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

      // Build categories list from protocol.
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

    // Optimistic UI update.
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
      // Roll back on failure.
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

  int _parseCycleDays(ProtocolItem item) {
    // ProtocolItem doesn't currently expose cycle_length — default to 56.
    return _defaultCycleDays;
  }

  int _cycleDay(ProtocolItem item) {
    if (_onboardingDate == null) return 1;
    final days =
        DateTime.now().difference(_onboardingDate!).inDays + 1;
    final total = _parseCycleDays(item);
    return days.clamp(1, total);
  }

  double _cycleProgress(ProtocolItem item) {
    final day = _cycleDay(item);
    final total = _parseCycleDays(item);
    if (total <= 0) return 0;
    return day / total;
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
            'Loading your protocol...',
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
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Color(0x8CFFFFFF),
            ),
            const SizedBox(height: 16),
            Text(
              "We couldn't load your protocol right now.",
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xE6FFFFFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.sora(
                fontSize: 13,
                color: const Color(0x8CFFFFFF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoggingOut ? null : _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECFA0),
                foregroundColor: const Color(0xFF08101E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3ECFA0),
                        ),
                      ),
                    )
                  : Text(
                      'Sign out',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3ECFA0),
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
            const Icon(
              Icons.medical_services_outlined,
              size: 56,
              color: Color(0x8CFFFFFF),
            ),
            const SizedBox(height: 16),
            Text(
              'No protocol found yet.',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xE6FFFFFF),
              ),
              textAlign: TextAlign.center,
            ),
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
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.goals);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECFA0),
                foregroundColor: const Color(0xFF08101E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Start Onboarding',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _filteredProtocol();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF08101E),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _HeaderExpanded(
              peptideCount: _protocol.length,
              goalCount: _onboardingSummary?.goals.length ?? 0,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: _CategoryFilterBar(
              categories: _categories,
              selected: _selectedCategory,
              onSelect: (cat) {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = cat);
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (i >= filtered.length) return null;
                final item = filtered[i];
                return _StaggeredEntrance(
                  controller: _entranceController,
                  index: i,
                  child: _PeptideDetailCard(
                    item: item,
                    accent: _accentForCategory(item.peptideCategory),
                    isTaken: _takenTodayIds.contains(item.peptideId),
                    isExpanded: _expandedCards[item.peptideId] ?? false,
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
                            recommendation: _toPeptideRecommendation(item),
                          ),
                        ),
                      );
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// Header (expanded portion of the SliverAppBar)
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderExpanded extends StatelessWidget {
  final int peptideCount;
  final int goalCount;

  const _HeaderExpanded({
    required this.peptideCount,
    required this.goalCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'My Protocol',
                  style: GoogleFonts.sora(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xE6FFFFFF),
                    height: 1.1,
                  ),
                ),
                const _PhysicianBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$peptideCount peptides · $goalCount goals',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0x4DFFFFFF),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PhysicianBadge extends StatefulWidget {
  const _PhysicianBadge();

  @override
  State<_PhysicianBadge> createState() => _PhysicianBadgeState();
}

class _PhysicianBadgeState extends State<_PhysicianBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final t = _pulseController.value;
              final opacity = 1.0 - (t * 0.7);
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF3ECFA0).withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Text(
            'Pending review',
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: const Color(0x8CFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter bar (sticky under header)
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFF08101E),
        border: Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3ECFA0).withValues(alpha: 0.15)
                    : const Color(0x0AFFFFFF),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3ECFA0).withValues(alpha: 0.4)
                      : const Color(0x1AFFFFFF),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF3ECFA0)
                        : const Color(0x8CFFFFFF),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered entrance wrapper
// ─────────────────────────────────────────────────────────────────────────────

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
    // Delay 80ms per card, 350ms duration each, controller is 600ms total.
    const totalMs = 600;
    final startMs = (index * 80).clamp(0, totalMs - 1);
    const durationMs = 350;
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
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Peptide detail card (expandable)
// ─────────────────────────────────────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(
          color: isTaken
              ? accent.withValues(alpha: 0.25)
              : const Color(0x1AFFFFFF),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isTaken
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : const [],
      ),
      child: Column(
        children: [
          // Header (always visible)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Mini progress ring
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: const Color(0x1AFFFFFF),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                        Text(
                          '$cycleDay',
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xE6FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.peptideName,
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xE6FFFFFF),
                          ),
                        ),
                        if (item.peptideCategory.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.peptideCategory.toUpperCase(),
                              style: GoogleFonts.sora(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: accent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0x4DFFFFFF),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Taken-today toggle (always visible)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: onToggleDose,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isTaken
                      ? accent.withValues(alpha: 0.12)
                      : const Color(0x0AFFFFFF),
                  border: Border.all(
                    color: isTaken
                        ? accent.withValues(alpha: 0.35)
                        : const Color(0x1AFFFFFF),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isTaken
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        key: ValueKey(isTaken),
                        size: 16,
                        color:
                            isTaken ? accent : const Color(0x4DFFFFFF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTaken
                          ? 'Taken today \u2713'
                          : 'Mark as taken today',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight:
                            isTaken ? FontWeight.w500 : FontWeight.w400,
                        color:
                            isTaken ? accent : const Color(0x4DFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded detail
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded detail block
// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 0.5,
            color: const Color(0x1AFFFFFF),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Cycle progress bar with label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CYCLE PROGRESS',
                style: GoogleFonts.sora(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: const Color(0x4DFFFFFF),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Day $cycleDay of $cycleDays',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0x1AFFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 20),

          // Dosing info row
          Row(
            children: [
              _InfoTile(
                label: 'DOSE',
                value: item.shortBenefits.isNotEmpty
                    ? item.shortBenefits.first
                    : '—',
                accent: accent,
              ),
              const SizedBox(width: 8),
              _InfoTile(
                label: 'FREQUENCY',
                value: 'Once daily',
                accent: accent,
              ),
              const SizedBox(width: 8),
              _InfoTile(
                label: 'CYCLE',
                value: '${cycleDays}d',
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Short benefits
          if (item.shortBenefits.isNotEmpty) ...[
            Text(
              'BENEFITS',
              style: GoogleFonts.sora(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: const Color(0x4DFFFFFF),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            ...item.shortBenefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Reasoning
          if (item.reasoning.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0AFFFFFF),
                border: Border(
                  left: BorderSide(
                    color: accent.withValues(alpha: 0.4),
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
                  color: const Color(0x8CFFFFFF),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // View full details link
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
                    fontWeight: FontWeight.w500,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: const Color(0x4DFFFFFF),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xCCFFFFFF),
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
