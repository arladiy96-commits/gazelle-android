import 'dart:convert';

import '../models/advance_report.dart';
import 'test_store.dart';

class AdvanceReportData {
  final AdvanceLedger ledger;
  final AdvanceReport current;
  AdvanceReportData(this.ledger, this.current);
}

/// Reads existing trips, writes only report metadata/manual expenses/snapshots.
/// Uses the same sandbox as the existing journal, without modifying trips.
class AdvanceReportRepository {
  final String _key;
  static Future<void> _queue = Future<void>.value();
  AdvanceReportRepository(String owner)
    : _key = 'advance_report_v1_${base64Url.encode(utf8.encode(owner))}';
  Future<AdvanceLedger> _ledger() async => AdvanceLedger.decode(
    (await TestPreferences.getInstance()).getString(_key),
  );
  Future<AdvanceReportData> load() async {
    await _queue;
    final ledger = await _ledger();
    return AdvanceReportData(
      ledger,
      ledger.current((await TestStore.load()).records),
    );
  }

  Future<void> _change(
    Future<AdvanceLedger> Function(AdvanceLedger ledger) edit,
  ) {
    final task = _queue.then((_) async {
      final next = await edit(await _ledger());
      await (await TestPreferences.getInstance()).setString(
        _key,
        jsonEncode(next.toJson()),
      );
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
        final book = await TestStore.load();
        return ledger.submit(book.records, expectedSignature, DateTime.now());
      });
}
