import 'package:flutter/foundation.dart';
import '../engine/models/peptide_recommendation.dart';

/// Provider for storing protocol recommendations locally before account creation
class ProtocolProvider extends ChangeNotifier {
  List<PeptideRecommendation> _protocol = [];

  List<PeptideRecommendation> get protocol => _protocol;

  bool get hasProtocol => _protocol.isNotEmpty;

  /// Save protocol recommendations
  void saveProtocol(List<PeptideRecommendation> recommendations) {
    _protocol = recommendations;
    notifyListeners();
  }

  /// Clear protocol (e.g., after saving to Supabase)
  void clearProtocol() {
    _protocol = [];
    notifyListeners();
  }
}

