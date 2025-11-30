import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';

/// Home screen for authenticated users
/// Now uses the HomeDashboardScreen for the full dashboard experience
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeDashboardScreen();
  }
}

