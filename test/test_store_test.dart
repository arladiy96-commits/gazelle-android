import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazelle_android/services/test_store.dart';
import 'package:gazelle_android/services/activity_service.dart';

Map<String,dynamic> shift(String id,String day,{double hours=8,bool closed=true,int start=100,int end=120})=>
  {'id':id,'start':'${day}T08:00:00','end':closed?'${day}T18:00:00':null,'hoursWorked':hours,'startKm':start,'currentKm':end,'odometerSet':true,'gpsStatus':closed?'stopped':'active','gpsKm':20.0};
void main(){
  setUp((){SharedPreferences.setMockInitialValues({'home_2026_9_salary':324500.0,'server_token':'production-sentinel','gazelle_sandbox_v1':'old-test-sentinel'});TestPreferences.resetCache();});
  test('manual hours are independent from elapsed timer and survive restart',() async{
    await TestStore.open(100,hours:8);final b=await TestStore.load();expect(b.hours(b.active!),8);expect(b.elapsed(b.active!),lessThan(1));
    TestPreferences.resetCache();final restored=await TestStore.load();expect(restored.hours(restored.active!),8);
    await TestStore.odometer(restored.active!['id'] as String,120,close:true,hours:12);final done=await TestStore.load();expect(done.active,isNull);expect(done.hours(done.shifts.single),12);
  });
  test('miniapp September 2026 payroll matches recorded fixture',(){
    final b=TestState(shifts:[shift('s','2026-09-24',closed:false)],records:[
      {'id':'a','shiftId':'s','kind':'trip','type':'Город','amount':4000.0,'isPaid':false},
      {'id':'b','shiftId':'s','kind':'trip','type':'Район','amount':2500.0,'isPaid':true}]);
    final x=b.statistics(DateTime(2026,9));expect(x['norm_hours'],176);expect(x['base_salary'],closeTo(8636.363636,0.001));expect(x['salary'],closeTo(20386.363636,0.001));
  });
  test('miniapp holiday-on-Sunday compatibility is explicit',(){
    final b=TestState(shifts:[shift('s','2026-03-08')]);final x=b.statistics(DateTime(2026,3));
    expect(x['weekend_pay'],10000);expect(x['holiday_pay'],10000);expect(x['salary'],20000);
  });
  test('miniapp groups bonuses and mileage by day for multiple shifts',(){
    final b=TestState(shifts:[shift('a','2026-09-19'),{...shift('b','2026-09-19',start:120,end:140),'start':'2026-09-19T19:00:00','end':'2026-09-19T23:00:00'}]);
    final x=b.statistics(DateTime(2026,9));expect(x['weekend_pay'],10000);expect(x['mileage'],20);expect(x['salary'],10000);
  });
  test('base salary is capped at 190000',(){final b=TestState(shifts:[shift('s','2026-09-24',hours:300)]);expect(b.statistics(DateTime(2026,9))['base_salary'],190000);});
  test('kg storage, automatic paid direction, HUD tonnes, edit and delete',() async{
    await TestStore.open(100);await TestStore.saveRecord({'kind':'trip','type':'Район','amount':2500,'direction':' Щучинск ','isPaid':false});
    final e=(await TestStore.load()).records.single;expect(e['isPaid'],true);expect(e['amount'],2500);
    expect((await ActivityRepository.load(DateTime.now())).total('region_tonnage'),2.5);
    await TestStore.saveRecord({...e,'amount':4000});expect((await ActivityRepository.load(DateTime.now())).total('region_tonnage'),4);
    await TestStore.deleteRecord(e['id'] as String);expect((await ActivityRepository.load(DateTime.now())).total('region_tonnage'),0);
  });
  test('invoice positions retain snapshots; closed invoice cannot be edited',() async{
    await TestStore.open(100);final product=(await TestStore.load()).products.first;
    await TestStore.saveRecord({'kind':'invoice','direction':'Тест','items':[{'name':product['name'],'packKg':50.0,'totalKg':225.0,'checked':true}]});
    var e=(await TestStore.load()).records.single;final row=(e['items'] as List).single as Map;expect(row['quantity'],4);expect(row['totalKg'],225);expect(row['checked'],true);
    await TestStore.deleteProduct(product['id'] as String);e=(await TestStore.load()).records.single;expect((e['items'] as List).length,1);
    await TestStore.closeInvoice(e['id'] as String);await expectLater(TestStore.saveRecord(e),throwsStateError);
    await TestStore.deleteRecord(e['id'] as String);expect((await TestStore.load()).records,isEmpty);
  });
  test('GPS pause and distance do not silently overwrite odometer',() async{
    await TestStore.open(100);final id=(await TestStore.load()).active!['id'] as String;
    await TestStore.gps(id,addKm:10);var s=(await TestStore.load()).active!;expect(s['currentKm'],100);expect(s['gpsKm'],10);
    await TestStore.gps(id,paused:true);await expectLater(TestStore.gps(id,addKm:10),throwsStateError);
    await TestStore.gps(id,paused:false);await TestStore.odometer(id,110,close:true,hours:8);s=(await TestStore.load()).shifts.single;expect(s['gpsStatus'],'stopped');
  });
  test('concurrent starts create one shift; reset never touches original data',() async{
    final results=await Future.wait([TestStore.open(100).then((_)=>true,onError:(_)=>false),TestStore.open(100).then((_)=>true,onError:(_)=>false)]);
    expect(results.where((v)=>v).length,1);await TestStore.reset();expect((await TestStore.load()).shifts,isEmpty);
    final p=await SharedPreferences.getInstance();expect(p.getDouble('home_2026_9_salary'),324500);expect(p.getString('server_token'),'production-sentinel');expect(p.getString('gazelle_sandbox_v1'),'old-test-sentinel');
  });
  test('records cannot be added without an active shift and invalid numbers are rejected',() async{
    await expectLater(TestStore.saveRecord({'kind':'fuel','type':'Газ','amount':20}),throwsStateError);
    await TestStore.open(100);await expectLater(TestStore.saveRecord({'kind':'fuel','type':'Газ','amount':double.nan}),throwsArgumentError);
    await TestStore.saveRecord({'kind':'fuel','type':'Газ','amount':20});expect((await TestStore.load()).records.length,1);
  });
}
