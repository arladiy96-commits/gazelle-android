import 'test_store.dart';

class ActivityEntry {
  final String id, kind, type, direction;
  final DateTime date;
  final double amount;
  const ActivityEntry({required this.id,required this.date,required this.kind,
    required this.type,required this.amount,this.direction=''});
  Map<String,dynamic> toJson()=>{'id':id,'date':date.toIso8601String(),'kind':kind,'type':type,'amount':kind=='trip'?amount*1000:amount,'direction':direction};
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
  static String key(DateTime d)=>'sandbox_activity_${d.year}_${d.month}';
  static Future<ActivityBook> load(DateTime d) async {
    final b=await TestStore.load();return ActivityBook(entries:[for(final e in b.records)
      if(['trip','fuel'].contains(e['kind'])&&b.inMonth(b.recordDay(e).toIso8601String(),d))ActivityEntry.fromJson({...e,'direction':e['direction']??'','date':DateTime(b.recordDay(e).year,b.recordDay(e).month,b.recordDay(e).day,DateTime.parse(e['date'] as String).hour,DateTime.parse(e['date'] as String).minute).toIso8601String(),'amount':e['kind']=='trip'?(e['amount'] as num).toDouble()/1000:e['amount']})]);
  }
  static Future<void> add({required String kind,required String type,required double amount,String direction='',DateTime? date})=>
    TestStore.saveRecord({'kind':kind,'type':type,'amount':kind=='trip'?amount*1000:amount,'direction':direction,'date':(date??DateTime.now()).toIso8601String()});
}
