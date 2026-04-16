import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/peps_ambient_orbs.dart';
import '../../../core/widgets/peps_glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/supabase_client.dart';
import '../../../services/auth_service.dart';
import '../../../providers/auth_credentials_provider.dart';

/// Email verification pending
class EmailVerificationPendingScreen extends StatefulWidget {
  const EmailVerificationPendingScreen({super.key});

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen>
    with TickerProviderStateMixin {
  bool _isVerifying = false;
  String? _errorMessage;

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
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      final credentialsProvider =
          Provider.of<AuthCredentialsProvider>(context, listen: false);

      if (!credentialsProvider.hasCredentials) {
        throw Exception('Credentials not found. Please sign up again.');
      }

      final email = credentialsProvider.email!;
      final password = credentialsProvider.password!;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        if (user.emailConfirmedAt == null) {
          throw Exception(
              'Email not yet verified. Please check your email and click the verification link.');
        }

        credentialsProvider.clearCredentials();

        if (mounted) {
          await AuthService.handlePostLogin(context);
        }
      } else {
        throw Exception(
            'Email not yet verified. Please check your email and click the verification link.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Still not verified. Try again.';
        _isVerifying = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credentialsProvider = Provider.of<AuthCredentialsProvider>(context);
    final email = credentialsProvider.email ?? 'your email';

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
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: PepsGlassCard(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: ColorPalette.accentDim,
                          shape: BoxShape.circle,
                          border: Border.all(color: ColorPalette.accentBorder),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 40,
                          color: ColorPalette.gold,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Check your inbox',
                        style: GoogleFonts.sora(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.textPrimary,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "We've sent a verification link to $email. Please confirm your email to activate your account.",
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: ColorPalette.textSecondary,
                          height: 1.55,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: "I've verified →",
                        isLoading: _isVerifying,
                        isEnabled: !_isVerifying,
                        onPressed: _handleVerify,
                      ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
