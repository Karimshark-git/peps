import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/onboarding_progress_bar.dart';
import '../../../core/theme/color_palette.dart';
import '../provider/onboarding_provider.dart';

/// Beautiful name input screen - first step of onboarding
class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;

  @override
  void initState() {
    super.initState();

    // Fade animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Load saved name from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      if (provider.model.firstName != null && provider.model.firstName!.isNotEmpty) {
        _nameController.text = provider.model.firstName!;
        setState(() {});
      }
      _fadeController.forward();
      // Removed auto-focus to prevent keyboard from opening automatically
    });

    _nameFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isNameValid {
    return _nameController.text.trim().isNotEmpty &&
        _nameController.text.trim().length >= 2;
  }

  void _handleNext() {
    if (!_isNameValid) return;

    final name = _nameController.text.trim();
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.updateFirstName(name);

    Navigator.pushNamed(context, '/goals');
  }

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.updateFirstName(name);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // Swipe right (from left to right) to go back
        if (details.primaryVelocity != null &&
            details.primaryVelocity! > 300 &&
            dragDistance > 50) {
          _saveName();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F1), // Cream background - matches goals screen
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                child: OnboardingProgressBar(stepIndex: 1, totalSteps: 6),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      // Title
                      Text(
                        'What do we call you?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: ColorPalette.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      Text(
                        'We\'d love to personalize your experience.',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: ColorPalette.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Name input field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'First Name',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Animated input container
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: ColorPalette.cardBackground,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isFocused
                                    ? ColorPalette.gold
                                    : Colors.transparent,
                                width: isFocused ? 2.5 : 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isFocused
                                      ? ColorPalette.gold.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: isFocused ? 16 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Transform.scale(
                              scale: isFocused ? 1.01 : 1.0,
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                textCapitalization: TextCapitalization.words,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: ColorPalette.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your first name',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    color: ColorPalette.textPlaceholder,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 22,
                                  ),
                                ),
                                onChanged: (_) {
                                  setState(() {});
                                  // Button animation will be handled by AnimatedBuilder
                                },
                                onSubmitted: (_) {
                                  if (_isNameValid) {
                                    _handleNext();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                      // Next button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: _isNameValid
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFC8A96A),
                                    const Color(0xFFC8A96A).withValues(alpha: 0.9),
                                  ],
                                )
                              : null,
                          color: _isNameValid
                              ? null
                              : const Color(0xFFE8DCC4).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _isNameValid
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isNameValid ? _handleNext : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _isNameValid
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

