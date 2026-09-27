import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/services/activity_service.dart';
import 'package:gazelle_android/services/test_store.dart';

void main(){
  setUp((){SharedPreferences.setMockInitialValues({'home_2026_9_city_tonnage':71.8});TestPreferences.resetCache();});
  test('test journal does not include or overwrite production totals',() async{
    await TestStore.open(100);
    await ActivityRepository.add(kind:'trip',type:'Город',amount:4,direction:'Султан');
    final b=await ActivityRepository.load(DateTime.now());
    expect(b.total('city_tonnage'),4);expect(b.total('trips'),1);
    expect((await SharedPreferences.getInstance()).getDouble('home_2026_9_city_tonnage'),71.8);
  });
  test('identical trips remain separate events and fuel types remain separate',() async{
    await TestStore.open(100);
    await Future.wait([for(var i=0;i<2;i++)ActivityRepository.add(kind:'trip',type:'Город',amount:4,direction:'Султан')]);
    await ActivityRepository.add(kind:'fuel',type:'Газ',amount:30);
    await ActivityRepository.add(kind:'fuel',type:'Бензин',amount:20);
    final b=await ActivityRepository.load(DateTime.now());
    expect(b.entries.length,4);expect(b.entries.map((e)=>e.id).toSet().length,4);
    expect(b.total('city_tonnage'),8);expect(b.total('gas'),30);expect(b.total('petrol'),20);
  });
  test('unknown journal version is reported without overwriting it',() async{
    final p=await TestPreferences.getInstance();await p.setString('journal','{"version":99}');
    await expectLater(ActivityRepository.load(DateTime.now()),throwsFormatException);
    expect(p.getString('journal'),'{"version":99}');
  });
}
