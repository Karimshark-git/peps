import 'dart:convert';

import 'package:http/http.dart' as http;

import '../env/supabase_env.dart';
import '../features/onboarding/models/onboarding_model.dart';
import 'models/peptide_recommendation.dart';

class AiProtocolEngine {
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-haiku-4-5-20251001';

  static Future<List<PeptideRecommendation>> generateProtocol({
    required OnboardingModel onboarding,
    required List<Map<String, dynamic>> peptideCatalog,
    int maxRecommendations = 3,
  }) async {
    final userProfile = _buildUserProfile(onboarding);
    final catalogJson = _buildCatalogJson(peptideCatalog);
    final systemPrompt = _buildSystemPrompt();
    final userMessage = _buildUserMessage(
      userProfile: userProfile,
      catalogJson: catalogJson,
      maxRecommendations: maxRecommendations,
    );

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2048,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Anthropic API error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final blocks = data['content'] as List<dynamic>? ?? [];
    String rawText = '';
    for (final block in blocks) {
      final m = block as Map<String, dynamic>;
      if (m['type'] == 'text' && m['text'] != null) {
        rawText = m['text'] as String;
        break;
      }
    }
    if (rawText.isEmpty) {
      throw Exception('Anthropic API returned no text content');
    }

    return _parseResponse(rawText, peptideCatalog);
  }

  static String _buildSystemPrompt() => '''
You are the PEPS Clinical AI — a precision wellness protocol engine for 
a physician-supervised peptide telehealth platform operating in the UAE 
under DHA (Dubai Health Authority) guidelines.

Your role is to analyze a user's health profile and recommend the optimal 
peptide protocol from the available catalog. Your recommendations will be 
reviewed and approved by a licensed DHA physician before any prescription 
is issued. You are an advisory system — the physician makes the final call.

CORE PRINCIPLES:
- Prioritize safety above all else
- Flag contraindications clearly and explicitly  
- Match peptides to goals with clinical reasoning
- Consider lifestyle factors and biometric context
- Never recommend more than the requested number of peptides
- Always structure output as valid JSON — no prose, no markdown, no preamble

CONTRAINDICATION RULES (hard stops — never recommend if present):
- Active malignancy → no GH-axis peptides (CJC-1295, GHRP-2, GHRP-6, 
  IGF-1 LR3, Follistatin-344, TB-500)
- Unstable cardiovascular disease → no PT-141, GHRP-6, Tesofensine, 
  Semaglutide
- Pregnancy → no AOD-9604, Semaglutide
- Active autoimmune condition → flag BPC-157, Thymosin Alpha-1 for 
  physician review with elevated caution
- Severe psychiatric illness → no Selank, Oxytocin without specialist input
- Uncontrolled hypertension → no PT-141, Tesofensine
- History of pancreatitis → no Semaglutide

SCORING GUIDANCE:
- Primary goal match: highest weight (40%)
- Secondary goal overlap: medium weight (25%)  
- Lifestyle factor alignment: medium weight (20%)
- Absence of contraindications: critical gate (pass/fail)
- Biometric suitability: lower weight (15%)

OUTPUT FORMAT — respond with ONLY this JSON structure, nothing else:
{
  "protocol_summary": "2-3 sentence plain-language summary of the overall 
    protocol rationale for this user",
  "recommendations": [
    {
      "peptide_id": "uuid from catalog",
      "peptide_name": "exact name from catalog",
      "rank": 1,
      "confidence": "high|medium|low",
      "primary_goal_match": "the specific goal this addresses",
      "reasoning": "2-3 sentence clinical reasoning for this user 
        specifically — reference their goals, lifestyle, and any 
        relevant biometrics",
      "patient_summary": "1-2 sentence plain-language explanation 
        for the patient (non-clinical, reassuring tone)",
      "contraindication_flags": [],
      "dosage": "dosage from catalog",
      "frequency": "frequency from catalog",
      "cycle_length": "cycle_length from catalog",
      "stack_note": "optional: how this peptide interacts with 
        others in the stack"
    }
  ],
  "physician_notes": "Clinical summary for the reviewing physician — 
    flag anything requiring extra scrutiny, note any borderline 
    contraindications, suggest any follow-up questions",
  "safety_cleared": true
}
''';

  static String _buildUserMessage({
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> catalogJson,
    required int maxRecommendations,
  }) =>
      '''
Analyze this user profile and select the best $maxRecommendations peptides 
from the catalog below.

USER PROFILE:
${jsonEncode(userProfile)}

AVAILABLE PEPTIDE CATALOG:
${jsonEncode(catalogJson)}

Return ONLY the JSON protocol. No prose. No markdown. No explanation 
outside the JSON structure. The JSON must be valid and parseable.
''';

