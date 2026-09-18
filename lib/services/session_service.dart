import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';

class AppSession {
  final AppRole role;
  final String displayName;
  final String login;

  const AppSession({
    required this.role,
    required this.displayName,
    required this.login,
  });
}

class SessionService {
  SessionService._();

  static const _loggedInKey = 'tamerlan_logged_in';
  static const _roleKey = 'tamerlan_role';
  static const _nameKey = 'tamerlan_name';
  static const _loginKey = 'tamerlan_login';

  static Future<AppSession?> read() async {
    final prefs = await SharedPreferences.getInstance();

    if (!(prefs.getBool(_loggedInKey) ?? false)) {
      return null;
    }

    final role = AppRole.fromStorage(prefs.getString(_roleKey));
    final name = prefs.getString(_nameKey)?.trim();
    final login = prefs.getString(_loginKey)?.trim();

    return AppSession(
      role: role,
      displayName: (name == null || name.isEmpty) ? _defaultName(role) : name,
      login: login ?? '',
    );
  }

  static Future<AppSession> createTestSession({
    required String login,
  }) async {
    final role = AppRole.fromTestLogin(login);
    final displayName = _defaultName(role);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_roleKey, role.storageValue);
    await prefs.setString(_nameKey, displayName);
    await prefs.setString(_loginKey, login.trim());

    return AppSession(
      role: role,
      displayName: displayName,
      login: login.trim(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_loginKey);
  }

  static String _defaultName(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 'Администратор';
      case AppRole.driver:
        return 'Водитель';
      case AppRole.loader:
        return 'Грузчик';
    }
  }
}
