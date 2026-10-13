import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';
import 'account_scope.dart';
import '../models/employee_access.dart';
import 'employee_server_api.dart';

class AppSession {
  final String accountId, displayName, login;
  final AppRole role;
  const AppSession({
    this.accountId = '',
    required this.role,
    required this.displayName,
    required this.login,
  });
  String get ownerKey =>
      accountId.isEmpty ? '${role.storageValue}:$login' : accountId;
  bool get isAdmin => role == AppRole.admin;
}

class EmployeeAccount {
  final String id, name, login;
  final AppRole role;
  final bool active;
  final bool isOwner;
  final EmployeeAccess access;
  final int hourlyRateMinor;
  final Map<String, int> deductions, openingMinutes;
  final int defaultDeductionMinor;
  const EmployeeAccount({
    required this.id,
    required this.name,
    required this.login,
    required this.role,
    required this.active,
    this.isOwner = false,
    this.access = const EmployeeAccess(),
    this.hourlyRateMinor = 0,
    this.deductions = const {},
    this.defaultDeductionMinor = 0,
    this.openingMinutes = const {},
  });
  factory EmployeeAccount.fromJson(Map<String, dynamic> row) => EmployeeAccount(
    id: row['id'] as String,
    name: row['name'] as String,
    login: row['login'] as String,
    role: AppRole.fromStorage(row['role'] as String),
    active: row['active'] == true,
    isOwner: row['isOwner'] == true,
    access: row['access'] is Map
        ? EmployeeAccess.fromJson(
            Map<String, dynamic>.from(row['access'] as Map),
          )
        : EmployeeAccess(
            status: row['active'] == true
                ? EmployeeAccessStatus.active
                : EmployeeAccessStatus.blocked,
          ),
    hourlyRateMinor: (row['hourlyRateMinor'] as num?)?.toInt() ?? 0,
    deductions: Map<String, int>.from(row['loaderDeductions'] as Map? ?? {}),
    defaultDeductionMinor:
        (row['loaderDefaultDeductionMinor'] as num?)?.toInt() ?? 0,
    openingMinutes: Map<String, int>.from(
      row['loaderOpeningMinutes'] as Map? ?? {},
    ),
  );
  AppSession get session =>
      AppSession(accountId: id, displayName: name, login: login, role: role);
}

/// Local auth adapter. Domain IDs can later be mapped to server IDs.
class SessionService {
  SessionService._();
  static const accountsKey = 'melnitsa_accounts_v1',
      sessionKey = 'melnitsa_session_v1';
  static final revision = ValueNotifier<int>(0);
  static AppSession? current;
  static Future<void> _queue = Future<void>.value();
  static Future<T> _serial<T>(Future<T> Function() action) {
    final task = _queue.then((_) => action());
    _queue = task.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    return task;
  }

  static Future<List<Map<String, dynamic>>> _rows() async {
    final raw = (await SharedPreferences.getInstance()).getString(accountsKey);
    if (raw == null) return [];
    final root = jsonDecode(raw) as Map<String, dynamic>;
    if (root['version'] != 1)
      throw const FormatException('Неизвестная версия учётных записей');
    final rows = [
      for (final row in root['accounts'] as List)
        Map<String, dynamic>.from(row as Map),
    ];
    final admins = rows.where((r) => r['role'] == 'admin').toList();
    final owner =
        root['ownerId'] as String? ??
        (admins.length == 1 ? admins.single['id'] as String : null);
    if (owner == null && rows.isNotEmpty)
      throw StateError(
        'Нужно сопоставить единственного владельца при миграции',
      );
    for (final row in rows) {
      row['isOwner'] = row['id'] == owner;
    }
    return rows;
  }

