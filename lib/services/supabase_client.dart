import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client instance.
/// Use this throughout the app to access Supabase functionality.
/// 
/// Example usage:
/// ```dart
/// import 'services/supabase_client.dart';
/// 
/// final data = await supabase.from('table').select();
/// ```
final supabase = Supabase.instance.client;

