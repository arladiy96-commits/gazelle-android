import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';
import 'account_scope.dart';

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
  const EmployeeAccount({
    required this.id,
    required this.name,
    required this.login,
    required this.role,
    required this.active,
  });
  factory EmployeeAccount.fromJson(Map<String, dynamic> row) => EmployeeAccount(
    id: row['id'] as String,
    name: row['name'] as String,
    login: row['login'] as String,
    role: AppRole.fromStorage(row['role'] as String),
    active: row['active'] == true,
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
    return [
      for (final row in root['accounts'] as List)
        Map<String, dynamic>.from(row as Map),
    ];
  }

  static Future<void> _write(List<Map<String, dynamic>> rows) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      accountsKey,
      jsonEncode({'version': 1, 'accounts': rows}),
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
    if (password != null && (password.length < 4 || password.length > 128))
      throw ArgumentError('Пароль: от 4 до 128 символов');
  }

  static Future<bool> needsSetup() async => (await _rows()).isEmpty;
  static Future<AppSession> _enter(Map<String, dynamic> row) async {
    final account = EmployeeAccount.fromJson(row);
    if (!account.active) throw StateError('Учётная запись отключена');
    if (!await (await SharedPreferences.getInstance()).setString(
      sessionKey,
      account.id,
    ))
      throw StateError('Не удалось сохранить вход');
    if (current?.accountId != account.id || !AccountScope.signedIn)
      AccountScope.activate(account.id, account.role);
    current = account.session;
    return current!;
  }

  static Future<AppSession?> read() => _serial(() async {
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
    if ((await _rows()).isNotEmpty)
      throw StateError('Администратор уже создан. Войдите по логину и паролю');
    _validate(name, login, password);
    final salt = _random(24);
    final row = <String, dynamic>{
      'id': _random(18),
      'name': name.trim(),
      'login': login.trim(),
      'role': AppRole.admin.name,
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
    final rows = await _rows();
    token.check();
    return rows.map(EmployeeAccount.fromJson).toList();
  }

  static Future<void> saveEmployee({
    String? id,
    required String name,
    required String login,
    required AppRole role,
    String? password,
    bool active = true,
  }) {
    AccountScope.requireAdmin();
    final token = AccountScope.capture();
    return _serial(() async {
      token.check();
      AccountScope.requireAdmin();
      _validate(name, login, password);
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
        'createdAt': old?['createdAt'] ?? DateTime.now().toIso8601String(),
      };
      if (password != null) {
        final salt = _random(24);
        row['salt'] = salt;
        row['hash'] = await _hash(password, salt);
      }
      token.check();
      rows.removeWhere((e) => e['id'] == id);
      rows.add(row);
      if (!rows.any((e) => e['role'] == 'admin' && e['active'] == true))
        throw StateError('Нужен хотя бы один активный администратор');
      await _write(rows);
      if (id == current?.accountId)
        current = EmployeeAccount.fromJson(row).session;
    });
  }

  static Future<void> clear() => _serial(() async {
    final disk = await SharedPreferences.getInstance();
    if (!await disk.remove(sessionKey))
      throw StateError('Не удалось выйти из учётной записи');
    current = null;
    AccountScope.close();
  });
}
