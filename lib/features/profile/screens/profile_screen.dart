import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../services/supabase_client.dart';
import '../../../services/protocol_service.dart';
import '../../../app_router.dart';

/// Health Profile screen for authenticated users
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _onboardingData;
  bool _isLoggingOut = false;

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
    _loadProfileData();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        // Redirect to welcome/login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.welcome,
            (route) => false,
          );
        }
        return;
      }

      final profileData = await ProtocolService.fetchUserProfileData();

      setState(() {
        _userData = profileData['user'] as Map<String, dynamic>?;
        _onboardingData = profileData['onboarding'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      await supabase.auth.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  /// Gets user initials from email
  String _getInitials() {
    final email = _userData?['email'] as String? ?? '';
    if (email.isEmpty) return 'P';
    final parts = email.split('@');
    if (parts.isEmpty) return 'P';
    final firstPart = parts[0];
    if (firstPart.isEmpty) return 'P';
    return firstPart[0].toUpperCase();
  }

  /// Formats created_at date
  String _formatMemberSince() {
    final createdAt = _userData?['created_at'];
    if (createdAt == null) return 'Recently';
    try {
      final date = DateTime.parse(createdAt.toString());
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageFadeAnimation,
          child: SlideTransition(
            position: _pageSlideAnimation,
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.gold),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: ColorPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: ColorPalette.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              "We couldn't load your profile right now.",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ColorPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final hasOnboardingData = _onboardingData != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Title
          Text(
            'Your Profile',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          // Header Card - Your Peps ID
          _HeaderCard(
            email: _userData?['email'] as String? ?? 'No email',
            memberSince: _formatMemberSince(),
            initials: _getInitials(),
          ),
          const SizedBox(height: 24),
          // Biometrics Card
          if (hasOnboardingData)
            _BiometricsCard(onboardingData: _onboardingData!)
          else
            _EmptySectionCard(
              title: 'Biometrics',
              message:
                  'No data available yet. Your protocol will appear here after you complete onboarding.',
            ),
          const SizedBox(height: 24),
          // Goals Card
          if (hasOnboardingData)
            _GoalsCard(onboardingData: _onboardingData!)
          else
            _EmptySectionCard(
              title: 'Goals',
              message:
                  'No data available yet. Your protocol will appear here after you complete onboarding.',
            ),
          const SizedBox(height: 24),
          // Lifestyle Factors Card
          if (hasOnboardingData)
            _LifestyleCard(onboardingData: _onboardingData!)
          else
            _EmptySectionCard(
              title: 'Lifestyle Factors',
              message:
                  'No data available yet. Your protocol will appear here after you complete onboarding.',
            ),
          const SizedBox(height: 24),
          // Medical Conditions Card
          if (hasOnboardingData)
            _MedicalConditionsCard(onboardingData: _onboardingData!)
          else
            _EmptySectionCard(
              title: 'Medical Considerations',
              message:
                  'No data available yet. Your protocol will appear here after you complete onboarding.',
            ),
          const SizedBox(height: 24),
          // Account Actions Card
          _AccountActionsCard(
            onLogout: _handleLogout,
            isLoggingOut: _isLoggingOut,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Header Card - Your Peps ID
class _HeaderCard extends StatelessWidget {
  final String email;
  final String memberSince;
  final String initials;

  const _HeaderCard({
    required this.email,
    required this.memberSince,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8F3EC),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ColorPalette.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorPalette.gold,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.gold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Email and member since
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Peps ID',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Member since $memberSince',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Biometrics Card
class _BiometricsCard extends StatelessWidget {
  final Map<String, dynamic> onboardingData;

  const _BiometricsCard({required this.onboardingData});

  @override
  Widget build(BuildContext context) {
    final age = onboardingData['age'] as int?;
    final heightCm = onboardingData['height_cm'] as int?;
    final weightKg = onboardingData['weight_kg'] as int?;
    final activityLevel = onboardingData['activity_level'] as String?;

    final hasAnyData = age != null ||
        heightCm != null ||
        weightKg != null ||
        (activityLevel != null && activityLevel.isNotEmpty);

    if (!hasAnyData) {
      return _EmptySectionCard(
        title: 'Biometrics',
        message: 'No biometric data recorded yet.',
      );
    }

    return _SectionCard(
      title: 'Biometrics',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          if (age != null)
            _BiometricChip(
              label: 'Age',
              value: '$age years',
            ),
          if (heightCm != null)
            _BiometricChip(
              label: 'Height',
              value: '$heightCm cm',
            ),
          if (weightKg != null)
            _BiometricChip(
              label: 'Weight',
              value: '$weightKg kg',
            ),
          if (activityLevel != null && activityLevel.isNotEmpty)
            _BiometricChip(
              label: 'Activity Level',
              value: activityLevel,
            ),
        ],
      ),
    );
  }
}

/// Biometric chip widget
class _BiometricChip extends StatelessWidget {
  final String label;
  final String value;

  const _BiometricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorPalette.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ColorPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Goals Card
class _GoalsCard extends StatelessWidget {
  final Map<String, dynamic> onboardingData;

  const _GoalsCard({required this.onboardingData});

  @override
  Widget build(BuildContext context) {
    final goals = List<String>.from(
      onboardingData['goals'] as List<dynamic>? ?? [],
    );

    if (goals.isEmpty) {
      return _EmptySectionCard(
        title: 'Goals',
        message: 'No goals recorded yet.',
      );
    }

    return _SectionCard(
      title: 'Goals',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: goals.map((goal) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: ColorPalette.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ColorPalette.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              goal,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorPalette.gold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Lifestyle Factors Card
class _LifestyleCard extends StatelessWidget {
  final Map<String, dynamic> onboardingData;

  const _LifestyleCard({required this.onboardingData});

  @override
  Widget build(BuildContext context) {
    final lifestyleFactors = List<String>.from(
      onboardingData['lifestyle_factors'] as List<dynamic>? ?? [],
    );

    if (lifestyleFactors.isEmpty) {
      return _EmptySectionCard(
        title: 'Lifestyle Factors',
        message: 'No lifestyle factors recorded.',
      );
    }

    return _SectionCard(
      title: 'Lifestyle Factors',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: lifestyleFactors.map((factor) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: ColorPalette.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              factor,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorPalette.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Medical Conditions Card
class _MedicalConditionsCard extends StatelessWidget {
  final Map<String, dynamic> onboardingData;

  const _MedicalConditionsCard({required this.onboardingData});

  @override
  Widget build(BuildContext context) {
    final medicalConditions = List<String>.from(
      onboardingData['medical_conditions'] as List<dynamic>? ?? [],
    );

    final hasNone = medicalConditions.contains('None of the above') ||
        medicalConditions.isEmpty;

    return _SectionCard(
      title: 'Medical Considerations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasNone)
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: ColorPalette.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  'No medical conditions reported.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medicalConditions.map((condition) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorPalette.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorPalette.textSecondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: ColorPalette.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        condition,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPalette.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: ColorPalette.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Final decisions are always made by your clinician based on full medical review.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Account Actions Card
class _AccountActionsCard extends StatelessWidget {
  final VoidCallback onLogout;
  final bool isLoggingOut;

  const _AccountActionsCard({
    required this.onLogout,
    required this.isLoggingOut,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Account',
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoggingOut ? null : onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Log Out',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable section card
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Empty section card
class _EmptySectionCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptySectionCard({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColorPalette.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}
