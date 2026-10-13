import 'dart:convert';

import '../lib/models/server_bootstrap.dart';

Future<void> main() async {
  var checks = 0;
  final remote = <String, dynamic>{
    'accountId': '42',
    'version': 7,
    'preferences': {'journal': 'server-all-months'},
    'loaderShifts': [],
  };
  Map<String, Object> seed() => {
    'prefs': '{"journal":"old-local"}',
    'employee_sync_version_42': 99,
    'employee_sync_pending_42': 'old-upload',
    'employee_sync_recovery_42': 'old-recovery',
    'employee_route_sent_42_local': true,
    'employee_sync_pending_43': 'other-account',
  };
  Future<void> run(
    Map<String, Object> disk, {
    String server = 'https://example.test',
    int? failAt,
    bool failFetch = false,
    Map<String, dynamic>? response,
  }) async {
    var writes = 0;
    void fault() {
      if (writes++ == failAt) throw StateError('disk interrupted');
    }

    await ServerBootstrap.run(
      account: '42',
      server: server,
      preferencesKey: 'prefs',
      read: (key) => disk[key],
      keys: () => disk.keys,
      write: (key, value) async {
        fault();
        disk[key] = value;
      },
      remove: (key) async {
        fault();
        disk.remove(key);
      },
      fetch: () async {
        if (failFetch) throw StateError('offline');
        return response ?? remote;
      },
      resetRoutes: () async {
        fault();
        disk['nativeRoutes'] = 'empty';
      },
      localData: () async => {
        'preferences': jsonDecode(disk['prefs'] as String),
        'loaderShifts': jsonDecode(
          disk['melnitsa_loader_shifts_v1_42'] as String,
        ),
      },
    );
  }

  void expect(bool value) {
    if (!value) throw StateError('check ${checks + 1}');
    checks++;
  }

  final offline = seed();
  try {
    await run(offline, failFetch: true);
  } catch (_) {}
  expect(offline.toString() == seed().toString());
  final wrong = seed();
  try {
    await run(wrong, response: {...remote, 'accountId': '43'});
  } catch (_) {}
  expect(wrong.toString() == seed().toString());
  // Every persistent step can fail before completion. Retry must complete from
  // the staged server snapshot, even with an old version or an old pending POST.
  for (var failure = 0; failure < 12; failure++) {
    final disk = seed();
    try {
      await run(disk, failAt: failure);
    } catch (_) {}
    await run(disk);
    expect(disk['prefs'] == jsonEncode(remote['preferences']));
    expect(disk['employee_sync_version_42'] == 7);
    expect(!disk.containsKey('employee_sync_pending_42'));
    expect(!disk.containsKey('employee_sync_recovery_42'));
    expect(disk['employee_sync_pending_43'] == 'other-account');
    expect(disk['nativeRoutes'] == 'empty');
  }
  final connected = seed();
  await run(connected);
  connected['prefs'] = '{"journal":"new-unsent-work"}';
  await run(connected, failFetch: true);
  expect(connected['prefs'] == '{"journal":"new-unsent-work"}');
  await run(connected, server: 'https://another.test');
  expect(connected['prefs'] == jsonEncode(remote['preferences']));
  print('$checks bootstrap checks passed');
}
