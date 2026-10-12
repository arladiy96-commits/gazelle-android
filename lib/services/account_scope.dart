import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/employee_access.dart';

import '../models/app_role.dart';

/// Stable account identity and session generation. Async work retains its owner.
class AccountScope {
  static final Object _zoneKey = Object();
  static String? _id;
  static AppRole? _role;
  static int _generation = 0;
  static bool _owner = false;
  static final access = ValueNotifier<EmployeeAccess>(const EmployeeAccess());
  static final revoked = ValueNotifier<bool>(false);
  static bool get isOwner => signedIn && _owner;
  static bool get restricted =>
      signedIn &&
      (revoked.value ||
          access.value.blocked ||
          access.value.expiredAt(DateTime.now()));
  static bool canRead(String section) =>
      !restricted && (_owner || access.value.canRead(section));
  static bool canWrite(String section) =>
      !restricted && (_owner || access.value.canWrite(section));
  static void requireActiveWrite() {
    capture().check();
    if (restricted ||
        (!_owner && access.value.status != EmployeeAccessStatus.active)) {
      throw StateError('Внесение изменений запрещено');
    }
  }

  static void requireWrite([String section = 'work']) {
    capture().check();
    if (!canWrite(section))
      throw StateError('Нет разрешения на изменение этого раздела');
  }

  static void requireHistory() {
    requireWrite();
    if (!_owner && !access.value.editHistory)
      throw StateError('Изменение прошлых смен запрещено');
  }

  static void requireSubmit(String section) {
    requireWrite(section);
    if (!_owner && !access.value.submitReports)
      throw StateError('Сдача отчётов запрещена');
  }

  static void activate(
    String id,
    AppRole role, {
    bool owner = false,
    EmployeeAccess policy = const EmployeeAccess(),
  }) {
    _generation++;
    _id = id;
    _role = role;
    _owner = owner;
    revoked.value = false;
    access.value = policy;
  }

  static void close() {
    _generation++;
    _id = null;
    _role = null;
    _owner = false;
    revoked.value = false;
    access.value = const EmployeeAccess();
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

  static bool get isAdmin => _id != null && _owner && !restricted;
  static bool get signedIn => _id != null;
  static void requireAdmin() {
    final token = capture();
    if (token.role != AppRole.admin || !isAdmin)
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
