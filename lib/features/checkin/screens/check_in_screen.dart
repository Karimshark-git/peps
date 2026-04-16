import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/peps_glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/supabase_client.dart';

/// Weekly protocol check-in (persists to `public.check_ins`).
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  int _weekNumber = 1;
  bool _weekLoaded = false;

  double _energy = 5;
  double _sleep = 5;
  double _recovery = 5;
  double _mood = 5;
  double _overall = 5;

  final _sideEffectsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadWeekNumber();
  }

  @override
  void dispose() {
    _sideEffectsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWeekNumber() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        if (mounted) setState(() => _weekLoaded = true);
        return;
      }

      // users.id IS the auth UID — no intermediate lookup needed
      final firstOnboarding = await supabase
          .from('onboarding_responses')
          .select('created_at')
          .eq('user_id', authUser.id)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (firstOnboarding == null) {
        if (mounted) {
          setState(() {
            _weekNumber = 1;
            _weekLoaded = true;
          });
        }
        return;
      }

      final created =
          DateTime.parse(firstOnboarding['created_at'].toString());
      final weeksElapsed = DateTime.now().difference(created).inDays ~/ 7 + 1;

      if (mounted) {
        setState(() {
          _weekNumber = weeksElapsed.clamp(1, 999);
          _weekLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _weekLoaded = true);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        throw Exception('Not signed in');
      }

      // users.id IS the auth UID — use directly
      final userId = authUser.id;

      final sideText = _sideEffectsCtrl.text.trim();
      final userNotes = _notesCtrl.text.trim();

      final noteLines = <String>[];
      noteLines.add(
        'Overall protocol feeling (1-10): ${_overall.round()}',
      );
      if (userNotes.isNotEmpty) noteLines.add(userNotes);
      final combinedNotes = noteLines.join('\n\n');

      final e = _energy.round();
      final s = _sleep.round();
      final r = _recovery.round();
      final m = _mood.round();

      final flagged = e <= 3 ||
          s <= 3 ||
          r <= 3 ||
          m <= 3 ||
          sideText.isNotEmpty;

      await supabase.from('check_ins').insert({
        'user_id': userId,
        'week_number': _weekNumber,
        'energy_score': e,
        'sleep_score': s,
        'recovery_score': r,
        'mood_score': m,
        'side_effects': sideText.isEmpty ? null : sideText,
        'notes': combinedNotes,
        'flagged_for_physician': flagged,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in submitted ✓',
            style: GoogleFonts.sora(color: ColorPalette.buttonOnAccent),
          ),
          backgroundColor: ColorPalette.gold,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: GoogleFonts.sora(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: ColorPalette.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const _CheckInLogoMark(),
              const SizedBox(height: 20),
              Text(
                _weekLoaded
                    ? 'WEEK $_weekNumber CHECK-IN'
                    : 'WEEKLY CHECK-IN',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.gold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How has your protocol been this week?',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: ColorPalette.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 24),
              _SliderCard(
                label: 'ENERGY LEVEL',
                description: 'How energized have you felt?',
                value: _energy,
                onChanged: (v) => setState(() => _energy = v),
              ),
              const SizedBox(height: 12),
              _SliderCard(
                label: 'SLEEP QUALITY',
                description: 'How well have you been sleeping?',
                value: _sleep,
                onChanged: (v) => setState(() => _sleep = v),
              ),
              const SizedBox(height: 12),
              _SliderCard(
                label: 'RECOVERY SPEED',
                description:
                    'How quickly are you recovering from training?',
                value: _recovery,
                onChanged: (v) => setState(() => _recovery = v),
              ),
              const SizedBox(height: 12),
              _SliderCard(
                label: 'MOOD & FOCUS',
                description:
                    'How has your mental clarity and mood been?',
                value: _mood,
                onChanged: (v) => setState(() => _mood = v),
              ),
              const SizedBox(height: 12),
              _SliderCard(
                label: 'OVERALL FEELING',
                description: 'Overall, how do you feel on your protocol?',
                value: _overall,
                onChanged: (v) => setState(() => _overall = v),
              ),
              const SizedBox(height: 20),
              Text(
                'SIDE EFFECTS (IF ANY)',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.gold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _GlassTextField(
                controller: _sideEffectsCtrl,
                hint:
                    'Describe anything unusual, or leave blank if none',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'ADDITIONAL NOTES',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: ColorPalette.gold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _GlassTextField(
                controller: _notesCtrl,
                hint:
                    'Anything else you want your physician to know?',
                maxLines: 3,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Submit check-in →',
                isLoading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInLogoMark extends StatelessWidget {
  const _CheckInLogoMark();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.sora(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: ColorPalette.textPrimary,
    );
    final teal = GoogleFonts.sora(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: ColorPalette.gold,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'pe', style: base),
          TextSpan(text: 'p', style: teal),
          TextSpan(text: 's', style: base),
        ],
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String label;
  final String description;
  final double value;
  final ValueChanged<double> onChanged;

  const _SliderCard({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PepsGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.gold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: ColorPalette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.round()}',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: ColorPalette.gold,
              inactiveTrackColor: ColorPalette.progressBackground,
              thumbColor: ColorPalette.gold,
              overlayColor: ColorPalette.gold.withValues(alpha: 0.2),
              trackHeight: 3,
            ),
            child: Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: value.clamp(1, 10),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return PepsGlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColorPalette.textPrimary,
          height: 1.45,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.sora(
            fontSize: 14,
            color: ColorPalette.textTertiary,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
