import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Integer tiyn: invoice arithmetic never uses floating point.
class MoneyCount {
  static const denominations = [
    20000,
    10000,
    5000,
    2000,
    1000,
    500,
    200,
    100,
    50,
    20,
    10,
    5,
    2,
    1,
  ];
  final String id;
  final DateTime date;
  final List<int> invoices;
  final Map<int, int> counts;
  final String input;
  final int? editing;
  const MoneyCount({
    required this.id,
    required this.date,
    this.invoices = const [],
    this.counts = const {},
    this.input = '',
    this.editing,
  });
  factory MoneyCount.empty() {
    final now = DateTime.now();
    return MoneyCount(id: now.microsecondsSinceEpoch.toString(), date: now);
  }
  int get expected => invoices.fold(0, (a, b) => a + b);
  int get counted =>
      counts.entries.fold(0, (a, b) => a + b.key * b.value * 100);
  int get difference => counted - expected;
  bool get hasData =>
      invoices.isNotEmpty ||
      counts.values.any((v) => v > 0) ||
      input.isNotEmpty;
  MoneyCount snapshot({bool committed = false}) => MoneyCount(
    id: id,
    date: committed ? DateTime.now() : date,
    invoices: List.unmodifiable(invoices),
    counts: Map.unmodifiable(counts),
    input: committed ? '' : input,
    editing: committed ? null : editing,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'invoices': invoices,
    'counts': counts.map((k, v) => MapEntry('$k', v)),
    'input': input,
    'editing': editing,
  };
  factory MoneyCount.fromJson(Map<String, dynamic> j) {
    final invoices = (j['invoices'] as List).cast<int>();
    final counts = (j['counts'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), v as int),
    );
    final input = j['input'] as String? ?? '';
    final editing = j['editing'] as int?;
    if (invoices.any((v) => v <= 0) ||
        counts.entries.any(
          (e) => !denominations.contains(e.key) || e.value < 0,
        ) ||
        (editing != null && (editing < 0 || editing >= invoices.length)) ||
        !RegExp(r'^\d{0,9}([.,]\d{0,2})?$').hasMatch(input)) {
      throw const FormatException('Повреждены данные подсчёта');
    }
    return MoneyCount(
      id: j['id'] as String,
      date: DateTime.parse(j['date'] as String),
      invoices: List.unmodifiable(invoices),
      counts: Map.unmodifiable(counts),
      input: input,
      editing: editing,
    );
  }
  static int parseAmount(String value) {
    final parts = value.replaceAll(',', '.').split('.');
    if (parts.length > 2 || !RegExp(r'^\d{1,9}([.,]\d{0,2})?$').hasMatch(value))
      return 0;
    return int.parse(parts[0]) * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  }

  static String format(int tiyn) {
    final n = tiyn.abs();
    final whole = '${n ~/ 100}'.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '${tiyn < 0 ? '−' : ''}$whole${n % 100 == 0 ? '' : ',${(n % 100).toString().padLeft(2, '0')}'}';
  }

  static String editable(int tiyn) =>
      '${tiyn ~/ 100}${tiyn % 100 == 0 ? '' : ',${(tiyn % 100).toString().padLeft(2, '0')}'}';
}

class MoneyLedger {
  final MoneyCount draft;
  final List<MoneyCount> history;
  MoneyLedger(this.draft, this.history);
}

/// Separate from shifts and salary; scoped to the current login and role.
class MoneyRepository {
  final String _key;
  static Future<void> _queue = Future<void>.value();
  MoneyRepository(String owner)
    : _key = 'melnitsa_money_v1_${base64Url.encode(utf8.encode(owner))}';
  Future<MoneyLedger> load() async {
    await _queue;
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return MoneyLedger(MoneyCount.empty(), []);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['version'] != 1)
      throw const FormatException('Неизвестная версия подсчётов');
    return MoneyLedger(
      MoneyCount.fromJson(j['draft'] as Map<String, dynamic>),
      (j['history'] as List)
          .map((e) => MoneyCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> store(MoneyCount draft, List<MoneyCount> history) {
    final raw = jsonEncode({
      'version': 1,
      'draft': draft.toJson(),
      'history': history.map((e) => e.toJson()).toList(),
    });
    final task = _queue.then((_) async {
      final disk = await SharedPreferences.getInstance();
      if (!await disk.setString(_key, raw))
        throw StateError('Не удалось сохранить подсчёт');
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }
}
