import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../provider/onboarding_provider.dart';

/// Lifestyle — step 4/6 (orbit carousel). Chrome lives in [OnboardingPersonalizationShell].
class LifestylePersonalizationPage extends StatefulWidget {
  final VoidCallback onContinueToNextStep;
  final VoidCallback onFlowBackStep;

  const LifestylePersonalizationPage({
    super.key,
    required this.onContinueToNextStep,
    required this.onFlowBackStep,
  });

  @override
  State<LifestylePersonalizationPage> createState() =>
      LifestylePersonalizationPageState();
}

class _LifestyleData {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color accentColor;
  const _LifestyleData(
    this.label,
    this.sublabel,
    this.icon,
    this.accentColor,
  );
}

const List<_LifestyleData> _lifestyleOptions = [
  _LifestyleData(
    'Sleep Quality Issues',
    'Poor or disrupted sleep',
    Icons.bedtime_outlined,
    Color(0xFF6B9FFF),
  ),
  _LifestyleData(
    'High Stress Levels',
    'Chronic or work-related stress',
    Icons.psychology_outlined,
    Color(0xFFFF6B6B),
  ),
  _LifestyleData(
    'High-Intensity Training',
    'Regular intense workouts',
    Icons.fitness_center_outlined,
    Color(0xFF3ECFA0),
  ),
  _LifestyleData(
    'Chronic Fatigue / Burnout',
    'Persistent low energy',
    Icons.battery_alert_outlined,
    Color(0xFFFFB86B),
  ),
  _LifestyleData(
    'Sedentary Job',
    'Desk-bound most of the day',
    Icons.chair_outlined,
    Color(0xFF6B9FFF),
  ),
  _LifestyleData(
    'Irregular Meal Times',
    'Skipping meals or late eating',
    Icons.restaurant_outlined,
    Color(0xFFFFB86B),
  ),
  _LifestyleData(
    'Low Motivation / Low Energy',
    'Difficulty getting started',
    Icons.bolt_outlined,
    Color(0xFFFF6B6B),
  ),
  _LifestyleData(
    'Chronic Pain',
    'Ongoing physical discomfort',
    Icons.healing_outlined,
    Color(0xFFB06BFF),
  ),
  _LifestyleData(
    'Low Libido / Low Drive',
    'Reduced vitality and drive',
    Icons.favorite_outline,
    Color(0xFFFF6B9F),
  ),
  _LifestyleData(
    'Cravings / Appetite Control Issues',
    'Difficulty managing hunger',
    Icons.no_food_outlined,
    Color(0xFF3ECFA0),
  ),
  _LifestyleData(
    'Poor Gut Health',
    'Digestive issues or discomfort',
    Icons.monitor_heart_outlined,
    Color(0xFFFFB86B),
  ),
  _LifestyleData(
    'Difficulty Building Muscle / Slow Recovery',
    'Limited gains despite training',
    Icons.trending_up_outlined,
    Color(0xFF6B9FFF),
  ),
  _LifestyleData(
    'Limited Sun Exposure',
    'Indoor lifestyle, low vitamin D',
    Icons.wb_sunny_outlined,
    Color(0xFFFFB86B),
  ),
];

const double kLifestyleCardW = 220.0;
const double kLifestyleCardH = 280.0;

