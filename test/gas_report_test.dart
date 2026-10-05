import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/services/test_store.dart';
import 'package:gazelle_android/services/gas_report_service.dart';

Map<String, dynamic> shift(
  String id,
  int day, {
  int start = 184520,
  int km = 2500,
  bool manual = false,
  bool open = false,
}) => {
  'id': id,
  'start': DateTime(2026, 10, day, 8).toIso8601String(),
  'end': open ? null : DateTime(2026, 10, day, 18).toIso8601String(),
  'startKm': manual ? null : start,
  'currentKm': manual ? null : start + km,
  'mileageSource': manual ? 'manual' : 'odometer',
  'manualKm': manual ? km : null,
  'odometerSet': !manual && !open,
};
Map<String, dynamic> fuel(
  String id,
  String shiftId,
  String type,
  double amount,
) => {
  'id': id,
  'shiftId': shiftId,
  'kind': 'fuel',
  'type': type,
  'amount': amount,
  'date': '2026-10-01T12:00:00',
};
Map<String, dynamic> trip(String id, String type, String direction) => {
  'id': id,
  'shiftId': 'a',
  'kind': 'trip',
  'type': type,
  'direction': direction,
  'amount': 1000,
  'date': '2026-10-01T13:00:00',
};
TestState fixture() => TestState(
  shifts: [shift('a', 1), shift('b', 2, start: 187020, manual: true)],
  records: [
    fuel('g1', 'a', 'Газ', 800),
    fuel('g2', 'b', 'Газ', 700),
    fuel('p1', 'a', 'Бензин', 120),
    trip('t1', 'Город', 'Султан'),
    trip('t2', 'Город', 'Петрокондитер'),
    trip('t3', 'Район', 'Щучинск'),
    trip('t4', 'Район', 'Щучинск'),
    trip('t5', 'Район', 'Пресновка'),
  ],
);
void main() {
  final october = DateTime(2026, 10),
      november = DateTime(2026, 11),
      december = DateTime(2026, 12);
  Future<void> write(TestState b) async {
    await (await TestPreferences.getInstance()).setString(
      'journal',
      jsonEncode(b.toJson()),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestPreferences.resetCache();
  });
  test(
    '5000 km from mixed sources; 1500 L gas, 1400 L consumption, 150 L balance',
    () {
      final r = GasReportRepository.derive(fixture(), october, {
        '2026-10': {'openingOverride': 50},
      });
      expect(r.km, 5000);
      expect(r.gas, 1500);
      expect(r.petrol, 120);
      expect(r.consumption, 1400);
      expect(r.closing, 150);
      expect(r.days.first.directions, 'Город, Щучинск, Пресновка');
      expect(r.days.last.startKm, isNull);
      expect(r.days.last.endKm, isNull);
      expect(r.days.last.km, 2500);
      expect(r.pending, 0);
    },
  );
  test(
    'multiple shifts on same day contribute each distance, gas and petrol',
    () {
      final b = fixture();
      b.shifts[1]['start'] = '2026-10-01T19:00:00';
      b.shifts[1]['end'] = '2026-10-01T23:00:00';
      final r = GasReportRepository.derive(b, october, {});
      expect(r.days.length, 1);
      expect(r.days.single.km, 5000);
      expect(r.days.single.gas, 1500);
      expect(r.days.single.startKm, 184520);
      expect(r.days.single.endKm, isNull);
      expect(r.opening, isNull);
      expect(r.closing, isNull);
    },
  );
  test(
    'ordinary shifts use odometer; manual failure preserves only known start',
    () {
      final b = TestState(shifts: [shift('a', 1, km: 137)]);
      var r = GasReportRepository.derive(b, october, {});
      expect(r.km, 137);
      expect(r.days.single.startKm, 184520);
      expect(r.days.single.endKm, 184657);
      b.shifts.single.addAll({
        'mileageSource': 'manual',
        'manualKm': 137,
        'currentKm': 184520,
        'odometerSet': false,
      });
      r = GasReportRepository.derive(b, october, {});
      expect(r.km, 137);
      expect(r.days.single.startKm, 184520);
      expect(r.days.single.endKm, isNull);
    },
  );
  test('submission persists and carries 150 L; later source edits never silently change carry', () async {
    final b = fixture();
    await write(b);
    await GasReportRepository.setOpening(october, 50);
    var r = await GasReportRepository.load(october);
    expect((await GasReportRepository.load(november)).opening, isNull);
    await GasReportRepository.submit(october, expectedSignature: r.signature);
    TestPreferences.resetCache();
    r = await GasReportRepository.load(october);
    expect(r.submitted, true);
    expect(r.changed, false);
    expect(r.fixedClosing, 150);
    expect((await GasReportRepository.load(november)).opening, 150);
    b.records[0]['amount'] = 900;
    await write(b);
    r = await GasReportRepository.load(october);
    expect(r.closing, 250);
    expect(r.changed, true);
    expect(r.fixedClosing, 150);
    expect((await GasReportRepository.load(november)).opening, 150);
    await GasReportRepository.submit(october, expectedSignature: r.signature);
    expect((await GasReportRepository.load(november)).opening, 250);
    expect((await GasReportRepository.load(october)).changed, false);
  });
  test('updating upstream carry marks submitted next month dirty but keeps its frozen carry', () async {
    await write(fixture());
    await GasReportRepository.setOpening(october, 50);
    await GasReportRepository.submit(
      october,
      expectedSignature: (await GasReportRepository.load(october)).signature,
    );
    await GasReportRepository.submit(
      november,
      expectedSignature: (await GasReportRepository.load(november)).signature,
    );
    await GasReportRepository.setOpening(october, 100);
    await GasReportRepository.submit(
      october,
      expectedSignature: (await GasReportRepository.load(october)).signature,
    );
    final n = await GasReportRepository.load(november);
    expect(n.opening, 200);
    expect(n.changed, true);
    expect(n.fixedClosing, 150);
    expect((await GasReportRepository.load(december)).opening, 150);
  });
  test('manual correction survives carry update; can explicitly resume automatic carry', () async {
    await write(fixture());
    await GasReportRepository.setOpening(october, 50);
    await GasReportRepository.submit(
      october,
      expectedSignature: (await GasReportRepository.load(october)).signature,
    );
    await GasReportRepository.setOpening(november, 75);
    expect((await GasReportRepository.load(november)).opening, 75);
    expect((await GasReportRepository.load(november)).carriedOpening, 150);
    await GasReportRepository.useCarry(november);
    expect((await GasReportRepository.load(november)).opening, 150);
    await expectLater(
      GasReportRepository.setOpening(october, -1),
      throwsArgumentError,
    );
  });
  test('stale confirmation rejected and queue remains usable', () async {
    final b = fixture();
    await write(b);
    await GasReportRepository.setOpening(october, 50);
    final r = await GasReportRepository.load(october);
    b.shifts[1]['manualKm'] = 2000;
    await write(b);
    await expectLater(
      GasReportRepository.submit(october, expectedSignature: r.signature),
      throwsStateError,
    );
    final fresh = await GasReportRepository.load(october);
    expect(fresh.km, 4500);
    expect(fresh.consumption, 1260);
    await GasReportRepository.submit(
      october,
      expectedSignature: fresh.signature,
    );
    expect((await GasReportRepository.load(october)).submitted, true);
  });
  test('gas, petrol, directions and odometer edits all invalidate submitted fingerprint', () async {
    final b = fixture();
    await write(b);
    await GasReportRepository.setOpening(october, 50);
    await GasReportRepository.submit(
      october,
      expectedSignature: (await GasReportRepository.load(october)).signature,
    );
    for (final change in <void Function(TestState)>[
      (b) => b.records[0]['amount'] = 801,
      (b) => b.records[2]['amount'] = 121,
      (b) => b.records.last['direction'] = 'Кокшетау',
      (b) => b.shifts[0]['currentKm'] = 187021,
    ]) {
      final changed = fixture();
      change(changed);
      await write(changed);
      expect((await GasReportRepository.load(october)).changed, true);
      expect((await GasReportRepository.load(november)).opening, 150);
    }
  });
  test('unfinished shifts cannot be submitted; missing opening cannot be silently zero', () async {
    await write(TestState(shifts: [shift('a', 1, open: true)]));
    await GasReportRepository.setOpening(october, 0);
    final r = await GasReportRepository.load(october);
    expect(r.pending, 1);
    expect(r.km, 0);
    await expectLater(
      GasReportRepository.submit(october, expectedSignature: r.signature),
      throwsStateError,
    );
    final n = await GasReportRepository.load(november);
    await expectLater(
      GasReportRepository.submit(november, expectedSignature: n.signature),
      throwsStateError,
    );
  });
  test('year boundary, negative carry and unique district-only directions', () {
    final b = fixture();
    b.records.removeWhere((r) => r['type'] == 'Город');
    final r = GasReportRepository.derive(b, october, {
      '2026-09': {'submittedAt': '2026-09-30', 'fixedClosing': -20},
    });
    expect(r.opening, -20);
    expect(r.days.first.directions, 'Щучинск, Пресновка');
    final january = GasReportRepository.derive(TestState(), DateTime(2027, 1), {
      '2026-12': {'submittedAt': '2026-12-31', 'fixedClosing': 150},
    });
    expect(january.opening, 150);
  });
}
