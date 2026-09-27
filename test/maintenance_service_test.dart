import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/services/test_store.dart';
import 'package:gazelle_android/services/maintenance_service.dart';

void main() {
  setUp(() {SharedPreferences.setMockInitialValues({});TestPreferences.resetCache();});
  test('first real record replaces examples and persists per account', () async {
    final repo=MaintenanceRepository('a');
    expect((await repo.load()).example,isFalse);
    await repo.record(itemId:'oil',date:DateTime(2026,9,23),atKm:100,currentKm:150,nextKm:1000,note:'Фильтр');
    final book=await MaintenanceRepository('a').load();
    expect(book.example,isFalse);
    expect(book.entries.length,1);
    expect(book.latest('oil')!.nextKm!-book.odometer,850);
    expect(book.latest('oil')!.note,'Фильтр');
    expect((await MaintenanceRepository('b').load()).example,isFalse);
  });
  test('invalid mileage cannot overwrite history', () async {
    final repo=MaintenanceRepository('a');
    await repo.record(itemId:'oil',date:DateTime(2026,9,23),atKm:100,currentKm:150,nextKm:200);
    await expectLater(repo.record(itemId:'brakes',date:DateTime(2026,9,23),atKm:50,currentKm:60),throwsArgumentError);
    expect((await repo.load()).entries.length,1);
  });
  test('backdated entry does not become the latest service', () async {
    final repo=MaintenanceRepository('a');
    await repo.record(itemId:'oil',date:DateTime(2026,9,23),atKm:200,currentKm:400,nextKm:300);
    await repo.record(itemId:'oil',date:DateTime(2026,8,23),atKm:100,currentKm:400,nextKm:200);
    final book=await repo.load();
    expect(book.latest('oil')!.odometer,200);
    expect(book.latest('oil')!.nextKm!-book.odometer,-100);
  });
  test('damaged storage is reported and preserved', () async {
    final repo=MaintenanceRepository('a');
    final prefs=await TestPreferences.getInstance();
    await prefs.setString(repo.key,'broken');
    await expectLater(repo.load(),throwsFormatException);
    expect(prefs.getString(repo.key),'broken');
  });
  test('each category has its own Other history', () async {
    for(final category in MaintenanceCatalog.categories) {
      expect(MaintenanceCatalog.items.where((i)=>i.category==category&&i.title=='Другое').length,1);
    }
    final repo=MaintenanceRepository('other-test');
    await expectLater(repo.record(itemId:'other_engine',date:DateTime(2026,9,23),atKm:100,currentKm:100),throwsArgumentError);
    await repo.record(itemId:'other_engine',date:DateTime(2026,9,23),atKm:100,currentKm:100,note:'Замена патрубка');
    await repo.record(itemId:'other_chassis',date:DateTime(2026,9,23),atKm:100,currentKm:100,note:'Рулевой наконечник');
    final book=await repo.load();
    expect(book.history('other_engine').single.note,'Замена патрубка');
    expect(book.history('other_chassis').single.note,'Рулевой наконечник');
  });

}
