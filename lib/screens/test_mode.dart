part of 'app_shell.dart';

String _testError(Object e)=>e.toString().replaceFirst(RegExp(r'^(Invalid argument\(s\)|Bad state|Exception):\s*'),'');
Future<void> _testRun(BuildContext context,Future<void> Function() action) async {
  try{await action();}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_testError(e))));}
}
Future<bool> _testConfirm(BuildContext context,String message) async=>await showModalBottomSheet<bool>(context:context,backgroundColor:Colors.transparent,
  builder:(c)=>_QuickEntryShell(title:'Подтверждение',icon:Icons.help_outline,child:Column(children:[_dt(message),const SizedBox(height:16),
    _detailButton('Подтвердить',()=>Navigator.pop(c,true)),_detailButton('Отмена',()=>Navigator.pop(c,false))])))??false;
Future<void> _testEditor(BuildContext context,String kind,{Map<String,dynamic>? entry,String? shiftId,String? initialType}) async {
  await _testRun(context,() async{final b=await TestStore.load();if(!context.mounted)return;
    if(entry==null&&b.active==null){await _showShiftForm(context);if(!context.mounted||(await TestStore.load()).active==null)return;}
    if(kind=='invoice'){await Navigator.push(context,_SceneRoute<void>(builder:(_)=>_MiniInvoiceEditor(entry:entry)));return;}
    if(!context.mounted)return;
    await Navigator.push(context,_SceneRoute<void>(builder:(_)=>_TestRecordEditor(kind:kind,entry:entry,shiftId:shiftId,initialType:initialType)));});
}
void _testOpen(BuildContext context,{String page='Смена',String? shiftId})=>Navigator.of(context).push<void>(_SceneRoute(builder:(_)=>_TestHub(page:page,shiftId:shiftId)));

