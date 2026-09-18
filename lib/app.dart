import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class TamerlanApp extends StatelessWidget {
  const TamerlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ТАМЕРЛАН',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