  static Future<void> _write(List<Map<String, dynamic>> rows) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      accountsKey,
      jsonEncode({
        'version': 1,
        'ownerId': rows.where((r) => r['isOwner'] == true).single['id'],
        'accounts': rows,
      }),
    ))
      throw StateError('Не удалось сохранить сотрудников');
    revision.value++;
  }

  static String _random(int length) => base64Url
      .encode(List<int>.generate(length, (_) => Random.secure().nextInt(256)))
      .replaceAll('=', '');
  static Future<String> _hash(String password, String salt) =>
      Isolate.run(() async {
        final key =
            await Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: 210000,
              bits: 256,
            ).deriveKeyFromPassword(
              password: password,
              nonce: base64Url.decode(base64Url.normalize(salt)),
            );
        return base64Url.encode(await key.extractBytes());
      });
  static bool _same(String a, String b) {
    var diff = a.length ^ b.length;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ (i < b.length ? b.codeUnitAt(i) : 0);
    }
    return diff == 0;
  }

  static String _loginKey(String login) => login.trim().toLowerCase();
  static void _validate(String name, String login, String? password) {
    if (name.trim().isEmpty || name.trim().length > 80)
      throw ArgumentError('Введите имя до 80 символов');
    if (!RegExp(r'^[a-zA-Zа-яА-ЯёЁ0-9_.@-]{3,64}$').hasMatch(login.trim()))
      throw ArgumentError('Логин: 3–64 символа, без пробелов');
    if (password != null &&
        (password.length < (EmployeeServerApi.enabled ? 10 : 4) ||
            password.length > 128))
      throw ArgumentError(
        'Пароль: от ${EmployeeServerApi.enabled ? 10 : 4} до 128 символов',
      );
  }

  static Future<bool> needsSetup() async =>
      !EmployeeServerApi.enabled && (await _rows()).isEmpty;
  static Future<AppSession> _enter(Map<String, dynamic> row) async {
    final account = EmployeeAccount.fromJson(row);
    if (!account.active || account.access.blocked)
      throw StateError(
        account.access.reason.isEmpty
            ? 'Доступ заблокирован'
            : account.access.reason,
      );
    if (!await (await SharedPreferences.getInstance()).setString(
      sessionKey,
      account.id,
    ))
      throw StateError('Не удалось сохранить вход');
    AccountScope.activate(
      account.id,
      account.role,
      owner: account.isOwner,
      policy: account.access,
    );
    current = account.session;
    await EmployeeServerApi.configureGps(
      account.id,
      account.access,
      account.isOwner,
    );
    return current!;
  }

  static Future<AppSession?> read() => _serial(() async {
    if (EmployeeServerApi.enabled)
      return null; // Tokens stay in memory; login on cold start.
    final disk = await SharedPreferences.getInstance();
    final id = disk.getString(sessionKey);
    final row = (await _rows())
        .where((e) => e['id'] == id && e['active'] == true)
        .firstOrNull;
    if (row == null) {
      current = null;
      AccountScope.close();
      return null;
    }
    return _enter(row);
  });
  static Future<AppSession> createFirstAdmin({
    required String name,
    required String login,
    required String password,
  }) => _serial(() async {
    if (EmployeeServerApi.enabled)
      throw StateError('Владелец создаётся на сервере');
    if ((await _rows()).isNotEmpty)
      throw StateError('Администратор уже создан. Войдите по логину и паролю');
    _validate(name, login, password);
    final salt = _random(24);
    final row = <String, dynamic>{
      'id': _random(18),
      'name': name.trim(),
      'login': login.trim(),
      'role': AppRole.admin.name,
      'isOwner': true,
      'active': true,
      'salt': salt,
      'hash': await _hash(password, salt),
      'createdAt': DateTime.now().toIso8601String(),
      'serverId': null,
    };
    await _write([row]);
    return _enter(row);
  });
  static Future<AppSession> signIn({
    required String login,
    required String password,
  }) => _serial(() async {
    if (password.length > 128) throw ArgumentError('Неверный логин или пароль');
    if (EmployeeServerApi.enabled) {
      final result = await EmployeeServerApi.request(
        'POST',
        '/auth/login',
        anonymous: true,
        body: {'login': login.trim(), 'password': password},
      );
      final row = Map<String, dynamic>.from(result['employee'] as Map);
      final account = EmployeeAccount.fromJson(row);
      if (account.access.validUntil == null)
        throw const FormatException('Сервер не выдал срок доступа');
      EmployeeServerApi.authenticate(result['accessToken'] as String);
      try {
        return await _enter(row);
      } catch (_) {
        EmployeeServerApi.forget();
        rethrow;
      }
    }
    final row = (await _rows())
        .where((e) => _loginKey(e['login'] as String) == _loginKey(login))
        .firstOrNull;
    if (row == null ||
        !_same(
          await _hash(password, row['salt'] as String),
          row['hash'] as String,
        ))
      throw ArgumentError('Неверный логин или пароль');
    return _enter(row);
  });
  static Future<List<EmployeeAccount>> employees() async {
    AccountScope.requireAdmin();
    final token = AccountScope.capture();
    final rows = EmployeeServerApi.enabled
        ? (await EmployeeServerApi.request('GET', '/employees'))['employees']
              as List
        : await _rows();
    token.check();
    return rows
        .map(
          (r) => EmployeeAccount.fromJson(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  static Future<void> saveEmployee({
    String? id,
    String? telegramId,
    required String name,
    required String login,
    required AppRole role,
    String? password,
    bool active = true,
    int? hourlyRateMinor,
    String? deductionMonth,
    int? deductionMinor,
  }) {
    AccountScope.requireAdmin();
    final token = AccountScope.capture();
    return _serial(() async {
      token.check();
      AccountScope.requireAdmin();
      _validate(name, login, password);
      if (role == AppRole.admin && (id == null || id != current?.accountId)) {
        throw ArgumentError('Владелец один. Выберите водителя или грузчика');
      }
      if (EmployeeServerApi.enabled) {
        await EmployeeServerApi.request(
          id == null ? 'POST' : 'PATCH',
          id == null ? '/employees' : '/employees/${Uri.encodeComponent(id)}',
          body: {
            if (telegramId != null) 'telegramId': telegramId.trim(),
            'name': name.trim(),
            'login': login.trim(),
            'role': role.name,
            'active': active,
            if (password != null) 'password': password,
            if (hourlyRateMinor != null) 'hourlyRateMinor': hourlyRateMinor,
            if (deductionMinor != null) 'deductionMonth': deductionMonth,
            if (deductionMinor != null) 'deductionMinor': deductionMinor,
          },
        );
        token.check();
        revision.value++;
        return;
      }
      if (hourlyRateMinor != null &&
          (hourlyRateMinor < 0 || hourlyRateMinor > 100000000)) {
        throw ArgumentError('Ставка должна быть от 0 до 1 000 000 ₸');
      }
      if (deductionMinor != null &&
          (deductionMinor < 0 ||
              deductionMinor > 10000000000 ||
              deductionMonth == null ||
              !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(deductionMonth))) {
        throw ArgumentError('Проверьте месяц и сумму удержания');
      }
      final rows = await _rows();
      token.check();
      final old = rows.where((e) => e['id'] == id).firstOrNull;
      if (id != null && old == null) throw StateError('Сотрудник не найден');
      if (id == current?.accountId && (!active || role != AppRole.admin))
        throw ArgumentError(
          'Нельзя отключить свою запись или снять с себя права администратора',
        );
      if (rows.any(
        (e) =>
            e['id'] != id &&
            _loginKey(e['login'] as String) == _loginKey(login),
      ))
        throw ArgumentError('Этот логин уже занят');
      if (old == null && password == null)
        throw ArgumentError('Введите пароль');
      final row = <String, dynamic>{
        ...?old,
        'id': id ?? _random(18),
        'name': name.trim(),
        'login': login.trim(),
        'role': role.name,
        'active': active,
        'serverId': old?['serverId'],
        'isOwner': old?['isOwner'] == true,
        'createdAt': old?['createdAt'] ?? DateTime.now().toIso8601String(),
      };
      if (hourlyRateMinor != null) row['hourlyRateMinor'] = hourlyRateMinor;
      if (deductionMinor != null) {
        row['loaderDeductions'] = <String, dynamic>{
          ...Map<String, dynamic>.from(old?['loaderDeductions'] as Map? ?? {}),
          deductionMonth!: deductionMinor,
        };
      }
      if (password != null) {
        final salt = _random(24);
        row['salt'] = salt;
        row['hash'] = await _hash(password, salt);
      }
      token.check();
      row['audit'] = [
        ...old?['audit'] as List? ?? [],
        {
          'at': DateTime.now().toUtc().toIso8601String(),
          'actorId': token.id,
          'action': old == null ? 'employee_created' : 'profile_changed',
          'after': {
            'name': name.trim(),
            'login': login.trim(),
            'role': role.name,
            'passwordChanged': password != null,
          },
        },
      ];
      rows.removeWhere((e) => e['id'] == id);
      rows.add(row);
      if (!rows.any((e) => e['role'] == 'admin' && e['active'] == true))
        throw StateError('Нужен хотя бы один активный администратор');
      await _write(rows);
      if (id == current?.accountId)
        current = EmployeeAccount.fromJson(row).session;
    });
  }

  static Future<void> updateAccess(
    EmployeeAccount employee,
    EmployeeAccess next, {
    bool revoke = false,
  }) {
    AccountScope.requireAdmin();
    final actor = AccountScope.capture();
    return _serial(() async {
      actor.check();
      AccountScope.requireAdmin();
      if (employee.isOwner || employee.id == actor.id)
        throw StateError('Права владельца нельзя ограничить');
      if (EmployeeServerApi.enabled) {
        await EmployeeServerApi.request(
          'PUT',
          '/employees/${Uri.encodeComponent(employee.id)}/access',
          body: {
            'expectedRevision': employee.access.revision,
            'access': next.toJson(),
            'revokeSessions': revoke,
          },
        );
        actor.check();
        revision.value++;
        return;
      }
      final rows = await _rows();
      actor.check();
      final row = rows.firstWhere((r) => r['id'] == employee.id);
      if (row['isOwner'] == true)
        throw StateError('Нельзя ограничить владельца');
      final old = EmployeeAccount.fromJson(row).access;
      if (old.revision != employee.access.revision)
        throw StateError('Права уже изменились. Обновите карточку');
      final json = next.toJson()
        ..['revision'] = old.revision + 1
        ..['sessionEpoch'] = old.sessionEpoch + (revoke ? 1 : 0)
        ..['validUntil'] = null;
      row['access'] = json;
      row['active'] = !next.blocked;
      final events = List<dynamic>.from(row['audit'] as List? ?? []);
      events.add({
        'at': DateTime.now().toUtc().toIso8601String(),
        'actorId': actor.id,
        'action': revoke ? 'revoke_sessions' : 'access_changed',
        'before': old.toJson(),
        'after': json,
      });
      row['audit'] = events;
      await _write(rows);
    });
  }

  static Future<EmployeeAccount> refreshCurrent() async {
    final scope = AccountScope.capture();
    Future<Map<String, dynamic>> fetchCurrent() async {
      try {
        return await EmployeeServerApi.request('GET', '/me');
      } on EmployeeApiError catch (e) {
        if (scope.valid && (e.status == 401 || e.status == 403)) {
          AccountScope.revoked.value = true;
        }
        rethrow;
      }
    }

    final row = EmployeeServerApi.enabled
        ? Map<String, dynamic>.from((await fetchCurrent())['employee'] as Map)
        : (await _rows()).firstWhere((r) => r['id'] == scope.id);
    scope.check();
    final employee = EmployeeAccount.fromJson(row);
    if (employee.id != scope.id ||
        (EmployeeServerApi.enabled && employee.access.validUntil == null)) {
      throw const FormatException('Неверная учётная запись или срок доступа');
    }
    if (employee.role != scope.role ||
        employee.isOwner != AccountScope.isOwner ||
        employee.access.sessionEpoch !=
            AccountScope.access.value.sessionEpoch) {
      AccountScope.revoked.value = true;
    }
    AccountScope.access.value = employee.access;
    if (!AccountScope.revoked.value && EmployeeServerApi.enabled) {
      await EmployeeServerApi.configureGps(
        employee.id,
        employee.access,
        employee.isOwner,
      );
      scope.check();
    }
    if (!employee.active) AccountScope.revoked.value = true;
    current = employee.session;
    return employee;
  }

  static Future<List<Map<String, dynamic>>> audit(String id) async {
    AccountScope.requireAdmin();
    final scope = AccountScope.capture();
    final rows = EmployeeServerApi.enabled
        ? (await EmployeeServerApi.request(
                'GET',
                '/employees/${Uri.encodeComponent(id)}/audit',
              ))['events']
              as List
        : (await _rows()).firstWhere((r) => r['id'] == id)['audit'] as List? ??
              [];
    scope.check();
    return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  /// The loader can read only their own pay settings, never the account list.
  static Future<EmployeeAccount> ownLoaderSettings() async {
    final token = AccountScope.capture();
    if (token.role != AppRole.loader) throw StateError('Доступно грузчику');
    if (EmployeeServerApi.enabled) {
      final result = await EmployeeServerApi.request('GET', '/me');
      token.check();
      return EmployeeAccount.fromJson(
        Map<String, dynamic>.from(result['employee'] as Map),
      );
    }
    final rows = await _rows();
    token.check();
    return EmployeeAccount.fromJson(
      rows.firstWhere((r) => r['id'] == token.id),
    );
  }

  static Future<void> clear() => _serial(() async {
    final disk = await SharedPreferences.getInstance();
    if (current != null) await EmployeeServerApi.clearGps(current!.accountId);
    if (!await disk.remove(sessionKey))
      throw StateError('Не удалось выйти из учётной записи');
    EmployeeServerApi.forget();
    current = null;
    AccountScope.close();
  });
}
