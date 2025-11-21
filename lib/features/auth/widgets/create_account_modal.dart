import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_palette.dart';
import '../../../app_router.dart';
import '../../../services/supabase_client.dart';

/// Beautiful animated modal for account creation
class CreateAccountModal extends StatelessWidget {
  const CreateAccountModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: ColorPalette.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ColorPalette.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Header
                        Text(
                          'Your personalized protocol is ready',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.textPrimary,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        Text(
                          'Create your account to continue. A licensed doctor will finalize your plan.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: ColorPalette.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Google button
                        _GoogleAuthButton(
                          onAuthStateChange: () {
                            // Close modal when auth state changes
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Email button
                        _AuthButton(
                          text: 'Create Account with Email',
                          icon: Icons.email_outlined,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            // Close modal and navigate to create account email screen
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRouter.createAccountEmail,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
}

/// Google OAuth button that handles signup/login
class _GoogleAuthButton extends StatefulWidget {
  final VoidCallback onAuthStateChange;

  const _GoogleAuthButton({required this.onAuthStateChange});

  @override
  State<_GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<_GoogleAuthButton> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      // Close modal first
      widget.onAuthStateChange();
      
      // Then initiate OAuth
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.peps://login-callback',
      );
      // Note: OAuth will redirect, so we won't reach here in web/mobile
      // The callback handler in main/login screen should call handlePostLogin
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with Google: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    return _AuthButton(
      text: 'Continue with Google',
      icon: Icons.g_mobiledata,
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      isLoading: _isLoading,
    );
  }
}

/// Premium auth button with gradient
class _AuthButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _AuthButton({
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorPalette.gold,
                    ColorPalette.gold.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        if (widget.isLoading || widget.icon != Icons.g_mobiledata)
                          const SizedBox(width: 12),
                        if (widget.isLoading)
                          Text(
                            'Loading...',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          )
                        else
                          Text(
                            widget.text,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
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

