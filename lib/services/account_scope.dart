import 'dart:async';

import '../models/app_role.dart';

/// Stable account identity and session generation. Async work retains its owner.
class AccountScope {
  static final Object _zoneKey = Object();
  static String? _id;
  static AppRole? _role;
  static int _generation = 0;
  static void activate(String id, AppRole role) {
    _generation++;
    _id = id;
    _role = role;
  }

  static void close() {
    _generation++;
    _id = null;
    _role = null;
  }

  static AccountToken capture() {
    final bound = Zone.current[_zoneKey] as AccountToken?;
    if (bound != null) {
      bound.check();
      return bound;
    }
    if (_id == null) throw StateError('Войдите в учётную запись');
    return AccountToken._(_id!, _generation, _role!);
  }

  static bool get isAdmin => _id != null && _role == AppRole.admin;
  static bool get signedIn => _id != null;
  static void requireAdmin() {
    final token = capture();
    if (token.role != AppRole.admin)
      throw StateError('Доступно только администратору');
  }
}

class AccountToken {
  final String id;
  final int generation;
  final AppRole role;
  const AccountToken._(this.id, this.generation, this.role);
  bool get valid =>
      AccountScope._id == id && AccountScope._generation == generation;
  void check() {
    if (!valid)
      throw StateError('Учётная запись изменилась. Откройте экран заново');
  }

  T run<T>(T Function() action) {
    check();
    return runZoned(action, zoneValues: {AccountScope._zoneKey: this});
  }

  Future<T> bind<T>(Future<T> Function() action) => run(action);
}
