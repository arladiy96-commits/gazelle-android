import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This build has no production adapter or sync queue. Never migrate this key.
class TestPreferences {
  static const storageKey = 'gazelle_miniapp_sandbox_v2';
  static final revision = ValueNotifier<int>(0);
  static Future<TestPreferences>? _opening;
  final SharedPreferences _disk;
  Map<String,dynamic> _values;
  Future<void> _queue=Future<void>.value();
  TestPreferences._(this._disk,this._values);
  static Future<TestPreferences> getInstance()=>_opening??= _open();
  static Future<TestPreferences> _open() async {
    final disk=await SharedPreferences.getInstance();
    final raw=disk.getString(storageKey);
    final values=raw==null?<String,dynamic>{}:Map<String,dynamic>.from(jsonDecode(raw) as Map);
    return TestPreferences._(disk,values);
  }
  Object? get(String key){
    final match=RegExp(r'^home_day_(\d+)_(\d+)_(\d+)_(.+)$').firstMatch(key);
    if(match!=null){final d=DateTime(int.parse(match[1]!),int.parse(match[2]!),int.parse(match[3]!));final name=match[4];
      final b=TestState.decode(_values['journal'] as String?);final shifts=b.shifts.where((s){final t=DateTime.parse(s['start'] as String);return t.year==d.year&&t.month==d.month&&t.day==d.day;}).toList();
      if(shifts.isNotEmpty){switch(name){case 'hours':return shifts.fold<double>(0,(v,s)=>v+b.hours(s));case 'mileage':return shifts.fold<double>(0,(v,s)=>v+b.mileage(s));case 'salary':return b.statistics(d,day:d)['salary'];case 'status':return shifts.any((s)=>s['end']==null)?'open':'completed';case 'odometer_start':return shifts.first['startKm'];case 'odometer_end':return shifts.last['currentKm'];}}
    }
    final month=RegExp(r'^home_(\d+)_(\d+)_(.+)$').firstMatch(key);
    if(month!=null){final d=DateTime(int.parse(month[1]!),int.parse(month[2]!));final b=TestState.decode(_values['journal'] as String?);
      final stats=b.statistics(d);return stats[month[3]]??_values[key];}
    return _values[key];
  }
  String? getString(String key)=>get(key) as String?;
  bool? getBool(String key)=>get(key) as bool?;
  int? getInt(String key)=>(get(key) as num?)?.toInt();
  double? getDouble(String key)=>(get(key) as num?)?.toDouble();
  Set<String> getKeys(){final keys=_values.keys.toSet();final b=TestState.decode(_values['journal'] as String?);for(final s in b.shifts){final d=DateTime.parse(s['start'] as String);keys.add('home_day_${d.year}_${d.month}_${d.day}_status');}return keys;}
  Future<bool> _write(String? key,Object? value,{bool reset=false}) {
    final task=_queue.then((_) async {
      final next=reset?<String,dynamic>{}:Map<String,dynamic>.from(_values);
      if(key!=null){if(value==null){next.remove(key);}else{next[key]=value;}}
      if(!await _disk.setString(storageKey,jsonEncode(next)))throw StateError('Не удалось сохранить тестовые данные');
      _values=next;revision.value++;return true;
    });
    _queue=task.then<void>((_){},onError:(Object e,StackTrace s){});return task;
  }
  Future<bool> setString(String k,String v)=>_write(k,v);
  Future<bool> setDouble(String k,double v)=>_write(k,v);
  Future<bool> setInt(String k,int v)=>_write(k,v);
  Future<bool> setBool(String k,bool v)=>_write(k,v);
  Future<bool> remove(String k)=>_write(k,null);
  Future<bool> clear()=>_write(null,null,reset:true);
  @visibleForTesting
  static void resetCache(){_opening=null;}
}

