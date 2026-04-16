import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/peps_min_height_scroll_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../provider/onboarding_provider.dart';

/// Body for step 1 — chrome (back, progress, logo) lives in [OnboardingPersonalizationShell].
class NamePersonalizationPage extends StatefulWidget {
  final VoidCallback onContinueToNextStep;

  const NamePersonalizationPage({
    super.key,
    required this.onContinueToNextStep,
  });

  @override
  State<NamePersonalizationPage> createState() => NamePersonalizationPageState();
}

class NamePersonalizationPageState extends State<NamePersonalizationPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      if (provider.model.firstName != null &&
          provider.model.firstName!.isNotEmpty) {
        _nameController.text = provider.model.firstName!;
        setState(() {});
      }
      _fadeController.forward();
    });

    _nameFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _canContinue => _nameController.text.trim().isNotEmpty;

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.updateFirstName(name);
    }
  }

  /// Called from shell chrome back before [Navigator.pop].
  void persistToProvider() => _saveName();

  void _handleNext() {
    if (!_canContinue) return;
    FocusScope.of(context).unfocus();
    _saveName();
    widget.onContinueToNextStep();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isFocused = _nameFocusNode.hasFocus;

    return GestureDetector(
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
          FocusScope.of(context).unfocus();
          _saveName();
          Navigator.pop(context);
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: PepsMinHeightScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What should we\ncall you?',
                    style: GoogleFonts.sora(
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xE6FFFFFF),
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We'll personalize your protocol around you.",
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0x8CFFFFFF),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'FIRST NAME',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3ECFA0),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NameGlassTextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    isFocused: isFocused,
                    scrollPadding: EdgeInsets.only(
                      bottom:
                          MediaQuery.viewInsetsOf(context).bottom + 120,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (_canContinue) _handleNext();
                    },
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x4D3ECFA0),
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: PrimaryButton(
                      text: 'Continue →',
                      textColor: const Color(0xFF04201A),
                      isEnabled: _canContinue,
                      onPressed: _canContinue ? _handleNext : null,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameGlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final EdgeInsets scrollPadding;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _NameGlassTextField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    this.scrollPadding = const EdgeInsets.all(20.0),
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? const Color(0xFF3ECFA0)
                : const Color(0x1AFFFFFF),
            width: isFocused ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Color(0x3DFFFFFF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            TextField(
              controller: controller,
              focusNode: focusNode,
              scrollPadding: scrollPadding,
              cursorColor: const Color(0xFF3ECFA0),
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xE6FFFFFF),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your first name',
                hintStyle: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0x4DFFFFFF),
                ),
                border: InputBorder.none,
                isCollapsed: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ],
        ),
      ),
    );
  }
}
