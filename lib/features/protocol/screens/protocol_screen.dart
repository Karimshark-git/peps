import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/navigation/app_page_transitions.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/widgets/peps_ambient_orbs.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/theme/color_palette.dart';
import '../../auth/widgets/create_account_modal.dart';
import '../../../engine/models/peptide_recommendation.dart';
import '../../../providers/protocol_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_client.dart';
import 'peptide_details_screen_new.dart';

/// Split-layout immersive protocol — swipe hero, draggable detail panel.
class ProtocolScreen extends StatefulWidget {
  const ProtocolScreen({super.key});

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
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
  if (c.contains('immune') || c.contains('skin')) {
    return const Color(0xFF3ECFA0);
  }
  if (c.contains('energy') || c.contains('mitochondr')) {
    return const Color(0xFFFFD700);
  }
  return const Color(0xFF3ECFA0);
}

Color _accentLerpForPage(List<PeptideRecommendation> protocol, double page) {
  if (protocol.isEmpty) return const Color(0xFF3ECFA0);
  final maxI = protocol.length - 1;
  final p = page.clamp(0.0, maxI.toDouble());
  final i = p.floor();
  final j = math.min(i + 1, maxI);
  final t = p - i;
  final c0 = _accentForCategory(protocol[i].category);
  final c1 = _accentForCategory(protocol[j].category);
  return Color.lerp(c0, c1, i == j ? 0.0 : t) ?? c0;
}

class _PeptideVisual {
  final IconData icon;
  final String animType;
  const _PeptideVisual(this.icon, this.animType);
}

_PeptideVisual _visualForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('recovery') || c.contains('tissue')) {
    return const _PeptideVisual(Icons.healing_outlined, 'pulse');
  }
  if (c.contains('muscle') ||
      c.contains('gh axis') ||
      c.contains('performance')) {
    return const _PeptideVisual(Icons.fitness_center_outlined, 'breathe');
  }
  if (c.contains('weight') || c.contains('metabolic')) {
    return const _PeptideVisual(
      Icons.local_fire_department_outlined,
      'pulse',
    );
  }
  if (c.contains('aging') || c.contains('longevity')) {
    return const _PeptideVisual(Icons.all_inclusive_outlined, 'rotate');
  }
  if (c.contains('cognitive') || c.contains('focus')) {
    return const _PeptideVisual(Icons.psychology_outlined, 'breathe');
  }
  if (c.contains('libido') || c.contains('sexual')) {
    return const _PeptideVisual(Icons.favorite_outline, 'pulse');
  }
  if (c.contains('bonding') || c.contains('mood')) {
    return const _PeptideVisual(Icons.self_improvement_outlined, 'float');
  }
  if (c.contains('immune')) {
    return const _PeptideVisual(Icons.shield_outlined, 'breathe');
  }
  if (c.contains('skin')) {
    return const _PeptideVisual(
      Icons.face_retouching_natural_outlined,
      'float',
    );
  }
  if (c.contains('energy') || c.contains('mitochondr')) {
    return const _PeptideVisual(Icons.bolt_outlined, 'pulse');
  }
  if (c.contains('anxiety') || c.contains('stress')) {
    return const _PeptideVisual(Icons.spa_outlined, 'breathe');
  }
  return const _PeptideVisual(Icons.biotech_outlined, 'rotate');
}

