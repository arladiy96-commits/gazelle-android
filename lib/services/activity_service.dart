import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityEntry {
  final String id, kind, type, direction;
  final DateTime date;
  final double amount;
  const ActivityEntry({required this.id,required this.date,required this.kind,
    required this.type,required this.amount,this.direction=''});
  Map<String,dynamic> toJson()=>{'id':id,'date':date.toIso8601String(),'kind':kind,'type':type,'amount':amount,'direction':direction};
  factory ActivityEntry.fromJson(Map<String,dynamic> j)=>ActivityEntry(id:j['id'] as String,
    date:DateTime.parse(j['date'] as String),kind:j['kind'] as String,type:j['type'] as String,
    amount:(j['amount'] as num).toDouble(),direction:j['direction'] as String? ?? '');
}

/// Same device-wide scope as the existing home_* monthly values.
/// A month's baseline and its new events commit together in a single JSON value.
class ActivityBook {
  final Map<String,double> baseline;
  final List<ActivityEntry> entries;
  const ActivityBook({this.baseline=const{},this.entries=const[]});
  double total(String metric) {
    final events=entries.where((e)=>metric=='trips'?e.kind=='trip':metric=='tonnage'?e.kind=='trip':
      metric=='city_tonnage'?e.kind=='trip'&&e.type=='Город':metric=='region_tonnage'?e.kind=='trip'&&e.type=='Район':
      metric=='gas'?e.kind=='fuel'&&e.type=='Газ':metric=='petrol'?e.kind=='fuel'&&e.type=='Бензин':false);
    return (baseline[metric]??0)+events.fold<double>(0,(s,e)=>s+(metric=='trips'?1:e.amount));
  }
  List<ActivityEntry> onDay(DateTime d)=>entries.where((e)=>sameDay(e.date,d)).toList()..sort((a,b)=>a.date.compareTo(b.date));
  static bool sameDay(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;
}
class ActivityRepository {
  static String key(DateTime d)=>'activity_v1_${d.year}_${d.month}';
  static Future<void> _queue=Future<void>.value();
  static Future<ActivityBook> load(DateTime d) async {
    final prefs=await SharedPreferences.getInstance();final raw=prefs.getString(key(d));
    if(raw==null)return const ActivityBook();
    final j=jsonDecode(raw) as Map<String,dynamic>;
    if(j['version']!=1)throw const FormatException('Неизвестная версия журнала');
    return ActivityBook(baseline:(j['baseline'] as Map).map((k,v)=>MapEntry(k as String,(v as num).toDouble())),
      entries:(j['entries'] as List).map((e)=>ActivityEntry.fromJson(Map<String,dynamic>.from(e as Map))).toList());
  }
  static Future<void> add({required String kind,required String type,required double amount,String direction='',DateTime? date}) {
    final task=_queue.then((_) async {
      if(!amount.isFinite||amount<=0)throw ArgumentError('Введите число больше нуля');
      if(!(kind=='trip'&&['Город','Район'].contains(type)||kind=='fuel'&&['Газ','Бензин'].contains(type)))throw ArgumentError('Неизвестный тип');
      final d=date??DateTime.now();final prefs=await SharedPreferences.getInstance();final book=await load(d);
      final now=DateTime.now();final current=now.year==d.year&&now.month==d.month;
      const defaults={'gas':286.0,'petrol':74.0,'tonnage':284.6,'trips':48.0,'city_tonnage':184.6,'region_tonnage':100.0};
      final baseline=book.baseline.isNotEmpty?book.baseline:{for(final e in defaults.entries)
        e.key:(prefs.get('home_${d.year}_${d.month}_${e.key}') as num?)?.toDouble()??(current?e.value:0.0)};
      final entry=ActivityEntry(id:'${DateTime.now().microsecondsSinceEpoch}_${book.entries.length}',date:d,kind:kind,type:type,amount:amount,direction:direction);
      if(!await prefs.setString(key(d),jsonEncode({'version':1,'baseline':baseline,'entries':[...book.entries,entry].map((e)=>e.toJson()).toList()})))throw StateError('Не удалось сохранить');
    });
    _queue=task.then<void>((_){},onError:(Object e,StackTrace s){});
    return task;
  }
}
