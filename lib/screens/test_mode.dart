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
  Future<void> tripInput({bool weight=false})async{
    if(busy)return;
    final target=weight?amount:direction;
    final draft=TextEditingController(text:target.text);
    draft.selection=TextSelection(baseOffset:0,extentOffset:draft.text.length);
    final choices=type=='Город'?const ['Султан','Петрокондитер','Великанова','Визави','Казконд','Крылова']:const ['Саумалколь','Щучинск','Новоишимское','Бишкуль','Пресновка'];
    final value=await showModalBottomSheet<String>(context:context,isScrollControlled:true,
      backgroundColor:const Color(0xFF0D1920),
      sheetAnimationStyle:weight?AnimationStyle.noAnimation:const AnimationStyle(duration:Duration(milliseconds:220),reverseDuration:Duration(milliseconds:180)),
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))),
      builder:(c)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(c).bottom+16),
        child:SafeArea(top:false,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
          Text(weight?(widget.kind=='fuel'?'Литры':'Вес, кг'):'Выберите направление',style:const TextStyle(color:_paper,fontSize:20)),const SizedBox(height:14),
          TextField(controller:draft,autofocus:weight,keyboardType:weight?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,
            textInputAction:TextInputAction.done,style:const TextStyle(color:_paper,fontSize:20),
            decoration:InputDecoration(hintText:weight?(widget.kind=='fuel'?'Введите литры':'Введите вес'):'Введите своё направление',border:const OutlineInputBorder()),
            onSubmitted:(v)=>Navigator.pop(c,v)),
          if(!weight)ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(c).height*.3),
            child:ListView(shrinkWrap:true,children:[for(final name in choices)ListTile(title:Text(name),
              leading:const Icon(Icons.location_on_outlined,color:_amber),onTap:()=>Navigator.pop(c,name))])),
          const SizedBox(height:12),SizedBox(width:double.infinity,child:OutlinedButton(onPressed:()=>Navigator.pop(c,draft.text),child:const Text('Готово'))),
        ])))));
    if(mounted&&value!=null)setState((){target.text=value.trim();if(!weight)paid=TestState.paidDirection(value);error=null;});
    Future<void>.delayed(const Duration(seconds:1),draft.dispose);
  }
  Widget tripScreen(){
    const gold=Color(0xFFE6B46B),white=Color(0xFFEAEDEF),muted=Color(0xFFABB8C0);
    Widget text(String s,double size,{Color color=white})=>Text(s,maxLines:2,overflow:TextOverflow.ellipsis,
      style:TextStyle(color:color,fontSize:size,height:1.15,fontWeight:FontWeight.w400));
    BoxDecoration panel({bool active=false})=>BoxDecoration(borderRadius:BorderRadius.circular(24),
      border:Border.all(color:active?gold:const Color(0xFF52616A),width:2),
      gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:active?const [Color(0xDB553416),Color(0xE00B1014),Color(0xDB492908)]:const [Color(0xC0101D25),Color(0xDB080F14)]),
      boxShadow:active?const [BoxShadow(color:Color(0x508F561E),blurRadius:14,spreadRadius:2),BoxShadow(color:Color(0x60FFC275),blurRadius:3)]:null);
    Widget tap(Widget child,VoidCallback fn,String label)=>Semantics(button:true,label:label,child:GestureDetector(
      behavior:HitTestBehavior.opaque,onTap:busy?null:fn,child:child));
    Widget heading(IconData icon,String label)=>Row(children:[Icon(icon,color:gold,size:47),const SizedBox(width:28),text(label,31)]);
    return AnnotatedRegion<SystemUiOverlayStyle>(value:const SystemUiOverlayStyle(statusBarColor:Colors.transparent,
      statusBarIconBrightness:Brightness.light,systemNavigationBarColor:Colors.transparent,systemNavigationBarIconBrightness:Brightness.light),
      child:PopScope(canPop:!busy,child:Scaffold(resizeToAvoidBottomInset:false,backgroundColor:const Color(0xFF061016),
        body:LayoutBuilder(builder:(context,box){final scale=box.maxWidth/864;
          final top=math.max(0.0,MediaQuery.viewPaddingOf(context).top-35*scale);
          Widget at(double x,double y,double w,double h,Widget child)=>Positioned(left:x,top:y,width:w,height:h,child:child);
          Widget segment(String value,IconData icon)=>Expanded(child:tap(Container(decoration:panel(active:type==value),
            child:Center(child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:46,color:type==value?gold:white),const SizedBox(width:24),text(value,32,color:type==value?gold:white)]))),
            (){if(type!=value)setState((){type=value;direction.clear();paid=false;});},value));
          final controls=SizedBox(width:864,height:1536,child:Stack(children:[
            at(47,60,113,113,tap(Container(decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xD5081117),border:Border.all(color:gold,width:2)),
              child:const Icon(Icons.arrow_back,color:gold,size:52)),()=>Navigator.pop(context),'Назад')),
            at(198,94,585,76,Row(children:[const Icon(Icons.local_shipping_outlined,color:gold,size:78),const SizedBox(width:27),
              Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:text(widget.entry==null?'Добавить рейс':'Изменить рейс',43)))])),
            at(302,168,300,2,Container(color:gold)),
            at(77,538,690,58,heading(Icons.local_shipping_outlined,'Тип рейса')),
            at(74,609,720,88,Row(children:[segment('Город',Icons.location_city),const SizedBox(width:18),segment('Район',Icons.terrain)])),
            at(78,721,690,52,heading(Icons.location_on,'Направление')),
            at(74,778,720,80,tap(Container(decoration:panel(),padding:const EdgeInsets.symmetric(horizontal:29),
              child:Row(children:[Expanded(child:text(direction.text.isEmpty?'Выберите направление':direction.text,31,color:direction.text.isEmpty?muted:white)),
                const Icon(Icons.expand_more,color:gold,size:43)])),()=>tripInput(),'Выбрать направление')),
            at(78,879,690,52,heading(Icons.scale,'Вес, кг')),
            at(74,934,720,79,tap(Container(decoration:panel(),padding:const EdgeInsets.symmetric(horizontal:29),
              child:Row(children:[Expanded(child:text(amount.text.isEmpty?'Введите вес':amount.text,36,color:amount.text.isEmpty?muted:white)),text('кг',28,color:muted)])),()=>tripInput(weight:true),'Ввести вес')),
            at(77,1037,596,50,heading(Icons.account_balance_wallet,'Платное направление')),
            at(158,1084,450,38,text('+3 000 ₸',28,color:muted)),
            at(681,1047,112,61,Semantics(toggled:paid,label:'Платное направление',child:tap(Container(decoration:panel(active:paid),padding:const EdgeInsets.all(5),
              child:Align(alignment:paid?Alignment.centerRight:Alignment.centerLeft,child:Container(width:48,decoration:BoxDecoration(color:paid?gold:muted,borderRadius:BorderRadius.circular(17)),
                child:Icon(paid?Icons.check:Icons.remove,color:const Color(0xFF5C350D),size:37)))),()=>setState(()=>paid=!paid),'Платное направление'))),
            at(78,1133,690,54,heading(Icons.calendar_month,'Дата и время')),
            at(74,1192,720,82,tap(Container(decoration:panel(),padding:const EdgeInsets.symmetric(horizontal:32),child:Row(children:[
              const Icon(Icons.calendar_month,color:white,size:43),const SizedBox(width:47),Expanded(child:text('${_detailDate(date)} ${date.year} · ${_detailTime(date)}',31))])),
              ()async{final d=await _testDate(context,date);if(d!=null&&mounted)setState(()=>date=d);},'Изменить дату и время')),
            at(74,1301,720,84,tap(Container(decoration:panel(active:true),child:Center(child:Row(mainAxisSize:MainAxisSize.min,children:[
              if(busy)const SizedBox(width:35,height:35,child:CircularProgressIndicator(color:gold,strokeWidth:3))else const Icon(Icons.check,color:gold,size:52),
              const SizedBox(width:35),text(busy?'Сохранение…':'Сохранить',38,color:gold)]))),save,'Сохранить рейс')),
            if(error!=null)at(65,1425,734,91,Container(padding:const EdgeInsets.all(12),color:const Color(0xEE07131A),child:Center(child:text(error!,25,color:gold)))),
            if(widget.entry!=null&&error==null)at(200,1431,464,65,TextButton(onPressed:busy?null:()async{
              if(await _testConfirm(context,'Удалить запись? Итоги пересчитаются.')&&mounted)await _testRun(context,()async{
                await TestStore.deleteRecord(widget.entry!['id'] as String);if(mounted)Navigator.pop(context);
              });},child:text('Удалить рейс',27,color:gold))),
          ]));
          return SingleChildScrollView(child:SizedBox(width:box.maxWidth,height:math.max(box.maxHeight,1536*scale+top),child:Stack(children:[
            Positioned.fill(child:RepaintBoundary(child:_ExtendedArtwork(asset:'assets/images/scenes/trip_entry.png',topInset:top))),
            Positioned(top:top,left:0,width:box.maxWidth,height:1536*scale,child:FittedBox(fit:BoxFit.contain,
              child:MediaQuery.withClampedTextScaling(minScaleFactor:1,maxScaleFactor:1,child:controls))),
          ])));
        }))));
  }
  Widget fuelScreen(){
    const gold=Color(0xFFE6B46B),white=Color(0xFFEAEDEF),muted=Color(0xFFABB8C0);
    Widget text(String s,double size,{Color color=white})=>Text(s,maxLines:2,overflow:TextOverflow.ellipsis,
      style:TextStyle(color:color,fontSize:size,height:1.15,fontWeight:FontWeight.w400));
    BoxDecoration panel({bool active=false})=>BoxDecoration(borderRadius:BorderRadius.circular(24),
      border:Border.all(color:active?gold:const Color(0xFF52616A),width:2),
      gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:active?const [Color(0xDB553416),Color(0xE00B1014),Color(0xDB492908)]:const [Color(0xC0101D25),Color(0xDB080F14)]),
      boxShadow:active?const [BoxShadow(color:Color(0x508F561E),blurRadius:14,spreadRadius:2),BoxShadow(color:Color(0x60FFC275),blurRadius:3)]:null);
    Widget tap(Widget child,VoidCallback fn,String label)=>Semantics(button:true,label:label,child:GestureDetector(
      behavior:HitTestBehavior.opaque,onTap:busy?null:fn,child:child));
    Widget heading(IconData icon,String label)=>Row(children:[Icon(icon,color:gold,size:47),const SizedBox(width:28),text(label,31)]);
    return AnnotatedRegion<SystemUiOverlayStyle>(value:const SystemUiOverlayStyle(statusBarColor:Colors.transparent,
      statusBarIconBrightness:Brightness.light,systemNavigationBarColor:Colors.transparent,systemNavigationBarIconBrightness:Brightness.light),
      child:PopScope(canPop:!busy,child:Scaffold(resizeToAvoidBottomInset:false,backgroundColor:const Color(0xFF061016),
        body:LayoutBuilder(builder:(context,box){final scale=box.maxWidth/864;
          final top=math.max(0.0,MediaQuery.viewPaddingOf(context).top-35*scale);
          Widget at(double x,double y,double w,double h,Widget child)=>Positioned(left:x,top:y,width:w,height:h,child:child);
          Widget segment(String value,IconData icon)=>Expanded(child:tap(Container(decoration:panel(active:type==value),
            child:Center(child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:46,color:type==value?gold:white),const SizedBox(width:24),text(value,32,color:type==value?gold:white)]))),
            (){if(type!=value)setState((){type=value;});},value));
          final controls=SizedBox(width:864,height:1536,child:Stack(children:[
            at(47,60,113,113,tap(Container(decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xD5081117),border:Border.all(color:gold,width:2)),
              child:const Icon(Icons.arrow_back,color:gold,size:52)),()=>Navigator.pop(context),'Назад')),
            at(198,94,585,76,Row(children:[const Icon(Icons.local_gas_station_outlined,color:gold,size:78),const SizedBox(width:27),
              Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:text(widget.entry==null?'Добавить топливо':'Изменить топливо',43)))])),
            at(302,168,300,2,Container(color:gold)),
            at(77,591,690,58,heading(Icons.local_gas_station_outlined,'Тип топлива')),
            at(74,663,720,98,Row(children:[segment('Газ',Icons.local_fire_department),const SizedBox(width:18),segment('Бензин',Icons.local_gas_station_outlined)])),
            at(78,806,690,52,heading(Icons.water_drop_outlined,'Литры')),
            at(74,872,720,84,tap(Container(decoration:panel(),padding:const EdgeInsets.symmetric(horizontal:29),
              child:Row(children:[Expanded(child:text(amount.text.isEmpty?'Введите литры':amount.text,36,color:amount.text.isEmpty?muted:white)),Container(width:1,height:51,color:muted.withValues(alpha:.4)),const SizedBox(width:27),text('Литры',28,color:muted)])),()=>tripInput(weight:true),'Ввести литры')),
            at(78,1000,690,54,heading(Icons.calendar_month,'Дата и время')),
            at(74,1065,720,88,tap(Container(decoration:panel(),padding:const EdgeInsets.symmetric(horizontal:32),child:Row(children:[
              const Icon(Icons.calendar_month,color:white,size:43),const SizedBox(width:47),Expanded(child:text('${_detailDate(date)} ${date.year} · ${_detailTime(date)}',31))])),
              ()async{final d=await _testDate(context,date);if(d!=null&&mounted)setState(()=>date=d);},'Изменить дату и время')),
            at(74,1217,720,94,tap(Container(decoration:panel(active:true),child:Center(child:Row(mainAxisSize:MainAxisSize.min,children:[
              if(busy)const SizedBox(width:35,height:35,child:CircularProgressIndicator(color:gold,strokeWidth:3))else const Icon(Icons.check,color:gold,size:52),
              const SizedBox(width:35),text(busy?'Сохранение…':'Сохранить',38,color:gold)]))),save,'Сохранить топливо')),
            if(error!=null)at(65,1378,734,110,Container(padding:const EdgeInsets.all(12),color:const Color(0xEE07131A),child:Center(child:text(error!,25,color:gold)))),
            if(widget.entry!=null&&error==null)at(200,1390,464,65,TextButton(onPressed:busy?null:()async{
              if(await _testConfirm(context,'Удалить запись? Итоги пересчитаются.')&&mounted)await _testRun(context,()async{
                await TestStore.deleteRecord(widget.entry!['id'] as String);if(mounted)Navigator.pop(context);
              });},child:text('Удалить запись топлива',27,color:gold))),
          ]));
          return SingleChildScrollView(child:SizedBox(width:box.maxWidth,height:math.max(box.maxHeight,1536*scale+top),child:Stack(children:[
            Positioned.fill(child:RepaintBoundary(child:_ExtendedArtwork(asset:'assets/images/scenes/fuel_entry.png',topInset:top))),
            Positioned(top:top,left:0,width:box.maxWidth,height:1536*scale,child:FittedBox(fit:BoxFit.contain,
              child:MediaQuery.withClampedTextScaling(minScaleFactor:1,maxScaleFactor:1,child:controls))),
          ])));
        }))));
  }
  @override
  Widget build(BuildContext context){final kind=widget.kind;if(kind=='trip')return tripScreen();if(kind=='fuel')return fuelScreen();return _SceneForm(scene:kind=='trip'?_Scene.cargo:kind=='fuel'?(type=='Газ'?_Scene.gas:_Scene.petrol):_Scene.cab,child:_QuickEntryShell(title:'${widget.entry==null?'Добавить':'Изменить'} · ${_testKind(kind)}',icon:Icons.edit_outlined,
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
      _detailRow('Пробег','${_fmt1(b.mileage(s))} км',subtitle:TestState.mileageSource(s)==MileageSource.manual?'введено вручную':'Одометр ${s['startKm']} → ${s['currentKm']}'),
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
  bool get manual=>widget.shift!=null&&TestState.mileageSource(widget.shift!)==MileageSource.manual;
  late final hours=TextEditingController(text:widget.shift?['hoursWorked']?.toString()??'');
  @override void dispose(){hours.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>_QuickEntryShell(title:widget.shift==null?'Открыть смену':widget.close?'Завершить смену':'Одометр',icon:Icons.speed,child:Column(children:[
    if(widget.close&&widget.shift!=null)_TestLive(builder:(b){final rows=b.forShift(widget.shift!['id'] as String);return _DetailGlass(child:Column(children:[
      _detailRow('Рейсов','${rows.where((e)=>e['kind']=='trip').length}'),
      _detailRow('Перевезено','${_fmt1(rows.where((e)=>e['kind']=='trip').fold<double>(0,(n,e)=>n+(e['amount'] as num).toDouble())/1000)} т'),
      ValueListenableBuilder<TextEditingValue>(valueListenable:widget.controller,builder:(_,v,__)=>_detailRow('Пробег смены','${_fmtInt(math.max(0,(double.tryParse(v.text)??0)-(manual?0:(widget.shift!['startKm'] as num).toDouble())))} км'))]));}),
    _testField(widget.controller,manual?'Пробег за смену, км':'Показание одометра, км',numeric:true,integer:true),
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
  bool get manual=>TestState.mileageSource(widget.shift)==MileageSource.manual;
  late final distance=TextEditingController(text:widget.shift['manualKm']?.toString()??'');
  late final hours=TextEditingController(text:widget.shift['hoursWorked']?.toString()??'');
  late final a=TextEditingController(text:widget.shift['startKm']?.toString()??''),z=TextEditingController(text:widget.shift['currentKm']?.toString()??'');bool busy=false;
  @override void dispose(){a.dispose();z.dispose();hours.dispose();distance.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>_DetailFrame(title:'Изменить смену',children:[_detailButton('Начало: ${_detailDate(start)} ${_detailTime(start)}',() async{final d=await _testDate(context,start);if(d!=null&&mounted)setState(()=>start=d);}),
    if(end!=null)_detailButton('Конец: ${_detailDate(end!)} ${_detailTime(end!)}',() async{final d=await _testDate(context,end!);if(d!=null&&mounted)setState(()=>end=d);}),
    _testField(hours,'Отработано часов',numeric:true),if(manual)_testField(distance,'Пробег за смену, км',numeric:true,integer:true)else ...[_testField(a,'Одометр начала',numeric:true,integer:true),_testField(z,'Одометр конца / текущий',numeric:true,integer:true)],
    _detailButton('Сохранить',() async{if(busy)return;busy=true;await _testRun(context,() async{if(manual&&distance.text.trim().isEmpty&&end!=null)throw ArgumentError('Введите пробег за смену');await TestStore.editShift(widget.shift['id'] as String,start,end,int.tryParse(a.text),int.tryParse(z.text),manualKm:manual&&distance.text.trim().isNotEmpty?int.tryParse(distance.text)??-1:null,hours:hours.text.trim().isEmpty?null:double.tryParse(hours.text.replaceAll(',','.'))??double.nan);if(mounted)Navigator.pop(context);});busy=false;})]);}

class _TestLive extends StatefulWidget {
  final Widget Function(TestState) builder;
  const _TestLive({required this.builder});
  @override State<_TestLive> createState()=>_TestLiveState();
}
class _TestLiveState extends State<_TestLive>{
  TestState? b;String? error;Timer? timer;int request=0;
  bool get visible{
    if(!mounted||!TickerMode.of(context))return false;
    final route=ModalRoute.of(context);
    if(route!=null&&(!route.isCurrent||(route.animation!=null&&route.animation!.status!=AnimationStatus.completed)))return false;
    return MediaQuery.viewInsetsOf(context).bottom==0;
  }
  @override void initState(){super.initState();TestStore.revision.addListener(load);load();
    timer=Timer.periodic(const Duration(seconds:1),(_){if(mounted&&b?.active!=null&&visible)setState((){});});}
  Future<void> load()async{
    final id=++request;
    try{final value=await TestStore.load();if(!mounted||id!=request)return;
      // Cache current data while covered; avoid rebuilding a hidden heavy scene.
      if(b==null||visible){setState((){b=value;error=null;});}else{b=value;error=null;}
    }catch(e){if(mounted&&id==request){if(b==null||visible){setState(()=>error=_testError(e));}else{error=_testError(e);}}}
  }
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
