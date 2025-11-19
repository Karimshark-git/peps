import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/provider/onboarding_provider.dart';

void main() {
  runApp(const PepsApp());
}

class PepsApp extends StatelessWidget {
  const PepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: MaterialApp(
        title: 'PEPS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.welcome,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

