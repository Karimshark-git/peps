import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/navigation/app_page_transitions.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_client.dart';
import '../../../app_router.dart';
import 'email_login_screen.dart';

/// Premium login screen with Google and Email options
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Page entrance animation
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

    // Listen for OAuth callbacks
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        // OAuth callback successful - handle post login
        AuthService.handlePostLogin(context);
      }
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.peps://login-callback',
      );
      // Note: OAuth will redirect, so we won't reach here in web/mobile
      // The callback handler should call handlePostLogin
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing in with Google: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEmailLogin() {
    Navigator.push(
      context,
      AppPageTransitions.cardPushRoute(
        const EmailLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.textPrimary),
          onPressed: () {
            // Simply go back to previous screen
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageFadeAnimation,
          child: SlideTransition(
            position: _pageSlideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: ColorPalette.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa,
                      size: 40,
                      color: ColorPalette.gold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Welcome to PEPS',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: ColorPalette.textPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Sign in to view your personalized protocol',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Google Sign In Button
                  _AuthButton(
                    text: 'Continue with Google',
                    icon: Icons.g_mobiledata,
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Email Sign In Button
                  _AuthButton(
                    text: 'Continue with Email',
                    icon: Icons.email_outlined,
                    onPressed: _isLoading ? null : _navigateToEmailLogin,
                    isLoading: false,
                  ),
                  const SizedBox(height: 24),
                  
                  // Skip for now option
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              // Go back to protocol screen
                              Navigator.of(context).popUntil((route) {
                                return route.settings.name == AppRouter.protocol || route.isFirst;
                              });
                            },
                      child: Text(
                        'Continue without account',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: ColorPalette.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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

