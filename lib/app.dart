import 'widgets/keyboard_input.dart';

import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'widgets/employee_access_gate.dart';
import 'services/session_service.dart';
import 'services/employee_sync.dart';
import 'services/gps_tracker.dart';

final _rootNavigator = GlobalKey<NavigatorState>();

class TamerlanApp extends StatelessWidget {
  const TamerlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ТАМЕРЛАН',
      navigatorKey: _rootNavigator,
      builder: (context, child) => KeyboardScene(
        child: EmployeeAccessGate(
          child: child ?? const SizedBox.shrink(),
          onLogout: () async {
            await GpsTrackerController.instance.stopForAccess();
            EmployeeSync.instance.stop();
            await SessionService.clear();
            _rootNavigator.currentState?.pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