class _TestRecordEditor extends StatefulWidget {
  final String kind;final Map<String,dynamic>? entry;final String? shiftId,initialType;
  const _TestRecordEditor({required this.kind,this.entry,this.shiftId,this.initialType});
  @override
  State<_TestRecordEditor> createState()=>_TestRecordEditorState();
}
class _TestRecordEditorState extends State<_TestRecordEditor> {
  late final TextEditingController amount,direction,note,number;
  late String type;late DateTime date;late bool loaded;late bool paid;bool busy=false;String? error;
  @override
  void initState(){super.initState();final e=widget.entry??{};amount=TextEditingController(text:e['amount']?.toString()??'');direction=TextEditingController(text:e['direction'] as String? ?? '');
    note=TextEditingController(text:e['note'] as String? ?? '');number=TextEditingController(text:e['number'] as String? ?? '');type=e['type'] as String? ?? widget.initialType ?? (widget.kind=='fuel'?'Газ':'Город');date=DateTime.tryParse(e['date'] as String? ?? '')??DateTime.now();loaded=e['loaded']==true;paid=e['isPaid']==true;}
  @override
  void dispose(){for(final c in [amount,direction,note,number]){c.dispose();}super.dispose();}
  Future<void> save() async {if(busy)return;setState((){busy=true;error=null;});
    try{await TestStore.saveRecord({...?widget.entry,'shiftId':widget.entry?['shiftId']??widget.shiftId,'kind':widget.kind,'type':type,
      'amount':double.tryParse(amount.text.replaceAll(',','.'))??(widget.kind=='invoice'||widget.kind=='other'?0:double.nan),'direction':direction.text.trim(),
      'note':note.text.trim(),'number':number.text.trim(),'loaded':loaded,'isPaid':paid,'date':date.toIso8601String()});if(mounted)Navigator.pop(context);}
    catch(e){if(mounted)setState((){error=_testError(e);busy=false;});}}
  @override
  Widget build(BuildContext context){final kind=widget.kind;return _SceneForm(scene:kind=='trip'?_Scene.cargo:kind=='fuel'?(type=='Газ'?_Scene.gas:_Scene.petrol):_Scene.cab,child:_QuickEntryShell(title:'${widget.entry==null?'Добавить':'Изменить'} · ${_testKind(kind)}',icon:Icons.edit_outlined,
    child:Column(children:[if(['trip','fuel'].contains(kind))...[_QuickSegment(values:kind=='trip'?const ['Город','Район']:const ['Газ','Бензин'],selected:type,onChanged:(v)=>setState(()=>type=v)),const SizedBox(height:12)],
      if(['trip','invoice'].contains(kind))Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:_testField(direction,'Направление')),
        IconButton(tooltip:'Выбрать направление',icon:const Icon(Icons.expand_more,color:_amber),onPressed:() async{final v=await _pickQuickValue(context,'Направление',type=='Город'?const ['Султан','Петрокондитер','Великанова','Визави','Казконд','Крылова']:const ['Саумалколь','Щучинск','Новоишимское','Бишкуль','Пресновка']);if(v!=null&&mounted)setState((){direction.text=v;paid=TestState.paidDirection(v);});})]),
      if(kind=='trip')SwitchListTile(dense:true,contentPadding:EdgeInsets.zero,value:paid,onChanged:(v)=>setState(()=>paid=v),title:_dt('Платный рейс · +3 000 ₸',size:13),activeThumbColor:_amber),
      if(kind=='invoice')_testField(number,'Номер накладной'),
      if(['trip','fuel','income'].contains(kind))_testField(amount,kind=='trip'?'Вес, кг':kind=='fuel'?'Литры':'Сумма, ₸',numeric:true),
      _detailRow('Примечание',note.text.isEmpty?'Добавить':'Изменить',subtitle:note.text.isEmpty?null:note.text,onTap:() async{await _editCompactNote(context,note);if(mounted)setState((){});}),
      if(kind=='invoice')SwitchListTile(value:loaded,onChanged:(v)=>setState(()=>loaded=v),title:_dt('Груз проверен / загружен'),activeThumbColor:_amber),
      _detailButton('${_detailDate(date)} ${date.year} · ${_detailTime(date)}',() async{final d=await _testDate(context,date);if(d!=null&&mounted)setState(()=>date=d);},icon:Icons.calendar_month),
      if(error!=null)_dt(error!,color:const Color(0xFFFFAA91)),
      _detailButton(busy?'Сохранение…':'Сохранить',busy?(){}:save,icon:Icons.check),
      if(widget.entry!=null)TextButton.icon(onPressed:busy?null:() async{if(await _testConfirm(context,'Удалить запись? Итоги пересчитаются.')&&mounted)await _testRun(context,() async{await TestStore.deleteRecord(widget.entry!['id'] as String);if(mounted)Navigator.pop(context);});},icon:const Icon(Icons.delete_outline,size:18,color:_amber),label:_dt('Удалить запись',size:13,color:_amber))])));}
}
String _testKind(String kind)=>switch(kind){'trip'=>'Рейс','fuel'=>'Топливо','invoice'=>'Накладная','income'=>'Начисление',_=>'Другое'};
Widget _testField(TextEditingController c,String label,{bool numeric=false,bool integer=false,int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:c,
  keyboardType:numeric?TextInputType.numberWithOptions(decimal:!integer):TextInputType.multiline,
  inputFormatters:integer?[FilteringTextInputFormatter.digitsOnly]:null,maxLines:lines,style:const TextStyle(color:_paper,fontSize:15),
  decoration:InputDecoration(isDense:true,contentPadding:const EdgeInsets.symmetric(horizontal:12,vertical:14),labelText:label,labelStyle:const TextStyle(color:_ice,fontSize:13),filled:true,fillColor:const Color(0xA008151C),
    enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0x66768F98))),
    focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:_amber)))));
Future<DateTime?> _testDate(BuildContext context,DateTime initial) async {
  final d=await showDatePicker(context:context,initialDate:initial,firstDate:DateTime(2000),lastDate:DateTime.now(),
    builder:(c,w)=>Theme(data:Theme.of(c).copyWith(colorScheme:const ColorScheme.dark(primary:_amber,surface:Color(0xFF0B1A22))),child:w!));
  if(d==null||!context.mounted)return null;
  final t=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(initial),builder:(c,w)=>Theme(data:Theme.of(c).copyWith(colorScheme:const ColorScheme.dark(primary:_amber,surface:Color(0xFF0B1A22))),child:w!));
  return t==null?null:DateTime(d.year,d.month,d.day,t.hour,t.minute);
}

