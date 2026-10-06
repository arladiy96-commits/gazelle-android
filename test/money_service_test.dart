import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/services/money_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('invoice decimals and cash reconcile exactly in tiyn', () {
    final values = [
      '100,10',
      '200,90',
      '999999999,99',
    ].map(MoneyCount.parseAmount).toList();
    expect(values, [10010, 20090, 99999999999]);
    final c = MoneyCount(
      id: 'a',
      date: DateTime(2026),
      invoices: values.take(2).toList(),
      counts: {200: 1, 100: 1, 1: 1},
    );
    expect(c.expected, 30100);
    expect(c.counted, 30100);
    expect(c.difference, 0);
    expect(MoneyCount.format(-123456), '−1 234,56');
    expect(MoneyCount.parseAmount('4,999'), 0);
    expect(MoneyCount.parseAmount('-2'), 0);
  });
  test('shortage and surplus include all denominations including coins', () {
    final c = MoneyCount(
      id: 'a',
      date: DateTime(2026),
      invoices: [2500000],
      counts: {20000: 1, 2000: 2, 500: 1, 200: 2, 50: 1, 20: 2, 5: 2},
    );
    expect(c.difference, 0);
    final shortage = MoneyCount(
      id: 'b',
      date: DateTime(2026),
      invoices: [2500000],
      counts: {20000: 1},
    );
    expect(shortage.difference, -500000);
    final extra = MoneyCount(
      id: 'c',
      date: DateTime(2026),
      invoices: [2500000],
      counts: {20000: 2},
    );
    expect(extra.difference, 1500000);
  });
  test(
    'draft, pending edit and history survive reopening, accounts are isolated',
    () async {
      final repo = MoneyRepository('driver:a');
      final count = MoneyCount(
        id: '1',
        date: DateTime(2026),
        invoices: [50000, 70000],
        counts: {1000: 1},
        input: '600',
        editing: 0,
      );
      await repo.store(count, [count.snapshot(committed: true)]);
      final loaded = await MoneyRepository('driver:a').load();
      expect(loaded.draft.input, '600');
      expect(loaded.draft.editing, 0);
      expect(loaded.history.single.expected, 120000);
      expect(loaded.history.single.input, '');
      expect((await MoneyRepository('driver:b').load()).history, isEmpty);
      // Concurrent writes retain submission order rather than finishing out of order.
      await Future.wait([
        repo.store(count, []),
        repo.store(count, [count.snapshot(committed: true)]),
      ]);
      expect((await repo.load()).history.length, 1);
    },
  );
}