class _ProtocolScreenState extends State<ProtocolScreen>
    with TickerProviderStateMixin {
  List<PeptideRecommendation> _recommendedPeptides = [];

  int _activeIndex = 0;
  PageController? _pageController;

  AnimationController? _iconController;
  Animation<double>? _iconAnim;

  AnimationController? _colorController;
  Color _fromColor = const Color(0xFF3ECFA0);
  Color _toColor = const Color(0xFF3ECFA0);

  AnimationController? _panelController;
  Animation<double>? _panelAnim;

  static const double _panelHalfHeight = 0.44;
  static const double _panelFullHeight = 0.88;

  AnimationController? _contentFadeController;
  Animation<double>? _contentFadeAnim;

  StreamSubscription<AuthState>? _authSubscription;

  /// Hot reload does not re-run [initState]; nullable controllers + this guard
  /// avoid [LateInitializationError] when [State] is reused.
  void _ensureControllers() {
    if (_pageController != null) return;

    _pageController = PageController();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _iconAnim = CurvedAnimation(
      parent: _iconController!,
      curve: Curves.easeInOut,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..value = 1.0;

    _panelController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..value = 0.0;

    _panelAnim = CurvedAnimation(
      parent: _panelController!,
      curve: Curves.easeOutCubic,
    );

    _contentFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..value = 1.0;

    _contentFadeAnim = CurvedAnimation(
      parent: _contentFadeController!,
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();

    _ensureControllers();

    // Listen for OAuth callback when user signs in via the CreateAccountModal.
    // LoginScreen has its own listener; this covers the modal → OAuth flow.
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn &&
          data.session != null &&
          mounted) {
        AuthService.handlePostLogin(context);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p =
          Provider.of<ProtocolProvider>(context, listen: false).protocol;
      if (p.isEmpty) return;
      setState(() {
        final a = _accentForCategory(p.first.category);
        _fromColor = a;
        _toColor = a;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pageController?.dispose();
    _iconController?.dispose();
    _colorController?.dispose();
    _panelController?.dispose();
    _contentFadeController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (!mounted || _recommendedPeptides.isEmpty) return;
    if (index < 0 || index >= _recommendedPeptides.length) return;
    if (index == _activeIndex) return;

    _contentFadeController!.animateTo(
      0.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeIn,
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _fromColor = _toColor;
        _activeIndex = index;
        _toColor = _accentForCategory(
          _recommendedPeptides[index].category,
        );
      });
      _colorController!.forward(from: 0);
      _iconController!.stop();
      _iconController!.reset();
      Future.delayed(const Duration(milliseconds: 40), () {
        if (mounted) {
          _iconController!.repeat(reverse: true);
        }
      });
      _contentFadeController!.animateTo(
        1.0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openDetails(PeptideRecommendation item) {
    Navigator.push(
      context,
      AppPageTransitions.cardPushRoute(
        PeptideDetailsScreenNew(recommendation: item),
      ),
    );
  }

  void _showCreateAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const CreateAccountModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();

    final protocolProvider = Provider.of<ProtocolProvider>(context);
    _recommendedPeptides = protocolProvider.protocol;

    final screenH = MediaQuery.sizeOf(context).height;

    const scaffoldBg = Color(0xFF08101E);

    if (_recommendedPeptides.isEmpty) {
      return const Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No peptides recommended at this time.\nPlease complete your onboarding.',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final activeAccent =
        _accentForCategory(_recommendedPeptides[_activeIndex].category);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          const PepsAmbientOrbs(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenH * 0.5,
            child: Center(
              child: _AccentOrb(
                fromColor: _fromColor,
                toColor: _toColor,
                colorController: _colorController!,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenH * 0.50,
            child: AnimatedBuilder(
              animation: _panelAnim!,
              builder: (context, child) {
                final opacity =
                    (1.0 - _panelAnim!.value * 1.2).clamp(0.0, 1.0);
                return Opacity(opacity: opacity, child: child);
              },
              child: _TopHero(
                pageController: _pageController!,
                protocol: _recommendedPeptides,
                activeIndex: _activeIndex,
                iconAnim: _iconAnim!,
                onPageChanged: _onPageChanged,
              ),
            ),
          ),
          _BottomPanel(
            screenHeight: screenH,
            panelAnim: _panelAnim!,
            panelController: _panelController!,
            contentFadeAnim: _contentFadeAnim!,
            item: _recommendedPeptides[_activeIndex],
            accent: activeAccent,
            onOpenDetails: () =>
                _openDetails(_recommendedPeptides[_activeIndex]),
          ),
          _TopChrome(
            activeIndex: _activeIndex,
            total: _recommendedPeptides.length,
            panelAnim: _panelAnim!,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A1628).withValues(alpha: 0),
                    const Color(0xFF0A1628),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D3ECFA0),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: PrimaryButton(
                  text: 'Book Doctor Consultation →',
                  textColor: const Color(0xFF04201A),
                  onPressed: _showCreateAccountModal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentOrb extends StatelessWidget {
  final Color fromColor;
  final Color toColor;
  final AnimationController colorController;

  const _AccentOrb({
    required this.fromColor,
    required this.toColor,
    required this.colorController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: colorController,
      builder: (context, _) {
        final t = colorController.value;
        final current = Color.lerp(fromColor, toColor, t) ?? toColor;
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                current.withValues(alpha: 0.15),
                current.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _TopChrome extends StatelessWidget {
  final int activeIndex;
  final int total;
  final Animation<double> panelAnim;

  const _TopChrome({
    required this.activeIndex,
    required this.total,
    required this.panelAnim,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const OnboardingProgressBar(stepIndex: 6, totalSteps: 6),
            AnimatedBuilder(
              animation: panelAnim,
              builder: (context, child) {
                final opacity = (1.0 - ((panelAnim.value - 0.3) / 0.4))
                    .clamp(0.0, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR AI PROTOCOL',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3ECFA0),
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 4),
                          _PhysicianBadge(),
                        ],
                      ),
                      Text(
                        '${activeIndex + 1} / $total',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0x4DFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
            CurvedAnimation(parent: _c, curve: Curves.easeInOut),
          ),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3ECFA0),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Pending physician review',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFF3ECFA0),
          ),
        ),
      ],
    );
  }
}

class _TopHero extends StatelessWidget {
  final PageController pageController;
  final List<PeptideRecommendation> protocol;
  final int activeIndex;
  final Animation<double> iconAnim;
  final ValueChanged<int> onPageChanged;

  const _TopHero({
    required this.pageController,
    required this.protocol,
    required this.activeIndex,
    required this.iconAnim,
    required this.onPageChanged,
  });

  double _pageForBuild() {
    if (!pageController.hasClients) return activeIndex.toDouble();
    return pageController.page ?? activeIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, _) {
        final page = _pageForBuild();
        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: protocol.length,
                itemBuilder: (context, index) {
                  final item = protocol[index];
                  final accent = _accentForCategory(item.category);
                  final visual = _visualForCategory(item.category);
                  final dist = (page - index).abs().clamp(0.0, 1.0);
                  final opacity = dist >= 1.0
                      ? 0.0
                      : Curves.easeInOutCubic.transform(1.0 - dist);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Opacity(
                          opacity: opacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LivingIcon(
                                visual: visual,
                                accent: accent,
                                animation: iconAnim,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xE6FFFFFF),
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: accent,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _HeroPageIndicator(
                page: page,
                count: protocol.length,
                accent: _accentLerpForPage(protocol, page),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fixed track under the hero; selection morphs between pill (rest) and dot
/// (mid-swipe) so it does not cover neighboring markers.
class _HeroPageIndicator extends StatelessWidget {
  final double page;
  final int count;
  final Color accent;

  static const double _dot = 6;
  /// Center-to-center spacing — must exceed max pill width so neighbors stay clear.
  static const double _step = 24;
  static const double _pillMax = 20;
  static const double _edgePad = (_pillMax - _dot) / 2;

  const _HeroPageIndicator({
    required this.page,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final maxI = count - 1;
    final trackW = _edgePad * 2 + _dot + maxI * _step;
    final p = page.clamp(0.0, maxI.toDouble());
    final flo = p.floor();
    final cei = math.min(flo + 1, maxI);
    final t = p - flo;

    double centerX(int i) => _edgePad + _dot / 2 + i * _step;
    final cx = lerpDouble(
          centerX(flo),
          centerX(cei),
          flo == cei ? 0.0 : t,
        ) ??
        centerX(flo);

    // Near an integer page: full pill; halfway between pages: dot-sized.
    final distNearest = (p - p.round()).abs().clamp(0.0, 0.5);
    final squash = Curves.easeInOutCubic.transform(2 * distNearest);
    final w = lerpDouble(_pillMax, _dot, squash)!;
    final radius = w * 0.5;
    final pillLeft = cx - w / 2;

    return Center(
      child: SizedBox(
        width: trackW,
        height: _dot,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              Positioned(
                left: centerX(i) - _dot / 2,
                top: 0,
                child: Container(
                  width: _dot,
                  height: _dot,
                  decoration: BoxDecoration(
                    color: const Color(0x29FFFFFF),
                    borderRadius: BorderRadius.circular(_dot / 2),
                  ),
                ),
              ),
            Positioned(
              left: pillLeft,
              top: 0,
              child: Container(
                width: w,
                height: _dot,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: squash < 0.85 ? 8 : 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
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

class _LivingIcon extends StatelessWidget {
  final _PeptideVisual visual;
  final Color accent;
  final Animation<double> animation;

  const _LivingIcon({
    required this.visual,
    required this.accent,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final v = animation.value;
        Widget core = Icon(
          visual.icon,
          size: 36,
          color: accent,
        );

        switch (visual.animType) {
          case 'pulse':
            core = Transform.scale(
              scale: 1.0 + v * 0.12,
              child: core,
            );
            break;
          case 'rotate':
            core = Transform.rotate(
              angle: v * 2 * math.pi,
              child: core,
            );
            break;
          case 'breathe':
            core = Opacity(
              opacity: 0.7 + v * 0.3,
              child: Transform.scale(
                scale: 0.94 + v * 0.12,
                child: core,
              ),
            );
            break;
          case 'float':
            core = Transform.translate(
              offset: Offset(0, -8 + v * 16),
              child: core,
            );
            break;
          default:
            break;
        }

        return Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.10),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.20),
                blurRadius: 32,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Center(child: core),
        );
      },
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final double screenHeight;
  final Animation<double> panelAnim;
  final AnimationController panelController;
  final Animation<double> contentFadeAnim;
  final PeptideRecommendation item;
  final Color accent;
  final VoidCallback onOpenDetails;

  const _BottomPanel({
    required this.screenHeight,
    required this.panelAnim,
    required this.panelController,
    required this.contentFadeAnim,
    required this.item,
    required this.accent,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([panelAnim, panelController]),
      builder: (context, _) {
        final h = lerpDouble(
          screenHeight * _ProtocolScreenState._panelHalfHeight,
          screenHeight * _ProtocolScreenState._panelFullHeight,
          panelController.value,
        )!;
        final scrollable = panelController.value > 0.5;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: h,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              final range = screenHeight *
                  (_ProtocolScreenState._panelFullHeight -
                      _ProtocolScreenState._panelHalfHeight);
              final delta = -details.delta.dy / range;
              const dragDamping = 0.86;
              panelController.value = (panelController.value + delta * dragDamping)
                  .clamp(0.0, 1.0);
            },
            onVerticalDragEnd: (details) {
              final vy = details.velocity.pixelsPerSecond.dy;
              const flingThreshold = 650.0;
              void settle(double target) {
                panelController.animateTo(
                  target,
                  curve: Curves.easeOutCubic,
                  duration: const Duration(milliseconds: 400),
                );
              }

              if (vy < -flingThreshold) {
                settle(1.0);
              } else if (vy > flingThreshold) {
                settle(0.0);
              } else if (panelController.value > 0.5) {
                settle(1.0);
              } else {
                settle(0.0);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                border: const Border(
                  top: BorderSide(color: Color(0x29FFFFFF), width: 1),
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0x29FFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: scrollable
                          ? const BouncingScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      child: FadeTransition(
                        opacity: contentFadeAnim,
                        child: _PanelContent(
                          item: item,
                          accent: accent,
                          onOpenDetails: onOpenDetails,
                        ),
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

class _PanelContent extends StatelessWidget {
  final PeptideRecommendation item;
  final Color accent;
  final VoidCallback onOpenDetails;

  const _PanelContent({
    required this.item,
    required this.accent,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    void addChip(String label, String value) {
      if (value.trim().isEmpty) return;
      chips.add(
        Expanded(
          child: _DosingChip(label: label, value: value.trim()),
        ),
      );
    }

    addChip('DOSE', item.dosage);
    addChip('FREQ', item.frequency);
    addChip('CYCLE', item.cycleLength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.patientSummary.trim().isNotEmpty) ...[
          Text(
            item.patientSummary.trim(),
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: Color(0x8CFFFFFF),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (chips.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                chips[i],
              ],
            ],
          )
        else
          const Row(
            children: [
              Expanded(
                child: _DosingChip(label: 'DOSE', value: 'After review'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _DosingChip(label: 'FREQ', value: 'Clinician-set'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _DosingChip(label: 'CYCLE', value: 'After review'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        if (item.summary.trim().isNotEmpty) ...[
          Text(
            item.summary.trim(),
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0x8CFFFFFF),
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],
        if (item.shortBenefits.isNotEmpty) ...[
          Text(
            'BENEFITS',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: accent,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          ...item.shortBenefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (item.reasoning.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x0AFFFFFF),
              border: Border(
                left: BorderSide(
                  color: accent.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              item.reasoning.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: Color(0x8CFFFFFF),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (item.confidence.trim().isNotEmpty) ...[
          Row(
            children: [
              Text(
                'AI CONFIDENCE',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              _ConfidencePill(confidence: item.confidence.trim()),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (item.stackNote.trim().isNotEmpty) ...[
          Text(
            'Stack note: ${item.stackNote.trim()}',
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: Color(0x4DFFFFFF),
            ),
          ),
          const SizedBox(height: 24),
        ],
        GestureDetector(
          onTap: onOpenDetails,
          behavior: HitTestBehavior.opaque,
          child: const Text(
            'View full peptide details →',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0x4DFFFFFF),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DosingChip extends StatelessWidget {
  final String label;
  final String value;

  const _DosingChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: Color(0x4DFFFFFF),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xCCFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final String confidence;

  const _ConfidencePill({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final c = confidence.toLowerCase();
    late Color bg;
    late Color fg;
    late String label;
    if (c == 'high') {
      bg = const Color(0xFF3ECFA0).withValues(alpha: 0.15);
      fg = const Color(0xFF3ECFA0);
      label = 'High match';
    } else if (c == 'low') {
      bg = const Color(0x33FFB86B);
      fg = const Color(0xFFFFB86B);
      label = 'Possible match';
    } else {
      bg = const Color(0x1A6496FF);
      fg = const Color(0xFF7AABFF);
      label = 'Good match';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}
