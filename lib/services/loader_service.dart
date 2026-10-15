import '../models/server_merge.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';
import 'account_scope.dart';
import 'session_service.dart';
import 'employee_server_api.dart';

class LoaderShift {
  final String day;
  final int minutes, rateMinor;
  const LoaderShift({
    required this.day,
    required this.minutes,
    required this.rateMinor,
  });
  int get amountMinor => (minutes * rateMinor / 60).round();
  Map<String, dynamic> toJson() => {
    'day': day,
    'minutes': minutes,
    'rateMinor': rateMinor,
  };
  factory LoaderShift.fromJson(Map<String, dynamic> row) => LoaderShift(
    day: row['day'] as String,
    minutes: row['minutes'] as int,
    rateMinor: row['rateMinor'] as int,
  );
}

/// Separate account-owned journal; driver storage is never read or modified.
class LoaderService {
  static Future<void> _queue = Future<void>.value();
  static Future<void> mergeServer(
    List base,
    List remote, {
    bool preserveNewLocalChanges = false,
  }) {
    final scope = AccountScope.capture();
    return _serial(() async {
      final prefs = await SharedPreferences.getInstance();
      scope.check();
      final key = 'melnitsa_loader_shifts_v1_${scope.id}';
      final local = jsonDecode(prefs.getString(key) ?? '[]') as List;
      final merged = ServerMerge.merge(
        base,
        local,
        remote,
        'data',
        preserveNewLocalChanges,
      );
      if (ServerMerge.same(merged, local)) return;
      if (!await prefs.setString(key, jsonEncode(merged))) {
        throw StateError('Не удалось сохранить смены с сервера');
      }
    });
  }

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
  static String dayKey(DateTime d) =>
      '${monthKey(d)}-${d.day.toString().padLeft(2, '0')}';
  static int parseMoney(String text) {
    final value = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(value))
      throw ArgumentError(
        'Введите сумму от 0, не больше двух знаков после запятой',
      );
    final parts = value.split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  }

  static AccountToken _owner() {
    final token = AccountScope.capture();
    if (token.role != AppRole.loader) throw StateError('Доступно грузчику');
    return token;
  }

  static String _key(AccountToken t) => 'melnitsa_loader_shifts_v1_${t.id}';
  static List<LoaderShift> _decode(String? raw) => raw == null
      ? []
      : (jsonDecode(raw) as List)
            .map(
              (r) => LoaderShift.fromJson(Map<String, dynamic>.from(r as Map)),
            )
            .toList();
  static Future<List<LoaderShift>> read() async {
    final token = _owner();
    final prefs = await SharedPreferences.getInstance();
    token.check();
    return _decode(prefs.getString(_key(token)))
      ..sort((a, b) => b.day.compareTo(a.day));
  }

  static Future<void> save({
    required DateTime date,
    required int minutes,
    String? originalDay,
  }) {
    final token = _owner();
    return _serial(() async {
      token.check();
      AccountScope.requireWrite('work');
      if (originalDay != null || dayKey(date) != dayKey(DateTime.now()))
        AccountScope.requireHistory();
      final day = dayKey(date);
      if (minutes < 1 || minutes > 1440)
        throw ArgumentError('Укажите от 1 минуты до 24 часов');
      if (date.isAfter(DateTime.now()))
        throw ArgumentError('Нельзя добавить будущую смену');
      final settings = await token.bind(SessionService.ownLoaderSettings);
      final prefs = await SharedPreferences.getInstance();
      token.check();
      final rows = _decode(prefs.getString(_key(token)));
      final old = rows.where((r) => r.day == originalDay).firstOrNull;
      if (originalDay != null && old == null)
        throw StateError('Смена уже удалена');
      if (rows.any((r) => r.day == day && r.day != originalDay))
        throw ArgumentError(
          'На эту дату уже есть смена. Откройте её в истории и измените часы',
        );
      final rate = old?.rateMinor ?? settings.hourlyRateMinor;
      if (old == null && rate <= 0)
        throw StateError('Администратор ещё не указал часовую ставку');
      rows.removeWhere((r) => r.day == originalDay);
      rows.add(LoaderShift(day: day, minutes: minutes, rateMinor: rate));
      token.check();
      AccountScope.requireWrite('work');
      if (!await prefs.setString(
        _key(token),
        jsonEncode(rows.map((r) => r.toJson()).toList()),
      ))
        throw StateError('Не удалось сохранить смену');
    });
  }

  static Future<void> delete(String day) {
    if (EmployeeServerApi.enabled)
      throw StateError(
        'Удалите серверную смену в миниаппе. После синхронизации она исчезнет здесь.',
      );
    final token = _owner();
    return _serial(() async {
      token.check();
      final prefs = await SharedPreferences.getInstance();
      token.check();
      AccountScope.requireHistory();
      final rows = _decode(prefs.getString(_key(token)))
        ..removeWhere((r) => r.day == day);
      AccountScope.requireWrite('work');
      if (!await prefs.setString(
        _key(token),
        jsonEncode(rows.map((r) => r.toJson()).toList()),
      ))
        throw StateError('Не удалось удалить смену');
    });
  }

  static Future<void> _serial(Future<void> Function() f) {
    final task = _queue.then((_) => f());
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }
}
