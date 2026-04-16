import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/onboarding_chrome_header.dart';
import '../../../core/widgets/peps_ambient_orbs.dart';
import 'biometrics_screen.dart';
import 'goals_screen.dart';
import 'lifestyle_screen.dart';
import 'medical_screen.dart';
import 'name_screen.dart';

/// Hosts onboarding steps 1–5 (name → medical) with one fixed chrome
/// (back, continuous progress, logo) and cross-fading step bodies.
class OnboardingPersonalizationShell extends StatefulWidget {
  /// 0 name, 1 goals, 2 biometrics, 3 lifestyle, 4 medical
  final int initialPage;

  const OnboardingPersonalizationShell({
    super.key,
    this.initialPage = 0,
  }) : assert(initialPage >= 0 && initialPage <= 4);

  @override
  State<OnboardingPersonalizationShell> createState() =>
      _OnboardingPersonalizationShellState();
}

class _OnboardingPersonalizationShellState
    extends State<OnboardingPersonalizationShell>
    with SingleTickerProviderStateMixin {
  static const int _totalOnboardingSteps = 6;
  static const int _lastFlowPageIndex = 4;

  late final AnimationController _stepTransitionController;
  late int _pageIndex;
  late int _progressFromPage;
  late int _progressToPage;
  bool _swappedMidTransition = false;

  final GlobalKey<NamePersonalizationPageState> _nameKey =
      GlobalKey<NamePersonalizationPageState>();
  final GlobalKey<GoalsPersonalizationPageState> _goalsKey =
      GlobalKey<GoalsPersonalizationPageState>();
  final GlobalKey<BiometricsPersonalizationPageState> _bioKey =
      GlobalKey<BiometricsPersonalizationPageState>();
  final GlobalKey<LifestylePersonalizationPageState> _lifestyleKey =
      GlobalKey<LifestylePersonalizationPageState>();
  final GlobalKey<MedicalPersonalizationPageState> _medicalKey =
      GlobalKey<MedicalPersonalizationPageState>();

  /// Steps 1–5 map to flow pages 0–4 → progress (step-1)/(6-1).
  double get _chromeProgress {
    double page;
    final v = _stepTransitionController.value;
    final midTransition =
        _stepTransitionController.isAnimating || (v > 0.0 && v < 1.0);
    if (midTransition) {
      final t = Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
      page = _progressFromPage + (_progressToPage - _progressFromPage) * t;
    } else {
      page = _pageIndex.toDouble();
    }
    final clamped = page.clamp(0.0, _lastFlowPageIndex.toDouble());
    return clamped / (_totalOnboardingSteps - 1);
  }

  static double _bodyOpacityFor(double t) {
    if (t < 0.5) {
      return 1.0 - Curves.easeOut.transform((t * 2).clamp(0.0, 1.0));
    }
    return Curves.easeOut.transform(((t - 0.5) * 2).clamp(0.0, 1.0));
  }

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPage;
    _progressFromPage = _pageIndex;
    _progressToPage = _pageIndex;
    _stepTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..value = 1.0;
    _stepTransitionController.addListener(_onStepTransitionTick);
    _stepTransitionController.addStatusListener(_onStepTransitionStatus);
  }

  void _onStepTransitionTick() {
    final t = _stepTransitionController.value;
    setState(() {
      if (t >= 0.5 && !_swappedMidTransition) {
        _pageIndex = _progressToPage;
        _swappedMidTransition = true;
      }
    });
  }

  void _onStepTransitionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _progressFromPage = _pageIndex;
      _progressToPage = _pageIndex;
      _swappedMidTransition = false;
    }
  }

  @override
  void dispose() {
    _stepTransitionController.removeListener(_onStepTransitionTick);
    _stepTransitionController.removeStatusListener(_onStepTransitionStatus);
    _stepTransitionController.dispose();
    super.dispose();
  }

  Future<void> _animateToFlowPage(int index) {
    final target = index.clamp(0, _lastFlowPageIndex);
    if (!_stepTransitionController.isAnimating &&
        _stepTransitionController.value == 1.0 &&
        target == _pageIndex) {
      return Future.value();
    }
    if (_stepTransitionController.isAnimating) {
      return Future.value();
    }

    _progressFromPage = _pageIndex;
    _progressToPage = target;
    _swappedMidTransition = false;

    return _stepTransitionController.forward(from: 0);
  }

  void _chromeBack() {
    final i = _pageIndex.clamp(0, _lastFlowPageIndex);
    if (i <= 0) {
      FocusScope.of(context).unfocus();
      _nameKey.currentState?.persistToProvider();
      Navigator.pop(context);
      return;
    }
    if (i == 1) {
      _goalsKey.currentState?.syncToProvider();
      _animateToFlowPage(0);
      return;
    }
    if (i == 2) {
      _bioKey.currentState?.persistToProvider();
      FocusScope.of(context).unfocus();
      _animateToFlowPage(1);
      return;
    }
    if (i == 3) {
      _lifestyleKey.currentState?.syncToProvider();
      _animateToFlowPage(2);
      return;
    }
    _medicalKey.currentState?.persistToProvider();
    _animateToFlowPage(3);
  }

  void _goToGoals() => _animateToFlowPage(1);
  void _goToBiometrics() => _animateToFlowPage(2);
  void _goToLifestyle() => _animateToFlowPage(3);
  void _goToMedical() => _animateToFlowPage(4);

  @override
  Widget build(BuildContext context) {
    final bodyOpacity =
        _bodyOpacityFor(_stepTransitionController.value.clamp(0.0, 1.0));

    return Scaffold(
      backgroundColor: ColorPalette.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const PepsAmbientOrbs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnboardingChromeHeader(
                    onBack: _chromeBack,
                    progress: _chromeProgress,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Opacity(
                      opacity: bodyOpacity,
                      child: IndexedStack(
                        index: _pageIndex,
                        sizing: StackFit.expand,
                        children: [
                          NamePersonalizationPage(
                            key: _nameKey,
                            onContinueToNextStep: _goToGoals,
                          ),
                          GoalsPersonalizationPage(
                            key: _goalsKey,
                            onContinueToNextStep: _goToBiometrics,
                            onFlowBackStep: () => _animateToFlowPage(0),
                          ),
                          BiometricsPersonalizationPage(
                            key: _bioKey,
                            onContinueToNextStep: _goToLifestyle,
                            onFlowBackStep: () => _animateToFlowPage(1),
                          ),
                          LifestylePersonalizationPage(
                            key: _lifestyleKey,
                            onContinueToNextStep: _goToMedical,
                            onFlowBackStep: () => _animateToFlowPage(2),
                          ),
                          MedicalPersonalizationPage(
                            key: _medicalKey,
                            onFlowBackStep: () => _animateToFlowPage(3),
                          ),
                        ],
                      ),
                    ),
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
