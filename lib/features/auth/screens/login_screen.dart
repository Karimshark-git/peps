import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app_router.dart';
import '../../../core/navigation/app_page_transitions.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/peps_ambient_orbs.dart';
import '../../../core/widgets/peps_min_height_scroll_view.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_client.dart';
import 'email_login_screen.dart';

/// Login — Google, email, skip
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;
  bool _isGoogleLoading = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _pageAnimationController.forward();

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null && mounted) {
        AuthService.handlePostLogin(context);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final oauthResponse = await supabase.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: 'io.supabase.peps://login-callback',
      );

      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: oauthResponse.url,
        callbackUrlScheme: 'io.supabase.peps',
      );

      await supabase.auth.getSessionFromUrl(Uri.parse(callbackUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _navigateToEmailLogin() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      AppPageTransitions.cardPushRoute(const EmailLoginScreen()),
    );
  }

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
                child: PepsMinHeightScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top: back + logo ──────────────────────────────────
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 18,
                                color: Color(0x8CFFFFFF),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _LoginLogoBlock(),
                          const SizedBox(height: 48),
                        ],
                      ),

                      // ── Middle: headline + buttons ────────────────────────
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome back',
                            style: GoogleFonts.sora(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.textPrimary,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to your personalised protocol',
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: ColorPalette.textSecondary,
                              height: 1.55,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 44),
                          _GoogleLoginButton(
                            isLoading: _isGoogleLoading,
                            onPressed:
                                _isGoogleLoading ? null : _handleGoogleSignIn,
                          ),
                          const SizedBox(height: 16),
                          const _OrDivider(),
                          const SizedBox(height: 16),
                          _EmailLoginButton(
                            onPressed:
                                _isGoogleLoading ? null : _navigateToEmailLogin,
                          ),
                        ],
                      ),

                      // ── Bottom: skip ──────────────────────────────────────
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0x4DFFFFFF),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _isGoogleLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).popUntil((route) {
                                        return route.settings.name ==
                                                AppRouter.protocol ||
                                            route.isFirst;
                                      });
                                    },
                              child: Text(
                                'Continue without account',
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0x4DFFFFFF),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Logo block
// ─────────────────────────────────────────────────────────────────────────────

class _LoginLogoBlock extends StatelessWidget {
  const _LoginLogoBlock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Teal ambient glow behind logo
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorPalette.accent.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'pe',
                      style: GoogleFonts.sora(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: 'p',
                      style: GoogleFonts.sora(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.accent,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: 's',
                      style: GoogleFonts.sora(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PEPTIDE PROTOCOLS · UAE',
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0x4DFFFFFF),
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Or divider
// ─────────────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.08),
            thickness: 1,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.08),
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google login button
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLoginButton extends StatefulWidget {
  const _GoogleLoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  State<_GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<_GoogleLoginButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) _scaleCtrl.forward();
      },
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.accent.withValues(alpha: 0.06),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top shimmer highlight
                Positioned(
                  top: 0,
                  left: 32,
                  right: 32,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorPalette.accent,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _GoogleGLogo(size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: ColorPalette.textPrimary,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Email login button
// ─────────────────────────────────────────────────────────────────────────────

class _EmailLoginButton extends StatefulWidget {
  const _EmailLoginButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  State<_EmailLoginButton> createState() => _EmailLoginButtonState();
}

class _EmailLoginButtonState extends State<_EmailLoginButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) _scaleCtrl.forward();
      },
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: ColorPalette.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorPalette.accent.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 20,
                  color: ColorPalette.accent.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sign in with Email',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.accent,
                    letterSpacing: -0.1,
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

// ─────────────────────────────────────────────────────────────────────────────
// Official Google G logo — custom painted
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;
    final sw = r * 0.38;
    final midR = r - sw / 2;

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: midR);

    void arc(Color color, double startDeg, double sweepDeg) {
      canvas.drawArc(
        arcRect,
        startDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt
          ..color = color,
      );
    }

    arc(_blue, 15, 95);
    arc(_green, 110, 40);
    arc(_yellow, 150, 80);
    arc(_red, 230, 115);

    final barH = sw;
    final barTop = cy - barH / 2;
    canvas.drawRect(
      Rect.fromLTRB(cx, barTop, cx + midR + sw * 0.5, barTop + barH),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
