import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

/// Uppercase DM Mono section label in teal
class PepsSectionLabel extends StatelessWidget {
  final String text;

  const PepsSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyles.sectionLabelMono,
    );
  }
}
