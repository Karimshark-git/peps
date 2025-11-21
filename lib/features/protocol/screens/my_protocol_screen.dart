import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../services/supabase_client.dart';

/// My Protocol screen showing user's recommendations
class MyProtocolScreen extends StatefulWidget {
  const MyProtocolScreen({super.key});

  @override
  State<MyProtocolScreen> createState() => _MyProtocolScreenState();
}

class _MyProtocolScreenState extends State<MyProtocolScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageAnimationController;
  late Animation<double> _pageFadeAnimation;
  late Animation<Offset> _pageSlideAnimation;
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String? _error;

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
    _loadRecommendations();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Get user ID from users table
      final userResponse = await supabase
          .from('users')
          .select('id')
          .eq('auth_uid', user.id)
          .single();

      final userId = userResponse['id'] as String;

      // Fetch recommendations with peptide details
      final response = await supabase
          .from('recommendations')
          .select('''
            *,
            peptides (
              id,
              name,
              category,
              description,
              summary,
              benefits,
              short_benefits,
              dosage,
              frequency
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _recommendations = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load recommendations: ${e.toString()}';
        _isLoading = false;
      });
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'My Protocol',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorPalette.gold,
                              ),
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : _recommendations.isEmpty
                                ? Center(
                                    child: Text(
                                      'No recommendations yet.\nComplete your onboarding to get personalized recommendations.',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: ColorPalette.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _recommendations.length,
                                    itemBuilder: (context, index) {
                                      final recommendation =
                                          _recommendations[index];
                                      final peptide = recommendation['peptides']
                                          as Map<String, dynamic>?;

                                      if (peptide == null) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index <
                                                  _recommendations.length - 1
                                              ? 16
                                              : 0,
                                        ),
                                        child: _PeptideCard(
                                          peptide: peptide,
                                          reasoning: recommendation['reasoning']
                                              as String?,
                                        ),
                                      );
                                    },
                                  ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Peptide recommendation card
class _PeptideCard extends StatelessWidget {
  final Map<String, dynamic> peptide;
  final String? reasoning;

  const _PeptideCard({
    required this.peptide,
    this.reasoning,
  });

  @override
  Widget build(BuildContext context) {
    final name = peptide['name'] as String? ?? 'Unknown';
    final category = peptide['category'] as String? ?? '';
    final description = peptide['description'] as String? ?? '';
    final summary = peptide['summary'] as String? ?? '';
    final shortBenefits = List<String>.from(
      peptide['short_benefits'] as List<dynamic>? ?? [],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorPalette.cardBackground,
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
          // Name
          Text(
            name,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ColorPalette.textPrimary,
              height: 1.2,
            ),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Category
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: ColorPalette.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Summary or description
          Text(
            summary.isNotEmpty ? summary : description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textSecondary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // Short benefits (top 2)
          if (shortBenefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...shortBenefits.take(2).map((benefit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: ColorPalette.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        benefit,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: ColorPalette.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          if (reasoning != null && reasoning!.isNotEmpty) ...[
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
                    Icons.lightbulb_outline,
                    size: 16,
                    color: ColorPalette.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reasoning!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
        ],
      ),
    );
  }
}

