import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/color_palette.dart';
import '../../../engine/models/peptide_recommendation.dart';
import '../../../services/supabase_client.dart';

/// Premium Peptide Details screen with all metadata from Supabase
class PeptideDetailsScreenNew extends StatefulWidget {
  final PeptideRecommendation recommendation;

  const PeptideDetailsScreenNew({
    super.key,
    required this.recommendation,
  });

  @override
  State<PeptideDetailsScreenNew> createState() =>
      _PeptideDetailsScreenNewState();
}

class _PeptideDetailsScreenNewState extends State<PeptideDetailsScreenNew>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _peptideData;
  bool _isLoading = true;
  String? _error;

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

    _loadPeptideData();
    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPeptideData() async {
    try {
      final response = await supabase
          .from('peptides')
          .select('*')
          .eq('id', widget.recommendation.peptideId)
          .single();

      setState(() {
        _peptideData = Map<String, dynamic>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load peptide details';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD1A057);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle radial gradient behind header
            Positioned(
              left: MediaQuery.of(context).size.width * 0.5 - 100,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      goldColor.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            FadeTransition(
              opacity: _pageFadeAnimation,
              child: SlideTransition(
                position: _pageSlideAnimation,
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: ColorPalette.textPrimary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(goldColor),
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
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                      24.0, 0.0, 24.0, 32.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header Section
                                      _HeaderSection(
                                        name: widget.recommendation.name,
                                        category: widget.recommendation.category,
                                        summary: widget.recommendation.summary,
                                      ),
                                      const SizedBox(height: 32),

                                      // Reasoning Card
                                      if (widget.recommendation.reasoning
                                          .isNotEmpty)
                                        _InfoCard(
                                          icon: Icons.lightbulb_outline,
                                          title: 'Why This Peptide',
                                          content: widget.recommendation.reasoning,
                                          color: goldColor,
                                        ),

                                      if (widget.recommendation.reasoning
                                          .isNotEmpty)
                                        const SizedBox(height: 20),

                                      // Description Card
                                      if (_peptideData?['description'] != null)
                                        _InfoCard(
                                          icon: Icons.description_outlined,
                                          title: 'Description',
                                          content:
                                              _peptideData!['description'] as String,
                                          color: goldColor,
                                        ),

                                      if (_peptideData?['description'] != null)
                                        const SizedBox(height: 20),

                                      // Benefits Card
                                      if (_peptideData?['benefits'] != null)
                                        _BenefitsCard(
                                          benefits: List<String>.from(
                                            _peptideData!['benefits']
                                                as List<dynamic>,
                                          ),
                                          shortBenefits:
                                              widget.recommendation.shortBenefits,
                                        ),

                                      if (_peptideData?['benefits'] != null)
                                        const SizedBox(height: 20),

                                      // Goals Supported
                                      if (_peptideData?['goals_supported'] != null)
                                        _TagsCard(
                                          icon: Icons.flag_outlined,
                                          title: 'Goals Supported',
                                          tags: List<String>.from(
                                            _peptideData!['goals_supported']
                                                as List<dynamic>,
                                          ),
                                          color: goldColor,
                                        ),

                                      if (_peptideData?['goals_supported'] != null)
                                        const SizedBox(height: 20),

                                      // Lifestyle Factors
                                      if (_peptideData?['lifestyle_supported'] !=
                                          null)
                                        _TagsCard(
                                          icon: Icons.fitness_center_outlined,
                                          title: 'Lifestyle Factors',
                                          tags: List<String>.from(
                                            _peptideData!['lifestyle_supported']
                                                as List<dynamic>,
                                          ),
                                          color: goldColor,
                                        ),

                                      if (_peptideData?['lifestyle_supported'] !=
                                          null)
                                        const SizedBox(height: 20),

                                      // Medical Flags
                                      if (_peptideData?['medical_flags'] != null &&
                                          (_peptideData!['medical_flags']
                                                  as List)
                                              .isNotEmpty)
                                        _TagsCard(
                                          icon: Icons.medical_services_outlined,
                                          title: 'Medical Considerations',
                                          tags: List<String>.from(
                                            _peptideData!['medical_flags']
                                                as List<dynamic>,
                                          ),
                                          color: Colors.orange,
                                          isWarning: true,
                                        ),

                                      if (_peptideData?['medical_flags'] != null &&
                                          (_peptideData!['medical_flags']
                                                  as List)
                                              .isNotEmpty)
                                        const SizedBox(height: 20),

                                      // Contraindications
                                      if (_peptideData?['contraindications'] !=
                                              null &&
                                          (_peptideData!['contraindications']
                                                  as List)
                                              .isNotEmpty)
                                        _TagsCard(
                                          icon: Icons.warning_amber_rounded,
                                          title: 'Contraindications',
                                          tags: List<String>.from(
                                            _peptideData!['contraindications']
                                                as List<dynamic>,
                                          ),
                                          color: Colors.red,
                                          isWarning: true,
                                        ),

                                      if (_peptideData?['contraindications'] !=
                                              null &&
                                          (_peptideData!['contraindications']
                                                  as List)
                                              .isNotEmpty)
                                        const SizedBox(height: 20),

                                      // Dosage & Frequency
                                      if (_peptideData?['dosage'] != null ||
                                          _peptideData?['frequency'] != null)
                                        _DosageCard(
                                          dosage: _peptideData?['dosage'] as String?,
                                          frequency:
                                              _peptideData?['frequency'] as String?,
                                        ),

                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
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

/// Premium header section
class _HeaderSection extends StatelessWidget {
  final String name;
  final String category;
  final String summary;

  const _HeaderSection({
    required this.name,
    required this.category,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD1A057);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: ColorPalette.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        // Category badge
        if (category.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: goldColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: goldColor,
              ),
            ),
          ),
        if (category.isNotEmpty) const SizedBox(height: 20),
        // Summary
        Text(
          summary,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: ColorPalette.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Reusable info card component
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: ColorPalette.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Benefits card with bullet points
class _BenefitsCard extends StatelessWidget {
  final List<String> benefits;
  final List<String> shortBenefits;

  const _BenefitsCard({
    required this.benefits,
    required this.shortBenefits,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD1A057);
    final displayBenefits = shortBenefits.isNotEmpty
        ? shortBenefits
        : benefits.take(5).toList();

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
          Row(
            children: [
              const Icon(Icons.star_outline, color: goldColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Benefits',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayBenefits.map((benefit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      benefit,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Tags card for goals, lifestyle, etc.
class _TagsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> tags;
  final Color color;
  final bool isWarning;

  const _TagsCard({
    required this.icon,
    required this.title,
    required this.tags,
    required this.color,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWarning
            ? color.withValues(alpha: 0.05)
            : ColorPalette.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isWarning
            ? Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
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
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isWarning
                      ? color.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Dosage and frequency card
class _DosageCard extends StatelessWidget {
  final String? dosage;
  final String? frequency;

  const _DosageCard({
    this.dosage,
    this.frequency,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD1A057);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldColor.withValues(alpha: 0.1),
            goldColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
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
          Row(
            children: [
              const Icon(Icons.medication_outlined, color: goldColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Dosage & Frequency',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ],
          ),
          if (dosage != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dosage: ',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                Expanded(
                  child: Text(
                    dosage!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (frequency != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frequency: ',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                Expanded(
                  child: Text(
                    frequency!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

