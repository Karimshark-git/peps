import 'package:flutter/foundation.dart';

/// Provider for temporarily storing auth credentials during email verification
class AuthCredentialsProvider extends ChangeNotifier {
  String? _email;
  String? _password;

  String? get email => _email;
  String? get password => _password;

  bool get hasCredentials => _email != null && _password != null;

  /// Store credentials temporarily
  void setCredentials(String email, String password) {
    _email = email;
    _password = password;
    notifyListeners();
  }

  /// Clear credentials after use
  void clearCredentials() {
    _email = null;
    _password = null;
    notifyListeners();
  }
}