class LifestylePersonalizationPageState extends State<LifestylePersonalizationPage>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  // ignore: prefer_collection_literals — explicit LinkedHashSet for insertion order
  final Set<int> _selectedIndices = LinkedHashSet<int>();
  final PageController _pageController = PageController(
    initialPage: 0,
    viewportFraction: 0.62,
  );
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      final rounded = page.round();
      if (rounded != _currentIndex) {
        setState(() => _currentIndex = rounded);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      final saved =
          provider.model.lifestyle['factors'] as List<dynamic>?;
      if (saved != null) {
        setState(() {
          for (final label in saved.cast<String>()) {
            final i =
                _lifestyleOptions.indexWhere((o) => o.label == label);
            if (i >= 0) _selectedIndices.add(i);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncProvider() {
    final sorted = _selectedIndices.toList()..sort();
    Provider.of<OnboardingProvider>(context, listen: false).updateLifestyle({
      'factors': sorted.map((i) => _lifestyleOptions[i].label).toList(),
    });
  }

  void syncToProvider() => _syncProvider();

  void _selectLifestyle(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
    _syncProvider();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onHorizontalDragStart: (details) {
        _dragStartX = details.globalPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        _dragCurrentX = details.globalPosition.dx;
      },
      onHorizontalDragEnd: (details) {
        final dragDistance = _dragCurrentX - _dragStartX;
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300 &&
            dragDistance > 50) {
          _syncProvider();
          widget.onFlowBackStep();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR LIFESTYLE',
                                  style: GoogleFonts.sora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF3ECFA0),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'How do you\nlive?',
                                  style: GoogleFonts.sora(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xE6FFFFFF),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, anim) =>
                                FadeTransition(
                              opacity: anim,
                              child: child,
                            ),
                            child: Container(
                              key: ValueKey(_selectedIndices.length),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1A3ECFA0),
                                border: Border.all(
                                  color: const Color(0x473ECFA0),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedIndices.length} selected',
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF3ECFA0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Swipe to browse · tap to select',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0x4DFFFFFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: kLifestyleCardH + 20,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _lifestyleOptions.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double page = 0;
                            if (_pageController.hasClients &&
                                _pageController.position.haveDimensions) {
                              page = _pageController.page ?? 0;
                            }
                            final distance = (page - index).abs();
                            final scale =
                                (1.0 - (distance * 0.18)).clamp(0.82, 1.0);
                            final opacity =
                                (1.0 - (distance * 0.45)).clamp(0.55, 1.0);
                            final yOffset = distance * 12.0;

                            return Transform.translate(
                              offset: Offset(0, yOffset),
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (index == _currentIndex) {
                                          _selectLifestyle(index);
                                        } else {
                                          _pageController.animateToPage(
                                            index,
                                            duration: const Duration(
                                              milliseconds: 350,
                                            ),
                                            curve: Curves.easeOutCubic,
                                          );
                                        }
                                      },
                                      child: _LifestyleOrbitCard(
                                        lifestyle: _lifestyleOptions[index],
                                        isSelected: _selectedIndices
                                            .contains(index),
                                        isCenter: index == _currentIndex,
                                        pageDistance: distance,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        _lifestyleOptions.length,
                        (i) {
                          final isActive = i == _currentIndex;
                          final isSelected = _selectedIndices.contains(i);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3ECFA0)
                                  : isActive
                                      ? const Color(0x8C3ECFA0)
                                      : const Color(0x29FFFFFF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    height: _selectedIndices.isEmpty ? 0 : 44,
                    child: _selectedIndices.isEmpty
                        ? const SizedBox.shrink()
                        : Builder(
                            builder: (context) {
                              final ordered =
                                  List<int>.from(_selectedIndices);
                              return ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                  stops: [
                                    0.0,
                                    0.04,
                                    0.96,
                                    1.0,
                                  ],
                                ).createShader(bounds),
                                blendMode: BlendMode.dstIn,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: ordered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, i) {
                                    final idx = ordered[i];
                                    final opt = _lifestyleOptions[idx];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x0D3ECFA0),
                                        border: Border.all(
                                          color: const Color(0x473ECFA0),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            opt.icon,
                                            size: 11,
                                            color: const Color(0xFF3ECFA0),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            opt.label,
                                            style: const TextStyle(
                                              fontFamily: 'Sora',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF3ECFA0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
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
                        text: 'Next →',
                        textColor: const Color(0xFF04201A),
                        isEnabled: _selectedIndices.isNotEmpty,
                        onPressed: _selectedIndices.isNotEmpty
                            ? () {
                                _syncProvider();
                                widget.onContinueToNextStep();
                              }
                            : null,
                      ),
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
}

class _LifestyleOrbitCard extends StatelessWidget {
  final _LifestyleData lifestyle;
  final bool isSelected;
  final bool isCenter;
  final double pageDistance;

  const _LifestyleOrbitCard({
    required this.lifestyle,
    required this.isSelected,
    required this.isCenter,
    required this.pageDistance,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: kLifestyleCardW,
      height: kLifestyleCardH,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0x0D3ECFA0)
            : const Color(0x0FFFFFFF),
        border: Border.all(
          color: isSelected
              ? const Color(0x663ECFA0)
              : const Color(0x29FFFFFF),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  color: Color(0x333ECFA0),
                  blurRadius: 20,
                  spreadRadius: -6,
                ),
              ]
            : isCenter
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: Offset(0, 8),
                    ),
                  ]
                : const [],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isSelected
                        ? const Color(0x333ECFA0)
                        : const Color(0x29FFFFFF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lifestyle.accentColor.withValues(
                      alpha: isSelected ? 0.12 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: lifestyle.accentColor.withValues(
                        alpha: isSelected ? 0.22 : 0.2,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    lifestyle.icon,
                    size: 22,
                    color: isSelected
                        ? lifestyle.accentColor.withValues(alpha: 0.85)
                        : lifestyle.accentColor.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  lifestyle.label,
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xCCFFFFFF),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lifestyle.sublabel,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0x4DFFFFFF),
                  ),
                ),
                const SizedBox(height: 16),
                if (isCenter)
                  Text(
                    isSelected ? '· selected' : 'tap to select',
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: isSelected
                          ? const Color(0x4D3ECFA0)
                          : const Color(0x29FFFFFF),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3ECFA0),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x993ECFA0),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
