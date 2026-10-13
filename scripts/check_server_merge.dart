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
  print('$checks server merge checks passed');
}
