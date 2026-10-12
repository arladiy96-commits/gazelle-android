import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_scope.dart';
import 'employee_server_api.dart';
import 'employee_data_service.dart';
import 'session_service.dart';
import 'test_store.dart';
import 'gps_tracker.dart';

/// One durable in-flight snapshot per account. A timeout retries the same ID.
/// HTTP 409 retains local data and requires explicit conflict resolution.
class EmployeeSync with WidgetsBindingObserver {
  EmployeeSync._();
  static final instance = EmployeeSync._();
  final message = ValueNotifier<String?>(null);
  Timer? _timer;
  bool _busy = false, _attached = false, _again = false;
  Future<void> start() async {
    if (!_attached) {
      WidgetsBinding.instance.addObserver(this);
      _attached = true;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => tick());
    await tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_attached) WidgetsBinding.instance.removeObserver(this);
    _attached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) tick();
  }

  Future<void> restore() async {
    if (!EmployeeServerApi.enabled) return;
    final scope = AccountScope.capture();
    final disk = await SharedPreferences.getInstance();
    scope.check();
    final versionKey = 'employee_sync_version_${scope.id}';
    final restoreKey = 'employee_restore_${scope.id}';
    if (disk.getInt(versionKey) != null) return;
    final key = '${TestPreferences.storageKey}_account_${scope.id}';
    var staged = disk.getString(restoreKey);
    if (staged == null) {
      if (disk.containsKey(key) ||
          disk.containsKey('melnitsa_loader_shifts_v1_${scope.id}')) {
        throw StateError(
          'Есть местные данные: требуется подтверждённое сопоставление с сервером',
        );
      }
      final remote = await EmployeeServerApi.request('GET', '/me/data');
      scope.check();
      if (remote['accountId'] != scope.id || remote['version'] is! int)
        throw const FormatException('Неверный владелец или версия данных');
      staged = jsonEncode(remote);
      if (!await disk.setString(restoreKey, staged))
        throw StateError('Загрузка не сохранена');
    }
    final raw = Map<String, dynamic>.from(jsonDecode(staged) as Map);
    scope.check();
    if (!await disk.setString(key, jsonEncode(raw['preferences'] ?? {})))
      throw StateError('Данные не сохранены');
    scope.check();
    if (!await disk.setString(
      'melnitsa_loader_shifts_v1_${scope.id}',
      jsonEncode(raw['loaderShifts'] ?? []),
    ))
      throw StateError('Смены не сохранены');
    scope.check();
    if (!await disk.setInt(versionKey, raw['version'] as int))
      throw StateError('Версия не сохранена');
    await disk.remove(restoreKey);
    TestPreferences.resetCache();
  }

  Future<void> _sendHistoricalRoute(
    AccountToken scope,
    SharedPreferences disk,
  ) async {
    if (!AccountScope.access.value.shareLocation) return;
    final data = await EmployeeDataService.localData(scope.id);
    final prefs = Map<String, dynamic>.from(data['preferences'] as Map);
    final journal = TestState.decode(prefs['journal'] as String?);
    for (final shift in journal.shifts.reversed.where(
      (s) => s['end'] != null,
    )) {
      final id = shift['id'] as String;
      final key = 'employee_route_sent_${scope.id}_$id';
      if (disk.getBool(key) == true) continue;
      final route = await EmployeeDataService.localRoute(scope.id, id);
      scope.check();
      if ((route['points'] as List? ?? []).isEmpty) {
        if (!await disk.setBool(key, true))
          throw StateError('Подтверждение не сохранено');
        continue;
      }
      if (!AccountScope.access.value.shareLocation || AccountScope.restricted)
        return;
      final response = await EmployeeServerApi.request(
        'POST',
        '/me/routes/${Uri.encodeComponent(id)}',
        body: {'route': route},
      );
      scope.check();
      if (response['accountId'] != scope.id || response['shiftId'] != id)
        throw const FormatException('Неверное подтверждение маршрута');
      if (!await disk.setBool(key, true))
        throw StateError('Подтверждение маршрута не сохранено');
      break; // Bounded work per cycle; current GPS uses the native channel.
    }
  }

  Future<void> tick() async {
    if (!AccountScope.signedIn) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    final scope = AccountScope.capture();
    try {
      await SessionService.refreshCurrent();
      scope.check();
      if (AccountScope.restricted || !AccountScope.canWrite('work')) {
        await GpsTrackerController.instance.stopForAccess();
      } else {
        await GpsTrackerController.instance.resumeForAccess();
      }
      if (!EmployeeServerApi.enabled || AccountScope.restricted) return;
      final disk = await SharedPreferences.getInstance();
      scope.check();
      final key = 'employee_sync_pending_${scope.id}';
      var pending = disk.getString(key);
      if (pending == null) {
        final data = await EmployeeDataService.localData(scope.id);
        scope.check();
        final payload = data;
        final content = jsonEncode(payload);
        if (content == disk.getString('employee_sync_last_${scope.id}')) {
          await _sendHistoricalRoute(scope, disk);
          message.value = 'Данные актуальны';
          return;
        }
        pending = jsonEncode({
          'operationId': List.generate(
            24,
            (_) => Random.secure().nextInt(256),
          ).map((v) => v.toRadixString(16).padLeft(2, '0')).join(),
          'baseVersion': disk.getInt('employee_sync_version_${scope.id}') ?? 0,
          'data': payload,
        });
        if (utf8.encode(pending).length > 12 * 1024 * 1024)
          throw StateError('История превышает пакет: нужна пакетная миграция');
        if (!await disk.setString(key, pending))
          throw StateError('Очередь не сохранена');
      }
      final envelope = Map<String, dynamic>.from(jsonDecode(pending) as Map);
      final response = await EmployeeServerApi.request(
        'POST',
        '/me/sync',
        body: envelope,
      );
      scope.check();
      if (response['operationId'] != envelope['operationId'] ||
          response['version'] is! int)
        throw const FormatException('Неверное подтверждение сервера');
      if (!await disk.setInt(
        'employee_sync_version_${scope.id}',
        response['version'] as int,
      ))
        throw StateError('Версия не сохранена');
      if (!await disk.setString(
        'employee_sync_last_${scope.id}',
        jsonEncode(envelope['data']),
      ))
        throw StateError('Подтверждение не сохранено');
      if (!await disk.remove(key))
        throw StateError('Подтверждение не сохранено');
      await _sendHistoricalRoute(scope, disk);
      message.value = 'Данные переданы';
    } on EmployeeApiError catch (e) {
      if (!scope.valid) return;
      if (e.status == 401 || e.status == 403) {
        AccountScope.revoked.value = true;
        await GpsTrackerController.instance.stopForAccess();
      }
      message.value = e.status == 409
          ? 'Конфликт версий. Местные данные сохранены, требуется сверка владельцем.'
          : e.message;
    } catch (e) {
      if (scope.valid) message.value = 'Нет синхронизации: $e';
    } finally {
      _busy = false;
      if (_again && scope.valid) {
        _again = false;
        scheduleMicrotask(tick);
      }
      if (scope.valid && AccountScope.restricted) {
        await GpsTrackerController.instance.stopForAccess();
      }
    }
  }
}
