import 'dart:convert';

import '../lib/models/server_merge.dart';

void main() {
  var checks = 0;
  void check(bool v) {
    if (!v) throw StateError('Merge check ${checks + 1} failed');
    checks++;
  }

  check(
    ServerMerge.same(
      ServerMerge.merge({'a': 1, 'b': 1}, {'a': 2, 'b': 1}, {'a': 1, 'b': 2}),
      {'a': 2, 'b': 2},
    ),
  );
  check(
    ServerMerge.same(
      ServerMerge.merge(
        [
          {'id': 'a', 'v': 1},
        ],
        [
          {'id': 'a', 'v': 2},
        ],
        [
          {'id': 'a', 'v': 1},
          {'id': 'b', 'v': 3},
        ],
      ),
      [
        {'id': 'a', 'v': 2},
        {'id': 'b', 'v': 3},
      ],
    ),
  );
  var conflict = false;
  try {
    ServerMerge.merge({'a': 1}, {'a': 2}, {'a': 3});
  } on StateError {
    conflict = true;
  }
  check(conflict);
  check(ServerMerge.same(ServerMerge.merge({'a': 1}, {}, {'a': 1}), {}));
  check(
    ServerMerge.same(ServerMerge.merge({'a': 1}, {'a': 2}, {'a': 2}), {'a': 2}),
  );
  check(
    ServerMerge.same(
      ServerMerge.mergePreferences(
        {'journal': '{"a":1,"b":1}'},
        {'journal': '{"a":2,"b":1}'},
        {'journal': '{"a":1,"b":2}'},
      ),
      {'journal': '{"a":2,"b":2}'},
    ),
  );

  // Explicit resolution uses the snapshot taken at confirmation, not the old
  // sync baseline. Keep a new shift created while recovery was stuck.
  final backup = {
    'shifts': [
      {'id': 'old', 'km': 15},
    ],
  };
  final current = {
    'shifts': [
      {'id': 'old', 'km': 15},
      {'id': 'new', 'km': 0, 'end': null},
    ],
  };
  final server = {
    'shifts': [
      {'id': 'old', 'km': 20},
      {'id': 'history', 'km': 100},
    ],
  };
  final recovered =
      ServerMerge.merge(backup, current, server, 'data', true) as Map;
  check((recovered['shifts'] as List).length == 3);
  check(
    (recovered['shifts'] as List).any(
      (r) => r['id'] == 'new' && r['end'] == null,
    ),
  );
  check(
    (recovered['shifts'] as List).any((r) => r['id'] == 'old' && r['km'] == 20),
  );
  check(
    ServerMerge.same(
      ServerMerge.merge(backup, recovered, server, 'data', true),
      recovered,
    ),
  );
  // The observed delete-versus-edit conflict must preserve the later local edit.
  final changed = {
    'shifts': [
      {'id': 'old', 'km': 16},
    ],
  };
  final removed = {'shifts': []};
  check(
    ServerMerge.same(
      ServerMerge.merge(backup, changed, removed, 'data', true),
      changed,
    ),
  );
  // Without explicit resolution, the same conflict must still be reported.
  var ordinaryConflict = false;
  try {
    ServerMerge.merge(backup, changed, removed);
  } on StateError {
    ordinaryConflict = true;
  }
  check(ordinaryConflict);
  check(
    ServerMerge.same(
      ServerMerge.merge(backup, backup, removed, 'data', true),
      removed,
    ),
  );
  check(
    ServerMerge.same(
      ServerMerge.mergePreferences(
        {'journal': jsonEncode(backup)},
        {'journal': jsonEncode(changed)},
        {'journal': jsonEncode(removed)},
        preserveNewLocalChanges: true,
      ),
      {'journal': jsonEncode(changed)},
    ),
  );
  print('$checks server merge checks passed');
}