class _TestHub extends StatefulWidget {
  final String page;final String? shiftId;final bool embedded;
  const _TestHub({this.page='Смена',this.shiftId,this.embedded=false});
  @override
  State<_TestHub> createState()=>_TestHubState();
}
class _TestHubState extends State<_TestHub> {
  TestState? book;String? error;Timer? timer;int request=0;
  @override
  void initState(){super.initState();TestStore.revision.addListener(load);load();timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted&&book?.active!=null)setState((){});});}
  @override
  void dispose(){request++;timer?.cancel();TestStore.revision.removeListener(load);super.dispose();}
  Future<void> load() async{final r=++request;try{final b=await TestStore.load();if(mounted&&r==request)setState((){book=b;error=null;});}catch(e){if(mounted&&r==request)setState(()=>error=_testError(e));}}
  Future<void> odometer({Map<String,dynamic>? shift,bool close=false})=>_showShiftForm(context,shift:shift,close:close);
  @override
  Widget build(BuildContext context){final children=<Widget>[
    _DetailGlass(accent:true,child:_dt('ТЕСТОВЫЙ РЕЖИМ · только на этом устройстве',size:12,color:_amber)),
    if(error!=null)...[_dt(error!),_detailButton('Повторить',load)]
    else if(book==null)const Center(child:CircularProgressIndicator())
    else ...content()];
    return _DetailFrame(title:widget.page,embedded:widget.embedded,children:children);}
  List<Widget> content(){final b=book!;
    if(widget.page=='Накладные')return [_detailButton('Создать накладную',()=>_testEditor(context,'invoice'),icon:Icons.add),...records(b.records.where((e)=>e['kind']=='invoice').toList())];
    if(widget.page=='История смен')return [if(b.shifts.isEmpty)_dt('Смен пока нет'),for(final s in b.shifts.reversed)_DetailGlass(child:_detailRow(_detailDate(DateTime.parse(s['start'] as String)),s['end']==null?'Открыта':'Завершена',subtitle:'${_fmt1(b.mileage(s))} км · ${_fmt1(b.hours(s))} ч',onTap:()=>_testOpen(context,page:'Смена',shiftId:s['id'] as String)))];
    if(widget.page=='Тестовые данные')return [
      _dt('Основная база не подключена. Тестовые записи не отправляются на сервер.',size:14),const SizedBox(height:16),
      _detailButton('Текущая смена',()=>_testOpen(context)),_detailButton('История смен',()=>_testOpen(context,page:'История смен')),
      _detailButton('Расчёт зарплаты',()=>Navigator.push(context,_SceneRoute<void>(builder:(_)=>_TestRates(book:b)))),
      _detailButton('Заполнить примером',()=>_testRun(context,TestStore.seed)),
      _detailButton('Сбросить тестовые данные',() async{if(await _testConfirm(context,'Удалить все тестовые смены, рейсы, топливо, накладные, документы и ТО? Основные данные не затрагиваются.')&&mounted)await _testRun(context,TestStore.reset);},icon:Icons.delete_outline),
      _dt('Правила расчёта взяты из миниаппа. Данные и товары в этом режиме тестовые.',size:12)];
    final s=widget.shiftId==null?b.active:b.shifts.where((s)=>s['id']==widget.shiftId).firstOrNull;
    if(s==null)return [_DetailGlass(child:_dt('Смена закрыта. Откройте новую, чтобы добавлять записи.')),
      _detailButton('Открыть смену',()=>odometer(),icon:Icons.play_arrow),_detailButton('История смен',()=>_testOpen(context,page:'История смен')),_detailButton('Тестовые данные',()=>_testOpen(context,page:'Тестовые данные'))];
    final rows=b.forShift(s['id'] as String);double total(String kind,[String? type])=>rows.where((e)=>e['kind']==kind&&(type==null||e['type']==type)).fold<double>(0,(v,e)=>v+(e['amount'] as num).toDouble());
    final duration=Duration(seconds:(b.elapsed(s)*3600).round());final elapsed='${duration.inHours.toString().padLeft(2,'0')}:${(duration.inMinutes%60).toString().padLeft(2,'0')}:${(duration.inSeconds%60).toString().padLeft(2,'0')}';
    return [_DetailGlass(accent:true,child:Column(children:[_detailRow(s['end']==null?'Смена открыта':'Смена завершена',elapsed),
      _detailRow('Начало','${_detailDate(DateTime.parse(s['start'] as String))} · ${_detailTime(DateTime.parse(s['start'] as String))}'),
      _detailRow('Пробег','${_fmt1(b.mileage(s))} км',subtitle:'Одометр ${s['startKm']} → ${s['currentKm']}'),
      _detailRow('Учтено часов','${_fmt1(b.hours(s))} ч'),
      _detailRow('Город','${_fmt1(total('trip','Город'))} кг'),_detailRow('Район','${_fmt1(total('trip','Район'))} кг'),
      _detailRow('Рейсов','${rows.where((e)=>e['kind']=='trip').length}'),
      _detailRow('Газ / бензин','${_fmt1(total('fuel','Газ'))} / ${_fmt1(total('fuel','Бензин'))} л'),
      _detailRow('Начислено за месяц','${_fmtInt(b.statistics(DateTime.parse(s['start'] as String))['salary']!)} ₸') ])),
      if(s['end']==null)...[_detailButton('Указать текущий одометр',()=>odometer(shift:s),icon:Icons.speed),
        _DetailGlass(child:_detailRow('GPS · демо','${_fmt1((s['gpsKm'] as num?)?.toDouble()??0)} км',subtitle:s['gpsStatus']=='paused'?'Пауза':'Запись маршрута')),
        _detailButton(s['gpsStatus']=='paused'?'Продолжить GPS':'Приостановить GPS',()=>_testRun(context,()=>TestStore.gps(s['id'] as String,paused:s['gpsStatus']!='paused'))),
        _detailButton('GPS-демо: проехать 10 км',()=>_testRun(context,()=>TestStore.gps(s['id'] as String,addKm:10)),icon:Icons.route),
        _detailButton('Добавить рейс',()=>_testEditor(context,'trip'),icon:Icons.add),_detailButton('Добавить топливо',()=>_testEditor(context,'fuel'),icon:Icons.add),
        _detailButton('Накладная',()=>_testEditor(context,'invoice')),_detailButton('Другое / заметка',()=>_testEditor(context,'other')),
        _detailButton('Завершить смену',()=>odometer(shift:s,close:true),icon:Icons.stop)],
      _detailButton('Изменить время и пробег смены',()=>Navigator.push(context,_SceneRoute<void>(builder:(_)=>_TestShiftEditor(shift:s)))),
      _dt('Записи смены · нажмите для изменения',size:14),const SizedBox(height:12),...records(rows),
      _detailButton('История смен',()=>_testOpen(context,page:'История смен')),
      _detailButton('Удалить смену и её записи',() async{if(await _testConfirm(context,'Удалить эту смену и все связанные записи?')&&mounted)await _testRun(context,()=>TestStore.deleteShift(s['id'] as String));},icon:Icons.delete_outline),
      _dt('GPS-демо считает расстояние отдельно. При закрытии смены предлагает конечный одометр с возможностью исправления.',size:12)];
  }
  List<Widget> records(List<Map<String,dynamic>> rows)=>[if(rows.isEmpty)_DetailGlass(child:_dt('Записей пока нет')),
    for(final e in rows.reversed)_DetailGlass(child:Column(children:[_detailRow('${_testKind(e['kind'] as String)} · ${e['type']??''}',
      ['trip','fuel','income'].contains(e['kind'])?'${_fmt1((e['amount'] as num).toDouble())} ${e['kind']=='trip'?'кг':e['kind']=='fuel'?'л':'₸'}':e['kind']=='invoice'?(e['status']=='closed'?'Закрыта':'Черновик'):'',
      subtitle:'${_detailDate(DateTime.parse(e['date'] as String))} · ${_detailTime(DateTime.parse(e['date'] as String))}\n${e['direction']??''} ${e['number']??''}\n${e['note']??''}',
      onTap:()=>_testEditor(context,e['kind'] as String,entry:e)),
      Align(alignment:Alignment.centerRight,child:IconButton(tooltip:'Удалить запись',icon:const Icon(Icons.delete_outline,color:_amber),onPressed:() async{if(await _testConfirm(context,'Удалить запись? Итоги пересчитаются.')&&mounted)await _testRun(context,()=>TestStore.deleteRecord(e['id'] as String));}))]))];
}
class _TestOdometer extends StatefulWidget {
  final TextEditingController controller;final Map<String,dynamic>? shift;final bool close;
  const _TestOdometer({required this.controller,this.shift,required this.close});
  @override
  State<_TestOdometer> createState()=>_TestOdometerState();
}
class _TestOdometerState extends State<_TestOdometer>{bool busy=false;String? error;
  late final hours=TextEditingController(text:widget.shift?['hoursWorked']?.toString()??'');
  @override void dispose(){hours.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>_QuickEntryShell(title:widget.shift==null?'Открыть смену':widget.close?'Завершить смену':'Одометр',icon:Icons.speed,child:Column(children:[
    if(widget.close&&widget.shift!=null)_TestLive(builder:(b){final rows=b.forShift(widget.shift!['id'] as String);return _DetailGlass(child:Column(children:[
      _detailRow('Рейсов','${rows.where((e)=>e['kind']=='trip').length}'),
      _detailRow('Перевезено','${_fmt1(rows.where((e)=>e['kind']=='trip').fold<double>(0,(n,e)=>n+(e['amount'] as num).toDouble())/1000)} т'),
      ValueListenableBuilder<TextEditingValue>(valueListenable:widget.controller,builder:(_,v,__)=>_detailRow('Пробег смены','${_fmtInt(math.max(0,(double.tryParse(v.text)??0)-(widget.shift!['startKm'] as num).toDouble()))} км'))]));}),
    _testField(widget.controller,'Показание одометра, км',numeric:true,integer:true),
    _testField(hours,'Отработано часов (вручную)',numeric:true),if(error!=null)_dt(error!,color:_amber),
    _detailButton(busy?'Сохранение…':widget.shift==null?'Открыть смену':widget.close?'Завершить смену':'Сохранить показание',() async{if(busy)return;setState((){busy=true;error=null;});try{final km=int.tryParse(widget.controller.text);if(km==null)throw ArgumentError('Введите целый пробег');
      final h=hours.text.trim().isEmpty?null:double.tryParse(hours.text.replaceAll(',','.'))??double.nan;
      if(widget.shift==null){await TestStore.open(km,hours:h);}else{await TestStore.odometer(widget.shift!['id'] as String,km,close:widget.close,hours:h);}if(context.mounted)Navigator.pop(context);
    }catch(e){if(mounted)setState((){busy=false;error=_testError(e);});}})]));
}
class _TestRates extends StatelessWidget {
  final TestState book;const _TestRates({required this.book});
  @override Widget build(BuildContext context)=>_DetailFrame(title:'Расчёт как в миниаппе',children:[
    _DetailGlass(child:Column(children:[_detailRow('Оклад, максимум','190 000 ₸'),_detailRow('Выходной / праздник','10 000 ₸'),
      _detailRow('Платный рейс','3 000 ₸'),_detailRow('Город','1 ₸ / кг'),_detailRow('Район','1,9 ₸ / кг')])),
    _dt('Часы вводятся вручную. Оклад зависит от нормы рабочих часов месяца и не растёт сверх 190 000 ₸. Календарь и группировка дней повторяют присланный миниапп.'),
    const SizedBox(height:12),_detailButton('Товары для накладных',()=>Navigator.push(context,_SceneRoute<void>(builder:(_)=>const _MiniCatalog())))]);
}
class _TestShiftEditor extends StatefulWidget {final Map<String,dynamic> shift;const _TestShiftEditor({required this.shift});@override State<_TestShiftEditor> createState()=>_TestShiftEditorState();}
class _TestShiftEditorState extends State<_TestShiftEditor>{late DateTime start=DateTime.parse(widget.shift['start'] as String);late DateTime? end=DateTime.tryParse(widget.shift['end'] as String? ?? '');
  late final hours=TextEditingController(text:widget.shift['hoursWorked']?.toString()??'');
  late final a=TextEditingController(text:widget.shift['startKm'].toString()),z=TextEditingController(text:widget.shift['currentKm'].toString());bool busy=false;
  @override void dispose(){a.dispose();z.dispose();hours.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>_DetailFrame(title:'Изменить смену',children:[_detailButton('Начало: ${_detailDate(start)} ${_detailTime(start)}',() async{final d=await _testDate(context,start);if(d!=null&&mounted)setState(()=>start=d);}),
    if(end!=null)_detailButton('Конец: ${_detailDate(end!)} ${_detailTime(end!)}',() async{final d=await _testDate(context,end!);if(d!=null&&mounted)setState(()=>end=d);}),
    _testField(hours,'Отработано часов',numeric:true),_testField(a,'Одометр начала',numeric:true,integer:true),_testField(z,'Одометр конца / текущий',numeric:true,integer:true),
    _detailButton('Сохранить',() async{if(busy)return;busy=true;await _testRun(context,() async{await TestStore.editShift(widget.shift['id'] as String,start,end,int.tryParse(a.text)??-1,int.tryParse(z.text)??-1,hours:hours.text.trim().isEmpty?null:double.tryParse(hours.text.replaceAll(',','.'))??double.nan);if(mounted)Navigator.pop(context);});busy=false;})]);}

class _TestLive extends StatefulWidget {
  final Widget Function(TestState) builder;
  const _TestLive({required this.builder});
  @override State<_TestLive> createState()=>_TestLiveState();
}
class _TestLiveState extends State<_TestLive>{TestState? b;String? error;Timer? timer;int request=0;
  @override void initState(){super.initState();TestStore.revision.addListener(load);load();timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted&&b?.active!=null)setState((){});});}
  Future<void> load() async{final id=++request;try{final value=await TestStore.load();if(mounted&&id==request)setState((){b=value;error=null;});}catch(e){if(mounted&&id==request)setState(()=>error=_testError(e));}}
  @override void dispose(){request++;timer?.cancel();TestStore.revision.removeListener(load);super.dispose();}
  @override Widget build(BuildContext context)=>error!=null?_DetailGlass(child:Column(mainAxisSize:MainAxisSize.min,children:[_dt(error!),_detailButton('Повторить',load)])):b==null?const Center(child:CircularProgressIndicator(color:_amber)):widget.builder(b!);
}
class _TestHomeStatus extends StatelessWidget {
  const _TestHomeStatus();
  @override Widget build(BuildContext context)=>_TestLive(builder:(b){final s=b.active;final seconds=s==null?0:(b.elapsed(s)*3600).round();
    return Container(alignment:Alignment.center,decoration:BoxDecoration(color:const Color(0xC0042028),borderRadius:BorderRadius.circular(31),border:Border.all(color:_ice)),
      child:_garageText(s==null?'Смена закрыта':'Смена открыта · ${seconds~/3600}:${((seconds~/60)%60).toString().padLeft(2,'0')}:${(seconds%60).toString().padLeft(2,'0')}',24,color:_ice));});
}
class _TestHomeShiftButton extends StatelessWidget {
  const _TestHomeShiftButton();
  @override Widget build(BuildContext context)=>_TestLive(builder:(b)=>Container(decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xDD101010),border:Border.all(color:_amber,width:3),boxShadow:const [BoxShadow(color:Color(0xAAFF981B),blurRadius:22)]),
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(b.active==null?Icons.play_arrow:Icons.stop_rounded,color:_amber,size:44),const SizedBox(height:14),_garageText(b.active==null?'ОТКРЫТЬ\nСМЕНУ':'ЗАВЕРШИТЬ\nСМЕНУ',22,align:TextAlign.center)])));
}
class _TestHomeTrip extends StatelessWidget {final VoidCallback onTap;const _TestHomeTrip({required this.onTap});
  @override Widget build(BuildContext context)=>_TestLive(builder:(b){final s=b.active;final trips=s==null?<Map<String,dynamic>>[]:b.forShift(s['id'] as String).where((e)=>e['kind']=='trip').toList();
    return _GarageTap(label:'Текущая смена',onTap:onTap,child:Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:const Color(0xCC08141B),borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0x66768F98))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_garageText(trips.isEmpty?'Текущая смена':'Последний добавленный рейс',23,color:_ice),const SizedBox(height:12),
        _garageText(trips.isEmpty?'Добавьте рейс через «+»':'${trips.last['direction']} · ${_fmt1((trips.last['amount'] as num).toDouble())} кг',29)])));});}
