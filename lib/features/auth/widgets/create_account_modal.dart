import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app_router.dart';
import '../../../core/theme/color_palette.dart';
import '../../../services/supabase_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

class CreateAccountModal extends StatelessWidget {
  const CreateAccountModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.55,
          maxChildSize: 0.92,
          snap: true,
          snapSizes: const [0.72, 0.92],
          builder: (context, scrollController) => _ModalSheet(
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ModalSheet extends StatelessWidget {
  const _ModalSheet({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.accent.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: -8,
            offset: const Offset(0, -12),
          ),
          const BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            // Teal ambient glow behind content
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 300,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ColorPalette.accent.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 14, bottom: 28),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Emblem ──────────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              ColorPalette.accent.withValues(alpha: 0.22),
                              ColorPalette.accent.withValues(alpha: 0.06),
                            ],
                          ),
                          border: Border.all(
                            color: ColorPalette.accent.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: ColorPalette.accent,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Headline ─────────────────────────────────────────────
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Your protocol\nis ',
                            style: GoogleFonts.sora(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.textPrimary,
                              height: 1.18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'ready.',
                            style: GoogleFonts.sora(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.accent,
                              height: 1.18,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // ── Subtitle ─────────────────────────────────────────────
                    Text(
                      'Save your personalised peptide stack and get it reviewed by a licensed physician.',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // ── Trust badges ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const _TrustChip(
                            icon: Icons.lock_outline_rounded,
                            label: 'Encrypted',
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          const _TrustChip(
                            icon: Icons.medical_services_outlined,
                            label: 'Physician-reviewed',
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          const _TrustChip(
                            icon: Icons.shield_outlined,
                            label: 'DHA',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Google button ────────────────────────────────────────
                    _GoogleAuthButton(
                      onDismiss: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 14),

                    // ── Divider ──────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              color: ColorPalette.textTertiary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Email button ─────────────────────────────────────────
                    _EmailButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRouter.createAccountEmail);
                      },
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

// ─────────────────────────────────────────────────────────────────────────────
// Trust chip
// ─────────────────────────────────────────────────────────────────────────────

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: ColorPalette.accent),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: ColorPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google auth button
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleAuthButton extends StatefulWidget {
  const _GoogleAuthButton({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  State<_GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<_GoogleAuthButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
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

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Get OAuth URL — generates & stores the PKCE code verifier
      final oauthResponse = await supabase.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: 'io.supabase.peps://login-callback',
      );

      // Dismiss modal before opening browser
      widget.onDismiss();

      // ASWebAuthenticationSession — auto-closes when redirect fires
      final callbackUrl = await FlutterWebAuth2.authenticate(
        url: oauthResponse.url,
        callbackUrlScheme: 'io.supabase.peps',
      );

      // Exchange PKCE code → session → onAuthStateChange → handlePostLogin
      await supabase.auth.getSessionFromUrl(Uri.parse(callbackUrl));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        if (!_isLoading) _handleGoogleSignIn();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Top highlight line
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
                          Colors.white.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: _isLoading
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
// Email button
// ─────────────────────────────────────────────────────────────────────────────

class _EmailButton extends StatefulWidget {
  const _EmailButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_EmailButton> createState() => _EmailButtonState();
}

class _EmailButtonState extends State<_EmailButton>
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
      onTapDown: (_) => _scaleCtrl.forward(),
      onTapUp: (_) {
        _scaleCtrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            height: 58,
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
                  'Continue with Email',
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
    final sw = r * 0.38; // stroke width as ~38% of radius
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

    // Flutter canvas: 0° = 3 o'clock, clockwise.
    // The G opening sits at ~345°→15° (right side).
    // Going clockwise from the opening:
    arc(_blue, 15, 95);   // blue  — right top to bottom
    arc(_green, 110, 40); // green — lower right
    arc(_yellow, 150, 80);// yellow — bottom to left
    arc(_red, 230, 115);  // red   — left to top

    // Crossbar (horizontal bar into the G)
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
