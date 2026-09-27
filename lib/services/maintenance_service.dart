import 'dart:convert';
import 'test_store.dart';

/// Stable IDs keep history intact when a title or the catalogue order changes.
class MaintenanceItem {
  final String id, title, category, icon;
  final bool usesDate;
  const MaintenanceItem(this.id,this.title,this.category,this.icon,{this.usesDate=false});
}
class MaintenanceCatalog {
  static const categories=['Двигатель','Ходовая','Документы'];
  // To extend the screen, add one item here with a new permanent ID.
  static const items=[
    MaintenanceItem('oil','Моторное масло','Двигатель','oil'),
    MaintenanceItem('air_filter','Воздушный фильтр','Двигатель','filter'),
    MaintenanceItem('oil_filter','Масляный фильтр','Двигатель','filter'),
    MaintenanceItem('coolant','Антифриз','Двигатель','coolant'),
    MaintenanceItem('battery','Аккумулятор','Двигатель','battery'),
    MaintenanceItem('belts','Ремни','Двигатель','belt'),
    MaintenanceItem('other_engine','Другое','Двигатель','other'),
    MaintenanceItem('brakes','Тормозные колодки','Ходовая','brakes'),
    MaintenanceItem('tyres','Шины','Ходовая','tyre'),
    MaintenanceItem('other_chassis','Другое','Ходовая','other'),
    MaintenanceItem('inspection','Техосмотр','Документы','document',usesDate:true),
    MaintenanceItem('insurance','Страховка','Документы','document',usesDate:true),
    MaintenanceItem('other_documents','Другое','Документы','other',usesDate:true),
  ];
  static MaintenanceItem byId(String id)=>items.firstWhere((item)=>item.id==id);
}
class MaintenanceEntry {
  final String id, itemId, note;
  final DateTime date;
  final int odometer;
  final int? nextKm;
  final DateTime? nextDate;
  final double? cost;
  final bool example;
  const MaintenanceEntry({required this.id,required this.itemId,required this.date,
    required this.odometer,this.nextKm,this.nextDate,this.cost,this.note='',this.example=false});
  Map<String,dynamic> toJson()=>{'id':id,'itemId':itemId,'date':date.toIso8601String(),
    'odometer':odometer,'nextKm':nextKm,'nextDate':nextDate?.toIso8601String(),
    'cost':cost,'note':note,'example':example};
  factory MaintenanceEntry.fromJson(Map<String,dynamic> json)=>MaintenanceEntry(
    id:json['id'] as String,itemId:json['itemId'] as String,date:DateTime.parse(json['date'] as String),
    odometer:(json['odometer'] as num).toInt(),nextKm:(json['nextKm'] as num?)?.toInt(),
    nextDate:json['nextDate']==null?null:DateTime.parse(json['nextDate'] as String),
    cost:(json['cost'] as num?)?.toDouble(),note:json['note'] as String? ?? '',example:json['example']==true);
}
class MaintenanceBook {
  final int odometer;
  final List<MaintenanceEntry> entries;
  final Map<String,String> notes;
  final bool example;
  const MaintenanceBook({required this.odometer,this.entries=const[],this.notes=const{},this.example=false});
  List<MaintenanceEntry> history(String id) {
    final found=entries.where((entry)=>entry.itemId==id).toList();
    found.sort((a,b){final d=b.date.compareTo(a.date);return d!=0?d:b.id.compareTo(a.id);});
    return found;
  }
  MaintenanceEntry? latest(String id){final rows=history(id);return rows.isEmpty?null:rows.first;}
  Map<String,dynamic> toJson()=>{'version':1,'odometer':odometer,'example':example,
    'entries':entries.map((e)=>e.toJson()).toList(),'notes':notes};
  factory MaintenanceBook.fromJson(Map<String,dynamic> json)=>MaintenanceBook(
    odometer:(json['odometer'] as num).toInt(),example:json['example']==true,
    entries:(json['entries'] as List).map((e)=>MaintenanceEntry.fromJson(Map<String,dynamic>.from(e as Map))).toList(),
    notes:Map<String,String>.from(json['notes'] as Map? ?? {}));
  factory MaintenanceBook.preview({int remaining=2350})=>MaintenanceBook(odometer:128664,example:true,
    entries:[MaintenanceEntry(id:'example-oil',itemId:'oil',date:DateTime(2026,9,8),
      odometer:121014,nextKm:128664+remaining,note:'Масло и фильтр заменены',example:true)]);
}
class MaintenanceRepository {
  final String account;
  MaintenanceRepository(this.account);
  String get key=>'maintenance_v1_${Uri.encodeComponent(account)}';
  Future<MaintenanceBook> load() async {
    final prefs=await TestPreferences.getInstance();
    final raw=prefs.getString(key);
    if(raw==null){final b=await TestStore.load();final shifts=[...b.shifts]..sort((a,z)=>(z['start'] as String).compareTo(a['start'] as String));return MaintenanceBook(odometer:shifts.isEmpty?0:(shifts.first['currentKm'] as num).toInt());}
    // Do not silently replace a damaged/unknown file with demo data.
    final json=jsonDecode(raw) as Map<String,dynamic>;
    if(json['version']!=1)throw const FormatException('Неизвестная версия данных ТО');
    final saved=MaintenanceBook.fromJson(json);final b=await TestStore.load();
    final current=b.active??(b.shifts.isEmpty?null:b.shifts.last);
    final km=(current?['currentKm'] as num?)?.toInt()??saved.odometer;
    return MaintenanceBook(odometer:km>saved.odometer?km:saved.odometer,entries:saved.entries,notes:saved.notes,example:saved.example);
  }
  Future<void> save(MaintenanceBook book) async {
    final prefs=await TestPreferences.getInstance();
    if(!await prefs.setString(key,jsonEncode(book.toJson())))throw StateError('Не удалось сохранить ТО');
  }
  Future<MaintenanceBook> record({required String itemId,required DateTime date,
    required int atKm,required int currentKm,int? nextKm,DateTime? nextDate,
    double? cost,String note='',String? entryId}) async {
    final item=MaintenanceCatalog.byId(itemId);
    if(itemId.startsWith('other_')&&note.trim().isEmpty)throw ArgumentError('Укажите, что именно сделано');
    if(atKm<0||currentKm<atKm)throw ArgumentError('Пробег обслуживания не может быть больше текущего');
    if(nextKm!=null&&nextKm<=atKm)throw ArgumentError('Следующая замена должна быть позже пробега обслуживания');
    if(item.usesDate&&nextDate==null)throw ArgumentError('Укажите срок действия');
    if(nextDate!=null&&!nextDate.isAfter(date))throw ArgumentError('Срок должен быть позже даты обслуживания');
    if(cost!=null&&(!cost.isFinite||cost<0))throw ArgumentError('Проверьте стоимость');
    final book=await load();
    if(entryId!=null&&!book.entries.any((e)=>e.id==entryId))throw StateError('Запись уже удалена');
    final real=book.entries.where((entry)=>!entry.example&&entry.id!=entryId).toList();
    if(real.any((entry)=>entry.odometer>currentKm))throw ArgumentError('Текущий пробег меньше пробега в истории');
    final entry=MaintenanceEntry(id:entryId??DateTime.now().microsecondsSinceEpoch.toString(),
      itemId:itemId,date:date,odometer:atKm,nextKm:nextKm,nextDate:nextDate,cost:cost,note:note.trim());
    final updated=MaintenanceBook(odometer:currentKm,entries:[...real,entry],notes:book.notes);
    await save(updated);return updated;
  }
  Future<MaintenanceBook> delete(String id) async {
    final book=await load();final updated=MaintenanceBook(odometer:book.odometer,entries:book.entries.where((e)=>e.id!=id).toList(),notes:book.notes);
    await save(updated);return updated;
  }
  Future<MaintenanceBook> setNote(String id,String note) async {
    MaintenanceCatalog.byId(id);
    final book=await load();
    final updated=MaintenanceBook(odometer:book.odometer,entries:book.entries,
      notes:{...book.notes,id:note.trim()},example:book.example);
    await save(updated);return updated;
  }
}
