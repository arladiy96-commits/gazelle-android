part of 'app_shell.dart';

// Scene artwork contains no data. Every number and control is a Flutter widget.
enum _Scene { cargo, instruments, gas, petrol, cab }
String _sceneAsset(_Scene scene)=>'assets/images/scenes/${scene.name}.png';
_Scene _sceneFor(String title){
  if(title=='Город'||title=='Район'||title.contains('рейс')||title=='Направления')return _Scene.cargo;
  if(title=='Газ')return _Scene.gas;
  if(title=='Бензин')return _Scene.petrol;
  if(title=='Пробег'||title=='Смена'||title.contains('Одометр'))return _Scene.instruments;
  return _Scene.cab;
}
class _SceneRoute<T> extends PageRouteBuilder<T> {
  _SceneRoute({required WidgetBuilder builder}) : super(
    transitionDuration:const Duration(milliseconds:560),
    reverseTransitionDuration:const Duration(milliseconds:400),
    pageBuilder:(context,animation,secondary)=>builder(context),
    transitionsBuilder:(context,animation,secondary,child){
      if(MediaQuery.disableAnimationsOf(context))return child;
      final enter=animation.drive(CurveTween(curve:Curves.easeInOutCubic));
      return FadeTransition(opacity:enter,child:ScaleTransition(
        alignment:const Alignment(0,-.35),
        scale:Tween<double>(begin:.94,end:1).animate(enter),
        child:AnimatedBuilder(animation:secondary,child:child,builder:(context,child)=>
          Transform.scale(scale:1+secondary.value*.045,alignment:const Alignment(0,-.35),child:child))));
    });
}
class _SceneReveal extends StatelessWidget {
  final Widget child;const _SceneReveal({required this.child});
  @override Widget build(BuildContext context){
    final animation=ModalRoute.of(context)?.animation;
    if(animation==null||MediaQuery.disableAnimationsOf(context))return child;
    final curve=animation.drive(CurveTween(curve:const Interval(.18,1,curve:Curves.easeOutCubic)));
    return FadeTransition(opacity:curve,child:SlideTransition(position:Tween<Offset>(begin:const Offset(0,.035),end:Offset.zero).animate(curve),child:child));
  }
}
// Exactly one full-screen image per scene. Data is painted over that same image.
class _SceneBackdrop extends StatelessWidget {
  final _Scene scene;final bool dim;final TextEditingController? odometerController;
  const _SceneBackdrop({this.scene=_Scene.cab,this.dim=true,this.odometerController});
  @override Widget build(BuildContext context)=>Stack(fit:StackFit.expand,children:[
    LayoutBuilder(builder:(context,c)=>Image.asset(_sceneAsset(scene),fit:BoxFit.cover,
      alignment:scene==_Scene.instruments&&c.maxWidth>c.maxHeight?Alignment.center:Alignment.topCenter,filterQuality:FilterQuality.medium)),
    DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
      stops:const [0,.18,.52,1],colors:dim?const [Color(0x30030A0F),Color(0x08030A0F),Color(0x20030A0F),Color(0x80030A0F)]:const [Color(0x20030A0F),Colors.transparent,Color(0x10030A0F),Color(0x65030A0F)]))),
    if(scene==_Scene.instruments)IgnorePointer(child:odometerController==null
      ?_TestLive(builder:(b)=>_SceneOdometer(value:_actualOdometer(b)))
      :ValueListenableBuilder<TextEditingValue>(valueListenable:odometerController!,builder:(_,v,__)=>_SceneOdometer(value:double.tryParse(v.text)))),
  ]);
}
class _SceneOdometer extends StatelessWidget {
  final double? value;const _SceneOdometer({this.value});
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,c){
    const imageSize=Size(887,1774);
    final viewport=Size(c.maxWidth,c.maxHeight);
    final fitted=applyBoxFit(BoxFit.cover,imageSize,viewport);
    final alignment=c.maxWidth>c.maxHeight?Alignment.center:Alignment.topCenter;
    final source=alignment.inscribe(fitted.source,Offset.zero & imageSize);
    final destination=alignment.inscribe(fitted.destination,Offset.zero & viewport);
    final scale=destination.width/source.width;
    final lcd=Rect.fromLTWH(destination.left+(887*.386-source.left)*scale,
      destination.top+(1774*.398-source.top)*scale,887*.224*scale,1774*.050*scale);
    return Stack(children:[Positioned.fromRect(rect:lcd,child:Semantics(label:value==null?'Одометр не указан':'Одометр ${value!.round()} километров',
      child:Container(color:const Color(0xFF020808),padding:EdgeInsets.symmetric(horizontal:lcd.width*.04,vertical:lcd.height*.08),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Flexible(child:FittedBox(fit:BoxFit.scaleDown,child:Text(value==null?'— — — — — —':_fmtInt(value!),style:const TextStyle(color:_amber,fontFamily:'monospace',fontSize:30,letterSpacing:1.2)))),
        const SizedBox(height:2),Text('ОДОМЕТР · КМ',style:TextStyle(color:_amber,fontSize:math.min(9.0,lcd.height*.15)))]))))]);
  });
}
// Transparent space exposes the scene, never inserts a second photograph.
class _SceneSpace extends StatelessWidget {
  final _Scene scene;final double controlsHeight;
  const _SceneSpace({required this.scene,this.controlsHeight=48});
  @override Widget build(BuildContext context){final mq=MediaQuery.of(context);
    final imageBottom=mq.size.height*(scene==_Scene.instruments ? .56 : .53);
    final space=(imageBottom-mq.padding.top-controlsHeight).clamp(90.0,520.0).toDouble();
    return SizedBox(height:space);
  }
}
class _SceneSummary extends StatelessWidget {
  final String value,label;const _SceneSummary({required this.value,required this.label});
  @override Widget build(BuildContext context)=>_DetailGlass(accent:true,child:Row(children:[
    Expanded(child:_dt(label,size:13,color:const Color(0xFFB6C6CD))),const SizedBox(width:12),
    Flexible(child:Text(value,textAlign:TextAlign.right,style:const TextStyle(color:_amber,fontSize:22,fontWeight:FontWeight.w500))),
  ]));
}
double? _actualOdometer(TestState b){
  final shifts=[...b.shifts]..sort((a,z)=>(z['start'] as String).compareTo(a['start'] as String));
  return shifts.isEmpty?null:(shifts.first['currentKm'] as num).toDouble();
}

