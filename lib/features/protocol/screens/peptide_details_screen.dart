import 'package:flutter/material.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/color_palette.dart';
import '../../onboarding/models/onboarding_model.dart';
import '../data/peptides.dart';
import '../engine/protocol_engine.dart';

/// Peptide details screen - Shows full information about a peptide
class PeptideDetailsScreen extends StatelessWidget {
  final Peptide peptide;
  final OnboardingModel model;

  const PeptideDetailsScreen({
    super.key,
    required this.peptide,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final whyRecommended = ProtocolEngine.getWhyRecommended(peptide, model);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorPalette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Name
              Text(
                peptide.name,
                style: TextStyles.headingLarge,
              ),
              const SizedBox(height: 8),
              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorPalette.softBeige,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  peptide.category,
                  style: TextStyles.bodySmall.copyWith(
                    color: ColorPalette.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Why Recommended
              _DetailSection(
                title: 'Why Recommended',
                content: whyRecommended,
              ),
              const SizedBox(height: 24),
              // Description
              _DetailSection(
                title: 'Description',
                content: peptide.description,
              ),
              const SizedBox(height: 24),
              // Mechanism
              _DetailSection(
                title: 'How It Works',
                content: peptide.mechanism,
              ),
              const SizedBox(height: 24),
              // Benefits
              _DetailSection(
                title: 'Benefits',
                content: peptide.benefits,
                isList: true,
              ),
              const SizedBox(height: 24),
              // Dosage
              _DetailSection(
                title: 'Dosage',
                content: peptide.dosage,
              ),
              const SizedBox(height: 24),
              // Frequency
              _DetailSection(
                title: 'Frequency',
                content: peptide.frequency,
              ),
              const SizedBox(height: 32),
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.softBeige.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Important: This protocol is for informational purposes only. Please consult with a qualified healthcare provider before starting any peptide protocol.',
                  style: TextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: ColorPalette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail section widget
class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final bool isList;

  const _DetailSection({
    required this.title,
    required this.content,
    this.isList = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.headingSmall,
        ),
        const SizedBox(height: 12),
        if (isList)
          ...content.split(',').map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyles.bodyMedium.copyWith(
                      color: ColorPalette.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.trim(),
                      style: TextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList()
        else
          Text(
            content,
            style: TextStyles.bodyMedium,
          ),
      ],
    );
  }
}