Future<void> _editActivity(BuildContext context,ActivityEntry entry) async {
  await _testRun(context,() async{final b=await TestStore.load();final e=b.records.where((e)=>e['id']==entry.id).firstOrNull;
    if(e!=null&&context.mounted)_testEditor(context,e['kind'] as String,entry:e);});
}

class _MiniInvoiceEditor extends StatefulWidget {
  final Map<String,dynamic>? entry;
  const _MiniInvoiceEditor({this.entry});
  @override State<_MiniInvoiceEditor> createState()=>_MiniInvoiceEditorState();
}
class _MiniInvoiceEditorState extends State<_MiniInvoiceEditor> {
  late final direction=TextEditingController(text:widget.entry?['direction'] as String? ?? '');
  late final List<Map<String,dynamic>> items=[for(final r in widget.entry?['items'] as List? ?? [])Map<String,dynamic>.from(r as Map)];
  TestState? book;int step=0;bool busy=false;String? error;
  bool get closed=>widget.entry?['status']=='closed';
  @override void initState(){super.initState();load();}
  Future<void> load() async{try{final b=await TestStore.load();if(mounted)setState(()=>book=b);}catch(e){if(mounted)setState(()=>error=_testError(e));}}
  @override void dispose(){direction.dispose();super.dispose();}
  Future<void> weight(Map<String,dynamic> product,{int? index}) async {
    final initial=index==null?'':items[index]['totalKg'].toString();
    final amount=await showModalBottomSheet<double>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
      builder:(_)=>_MiniWeightPad(initial:initial,pack:(product['packKg'] as num).toDouble(),name:product['name'] as String));
    if(amount==null||!mounted)return;
    final pack=(product['packKg'] as num).toDouble();
    final row={'name':product['name'],'packKg':pack,'totalKg':amount,'quantity':(amount/pack).floor(),'checked':false};
    setState((){if(index==null){items.add(row);}else{items[index]=row;}});
  }
  Future<void> save() async {
    if(busy||closed)return;setState((){busy=true;error=null;});
    try{await TestStore.saveRecord({...?widget.entry,'kind':'invoice','amount':0.0,'direction':direction.text.trim(),'items':items,
      'date':widget.entry?['date']??DateTime.now().toIso8601String()});if(mounted)Navigator.pop(context);}
    catch(e){if(mounted)setState((){busy=false;error=_testError(e);});}
  }
  @override Widget build(BuildContext context)=>_DetailFrame(title:closed?'Накладная №${widget.entry!['number']} · закрыта':step==0?'Товары накладной':'Проверка загрузки',children:[
    _DetailGlass(accent:true,child:_dt('Тестовые данные · ${items.length} поз. · ${_fmt1(items.fold<double>(0,(v,e)=>v+(e['totalKg'] as num).toDouble()))} кг',color:_amber)),
    if(error!=null)_DetailGlass(child:_dt(error!,color:_amber)),
    if(closed)_DetailGlass(child:_dt(direction.text.isEmpty?'Направление не указано':direction.text))
    else if(step==0)_testField(direction,'Направление (выберите или введите)'),
    if(!closed&&step==0)_detailButton('Выбрать направление',() async{final v=await _pickQuickValue(context,'Направление',const ['Султан','Петрокондитер','Великанова','Визави','Казконд','Крылова','Саумалколь','Щучинск','Новоишимское','Бишкуль','Пресновка']);if(v!=null&&mounted)setState(()=>direction.text=v);}),
    if(book==null&&error==null)const Center(child:CircularProgressIndicator()),
    if(!closed&&step==0&&book!=null)...[
      _dt('Выберите товар и укажите вес',size:14),const SizedBox(height:12),
      Wrap(spacing:10,runSpacing:10,children:[for(final p in book!.products)SizedBox(width:(MediaQuery.sizeOf(context).width-42)/2,
        child:_DetailGlass(child:InkWell(onTap:()=>weight(p),child:Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Column(children:[
          const Align(alignment:Alignment.topRight,child:Icon(Icons.inventory_2_outlined,color:_amber,size:22)),const SizedBox(height:8),_dt(p['name'] as String),const SizedBox(height:8),_dt('${_fmt1((p['packKg'] as num).toDouble())} кг / уп.',color:_ice)])))))]),
      _detailButton('Справочник товаров / добавить свой',() async{await Navigator.push(context,_SceneRoute<void>(builder:(_)=>const _MiniCatalog()));if(mounted)await load();},icon:Icons.add)],
    for(var i=0;i<items.length;i++)_DetailGlass(child:Column(children:[
      _detailRow(items[i]['name'] as String,'${_fmt1((items[i]['totalKg'] as num).toDouble())} кг',
        subtitle:'${items[i]['quantity']} уп. × ${_fmt1((items[i]['packKg'] as num).toDouble())} кг',onTap:closed||step==1?null:()=>weight(items[i],index:i)),
      if(!closed&&step==0)Align(alignment:Alignment.centerRight,child:IconButton(tooltip:'Убрать товар',onPressed:()=>setState(()=>items.removeAt(i)),icon:const Icon(Icons.delete_outline,color:_amber))),
      if(closed||step==1)CheckboxListTile(value:items[i]['checked']==true,onChanged:closed?null:(v)=>setState(()=>items[i]['checked']=v==true),activeColor:_amber,title:_dt('Загружено'))])),
    if(!closed&&step==0)_detailButton('Готово · проверить загрузку',(){if(items.isEmpty){setState(()=>error='Добавьте товары');return;}setState((){step=1;error=null;});},icon:Icons.check),
    if(!closed&&step==1)...[_detailButton('Вернуться к товарам',()=>setState(()=>step=0)),
      _detailButton(busy?'Сохранение…':'ОК · сохранить накладную',busy?(){}:save,icon:Icons.check)],
    if(widget.entry!=null&&!closed)_detailButton('Закрыть накладную',() async{if(await _testConfirm(context,'Закрыть сохранённую накладную? После закрытия редактирование недоступно. Несохранённые изменения не применятся.')&&mounted){await _testRun(context,() async{await TestStore.closeInvoice(widget.entry!['id'] as String);if(mounted)Navigator.pop(context);});}}),
    if(widget.entry!=null)_detailButton('Удалить накладную',() async{if(await _testConfirm(context,'Удалить накладную со всеми товарами?')&&mounted){await _testRun(context,() async{await TestStore.deleteRecord(widget.entry!['id'] as String);if(mounted)Navigator.pop(context);});}},icon:Icons.delete_outline)
  ]);
}
class _MiniWeightPad extends StatefulWidget {
  final String initial,name;final double pack;
  const _MiniWeightPad({required this.initial,required this.pack,required this.name});
  @override State<_MiniWeightPad> createState()=>_MiniWeightPadState();
}
class _MiniWeightPadState extends State<_MiniWeightPad>{late String value=widget.initial;String? error;
  @override Widget build(BuildContext context){final n=double.tryParse(value)??0;final qty=(n/widget.pack).floor();final rest=n-qty*widget.pack;
    return _QuickEntryShell(title:widget.name,icon:Icons.scale_outlined,child:Column(children:[
      _DetailGlass(accent:true,child:_detailRow('Вес, кг',value.isEmpty?'0':value,subtitle:'$qty уп. · ${_fmt1(widget.pack)} кг / уп.${rest>0.001?' · остаток ${_fmt1(rest)} кг':''}')),
      for(final row in const [['1','2','3'],['4','5','6'],['7','8','9'],['.','0','⌫']])Row(children:[for(final key in row)Expanded(child:Padding(padding:const EdgeInsets.all(4),child:OutlinedButton(onPressed:()=>setState((){
        error=null;if(key=='⌫'){if(value.isNotEmpty)value=value.substring(0,value.length-1);}else if(value.length<12){if(key!='.'||!value.contains('.'))value+=value.isEmpty&&key=='.'?'0.':key;}}),
        style:OutlinedButton.styleFrom(foregroundColor:_amber,minimumSize:const Size(0,48),side:const BorderSide(color:Color(0x88FFBB4D))),child:Text(key,style:const TextStyle(fontSize:20)))))]),
      if(error!=null)_dt(error!,color:_amber),_detailButton('ОК',(){if(!n.isFinite||n<=0||qty<1){setState(()=>error='Введите вес не меньше одной упаковки');return;}Navigator.pop(context,n);},icon:Icons.check)]));}
}
class _MiniCatalog extends StatefulWidget {const _MiniCatalog();@override State<_MiniCatalog> createState()=>_MiniCatalogState();}
class _MiniCatalogState extends State<_MiniCatalog>{TestState? book;String? error;
  @override void initState(){super.initState();TestStore.revision.addListener(load);load();}
  @override void dispose(){TestStore.revision.removeListener(load);super.dispose();}
  Future<void> load() async{try{final b=await TestStore.load();if(mounted)setState((){book=b;error=null;});}catch(e){if(mounted)setState(()=>error=_testError(e));}}
  Future<void> edit([Map<String,dynamic>? product]) async=>showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(_)=>_MiniProductForm(product:product));
  @override Widget build(BuildContext context)=>_DetailFrame(title:'Тестовый справочник товаров',children:[_detailButton('Добавить товар',()=>edit(),icon:Icons.add),
    if(error!=null)_dt(error!),if(book==null)const Center(child:CircularProgressIndicator()),
    for(final p in book?.products??[])_DetailGlass(child:Column(children:[_detailRow(p['name'] as String,'${_fmt1((p['packKg'] as num).toDouble())} кг',onTap:()=>edit(p)),
      _detailButton('Удалить из справочника',() async{if(await _testConfirm(context,'Убрать товар? Уже созданные накладные сохранят свои позиции.')&&mounted)await _testRun(context,()=>TestStore.deleteProduct(p['id'] as String));},icon:Icons.delete_outline)]))]);
}
class _MiniProductForm extends StatefulWidget {final Map<String,dynamic>? product;const _MiniProductForm({this.product});@override State<_MiniProductForm> createState()=>_MiniProductFormState();}
class _MiniProductFormState extends State<_MiniProductForm>{late final name=TextEditingController(text:widget.product?['name'] as String? ?? ''),pack=TextEditingController(text:widget.product?['packKg']?.toString()??'');bool busy=false;String? error;
  @override void dispose(){name.dispose();pack.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>_QuickEntryShell(title:'Товар',icon:Icons.inventory_2_outlined,child:Column(children:[_testField(name,'Название'),_testField(pack,'Вес упаковки, кг',numeric:true),
    if(error!=null)_dt(error!,color:_amber),_detailButton(busy?'Сохранение…':'Сохранить',() async{if(busy)return;setState(()=>busy=true);try{await TestStore.saveProduct(id:widget.product?['id'] as String?,name:name.text,packKg:double.tryParse(pack.text.replaceAll(',','.'))??double.nan);if(mounted)Navigator.pop(context);}catch(e){if(mounted)setState((){busy=false;error=_testError(e);});}})]));
}
