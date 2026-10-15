import 'dart:convert';

/// Three-way merge. Equal edits are idempotent; conflicting edits stay local.
class ServerMerge {
  static const _missing = Object();
  static bool same(Object? a, Object? b) {
    if (identical(a, _missing) || identical(b, _missing))
      return identical(a, b);
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every((k) => b.containsKey(k) && same(a[k], b[k]));
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => i).every((i) => same(a[i], b[i]));
    }
    return a == b;
  }

  static Object? merge(
    Object? base,
    Object? local,
    Object? remote, [
    String path = 'data',
    bool preserveNewLocalChanges = false,
  ]) {
    if (same(local, base)) return remote;
    if (same(remote, base) || same(local, remote)) return local;
    if (base is Map && local is Map && remote is Map) {
      final out = <String, dynamic>{};
      for (final k in {...base.keys, ...local.keys, ...remote.keys}) {
        final value = merge(
          base.containsKey(k) ? base[k] : _missing,
          local.containsKey(k) ? local[k] : _missing,
          remote.containsKey(k) ? remote[k] : _missing,
          '$path.$k',
          preserveNewLocalChanges,
        );
        if (!identical(value, _missing)) out[k as String] = value;
      }
      return out;
    }
    if (base is List && local is List && remote is List) {
      for (final key in ['id', 'day', 'invoiceId', 'itemId', 'number']) {
        if ([
          ...base,
          ...local,
          ...remote,
        ].every((r) => r is Map && r.containsKey(key))) {
          Map<String, dynamic> indexed(List rows) {
            final out = <String, dynamic>{};
            for (final row in rows) {
              if (out.containsKey('${row[key]}'))
                throw StateError('Повтор записи: $path');
              out['${row[key]}'] = row;
            }
            return out;
          }

          return (merge(
            indexed(base),
            indexed(local),
            indexed(remote),
            path,
            preserveNewLocalChanges,
          ) as Map).values.toList();
        }
      }
    }
    // Only after an explicit server-version choice: base is the durable local
    // backup at confirmation time. Differences from it are newer user work.
    if (preserveNewLocalChanges) return local;
    throw StateError(
      'Запись изменена с двух устройств: $path. Местные данные сохранены.',
    );
  }

  static Map<String, dynamic> decodePreferences(Map raw) => {
    for (final e in raw.entries) e.key as String: _decode(e.value),
  };
  static Object? _decode(Object? value) {
    if (value is String) {
      try {
        return jsonDecode(value);
      } on FormatException {
        return value;
      }
    }
    return value;
  }

  static Map<String, dynamic> mergePreferences(
    Map base,
    Map local,
    Map remote, {
    bool preserveNewLocalChanges = false,
  }) {
    final merged = merge(
      decodePreferences(base),
      decodePreferences(local),
      decodePreferences(remote),
      'data',
      preserveNewLocalChanges,
    ) as Map;
    return {
      for (final e in merged.entries)
        e.key as String: e.value is Map || e.value is List
            ? jsonEncode(e.value)
            : e.value,
    };
  }
}
