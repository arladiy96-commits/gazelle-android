import 'dart:convert';

/// First connection is a replacement, never an upload or a merge. The final
/// marker is written last; an interrupted replacement replays its staged GET.
class ServerBootstrap {
  static Future<void> run({
    required String account,
    required String server,
    required String preferencesKey,
    required Object? Function(String) read,
    required Iterable<String> Function() keys,
    required Future<void> Function(String, Object) write,
    required Future<void> Function(String) remove,
    required Future<Map<String, dynamic>> Function() fetch,
    required Future<void> Function() resetRoutes,
    required Future<Map<String, dynamic>> Function() localData,
  }) async {
    final source = server.replaceFirst(RegExp(r'/+$'), '');
    final marker = 'employee_server_source_v1_$account';
    final stageKey = 'employee_server_bootstrap_v1_$account';
    if (read(marker) == source) return;
    Map<String, dynamic>? remote;
    final staged = read(stageKey);
    if (staged is String) {
      final job = jsonDecode(staged) as Map;
      if (job['source'] == source) {
        remote = Map<String, dynamic>.from(job['data'] as Map);
      }
    }
    remote ??= await fetch();
    if (remote['accountId'] != account ||
        remote['version'] is! int ||
        remote['preferences'] is! Map ||
        remote['loaderShifts'] is! List) {
      throw const FormatException('Неверные данные сервера');
    }
    await write(stageKey, jsonEncode({'source': source, 'data': remote}));
    // No old queued request or native route may survive the initial replacement.
    await resetRoutes();
    for (final key in keys().toList()) {
      if (key == 'employee_restore_$account' ||
          key == 'employee_sync_pending_$account' ||
          key == 'employee_sync_recovery_$account' ||
          key.startsWith('employee_sync_backup_${account}_') ||
          key.startsWith('employee_route_sent_${account}_')) {
        await remove(key);
      }
    }
    await write(preferencesKey, jsonEncode(remote['preferences']));
    await write(
      'melnitsa_loader_shifts_v1_$account',
      jsonEncode(remote['loaderShifts']),
    );
    await write('employee_sync_version_$account', remote['version'] as int);
    await write('employee_sync_last_$account', jsonEncode(await localData()));
    await write(marker, source);
    await remove(stageKey);
  }
}