  static Map<String, dynamic> _buildUserProfile(OnboardingModel model) {
    final lifestyle = <String>[];
    if (model.lifestyle.containsKey('factors')) {
      final f = model.lifestyle['factors'];
      if (f is List) lifestyle.addAll(f.whereType<String>());
    }

    final medical = <String>[];
    if (model.medical.containsKey('conditions')) {
      final c = model.medical['conditions'];
      if (c is List) medical.addAll(c.whereType<String>());
    }

    return {
      'first_name': model.firstName ?? 'User',
      'goals': model.goals,
      'age': model.age,
      'height_cm': model.height?.toInt(),
      'weight_kg': model.weight?.toInt(),
      'activity_level': model.activityLevel,
      'lifestyle_factors': lifestyle,
      'medical_conditions': medical,
      'bmi': (model.height != null && model.weight != null)
          ? _calcBmi(model.weight!, model.height!)
          : null,
    };
  }

  static double _calcBmi(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return double.parse(
      (weightKg / (heightM * heightM)).toStringAsFixed(1),
    );
  }

  static List<Map<String, dynamic>> _buildCatalogJson(
    List<Map<String, dynamic>> peptides,
  ) =>
      peptides
          .where((p) => p['is_active'] == true || p['is_active'] == null)
          .map((p) => {
                'id': p['id'],
                'name': p['name'],
                'category': p['category'],
                'summary': p['summary'],
                'goals_supported': p['goals_supported'] ?? [],
                'lifestyle_supported': p['lifestyle_supported'] ?? [],
                'medical_flags': p['medical_flags'] ?? [],
                'contraindications': p['contraindications'] ?? [],
                'dosage': p['dosage'],
                'frequency': p['frequency'],
                'cycle_length': p['cycle_length'],
                'risk_level': p['risk_level'] ?? 'low',
                'reasoning_template': p['reasoning_template'],
              })
          .toList();

  static Map<String, dynamic>? _catalogRowById(
    String id,
    List<Map<String, dynamic>> catalog,
  ) {
    for (final p in catalog) {
      if (p['id']?.toString() == id) return p;
    }
    return null;
  }

  static List<PeptideRecommendation> _parseResponse(
    String rawText,
    List<Map<String, dynamic>> catalog,
  ) {
    var cleaned = rawText.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'^```[a-z]*\n?'), '')
          .replaceAll(RegExp(r'\n?```$'), '')
          .trim();
    }

    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    final recs = parsed['recommendations'] as List<dynamic>? ?? [];

    final out = <PeptideRecommendation>[];
    for (final item in recs) {
      final rec = item as Map<String, dynamic>;
      final id = rec['peptide_id']?.toString() ?? '';
      final row = _catalogRowById(id, catalog);
      final name = (rec['peptide_name'] as String?)?.trim().isNotEmpty == true
          ? rec['peptide_name'] as String
          : (row?['name'] as String? ?? '');
      final rank = (rec['rank'] as num?)?.toInt() ?? out.length + 1;
      final shortBenefits = List<String>.from(
        row?['short_benefits'] as List<dynamic>? ?? [],
      );

      String pickStr(dynamic fromAi, dynamic fromRow) {
        final a = fromAi?.toString().trim() ?? '';
        if (a.isNotEmpty) return a;
        final b = fromRow?.toString().trim() ?? '';
        return b;
      }

      out.add(
        PeptideRecommendation(
          peptideId: id,
          name: name,
          summary: row?['summary'] as String? ?? '',
          reasoning: rec['reasoning'] as String? ?? '',
          score: (11 - rank).clamp(0, 10).toDouble(),
          category: row?['category'] as String? ?? '',
          shortBenefits: shortBenefits,
          patientSummary: rec['patient_summary'] as String? ?? '',
          confidence: rec['confidence'] as String? ?? 'medium',
          rank: rank,
          primaryGoalMatch: rec['primary_goal_match'] as String? ?? '',
          contraindictionFlags: List<String>.from(
            rec['contraindication_flags'] as List<dynamic>? ?? [],
          ),
          dosage: pickStr(rec['dosage'], row?['dosage']),
          frequency: pickStr(rec['frequency'], row?['frequency']),
          cycleLength: pickStr(rec['cycle_length'], row?['cycle_length']),
          stackNote: rec['stack_note'] as String? ?? '',
        ),
      );
    }

    out.sort((a, b) => a.rank.compareTo(b.rank));
    return out;
  }
}