class _SceneForm extends StatelessWidget {
  final _Scene scene;final Widget child;final TextEditingController? odometerController;
  const _SceneForm({required this.scene,required this.child,this.odometerController});
  @override Widget build(BuildContext context)=>Scaffold(resizeToAvoidBottomInset:false,backgroundColor:const Color(0xFF030A0F),body:Stack(children:[
    Positioned.fill(child:_SceneBackdrop(scene:scene,dim:false,odometerController:odometerController)),
    SafeArea(child:Align(alignment:Alignment.bottomCenter,child:_SceneReveal(child:child)))
  ]));
}
Future<void> _showShiftForm(BuildContext context,{Map<String,dynamic>? shift,bool close=false}) async {
  final b=await TestStore.load();if(!context.mounted)return;
  final gps=(shift?['gpsKm'] as num?)?.toDouble()??0;
  final initial=shift==null?_actualOdometer(b)?.round():close&&gps>0?(shift['startKm'] as num).toInt()+gps.round():(shift['currentKm'] as num).toInt();
  final controller=TextEditingController(text:initial?.toString()??'');
  final route=_SceneRoute<void>(builder:(_)=>_SceneForm(scene:_Scene.instruments,
    odometerController:controller,
    child:_TestOdometer(controller:controller,shift:shift,close:close)));
  await Navigator.of(context).push<void>(route);await route.completed;controller.dispose();
}
Future<void> _openShiftAction(BuildContext context) async=>_testRun(context,() async{
  final b=await TestStore.load();if(context.mounted)await _showShiftForm(context,shift:b.active,close:b.active!=null);
});
Future<void> _editCompactNote(BuildContext context,TextEditingController target) async {
  final copy=TextEditingController(text:target.text);
  final result=await showModalBottomSheet<String>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
    builder:(c)=>_QuickEntryShell(title:'Примечание',icon:Icons.edit_note,child:Column(mainAxisSize:MainAxisSize.min,children:[
      _testField(copy,'Текст примечания',lines:3),_detailButton('Сохранить',()=>Navigator.pop(c,copy.text),icon:Icons.check)])));
  if(result!=null)target.text=result;
  Future<void>.delayed(const Duration(seconds:1),copy.dispose);
}

