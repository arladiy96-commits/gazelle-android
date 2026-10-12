import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import 'account_scope.dart';
import 'employee_server_api.dart';
import 'test_store.dart';

const _gpsChannel = MethodChannel('melnitsa/shift_gps');

class GpsRouteStore {
  static const storageKey = 'gazelle_real_gps_routes_v1';

  static Future<Map<String, dynamic>> loadShift(String shiftId) async {
    final scope = AccountScope.capture();
    final prefs = await TestPreferences.getInstance();
    scope.check();
    final raw = prefs.getString(storageKey);
    Map<String, dynamic> legacy = {};
    if (raw != null && raw.isNotEmpty) {
      final root = jsonDecode(raw) as Map;
      if (root[shiftId] is Map)
        legacy = Map<String, dynamic>.from(root[shiftId]);
    }
    Map<String, dynamic> native = {};
    if (Platform.isAndroid) {
      final result = await _gpsChannel.invokeMapMethod<String, dynamic>(
        'route',
        {'account': scope.id, 'shift': shiftId},
      );
      scope.check();
      native = result ?? {};
    }
    if ((legacy['points'] as List? ?? []).isEmpty &&
        (native['points'] as List? ?? []).isEmpty &&
        EmployeeServerApi.enabled) {
      final remote = await EmployeeServerApi.request(
        'GET',
        '/me/routes/${Uri.encodeComponent(shiftId)}',
      );
      scope.check();
      return remote;
    }
    final oldPoints = legacy['points'] as List? ?? const [];
    final newPoints = native['points'] as List? ?? const [];
    return {
      ...legacy,
      ...native,
      'distanceKm':
          ((legacy['distanceKm'] as num?)?.toDouble() ?? 0) +
          ((native['distanceKm'] as num?)?.toDouble() ?? 0),
      'points': [...oldPoints, ...newPoints],
    };
  }

  static Future<List<Map<String, dynamic>>> points(String shiftId) async {
    final route = await loadShift(shiftId);
    return [
      for (final row in route['points'] as List? ?? const [])
        Map<String, dynamic>.from(row as Map),
    ];
  }
}

/// Android owns recording. Flutter only imports durable cumulative counters.
/// Disposing an Activity must NOT end a shift or stop background recording.
class GpsTrackerController with WidgetsBindingObserver {
  GpsTrackerController._();
  static final instance = GpsTrackerController._();
  final ValueNotifier<String?> issue = ValueNotifier(null);
  Timer? _timer;
  bool _attached = false;
  bool _busy = false;
  bool _again = false;
  bool _stopping = false;
  bool _askedPermission = false;
  bool _askedNotification = false;
  int _epoch = 0;
  Future<void> _pending = Future.value();

  bool get _visible =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void _attach() {
    if (_attached) return;
    _attached = true;
    _stopping = false;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_visible && !_stopping) syncWithJournal();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_stopping) syncWithJournal();
  }

  Future<void> syncWithJournal() {
    if (!Platform.isAndroid ||
        !AccountScope.signedIn ||
        _stopping ||
        AccountScope.capture().role.storageValue == 'loader')
      return Future.value();
    if (AccountScope.restricted || !AccountScope.canWrite('work'))
      return stopForAccess();
    _attach();
    if (_busy) {
      _again = true;
      return _pending;
    }
    _busy = true;
    final scope = AccountScope.capture();
    final epoch = _epoch;
    _pending = scope.bind(() async {
      try {
        // Import before checking active: includes the last points of a closed shift.
        final snapshots = await _gpsChannel.invokeListMethod<dynamic>(
          'snapshot',
          {'account': scope.id},
        );
        if (!scope.valid || epoch != _epoch) return;
        await TestStore.importGpsSnapshots(snapshots ?? const []);
        if (!scope.valid || epoch != _epoch) return;
        final state = await TestStore.load();
        if (!scope.valid || epoch != _epoch) return;
        final active = state.active;
        if (active == null || active['gpsStatus'] == 'paused') {
          final finalRows = await _gpsChannel.invokeListMethod<dynamic>(
            'stop',
            {'account': scope.id},
          );
          if (scope.valid && epoch == _epoch)
            await TestStore.importGpsSnapshots(finalRows ?? const []);
          issue.value = null;
          return;
        }
        if (!_visible)
          return; // Existing service keeps working without Flutter.
        if (!await Geolocator.isLocationServiceEnabled()) {
          issue.value = 'GPS выключен. Включите местоположение на телефоне.';
          return;
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied && !_askedPermission) {
          _askedPermission = true;
          permission = await Geolocator.requestPermission();
        }
        if (!scope.valid || epoch != _epoch || !_visible) return;
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          issue.value = 'Пробег не записывается: разрешите точное местоположение в настройках приложения.';
          return;
        }
        // Re-read after the system permission dialog: the shift may have closed.
        final latest = (await TestStore.load()).active;
        if (!scope.valid ||
            epoch != _epoch ||
            latest == null ||
            latest['id'] != active['id'] ||
            latest['gpsStatus'] == 'paused')
          return;
        await _gpsChannel.invokeMethod<void>('start', {
          'account': scope.id,
          'shift': active['id'],
        });
        if (!scope.valid || epoch != _epoch) return;
        issue.value = null;
        if (!_askedNotification && _visible) {
          _askedNotification = true;
          await _gpsChannel.invokeMethod<void>('notifications', {
            'account': scope.id,
          });
        }
      } catch (error) {
        if (scope.valid && epoch == _epoch) {
          issue.value =
              'Не удалось запустить или сохранить GPS: ${error is PlatformException ? error.message ?? error.code : error}';
        }
      } finally {
        _busy = false;
        if (_again && !_stopping) {
          _again = false;
          Zone.root.run(() => scheduleMicrotask(syncWithJournal));
        }
      }
    });
    return _pending;
  }

  /// Explicit logout only. Native service is stopped before the final snapshot.
  Future<void> stop() async {
    _stopping = true;
    _epoch++;
    _again = false;
    await _pending;
    if (Platform.isAndroid && AccountScope.signedIn) {
      final scope = AccountScope.capture();
      final rows = await _gpsChannel.invokeListMethod<dynamic>('stop', {
        'account': scope.id,
      });
      scope.check();
      await scope.bind(() => TestStore.importGpsSnapshots(rows ?? const []));
    }
    await dispose();
  }

  Future<void> resumeForAccess() async {
    if (AccountScope.restricted || !AccountScope.canWrite('work')) return;
    _stopping = false;
    await syncWithJournal();
  }

  /// Policy stop preserves native counters/routes for later recovery. Do not
  /// import into the journal after permission to write has been withdrawn.
  Future<void> stopForAccess() async {
    _stopping = true;
    _epoch++;
    _again = false;
    _timer?.cancel();
    if (Platform.isAndroid && AccountScope.signedIn) {
      final scope = AccountScope.capture();
      await _gpsChannel.invokeMethod<void>('stop', {'account': scope.id});
    }
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();

  Future<void> dispose() async {
    _epoch++;
    _timer?.cancel();
    _timer = null;
    if (_attached) WidgetsBinding.instance.removeObserver(this);
    _attached = false;
    // Android service and saved route intentionally stay alive while shift is open.
    _stopping = false;
  }
}
