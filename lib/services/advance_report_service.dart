import 'dart:convert';

import '../models/advance_report.dart';
import 'test_store.dart';
import 'account_scope.dart';

class AdvanceReportData {
  final AdvanceLedger ledger;
  final AdvanceReport current;
  AdvanceReportData(this.ledger, this.current);
}

/// Reads existing trips, writes only report metadata/manual expenses/snapshots.
/// Uses the same sandbox as the existing journal, without modifying trips.
class AdvanceReportRepository {
  final _scope = AccountScope.capture();
  Future<TestPreferences> _preferences() =>
      _scope.bind(TestPreferences.getInstance);
  final String _key;
  static Future<void> _queue = Future<void>.value();
  static Future<void> flush() => _queue;
  AdvanceReportRepository(String owner)
    : _key = 'advance_report_v1_${base64Url.encode(utf8.encode(owner))}';
  List<Map<String, dynamic>> _allowanceRecords(TestState book) => [
    for (final r in book.records)
      {...r, 'calculationSettings': book.settingsFor(r)},
  ];
  Future<AdvanceLedger> _ledger() async =>
      AdvanceLedger.decode((await _preferences()).getString(_key));
  Future<AdvanceReportData> load() async {
    await _queue;
    final ledger = await _ledger();
    return AdvanceReportData(
      ledger,
      ledger.current(_allowanceRecords(await TestStore.load())),
    );
  }

  Future<void> _change(
    Future<AdvanceLedger> Function(AdvanceLedger ledger) edit,
  ) {
    final task = _queue.then((_) async {
      final prefs = await _preferences();
      final base = prefs.getString(_key);
      final next = await edit(AdvanceLedger.decode(base));
      await prefs.mergeString(_key, base, jsonEncode(next.toJson()));
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  Future<void> saveExpense(AdvanceRow row) =>
      _change((AdvanceLedger ledger) async => ledger.withExpense(row));
  Future<void> deleteExpense(String id) =>
      _change((AdvanceLedger ledger) async => ledger.withoutExpense(id));
  Future<void> setCash(int? value) =>
      _change((AdvanceLedger ledger) async => ledger.withCash(value));
  Future<void> submit(String expectedSignature) =>
      _change((AdvanceLedger ledger) async {
        AccountScope.requireSubmit('advance');
        final book = await TestStore.load();
        return ledger.submit(
          _allowanceRecords(book),
          expectedSignature,
          DateTime.now(),
        );
      });
}