class _CinematicWork extends StatelessWidget {
  final AppSession session;final ValueChanged<int>? onNavigate;final VoidCallback? onQuickAdd;
  final bool showNavigation;
  const _CinematicWork({required this.session,this.onNavigate,this.onQuickAdd,
    this.showNavigation=true});
  @override Widget build(BuildContext context)=>_TestLive(builder:(b){
    final s=b.active;final rows=s==null?<Map<String,dynamic>>[]:b.forShift(s['id'] as String);
    double total(String kind,[String? type])=>rows.where((e)=>e['kind']==kind&&(type==null||e['type']==type)).fold<double>(0,(n,e)=>n+(e['amount'] as num? ?? 0).toDouble());
    final seconds=s==null?0:(b.elapsed(s)*3600).round();
    final elapsed='${(seconds~/3600).toString().padLeft(2,'0')}:${((seconds~/60)%60).toString().padLeft(2,'0')}:${(seconds%60).toString().padLeft(2,'0')}';
    return Column(children:[Expanded(child:_DetailFrame(title:'Работа',embedded:true,scene:_Scene.instruments,children:[
      _DetailGlass(padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),child:Row(children:[Icon(Icons.schedule,size:18,color:_ice),const SizedBox(width:8),Expanded(child:_dt(s==null?'Смена закрыта':'Смена открыта · $elapsed',color:_ice,size:13)),
        if(s!=null)IconButton(tooltip:'Управление сменой',onPressed:()=>_testOpen(context),icon:const Icon(Icons.more_horiz,color:_paper))])),
      _DetailGlass(accent:true,child:Row(children:[Expanded(child:_workNumber('За смену',s==null?'0 км':'${_fmtInt(b.mileage(s))} км')),
        Expanded(child:_workNumber('Город','${_fmt1(total('trip','Город')/1000)} т')),
        Expanded(child:_workNumber('Район','${_fmt1(total('trip','Район')/1000)} т')),
        Expanded(child:_workNumber('Рейсы','${rows.where((e)=>e['kind']=='trip').length}'))])),
      _DetailGlass(child:Column(children:[_detailRow('Маршрут смены',s==null?'—':'${_fmt1((s['gpsKm'] as num?)?.toDouble()??0)} км',subtitle:'GPS · демонстрационный режим',onTap:()=>_testOpen(context)),
        const SizedBox(height:100,child:CustomPaint(painter:_SceneMapPainter(),child:SizedBox.expand())),
        if(s!=null)Row(children:[Expanded(child:TextButton(onPressed:()=>_testRun(context,()=>TestStore.gps(s['id'] as String,paused:s['gpsStatus']!='paused')),child:_dt(s['gpsStatus']=='paused'?'Продолжить':'Пауза',color:_ice,size:13))),
          Expanded(child:TextButton(onPressed:()=>_testRun(context,()=>TestStore.gps(s['id'] as String,addKm:10)),child:_dt('+10 км · демо',color:_amber,size:13)))])])),
      _DetailGlass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Последние действия',size:15),const SizedBox(height:6),
        if(rows.isEmpty)_detailRow('Записей пока нет','',subtitle:'Добавьте рейс или топливо через «+»'),
        ..._separated([for(final e in rows.reversed.take(3))_detailRow(e['kind']=='trip'?'${e['direction']}':_testKind(e['kind'] as String),
          ['trip','fuel'].contains(e['kind'])?'${_fmt1((e['amount'] as num).toDouble())} ${e['kind']=='trip'?'кг':'л'}':'',
          subtitle:_detailTime(DateTime.parse(e['date'] as String)),onTap:()=>_testEditor(context,e['kind'] as String,entry:e))])])),
      _detailButton(s==null?'Открыть смену':'Завершить смену',()=>_openShiftAction(context),icon:s==null?Icons.play_arrow:Icons.stop_rounded),
    ])),if(showNavigation)_workNavigation(context)]);
  });
  Widget _workNumber(String label,String value)=>Column(mainAxisSize:MainAxisSize.min,children:[_dt(label,size:11,color:const Color(0xFFB6C6CD)),const SizedBox(height:5),FittedBox(child:_dt(value,size:17,weight:FontWeight.w500))]);
  Widget _workNavigation(BuildContext context)=>SafeArea(top:false,child:Container(height:64,decoration:const BoxDecoration(color:Color(0xF0081117),border:Border(top:BorderSide(color:Color(0x444A6875)))),child:Row(children:[
    for(final item in [(Icons.home_outlined,'Главная',0),(Icons.local_shipping_outlined,'Работа',1),(Icons.add,'Добавить',2),(Icons.receipt_long_outlined,'Накладные',3),(Icons.more_horiz,'Ещё',4)])
      Expanded(child:InkWell(onTap:(){if(item.$3==2){onQuickAdd?.call();}else if(item.$3==4){_openHomeMenu(context,session);}else{onNavigate?.call(item.$3);}},child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(item.$1,color:item.$3==1||item.$3==2?_amber:_paper,size:item.$3==2?30:22),const SizedBox(height:4),_dt(item.$2,size:10,color:item.$3==1?_amber:_paper)])))
  ])));
}
class _SceneMapPainter extends CustomPainter {
  const _SceneMapPainter();
  @override void paint(Canvas canvas,Size s){final grid=Paint()..color=const Color(0x304B7480)..strokeWidth=1;
    for(double x=0;x<s.width;x+=30)canvas.drawLine(Offset(x,0),Offset(x,s.height),grid);
    for(double y=0;y<s.height;y+=25)canvas.drawLine(Offset(0,y),Offset(s.width,y),grid);
    final p=Path()..moveTo(s.width*.1,s.height*.75)..lineTo(s.width*.28,s.height*.55)..lineTo(s.width*.42,s.height*.68)..lineTo(s.width*.60,s.height*.25)..lineTo(s.width*.87,s.height*.35);
    canvas.drawPath(p,Paint()..color=_ice.withValues(alpha:.12)..style=PaintingStyle.stroke..strokeWidth=12);
    canvas.drawPath(p,Paint()..color=_ice..style=PaintingStyle.stroke..strokeWidth=2);
    for(final point in [Offset(s.width*.1,s.height*.75),Offset(s.width*.87,s.height*.35)])canvas.drawCircle(point,4,Paint()..color=_amber);
  }
  @override bool shouldRepaint(covariant _SceneMapPainter oldDelegate)=>false;
}

