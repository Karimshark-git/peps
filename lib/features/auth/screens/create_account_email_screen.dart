import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../services/supabase_client.dart';
import '../../../app_router.dart';
import '../../../providers/auth_credentials_provider.dart';

/// Email signup screen for account creation
class CreateAccountEmailScreen extends StatefulWidget {
  const CreateAccountEmailScreen({super.key});

  @override
  State<CreateAccountEmailScreen> createState() =>
      _CreateAccountEmailScreenState();
}

class _CreateAccountEmailScreenState extends State<CreateAccountEmailScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://example.com/verify',
      );

      // Store credentials for verification screen
      final credentialsProvider =
          Provider.of<AuthCredentialsProvider>(context, listen: false);
      credentialsProvider.setCredentials(email, password);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.emailVerificationPending,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageFadeAnimation,
          child: SlideTransition(
            position: _pageSlideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'Create Account',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      'Sign up to access your personalized protocol.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email field
                    _EmailTextField(
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    _PasswordTextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      label: 'Password',
                      onToggleVisibility: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password field
                    _PasswordTextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      label: 'Confirm Password',
                      onToggleVisibility: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Create Account button
                    _AuthButton(
                      text: 'Create Account',
                      onPressed: _handleCreateAccount,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Email text field
class _EmailTextField extends StatelessWidget {
  final TextEditingController controller;

  const _EmailTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'your@email.com',
        prefixIcon: const Icon(Icons.email_outlined, color: ColorPalette.gold),
        filled: true,
        fillColor: ColorPalette.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: ColorPalette.gold, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: ColorPalette.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          color: ColorPalette.textPlaceholder,
        ),
      ),
      style: GoogleFonts.inter(
        color: ColorPalette.textPrimary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }
}

/// Password text field
class _PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final String label;
  final VoidCallback onToggleVisibility;

  const _PasswordTextField({
    required this.controller,
    required this.obscureText,
    required this.label,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline, color: ColorPalette.gold),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: ColorPalette.textSecondary,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: ColorPalette.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: ColorPalette.gold, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: ColorPalette.textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          color: ColorPalette.textPlaceholder,
        ),
      ),
      style: GoogleFonts.inter(
        color: ColorPalette.textPrimary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}

/// Auth button
class _AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const _AuthButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

