import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import 'account_scope.dart';

import 'test_store.dart';

class GpsRouteStore {
  static const storageKey = 'gazelle_real_gps_routes_v1';

  static Future<Map<String, dynamic>> _root() async {
    final prefs = await TestPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }

  static Future<void> _saveRoot(Map<String, dynamic> data) async {
    final prefs = await TestPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> loadShift(String shiftId) async {
    final root = await _root();
    final route = root[shiftId];
    if (route is Map<String, dynamic>) return route;
    if (route is Map) return Map<String, dynamic>.from(route);
    return {'distanceKm': 0.0, 'points': <Map<String, dynamic>>[]};
  }

  static Future<List<Map<String, dynamic>>> points(String shiftId) async {
    final route = await loadShift(shiftId);
    final raw = route['points'] as List? ?? const [];
    return [for (final row in raw) Map<String, dynamic>.from(row as Map)];
  }

  static double _pointDistanceMeters(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    return Geolocator.distanceBetween(
      (a['lat'] as num).toDouble(),
      (a['lng'] as num).toDouble(),
      (b['lat'] as num).toDouble(),
      (b['lng'] as num).toDouble(),
    );
  }

  static Future<double> appendPoint({
    required String shiftId,
    required double lat,
    required double lng,
    required DateTime time,
    required double accuracy,
    double? speed,
  }) async {
    final account = AccountScope.capture();
    final root = await _root();
    account.check();
    final current = root[shiftId];
    final route = current is Map<String, dynamic>
        ? Map<String, dynamic>.from(current)
        : current is Map
        ? Map<String, dynamic>.from(current)
        : <String, dynamic>{};

    final rawPoints = route['points'] as List? ?? const [];
    final pts = [
      for (final row in rawPoints) Map<String, dynamic>.from(row as Map),
    ];

    final point = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'time': time.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed ?? 0.0,
    };

    double addedKm = 0.0;
    bool shouldStore = pts.isEmpty;

    if (pts.isNotEmpty) {
      final last = pts.last;
      final meters = _pointDistanceMeters(last, point);
      final prevTime =
          DateTime.tryParse(last['time']?.toString() ?? '') ?? time;
      final seconds = time.difference(prevTime).inSeconds.abs();

      // Filter GPS jitter but still keep the route alive in time.
      shouldStore = meters >= 8 || seconds >= 20;
      if (meters >= 8 && meters <= 3000) {
        addedKm = meters / 1000.0;
      }
    }

    if (shouldStore) {
      pts.add(point);
    } else if (pts.isNotEmpty) {
      pts[pts.length - 1] = point;
    }

    route['points'] = pts;
    route['distanceKm'] =
        ((route['distanceKm'] as num?)?.toDouble() ?? 0.0) + addedKm;
    route['updatedAt'] = DateTime.now().toIso8601String();
    root[shiftId] = route;
    await account.bind(() => _saveRoot(root));
    return addedKm;
  }
}

class GpsTrackerController {
  GpsTrackerController._();

  static final GpsTrackerController instance = GpsTrackerController._();

  StreamSubscription<Position>? _sub;
  Future<void> _locationQueue = Future<void>.value();
  String? _shiftId;
  bool _syncing = false;
  bool _syncAgain = false;
  int _lifecycle = 0;

  Future<void> syncWithJournal() async {
    if (!AccountScope.signedIn ||
        AccountScope.capture().role.storageValue == 'loader')
      return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    final account = AccountScope.capture();
    final lifecycle = _lifecycle;
    _syncing = true;
    try {
      final state = await TestStore.load();
      if (!account.valid || lifecycle != _lifecycle) return;
      final active = state.active;
      if (active == null) {
        await stop();
        return;
      }

      final shiftId = active['id']?.toString();
      final paused = active['gpsStatus'] == 'paused';
      if (shiftId == null || paused) {
        await stop();
        return;
      }

      final ok = await _ensureReady();
      if (!account.valid || lifecycle != _lifecycle) return;
      if (!ok) {
        await stop();
        return;
      }

      if (_sub != null && _shiftId == shiftId) return;

      await stop();
      if (!account.valid) return;
      final running = _lifecycle;
      _shiftId = shiftId;

      try {
        final first = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        ).timeout(const Duration(seconds: 8));
        if (!account.valid || running != _lifecycle) return;
        await account.bind(() => _handlePosition(shiftId, first));
      } catch (_) {}

      if (!account.valid || running != _lifecycle) return;
      _sub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 10,
            ),
          ).listen(
            (position) {
              _locationQueue = _locationQueue
                  .then(
                    (_) =>
                        account.bind(() => _handlePosition(shiftId, position)),
                  )
                  .catchError((Object error) {
                    // Ошибка записи точки не прерывает дальнейшие обновления.
                  });
            },
            onError: (Object error) {
              // При потере сигнала не записываем вымышленные координаты.
            },
          );
    } finally {
      _syncing = false;
      if (_syncAgain) {
        _syncAgain = false;
        scheduleMicrotask(() {
          syncWithJournal().catchError((Object _) {});
        });
      }
    }
  }

  Future<bool> _ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _handlePosition(String shiftId, Position p) async {
    if (_shiftId != shiftId) return;
    if (p.accuracy.isFinite && p.accuracy > 45) return;

    final addedKm = await GpsRouteStore.appendPoint(
      shiftId: shiftId,
      lat: p.latitude,
      lng: p.longitude,
      time: p.timestamp ?? DateTime.now(),
      accuracy: p.accuracy,
      speed: p.speed,
    );

    if (addedKm > 0) {
      try {
        await TestStore.gps(shiftId, addKm: addedKm);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    _lifecycle++;
    await _sub?.cancel();
    _sub = null;
    _shiftId = null;
  }

  Future<void> dispose() async => stop();
}