Future<void> _dayActions(BuildContext context,DateTime day) async=>_testRun(context,() async{
  final b=await TestStore.load();if(!context.mounted)return;
  final shifts=b.shifts.where((s)=>ActivityBook.sameDay(DateTime.parse(s['start'] as String),day)).toList();
  if(shifts.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('За этот день смен нет')));return;}
  final shift=shifts.length==1?shifts.first:await showModalBottomSheet<Map<String,dynamic>>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
    builder:(c)=>_QuickEntryShell(title:'Выберите смену',icon:Icons.schedule,child:Column(mainAxisSize:MainAxisSize.min,children:[
      for(final s in shifts)_detailRow(_detailTime(DateTime.parse(s['start'] as String)),s['end']==null?'Открыта':'Завершена',onTap:()=>Navigator.pop(c,s))])));
  if(shift==null||!context.mounted)return;
  final choice=await _pickQuickValue(context,'Действия со сменой',const ['Изменить смену','Удалить смену']);
  if(!context.mounted)return;
  if(choice=='Изменить смену'){await Navigator.push(context,_SceneRoute<void>(builder:(_)=>_TestShiftEditor(shift:shift)));}
  else if(choice=='Удалить смену'&&await _testConfirm(context,'Удалить смену и все её записи?')&&context.mounted){await TestStore.deleteShift(shift['id'] as String);}
});

