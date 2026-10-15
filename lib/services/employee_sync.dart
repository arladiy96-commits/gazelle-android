import 'loader_service.dart';
import '../models/server_bootstrap.dart';
import '../models/server_merge.dart';

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
  final conflict = ValueNotifier<bool>(false);
  Timer? _timer;
  bool _busy = false, _attached = false;
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
    conflict.value = false;
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
    await EmployeeServerApi.pauseGps(scope.id);
    await GpsTrackerController.instance.stopForAccess();
    await ServerBootstrap.run(
      account: scope.id,
      server: EmployeeServerApi.baseUrl,
      preferencesKey: '${TestPreferences.storageKey}_account_${scope.id}',
      read: (key) {
        scope.check();
        return disk.get(key);
      },
      keys: () {
        scope.check();
        return disk.getKeys();
      },
      write: (key, value) async {
        scope.check();
        final ok = value is int
            ? await disk.setInt(key, value)
            : await disk.setString(key, value as String);
        scope.check();
        if (!ok) throw StateError('Не удалось сохранить серверные данные');
      },
      remove: (key) async {
        scope.check();
        if (!await disk.remove(key))
          throw StateError('Не удалось очистить старые данные');
        scope.check();
      },
      fetch: () => EmployeeServerApi.request('GET', '/me/data'),
      resetRoutes: () async {
        scope.check();
        await EmployeeServerApi.resetLocalRoutes(scope.id);
        scope.check();
      },
      localData: () => EmployeeDataService.localData(scope.id),
    );
    scope.check();
    TestPreferences.resetCache();
    EmployeeServerApi.dataReadyAccount = scope.id;
    await EmployeeServerApi.configureGps(
      scope.id,
      AccountScope.access.value,
      AccountScope.isOwner,
    );
  }

  Future<void> _receive(
    AccountToken scope,
    SharedPreferences disk,
    Map<String, dynamic> base,
    Map<String, dynamic> remote, {
    bool preserveNewLocalChanges = false,
  }) async {
    scope.check();
    if (remote['accountId'] != scope.id || remote['version'] is! int) {
      throw const FormatException('Неверная область или версия данных');
    }
    await TestStore.mergeServerPreferences(
      base['preferences'] as Map? ?? {},
      remote['preferences'] as Map? ?? {},
      preserveNewLocalChanges: preserveNewLocalChanges,
    );
    scope.check();
    await LoaderService.mergeServer(
      base['loaderShifts'] as List? ?? [],
      remote['loaderShifts'] as List? ?? [],
      preserveNewLocalChanges: preserveNewLocalChanges,
    );
    scope.check();
    if (!await disk.setInt(
      'employee_sync_version_${scope.id}',
      remote['version'] as int,
    )) {
      throw StateError('Версия не сохранена');
    }
    final baseline = {...remote}..remove('version');
    baseline['receivedAt'] = null;
    if (!await disk.setString(
      'employee_sync_last_${scope.id}',
      jsonEncode(baseline),
    )) {
      throw StateError('Базовая версия не сохранена');
    }
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
    if (EmployeeServerApi.enabled &&
        EmployeeServerApi.dataReadyAccount != AccountScope.capture().id)
      return;
    if (_busy) return;
    // Do not compete with IME layout and text input on the UI isolate.
    if (WidgetsBinding.instance.platformDispatcher.views.any(
      (view) => view.viewInsets.bottom > 0,
    ))
      return;
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
      final recovery = disk.getString('employee_sync_recovery_${scope.id}');
      if (recovery != null) {
        await _finishRecovery(
          scope,
          disk,
          Map<String, dynamic>.from(jsonDecode(recovery) as Map),
        );
      }
      final key = 'employee_sync_pending_${scope.id}';
      var pending = disk.getString(key);
      if (pending == null) {
        final data = await EmployeeDataService.localData(scope.id);
        scope.check();
        final payload = data;
        final saved = disk.getString('employee_sync_last_${scope.id}');
        final previous = saved == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(saved) as Map);
        final unchanged =
            previous != null &&
            await compute(_sameSyncSnapshots, [data, previous]);
        scope.check();
        if (unchanged) {
          final remote = await EmployeeServerApi.request('GET', '/me/data');
          await _receive(scope, disk, previous!, remote);
          await _sendHistoricalRoute(scope, disk);
          message.value = 'Данные актуальны';
          conflict.value = false;
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
      final remote = Map<String, dynamic>.from(response['data'] as Map);
      await _receive(
        scope,
        disk,
        Map<String, dynamic>.from(envelope['data'] as Map),
        remote,
      );
      if (!await disk.remove(key))
        throw StateError('Подтверждение не сохранено');
      await _sendHistoricalRoute(scope, disk);
      message.value = 'Данные переданы';
      conflict.value = false;
    } on EmployeeApiError catch (e) {
      if (!scope.valid) return;
      if (e.status == 401) {
        AccountScope.revoked.value = true;
        await EmployeeServerApi.clearSavedSession();
        await GpsTrackerController.instance.stopForAccess();
      }
      message.value = e.status == 409
          ? '${e.message}. Местные данные сохранены.'
          : e.message;
      conflict.value = e.status == 409;
    } catch (e) {
      if (scope.valid) {
        message.value = 'Нет синхронизации: $e';
        if (e is StateError &&
            e.message.toString().contains('Запись изменена с двух устройств')) {
          conflict.value = true;
        }
      }
    } finally {
      _busy = false;
      if (scope.valid && AccountScope.restricted) {
        await GpsTrackerController.instance.stopForAccess();
      }
    }
  }

  Future<void> _finishRecovery(
    AccountToken scope,
    SharedPreferences disk,
    Map<String, dynamic> job,
  ) async {
    await _receive(
      scope,
      disk,
      Map<String, dynamic>.from(job['local'] as Map),
      Map<String, dynamic>.from(job['remote'] as Map),
      preserveNewLocalChanges: true,
    );
    scope.check();
    if (!await disk.remove('employee_sync_pending_${scope.id}'))
      throw StateError('Очередь не сохранена');
    if (!await disk.remove('employee_sync_recovery_${scope.id}'))
      throw StateError('Восстановление не завершено');
    conflict.value = false;
    message.value =
        'Версия сервера загружена. Более новые местные изменения сохранены.';
  }

  /// Explicit user choice only. Keep the full local version and pending request.
  Future<void> useServerVersion() async {
    if (_busy) throw StateError('Дождитесь завершения синхронизации');
    _busy = true;
    final scope = AccountScope.capture();
    try {
      final disk = await SharedPreferences.getInstance();
      final remote = await EmployeeServerApi.request('GET', '/me/data');
      scope.check();
      final job = {
        'at': DateTime.now().toUtc().toIso8601String(),
        'local': await EmployeeDataService.localData(scope.id),
        'remote': remote,
        'pending': disk.getString('employee_sync_pending_${scope.id}'),
      };
      final raw = jsonEncode(job);
      if (!await disk.setString(
        'employee_sync_backup_${scope.id}_${DateTime.now().microsecondsSinceEpoch}',
        raw,
      ))
        throw StateError('Резервная копия не сохранена');
      if (!await disk.setString('employee_sync_recovery_${scope.id}', raw))
        throw StateError('Восстановление не сохранено');
      await _finishRecovery(scope, disk, job);
    } finally {
      _busy = false;
    }
  }
}

bool _sameSyncSnapshots(List<Map<String, dynamic>> snapshots) =>
    ServerMerge.same(
      {
        ...snapshots[0],
        'preferences': ServerMerge.decodePreferences(
          snapshots[0]['preferences'] as Map,
        ),
      },
      {
        ...snapshots[1],
        'preferences': ServerMerge.decodePreferences(
          snapshots[1]['preferences'] as Map,
        ),
      },
    );
