import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'env/supabase_env.dart';
import 'features/onboarding/provider/onboarding_provider.dart';
import 'providers/protocol_provider.dart';
import 'providers/auth_credentials_provider.dart';
import 'services/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const PepsApp());
}

class PepsApp extends StatelessWidget {
  const PepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => ProtocolProvider()),
        ChangeNotifierProvider(create: (_) => AuthCredentialsProvider()),
      ],
      child: MaterialApp(
        title: 'PEPS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: _getInitialRoute(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }

  /// Determines initial route based on auth session
  String _getInitialRoute() {
    final session = supabase.auth.currentSession;
    if (session == null) {
      return AppRouter.welcome;
    } else {
      return AppRouter.home;
    }
  }
}