class TestState {
  final List<Map<String,dynamic>> shifts,records;
  final List<Map<String,dynamic>> products;
  TestState({List<Map<String,dynamic>> shifts=const[],List<Map<String,dynamic>> records=const[],List<Map<String,dynamic>>? products})
    :shifts=[...shifts],records=[...records],products=products??[
      {'id':'flour50','name':'Мука, тестовый товар','packKg':50.0},
      {'id':'flour25','name':'Мука, тестовый товар','packKg':25.0},
      {'id':'sugar10','name':'Сахар, тестовый товар','packKg':10.0}];
  factory TestState.decode(String? raw){
    if(raw==null)return TestState();final j=jsonDecode(raw) as Map<String,dynamic>;
    if(j['version']!=2)throw const FormatException('Неизвестная версия тестового журнала');
    List<Map<String,dynamic>> rows(String key)=>[for(final e in j[key] as List)Map<String,dynamic>.from(e as Map)];
    return TestState(shifts:rows('shifts'),records:rows('records'),products:rows('products'));
  }
  Map<String,dynamic> toJson()=>{'version':2,'shifts':shifts,'records':records,'products':products};
  Map<String,dynamic>? get active {for(final s in shifts){if(s['end']==null)return s;}return null;}
  List<Map<String,dynamic>> forShift(String id)=>records.where((e)=>e['shiftId']==id).toList();
  double hours(Map<String,dynamic> s)=>(s['hoursWorked'] as num?)?.toDouble()??0;
  double elapsed(Map<String,dynamic> s)=>DateTime.parse(s['end'] as String? ?? DateTime.now().toIso8601String()).difference(DateTime.parse(s['start'] as String)).inSeconds/3600;
  double mileage(Map<String,dynamic> s)=>(s['currentKm'] as num).toDouble()-(s['startKm'] as num).toDouble();
  bool inMonth(String value,DateTime d){final t=DateTime.parse(value);return t.year==d.year&&t.month==d.month;}
  DateTime recordDay(Map<String,dynamic> e)=>DateTime.parse(shifts.firstWhere((s)=>s['id']==e['shiftId'])['start'] as String);
  static String dayKey(DateTime d)=>'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  // Compatibility with the uploaded miniapp /api/stats calendar, not bot.py.
  static const holidays={'2026-03-08','2026-03-09','2026-03-15','2026-05-01','2026-05-07','2026-05-09','2026-05-11','2026-07-06','2026-10-25','2026-10-26','2026-12-16'};
  static bool holiday(DateTime d)=>holidays.contains(dayKey(d));
  static double norm(DateTime d){double n=0;for(int i=1;i<=DateTime(d.year,d.month+1,0).day;i++){final x=DateTime(d.year,d.month,i);if(x.weekday<6&&!holiday(x))n+=8;}return n;}
  static bool paidDirection(String value)=>const {'саумалколь','щучинск','новоишимское'}.contains(value.trim().toLowerCase());
  Map<String,double> statistics(DateTime month,{DateTime? day}){
    final ss=shifts.where((s){final d=DateTime.parse(s['start'] as String);return inMonth(s['start'] as String,month)&&(day==null||dayKey(d)==dayKey(day));}).toList();
    final days=<String,DateTime>{};double work=0,allHours=0,city=0,region=0,paid=0,km=0,gas=0,petrol=0;
    final seenMileage=<String>{};
    // Match miniapp's descending shift order and its one-mileage-per-day aggregation.
    ss.sort((a,b)=>(b['start'] as String).compareTo(a['start'] as String));
    for(final shift in ss){final d=DateTime.parse(shift['start'] as String);final key=dayKey(d);days[key]=d;allHours+=hours(shift);
      if(d.weekday<6&&!holiday(d))work+=hours(shift);
      if(shift['odometerSet']==true&&seenMileage.add(key))km+=mileage(shift);
      for(final e in forShift(shift['id'] as String)){final amount=(e['amount'] as num?)?.toDouble()??0;
        if(e['kind']=='trip'){if(e['type']=='Город'){city+=amount;}else{region+=amount;}if(e['isPaid']==true)paid++;}
        if(e['kind']=='fuel'){if(e['type']=='Газ'){gas+=amount;}else{petrol+=amount;}}}
    }
    final normal=norm(month);final base=normal==0?0.0:190000*(work.clamp(0,normal)/normal);
    final weekend=days.values.where((d)=>d.weekday>=6).length*10000.0;
    final festive=days.values.where(holiday).length*10000.0;
    return {'salary':base+weekend+festive+paid*3000+city+region*1.9,'base_salary':base,'weekend_pay':weekend,'holiday_pay':festive,
      'paid_routes_pay':paid*3000,'city_pay':city,'region_pay':region*1.9,'hours':work,'all_hours':allHours,'norm_hours':normal,'mileage':km,'gas':gas,'petrol':petrol,'city_kg':city,'region_kg':region};
  }
  double salary(Map<String,dynamic> s){final d=DateTime.parse(s['start'] as String);return statistics(d,day:d)['salary']!;}
}
class TestStore {
  static final revision=TestPreferences.revision;
  static Future<void> _queue=Future<void>.value();
  static Future<TestState> load() async=>TestState.decode((await TestPreferences.getInstance()).getString('journal'));
  static Future<void> _change(TestState Function(TestState) change){
    final task=_queue.then((_) async{final next=change(await load());await (await TestPreferences.getInstance()).setString('journal',jsonEncode(next.toJson()));});
    _queue=task.then<void>((_){},onError:(Object e,StackTrace s){});return task;
  }
  static String _id()=>DateTime.now().microsecondsSinceEpoch.toString();
  static void _km(int v){if(v<0)throw ArgumentError('Одометр не может быть отрицательным');}
  static Future<void> open(int km,{double? hours})=>_change((b){_km(km);_hours(hours);if(b.active!=null)throw StateError('Смена уже открыта');
    if(b.shifts.any((s)=>(s['currentKm'] as num)>km))throw ArgumentError('Одометр меньше предыдущего. Исправьте прошлую смену или введите больший пробег');
    b.shifts.add({'id':_id(),'start':DateTime.now().toIso8601String(),'end':null,'startKm':km,'currentKm':km,'hoursWorked':hours,'odometerSet':false,'gpsStatus':'active','gpsKm':0.0});return b;});
  static Future<void> odometer(String id,int km,{bool close=false,double? hours})=>_change((b){_km(km);final s=b.shifts.firstWhere((s)=>s['id']==id);
    if(s['end']!=null)throw StateError('Смена уже закрыта');if(km<(s['startKm'] as num))throw ArgumentError('Пробег меньше начала смены');
    _hours(hours);s['currentKm']=km;s['odometerSet']=true;if(hours!=null)s['hoursWorked']=hours;if(close){s['end']=DateTime.now().toIso8601String();s['gpsStatus']='stopped';}return b;});
  static Future<void> saveRecord(Map<String,dynamic> value)=>_change((b){
    final e=Map<String,dynamic>.from(value);final kind=e['kind'];
    if(!['trip','fuel','invoice','other'].contains(kind))throw ArgumentError('Неизвестная запись');
    final id=e['id'];final old=b.records.where((r)=>r['id']==id).firstOrNull;
    if(id!=null&&old==null)throw StateError('Запись уже удалена');
    e['shiftId']=old?['shiftId']??e['shiftId']??b.active?['id'];
    if(e['shiftId']==null)throw StateError('Сначала откройте смену');
    final s=b.shifts.firstWhere((s)=>s['id']==e['shiftId']);
    final d=DateTime.parse(e['date'] as String? ?? DateTime.now().toIso8601String());
    if(d.isAfter(DateTime.now())||d.isBefore(DateTime.parse(s['start'] as String))||(s['end']!=null&&d.isAfter(DateTime.parse(s['end'] as String))))throw ArgumentError('Время записи должно попадать в смену');
    final amount=(e['amount'] as num?)?.toDouble()??0;
    if(!amount.isFinite||amount<0||(['trip','fuel'].contains(kind)&&amount==0))throw ArgumentError('Введите число больше нуля');
    if(kind=='trip'&&(!['Город','Район'].contains(e['type'])||(e['direction'] as String? ?? '').trim().isEmpty))throw ArgumentError('Укажите тип и направление');
    if(kind=='fuel'&&!['Газ','Бензин'].contains(e['type']))throw ArgumentError('Выберите топливо');
    if(kind=='other'&&(e['note'] as String? ?? '').trim().isEmpty)throw ArgumentError('Заполните описание или товары');
    if(kind=='trip')e['isPaid']=e['isPaid']==true||TestState.paidDirection(e['direction'] as String);
    if(kind=='invoice'){
      if(old?['status']=='closed')throw StateError('Закрытую накладную нельзя редактировать');
      final items=[for(final row in e['items'] as List? ?? [])Map<String,dynamic>.from(row as Map)];
      if(items.isEmpty)throw ArgumentError('Добавьте хотя бы один товар');
      for(final item in items){final pack=(item['packKg'] as num?)?.toDouble()??0;final weight=(item['totalKg'] as num?)?.toDouble()??0;
        if((item['name'] as String? ?? '').trim().isEmpty||!pack.isFinite||pack<=0||!weight.isFinite||weight<=0)throw ArgumentError('Проверьте название, упаковку и вес товаров');
        item['quantity']=(weight/pack).floor();if(item['quantity']==0)throw ArgumentError('Вес меньше одной упаковки');
      }
      e['items']=items;e['status']='draft';
      if(old==null){int highest=0;for(final r in b.records.where((r)=>r['kind']=='invoice')){final number=int.tryParse(r['number']?.toString()??'')??0;if(number>highest)highest=number;}e['number']='${highest+1}';}
    }
    e['amount']=amount;e['id']=id??_id();e['date']=d.toIso8601String();
    if(old!=null)b.records.remove(old);b.records.add(e);return b;});
  static Future<void> deleteRecord(String id)=>_change((b){b.records.removeWhere((e)=>e['id']==id);return b;});
  static Future<void> deleteShift(String id)=>_change((b){b.records.removeWhere((e)=>e['shiftId']==id);b.shifts.removeWhere((e)=>e['id']==id);return b;});
  static Future<void> editShift(String id,DateTime start,DateTime? end,int startKm,int endKm,{double? hours})=>_change((b){
    _km(startKm);_hours(hours);if(endKm<startKm||start.isAfter(DateTime.now())||(end!=null&&(!end.isAfter(start)||end.isAfter(DateTime.now()))))throw ArgumentError('Проверьте время и одометр');
    final s=b.shifts.firstWhere((s)=>s['id']==id);if((s['end']==null)!=(end==null))throw ArgumentError('Статус смены меняется кнопкой завершения');
    for(final r in b.forShift(id)){final d=DateTime.parse(r['date'] as String);if(d.isBefore(start)||(end!=null&&d.isAfter(end)))throw ArgumentError('За границами смены остаются записи');}
    for(final other in b.shifts.where((s)=>s['id']!=id)){final a=DateTime.parse(other['start'] as String);final z=other['end']==null?DateTime.now():DateTime.parse(other['end'] as String);if(start.isBefore(z)&&(end??DateTime.now()).isAfter(a))throw ArgumentError('Смены не должны пересекаться');}
    s.addAll({'start':start.toIso8601String(),'end':end?.toIso8601String(),'startKm':startKm,'currentKm':endKm,'odometerSet':true,'hoursWorked':hours??s['hoursWorked']});return b;});
  static void _hours(double? h){if(h!=null&&(!h.isFinite||h<0))throw ArgumentError('Введите неотрицательное число часов');}
  static Future<void> gps(String id,{bool? paused,double addKm=0})=>_change((b){final s=b.shifts.firstWhere((s)=>s['id']==id);if(s['end']!=null)throw StateError('Смена закрыта');
    if(paused!=null)s['gpsStatus']=paused?'paused':'active';
    if(addKm>0){if(s['gpsStatus']!='active')throw StateError('GPS на паузе');s['gpsKm']=((s['gpsKm'] as num?)?.toDouble()??0)+addKm;}return b;});
  static Future<void> closeInvoice(String id)=>_change((b){final e=b.records.firstWhere((e)=>e['id']==id&&e['kind']=='invoice');e['status']='closed';return b;});
  static Future<void> saveProduct({String? id,required String name,required double packKg})=>_change((b){
    if(name.trim().isEmpty||!packKg.isFinite||packKg<=0)throw ArgumentError('Укажите название и вес упаковки');
    if(b.products.any((p)=>p['id']!=id&&p['name']==name.trim()&&p['packKg']==packKg))throw ArgumentError('Такой товар уже есть');
    if(id!=null&&!b.products.any((p)=>p['id']==id))throw StateError('Товар удалён');
    b.products.removeWhere((p)=>p['id']==id);b.products.add({'id':id??_id(),'name':name.trim(),'packKg':packKg});return b;});
  static Future<void> deleteProduct(String id)=>_change((b){b.products.removeWhere((p)=>p['id']==id);return b;});
  static Future<void> reset(){final task=_queue.then((_) async{await (await TestPreferences.getInstance()).clear();});_queue=task.then<void>((_){},onError:(Object e,StackTrace s){});return task;}
  static Future<void> seed()=>_change((b){if(b.shifts.isNotEmpty||b.records.isNotEmpty)throw StateError('Пример доступен только в пустом журнале');
    final start=DateTime.now().subtract(const Duration(hours:4));final id=_id();
    return TestState(shifts:[{'id':id,'start':start.toIso8601String(),'end':null,'startKm':128540,'currentKm':128664,'hoursWorked':8.0,'odometerSet':true,'gpsStatus':'active','gpsKm':124.0}],records:[
      {'id':'${id}a','shiftId':id,'kind':'trip','type':'Город','direction':'Петропавловск','amount':4000.0,'date':start.add(const Duration(minutes:30)).toIso8601String(),'note':'Тестовый рейс'},
      {'id':'${id}b','shiftId':id,'kind':'fuel','type':'Газ','amount':40.0,'date':start.add(const Duration(hours:1)).toIso8601String(),'note':''},
      {'id':'${id}c','shiftId':id,'kind':'trip','type':'Район','direction':'Щучинск','isPaid':true,'amount':2500.0,'date':start.add(const Duration(hours:2)).toIso8601String(),'note':''}]);});
}