// Keep every tab mounted: switching does not reset scroll, month or drafts.
class _SceneTabStage extends StatefulWidget {
  final int index;final List<Widget> children;
  const _SceneTabStage({required this.index,required this.children});
  @override State<_SceneTabStage> createState()=>_SceneTabStageState();
}
class _SceneTabStageState extends State<_SceneTabStage> with SingleTickerProviderStateMixin {
  late final controller=AnimationController(vsync:this,duration:const Duration(milliseconds:420),value:1);
  late final curve=CurvedAnimation(parent:controller,curve:Curves.easeOutCubic);
  @override void didUpdateWidget(covariant _SceneTabStage oldWidget){super.didUpdateWidget(oldWidget);if(oldWidget.index!=widget.index){if(MediaQuery.disableAnimationsOf(context)){controller.value=1;}else{controller.forward(from:0);}}}
  @override void dispose(){curve.dispose();controller.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>FadeTransition(opacity:Tween<double>(begin:.2,end:1).animate(curve),child:ScaleTransition(scale:Tween<double>(begin:.985,end:1).animate(curve),child:IndexedStack(index:widget.index,children:widget.children)));
}

class _CinematicMore extends StatelessWidget {
  final AppSession session;const _CinematicMore({required this.session});
  @override Widget build(BuildContext context)=>_DetailFrame(title:'Ещё',scene:_Scene.cab,children:[
    _DetailGlass(accent:true,child:_detailRow(session.displayName,session.login,subtitle:'Водитель · тестовый режим')),
    _DetailGlass(child:Column(children:_separated([
      _detailRow('Обслуживание','',onTap:()=>_openMaintenance(context,session)),
      _detailRow('Документы','',onTap:()=>_openGarageSection(context,'Документы',session.login)),
      _detailRow('Справочник товаров','',onTap:()=>Navigator.push(context,_SceneRoute<void>(builder:(_)=>const _MiniCatalog()))),
      _detailRow('Расчёт зарплаты','',onTap:()=>_testRun(context,() async{final b=await TestStore.load();if(context.mounted)await Navigator.push(context,_SceneRoute<void>(builder:(_)=>_TestRates(book:b)));})),
      _detailRow('Тестовые данные','',subtitle:'Заполнить примером или очистить журнал',onTap:()=>_testOpen(context,page:'Тестовые данные')),
    ]))),
    _dt('Данные хранятся на этом устройстве. Подключения к основной базе нет.',size:12,color:const Color(0xFFB6C6CD)),
  ]);
}
class _TonnageChart extends StatelessWidget {
  final ActivityBook book;final DateTime month;const _TonnageChart({required this.book,required this.month});
  @override Widget build(BuildContext context){final days=DateTime(month.year,month.month+1,0).day;
    final values=[for(var d=1;d<=days;d++)book.onDay(DateTime(month.year,month.month,d)).where((e)=>e.kind=='trip').fold<double>(0,(n,e)=>n+e.amount)];
    final maximum=values.fold<double>(0,math.max);
    return _DetailGlass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_detailRow('Тоннаж по дням',maximum==0?'Нет рейсов':'Макс. ${_fmt1(maximum)} т'),
      SizedBox(height:75,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[for(var i=0;i<days;i++)Expanded(child:Tooltip(message:'${i+1}: ${_fmt1(values[i])} т',child:Padding(padding:const EdgeInsets.symmetric(horizontal:1.5),child:Container(height:maximum==0?2:math.max(2,values[i]/maximum*75),decoration:BoxDecoration(color:values[i]>0?_amber:const Color(0xFF3D4E58),borderRadius:BorderRadius.circular(2))))))])),
      const SizedBox(height:6),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[_dt('1',size:11),_dt('$days',size:11)])]));
  }
}

class _DayGps extends StatelessWidget {
  final DateTime day;const _DayGps({required this.day});
  @override Widget build(BuildContext context)=>_TestLive(builder:(b){
    final shifts=b.shifts.where((s)=>ActivityBook.sameDay(DateTime.parse(s['start'] as String),day)).toList();
    final distance=shifts.fold<double>(0,(n,s)=>n+(s['gpsKm'] as num? ?? 0).toDouble());
    return _DetailFrame(title:'GPS · ${_detailDate(day)}',scene:_Scene.cab,children:[
      _DetailGlass(accent:true,child:_detailRow('GPS · тестовый пробег','${_fmt1(distance)} км')),
      _DetailGlass(child:Column(children:[
        if(shifts.isEmpty)_dt('Смен за этот день нет'),
        ..._separated([for(final s in shifts)_detailRow(_detailTime(DateTime.parse(s['start'] as String)),'${_fmt1((s['gpsKm'] as num? ?? 0).toDouble())} км',
          subtitle:s['end']!=null?'Запись завершена':s['gpsStatus']=='paused'?'Пауза':'Запись · демо',onTap:()=>_testOpen(context,shiftId:s['id'] as String))])])),
      _dt('В тестовом режиме сохраняется расстояние. Координаты, скорость и остановки не записываются.',size:12,color:const Color(0xFFB6C6CD)),
    ]);
  });
}
