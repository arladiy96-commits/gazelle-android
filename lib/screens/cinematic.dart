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
  final route=_SceneRoute<void>(builder:(_)=>shift==null&&!close
    ? _OpenShiftDashboard(controller:controller)
    : close&&shift!=null ? _CloseShiftDashboard(controller:controller,shift:shift)
    : _SceneForm(scene:_Scene.instruments,
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


// A live Work page built against the approved warehouse photo in AppShell.
// The reference image is a layout guide, not a screenshot used as the UI.
class _CinematicWork extends StatelessWidget {
  final AppSession session;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onQuickAdd;
  final bool showNavigation;

  const _CinematicWork({
    required this.session,
    this.onNavigate,
    this.onQuickAdd,
    this.showNavigation=true,
  });

  static const _gold=Color(0xFFFFCB78);
  static const _cyan=Color(0xFF4BDDED);
  static const _muted=Color(0xFFD0D6DC);
  static const _outline=Color(0x88738B97);
  static const _purple=Color(0xFFDF8DFF);

  Text _t(String text,double px,double unit,{
    Color color=Colors.white,
    FontWeight weight=FontWeight.w400,
    int maxLines=1,
    TextAlign? align,
  })=>Text(text,maxLines:maxLines,overflow:TextOverflow.ellipsis,
    textAlign:align,style:TextStyle(fontSize:px*unit,color:color,fontWeight:weight,height:1.17));

  Widget _panel(Widget child,double unit,{
    Color border=const Color(0x88738B97),double radius=19,
    EdgeInsetsGeometry? padding,
  })=>Container(
    decoration:BoxDecoration(
      gradient:const LinearGradient(
        begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:[Color(0xE615242C),Color(0xDC071219)]),
      borderRadius:BorderRadius.circular(radius*unit),
      border:Border.all(color:border,width:1.1*unit),
      boxShadow:const [BoxShadow(color:Color(0x45000000),blurRadius:10)]),
    padding:padding,child:child);

  @override
  Widget build(BuildContext context)=>_TestLive(builder:(book){
    final shift=book.active;
    final rows=shift==null?<Map<String,dynamic>>[]:
      book.forShift(shift['id'] as String);
    final records=[...rows]..sort((a,b)=>
      (b['date'] as String).compareTo(a['date'] as String));
    double sum(String kind,[String? type])=>rows
      .where((r)=>r['kind']==kind&&(type==null||r['type']==type))
      .fold<double>(0,(total,r)=>
        total+((r['amount'] as num?)?.toDouble()??0));
    final city=sum('trip','Город')/1000;
    final district=sum('trip','Район')/1000;
    final tripCount=rows.where((r)=>r['kind']=='trip').length;
    final mileage=shift==null?0:math.max(0,book.mileage(shift)).round();
    final initial=(shift?['startKm'] as num?)?.toInt();
    final current=(shift?['currentKm'] as num?)?.toInt();
    final seconds=shift==null?0:
      math.max(0,(book.elapsed(shift)*3600).round());
    final elapsed='${(seconds~/3600).toString().padLeft(2,'0')}:'
      '${((seconds~/60)%60).toString().padLeft(2,'0')}:'
      '${(seconds%60).toString().padLeft(2,'0')}';
    final started=shift==null?'—':
      _detailTime(DateTime.parse(shift['start'] as String));
    final paused=shift?['gpsStatus']=='paused';
    final gpsKm=(shift?['gpsKm'] as num?)?.toDouble()??0;
    final lastTrip=records.where((e)=>e['kind']=='trip').firstOrNull;
    final lastDestination=lastTrip?['direction']?.toString().trim()??'';

    return Column(children:[
      Expanded(child:LayoutBuilder(builder:(context,constraints){
        // The supplied reference is 691 pixels wide. Converting its visual
        // measurements through this scale keeps all widgets responsive.
        final u=(constraints.maxWidth/691).clamp(.43,1.2).toDouble();
        return Stack(children:[
          const Positioned.fill(child:IgnorePointer(child:DecoratedBox(
            decoration:BoxDecoration(gradient:LinearGradient(
              begin:Alignment.topCenter,end:Alignment.bottomCenter,
              stops:[0,.18,.57,1],
              colors:[Color(0x7503070A),Color(0x1803070A),
                Color(0x3A03070A),Color(0x7803070A)]))))),
          ListView(
            key:const PageStorageKey('reference-work-live'),
            padding:EdgeInsets.fromLTRB(22*u,0,22*u,29*u),
            children:[
              _header(context,u),
              SizedBox(height:9*u),
              _status(context,shift,elapsed,started,paused,u),
              SizedBox(height:30*u),
              _distance(mileage,initial,current,u),
              SizedBox(height:31*u),
              _metrics(city,district,tripCount,u),
              SizedBox(height:12*u),
              Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                _t('Всего перевезено',18,u,color:_muted),
                SizedBox(width:13*u),
                _t('${_fmt1(city+district)} т',23,u,color:_gold,
                  weight:FontWeight.w700),
              ]),
              SizedBox(height:16*u),
              _map(context,gpsKm,paused,lastDestination,u),
              SizedBox(height:14*u),
              _fuel(context,records,shift!=null,u),
              SizedBox(height:14*u),
              _events(context,records,u),
              SizedBox(height:18*u),
              _actions(context,shift!=null,u),
            ],
          ),
        ]);
      })),
      if(showNavigation)_workNavigation(context),
    ]);
  });

  Widget _header(BuildContext context,double u)=>SizedBox(
    height:73*u,
    child:Row(children:[
      InkWell(
        borderRadius:BorderRadius.circular(28*u),
        onTap:(){
          if(onNavigate!=null){onNavigate!(0);}
          else{Navigator.maybePop(context);}
        },
        child:SizedBox(width:46*u,height:58*u,
          child:Icon(Icons.arrow_back_ios_new_rounded,
            size:30*u,color:Colors.white))),
      Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        _t('Работа',31,u,weight:FontWeight.w600),
        SizedBox(height:4*u),
        _t('Текущая смена',18,u,color:_muted),
      ])),
      InkWell(
        borderRadius:BorderRadius.circular(28*u),
        onTap:()=>_showFeatureStub(context,'Уведомления',
          'Здесь будут события смены, документы, ТО и системные предупреждения.'),
        child:SizedBox(width:46*u,height:58*u,
          child:Icon(Icons.notifications_none_rounded,
            size:34*u,color:Colors.white))),
    ]));

  Widget _status(BuildContext context,Map<String,dynamic>? shift,
      String elapsed,String started,bool paused,double u){
    final active=shift!=null;
    return _panel(
      SizedBox(height:60*u,child:Row(children:[
        SizedBox(width:15*u),
        Container(width:14*u,height:14*u,decoration:BoxDecoration(
          color:active?const Color(0xFF00E596):_gold,
          shape:BoxShape.circle,
          boxShadow:[BoxShadow(color:active?
            const Color(0x8800E596):const Color(0x88FFCB78),blurRadius:8*u)])),
        SizedBox(width:16*u),
        Expanded(flex:5,child:_t(active?
          (paused?'GPS на паузе':'Смена открыта'):'Смена закрыта',
          19,u,color:_cyan,weight:FontWeight.w600)),
        Container(height:26*u,width:1*u,color:const Color(0x8854CBD5)),
        Expanded(flex:4,child:Center(child:_t(elapsed,21,u,
          color:_cyan,weight:FontWeight.w600))),
        Container(height:26*u,width:1*u,color:const Color(0x8854CBD5)),
        SizedBox(width:13*u),
        Expanded(flex:4,child:_t('Начало $started',16,u,
          color:const Color(0xFFACD9E5))),
        InkWell(
          onTap:active
            ?()=>_testRun(context,()=>TestStore.gps(
                shift!['id'] as String,paused:!paused))
            :()=>_openShiftAction(context),
          borderRadius:BorderRadius.circular(40*u),
          child:Container(width:58*u,height:58*u,
            decoration:BoxDecoration(
              color:const Color(0xFF071B24),shape:BoxShape.circle,
              border:Border.all(color:_cyan,width:2*u),
              boxShadow:[BoxShadow(color:const Color(0x554DDDEB),
                blurRadius:14*u)]),
            child:Icon(!active||paused?Icons.play_arrow_rounded:
              Icons.pause_rounded,color:_cyan,size:34*u)),
        ),
      ])),u,border:_cyan,radius:36);
  }

  Widget _distance(int mileage,int? initial,int? current,double u){
    Widget value(String caption,String digits)=>Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        _t(caption,18,u,color:_muted),
        SizedBox(height:6*u),
        FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            _t(digits,29,u,weight:FontWeight.w600),
            if(digits!='—')...[
              SizedBox(width:5*u),
              _t('км',29,u,weight:FontWeight.w600),
            ],
          ])),
      ]);
    return SizedBox(height:173*u,child:Row(children:[
      Expanded(flex:11,child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,
        mainAxisAlignment:MainAxisAlignment.center,children:[
          _t('Пробег за смену',23,u),
          SizedBox(height:8*u),
          FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
            child:_t('${_fmtInt(mileage.toDouble())} км',84,u,
              color:_gold,weight:FontWeight.w700)),
        ])),
      Container(width:1.5*u,height:126*u,color:_cyan),
      SizedBox(width:35*u),
      Expanded(flex:8,child:Column(
        mainAxisAlignment:MainAxisAlignment.spaceEvenly,
        crossAxisAlignment:CrossAxisAlignment.start,
        children:[
          value('Начало смены',
            initial==null?'—':_fmtInt(initial.toDouble())),
          value('Текущий одометр',
            current==null?'—':_fmtInt(current.toDouble())),
        ])),
    ]));
  }

  Widget _metrics(double city,double district,int trips,double u){
    Widget metric(String label,String value,IconData icon,Color color)=>
      Expanded(child:_panel(
        SizedBox(height:88*u,child:Row(children:[
          Container(width:63*u,height:63*u,
            decoration:BoxDecoration(
              color:const Color(0x8C061218),shape:BoxShape.circle,
              border:Border.all(color:color.withValues(alpha:.32))),
            child:Icon(icon,color:color,size:35*u)),
          SizedBox(width:8*u),
          Expanded(child:Column(
            mainAxisAlignment:MainAxisAlignment.center,
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              _t(label,17,u,color:_muted),
              SizedBox(height:5*u),
              FittedBox(fit:BoxFit.scaleDown,
                alignment:Alignment.centerLeft,
                child:_t(value,26,u,weight:FontWeight.w600)),
            ])),
        ])),u,
        padding:EdgeInsets.symmetric(horizontal:10*u),radius:15));
    return Row(children:[
      metric('Город','${_fmt1(city)} т',Icons.bar_chart_rounded,_gold),
      SizedBox(width:13*u),
      metric('Район','${_fmt1(district)} т',
        Icons.terrain_rounded,_purple),
      SizedBox(width:13*u),
      metric('Рейсы','$trips',Icons.local_shipping_outlined,_cyan),
    ]);
  }

  Widget _map(BuildContext context,double gpsKm,bool paused,
      String destination,double u){
    return _panel(
      SizedBox(height:346*u,child:Column(children:[
        Padding(
          padding:EdgeInsets.fromLTRB(14*u,12*u,14*u,10*u),
          child:Row(children:[
            Expanded(child:_t('Маршрут смены',20,u,
              weight:FontWeight.w600)),
            Container(width:12*u,height:12*u,
              decoration:BoxDecoration(
                shape:BoxShape.circle,
                color:paused?_gold:_cyan,
                border:Border.all(color:Colors.white,width:1*u))),
            SizedBox(width:7*u),
            _t(paused?'GPS · пауза':'GPS · демо',16,u,
              color:paused?_gold:_cyan),
          ])),
        Expanded(child:ClipRRect(
          borderRadius:BorderRadius.circular(14*u),
          child:Stack(children:[
            // Only a schematic map is currently possible. The journal stores
            // simulated mileage, not coordinates or GPS track geometry.
            const Positioned.fill(child:CustomPaint(
              painter:_WorkMapPainter())),
            Positioned.fill(child:DecoratedBox(
              decoration:BoxDecoration(gradient:LinearGradient(
                begin:Alignment.topCenter,end:Alignment.bottomCenter,
                colors:[const Color(0x2206121B),
                  Colors.transparent,const Color(0x97040F17)],
                stops:const [0,.5,1])))),
            Positioned(left:11*u,right:11*u,bottom:10*u,
              child:Container(
                padding:EdgeInsets.symmetric(horizontal:15*u,
                  vertical:10*u),
                decoration:BoxDecoration(
                  color:const Color(0xEB071A23),
                  borderRadius:BorderRadius.circular(16*u),
                  border:Border.all(color:const Color(0x88627D87))),
                child:Row(children:[
                  Expanded(child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,children:[
                      _t(destination.isEmpty?'Маршрут · демонстрация':
                        'Последний рейс · $destination',
                        19,u,weight:FontWeight.w600),
                      SizedBox(height:7*u),
                      _t('GPS: ${_fmt1(gpsKm)} км · схема, не трек',
                        15,u,color:_muted),
                    ])),
                  InkWell(
                    onTap:()=>_testOpen(context,page:'Смена'),
                    borderRadius:BorderRadius.circular(34*u),
                    child:Container(width:53*u,height:53*u,
                      decoration:BoxDecoration(shape:BoxShape.circle,
                        color:const Color(0xF706161D),
                        border:Border.all(color:_gold),
                        boxShadow:[BoxShadow(
                          color:const Color(0xAAFF9F28),
                          blurRadius:14*u)]),
                      child:Icon(Icons.navigation_outlined,color:_gold,
                        size:32*u)),
                  ),
                ])),
            ),
          ])),
        ),
      ])),u,radius:18);
  }

  Widget _fuel(BuildContext context,
      List<Map<String,dynamic>> records,bool active,double u){
    final fuels=records.where((r)=>r['kind']=='fuel').toList();
    double litres(String fuel)=>fuels.where((r)=>r['type']==fuel)
      .fold<double>(0,(s,r)=>s+((r['amount'] as num?)?.toDouble()??0));
    Map<String,dynamic>? last(String fuel){
      for(final r in fuels){if(r['type']==fuel)return r;}
      return null;
    }
    Widget fuelRow(String name,IconData icon,Color color){
      final entry=last(name);
      return InkWell(
        onTap:entry==null?null:()=>_testEditor(context,'fuel',entry:entry),
        borderRadius:BorderRadius.circular(14*u),
        child:Container(
          padding:EdgeInsets.symmetric(horizontal:12*u,vertical:10*u),
          decoration:BoxDecoration(
            color:const Color(0xA408171F),
            borderRadius:BorderRadius.circular(14*u),
            border:Border.all(color:const Color(0x66587480))),
          child:Row(children:[
            Container(width:40*u,height:40*u,
              decoration:BoxDecoration(shape:BoxShape.circle,
                color:color.withValues(alpha:.10)),
              child:Icon(icon,size:30*u,color:color)),
            SizedBox(width:13*u),
            Expanded(child:_t(name,17,u,color:_muted)),
            _t('+${_fmt1(litres(name))} л',20,u,
              weight:FontWeight.w600),
            SizedBox(width:25*u),
            _t(entry==null?'—':
              _detailTime(DateTime.parse(entry['date'] as String)),
              15,u,color:_muted),
          ])),
        );
    }
    return _panel(
      Padding(padding:EdgeInsets.fromLTRB(12*u,12*u,12*u,13*u),
        child:Column(children:[
          Row(children:[
            Expanded(child:_t('Заправки за смену',21,u,
              weight:FontWeight.w600)),
            InkWell(
              onTap:active
                ?()=>_testEditor(context,'fuel')
                :()=>_openShiftAction(context),
              borderRadius:BorderRadius.circular(8*u),
              child:Row(children:[
                Icon(Icons.add_circle_outline,color:_cyan,size:27*u),
                SizedBox(width:8*u),
                _t('Добавить',17,u,color:_cyan),
              ])),
          ]),
          SizedBox(height:12*u),
          fuelRow('Газ',Icons.local_fire_department_outlined,_cyan),
          SizedBox(height:4*u),
          fuelRow('Бензин',Icons.local_gas_station_outlined,
            const Color(0xFFFF715D)),
          SizedBox(height:9*u),
          Row(mainAxisAlignment:MainAxisAlignment.end,children:[
            _t('Всего',16,u,color:_muted),
            SizedBox(width:9*u),
            _t('${_fmt1(litres('Газ')+litres('Бензин'))} л',
              20,u,color:_gold,weight:FontWeight.w600),
          ]),
        ])),u,radius:17);
  }

  Widget _events(BuildContext context,
      List<Map<String,dynamic>> records,double u){
    IconData eventIcon(String kind)=>switch(kind){
      'trip'=>Icons.flag_outlined,
      'fuel'=>Icons.local_gas_station_outlined,
      'invoice'=>Icons.receipt_long_outlined,
      _=>Icons.notes_rounded,
    };
    Color eventColor(String kind)=>switch(kind){
      'trip'=>_muted,
      'fuel'=>_cyan,
      'invoice'=>_gold,
      _=>_purple,
    };
    String caption(Map<String,dynamic> r){
      final kind=r['kind'] as String? ?? '';
      final type=r['type']?.toString()??'';
      final number=r['number']?.toString()??'';
      final amount=(r['amount'] as num?)?.toDouble()??0;
      return switch(kind){
        'trip'=>'Рейс · $type · ${_fmt1(amount/1000)} т'
          '${(r['direction'] as String? ?? '').trim().isEmpty?'':' · ${r['direction']}'}',
        'fuel'=>'Заправка · $type +${_fmt1(amount)} л',
        'invoice'=>number.isEmpty?'Накладная':'Накладная №$number',
        _=>(r['note']?.toString().trim().isNotEmpty??false)
          ?r['note'].toString():'Заметка',
      };
    }
    return _panel(
      Padding(padding:EdgeInsets.fromLTRB(14*u,12*u,14*u,13*u),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _t('События смены',20,u,weight:FontWeight.w600),
          SizedBox(height:12*u),
          if(records.isEmpty)
            Padding(padding:EdgeInsets.symmetric(vertical:12*u),
              child:_t('Записей пока нет · добавьте рейс или топливо',
                17,u,color:_muted,maxLines:2))
          else for(final r in records.take(3))
            InkWell(
              onTap:()=>_testEditor(context,
                r['kind'] as String,entry:r),
              child:Padding(
                padding:EdgeInsets.symmetric(vertical:8*u),
                child:Row(children:[
                  Icon(eventIcon(r['kind'] as String),
                    color:eventColor(r['kind'] as String),size:25*u),
                  SizedBox(width:12*u),
                  _t(_detailTime(DateTime.parse(r['date'] as String)),
                    15,u,color:_muted),
                  SizedBox(width:12*u),
                  Container(width:1*u,height:21*u,color:_cyan),
                  SizedBox(width:13*u),
                  Expanded(child:_t(caption(r),17,u,maxLines:2)),
                ]),
              )),
        ])),u,radius:17);
  }

  Widget _actions(BuildContext context,bool active,double u)=>
    SizedBox(height:151*u,child:Row(
      mainAxisAlignment:MainAxisAlignment.spaceBetween,
      children:[
        Expanded(child:Align(
          alignment:Alignment.topLeft,
          child:OutlinedButton.icon(
            onPressed:active
              ?()=>_testEditor(context,'trip')
              :()=>_openShiftAction(context),
            style:OutlinedButton.styleFrom(
              foregroundColor:_gold,
              backgroundColor:const Color(0xBB0B151B),
              padding:EdgeInsets.symmetric(horizontal:15*u,vertical:13*u),
              side:BorderSide(color:_gold,width:1.3*u),
              shape:RoundedRectangleBorder(
                borderRadius:BorderRadius.circular(17*u))),
            icon:Icon(active?Icons.add_circle_outline:
              Icons.play_arrow_rounded,size:26*u),
            label:_t(active?'Добавить рейс':'Открыть смену',18,u,
              color:_gold),
          ),
        )),
        SizedBox(width:10*u),
        InkWell(
          onTap:()=>_openShiftAction(context),
          borderRadius:BorderRadius.circular(86*u),
          child:Container(
            width:140*u,height:140*u,
            decoration:BoxDecoration(
              color:const Color(0xE9161513),shape:BoxShape.circle,
              border:Border.all(color:_gold,width:1.8*u),
              boxShadow:[BoxShadow(color:const Color(0x88FF8A16),
                blurRadius:24*u,spreadRadius:2*u)]),
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Icon(active?Icons.stop_rounded:
                Icons.play_arrow_rounded,
                size:34*u,color:_gold),
              SizedBox(height:5*u),
              if(active)
                _t('Завершить смену',15,u,
                  align:TextAlign.center,maxLines:2)
              else ...[
                _t('ОТКРЫТЬ',15,u,align:TextAlign.center),
                _t('СМЕНУ',15,u,align:TextAlign.center),
              ],
            ]),
          ),
        ),
      ]));

  // Used only when WorkPage is opened outside AppShell's shared navigation.
  Widget _workNavigation(BuildContext context)=>SafeArea(top:false,
    child:Container(height:64,
      decoration:const BoxDecoration(
        color:Color(0xF0081117),
        border:Border(top:BorderSide(color:Color(0x444A6875)))),
      child:Row(children:[
        for(final item in [
          (Icons.home_outlined,'Главная',0),
          (Icons.local_shipping_outlined,'Работа',1),
          (Icons.add,'Добавить',2),
          (Icons.receipt_long_outlined,'Накладные',3),
          (Icons.more_horiz,'Ещё',4),
        ])Expanded(child:InkWell(
          onTap:(){
            if(item.$3==2){onQuickAdd?.call();}
            else if(item.$3==4){_openHomeMenu(context,session);}
            else{onNavigate?.call(item.$3);}
          },
          child:Column(mainAxisAlignment:MainAxisAlignment.center,
            children:[
              Icon(item.$1,color:item.$3==1||item.$3==2?
                _gold:Colors.white,size:item.$3==2?30:22),
              const SizedBox(height:4),
              Text(item.$2,style:TextStyle(
                color:item.$3==1?_gold:Colors.white,fontSize:10)),
            ]),
        )),
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

// Tab changes are opaque and never create Navigator routes.
// Disable timers/animations in hidden pages while retaining their UI state.
class _SceneTabStage extends StatelessWidget {
  final int index;final List<Widget> children;
  const _SceneTabStage({required this.index,required this.children});
  @override Widget build(BuildContext context)=>IndexedStack(index:index,
    children:[for(var i=0;i<children.length;i++)TickerMode(enabled:i==index,child:children[i])]);
}

class _CinematicMore extends StatelessWidget {
  final AppSession session;
  final ValueChanged<int>? onNavigate;
  final bool showNavigation;
  const _CinematicMore({required this.session,this.onNavigate,this.showNavigation=true});
  static const gold = Color(0xFFCEA15B);
  static const groups = <(String, IconData, List<(String,String,IconData,Color)>)>[
    ('РАБОЧЕЕ', Icons.bar_chart, [
      ('Деньги','Касса и чеки',Icons.payments_outlined,gold),
      ('Авансовый отчёт','Расходы и архив',Icons.assignment_outlined,gold),
      ('Отчёт за газ','Выдача и расход',Icons.local_gas_station_outlined,Color(0xFFC96B50)),
      ('Расчёт газа','Расчёт по своим данным',Icons.calculate_outlined,gold),
    ]),
    ('АВТОМОБИЛЬ', Icons.directions_car_outlined, [
      ('ТО и обслуживание','ТО, масло и история',Icons.handyman_outlined,gold),
      ('Документы','Страховка и техосмотр',Icons.shield_outlined,gold),
    ]),
    ('АДМИНИСТРИРОВАНИЕ', Icons.groups_outlined, [
      ('Сотрудники','Водители и грузчики',Icons.groups_rounded,gold),
      ('Направления','Общий список для всех',Icons.signpost_outlined,gold),
    ]),
    ('КАРТЫ И КОНТРОЛЬ', Icons.my_location_outlined, [
      ('GPS и геозоны','Общие точки и территории',Icons.location_on,Color(0xFF44B7D4)),
      ('Настройки','Интерфейс и ИИ',Icons.settings,gold),
    ]),
  ];
  static Widget backdrop() => Positioned.fill(child: Image.asset(
    'assets/images/scenes/more_dashboard.png',fit:BoxFit.cover,alignment:Alignment.topCenter));
  static BoxDecoration panel() => BoxDecoration(
    borderRadius:BorderRadius.circular(17),
    border:Border.all(color:const Color(0xFF776044),width:.8),
    gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[Color(0xEE171C1E),Color(0xF2081015),Color(0xF014181B)]),
    boxShadow:const [BoxShadow(color:Color(0x66000000),blurRadius:12,offset:Offset(0,5)),
      BoxShadow(color:Color(0x25C89851),blurRadius:2,spreadRadius:1)]);
  static Widget badge(IconData icon, Color color) => Container(width:38,height:38,
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(9),
      border:Border.all(color:const Color(0xFF60523F),width:.7),
      gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:[Color(0xFF57422B),Color(0xFF20282C),Color(0xFF080D10)]),
      boxShadow:const [BoxShadow(color:Color(0x66000000),blurRadius:4,offset:Offset(1,3))]),
    child:Icon(icon,color:color,size:26,shadows:const [Shadow(color:Colors.black,offset:Offset(1,2),blurRadius:3)]));
  void open(BuildContext context,(String,String,IconData,Color) item) {
    HapticFeedback.selectionClick();
    Navigator.push(context,_SceneRoute<void>(builder:(_)=>_MorePlaceholder(item:item)));
  }
  void navigate(BuildContext context,int index) {
    if(onNavigate!=null){onNavigate!(index);return;}
    final shell=context.findAncestorStateOfType<_AppShellState>();
    if(shell!=null){shell._selectTab(index);return;}
    if(index==4)return;
    if(index==2){_showQuickAddMenu(context,session);return;}
    if(index==0){Navigator.of(context).popUntil((r)=>r.isFirst);return;}
    if(index==3){Navigator.push(context,_SceneRoute<void>(builder:(_)=>_MillStatisticsRoute(session:session)));return;}
    Navigator.push(context,_SceneRoute<void>(builder:(page)=>WorkPage(session:session,
      onNavigate:(i)=>navigate(page,i),onQuickAdd:()=>_showQuickAddMenu(page,session))));
  }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:showNavigation?const Color(0xFF080E12):Colors.transparent,
    body:Stack(children:[if(showNavigation)backdrop(),SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(18,8,18,8),child:Row(children:[
        Container(width:38,height:38,decoration:BoxDecoration(shape:BoxShape.circle,
          color:const Color(0xB010161A),border:Border.all(color:gold)),
          child:IconButton(padding:EdgeInsets.zero,icon:const Icon(Icons.chevron_left,color:gold),
            tooltip:'Назад',onPressed:()=>navigate(context,0))),
        const SizedBox(width:17),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Ещё',style:TextStyle(color:Color(0xFFF1EEE6),fontSize:27,fontWeight:FontWeight.w600)),
          SizedBox(height:3),SizedBox(width:48,child:Divider(color:gold,height:3,thickness:1.5)),
          SizedBox(height:6),Text('Управление, отчёты и настройки',style:TextStyle(color:Color(0xFFC1C4C5),fontSize:11)),
        ])),
      ])),
      Expanded(child:ListView.builder(padding:const EdgeInsets.fromLTRB(22,2,18,10),
        itemCount:groups.length,itemBuilder:(context,index){final group=groups[index];
          return Padding(padding:const EdgeInsets.only(bottom:12),child:Column(children:[
            Padding(padding:const EdgeInsets.only(bottom:7,top:6),child:Row(children:[
              Icon(group.$2,color:gold,size:19),const SizedBox(width:12),
              Text(group.$1,style:const TextStyle(color:Color(0xFF7397A9),fontSize:10,fontWeight:FontWeight.w600)),
              const SizedBox(width:9),const Expanded(child:Divider(color:Color(0xFF62605A),height:1)),
            ])),
            Align(alignment:Alignment.centerLeft,child:FractionallySizedBox(widthFactor:index == 0 ? .80 : 1.0,
              child:Container(decoration:panel(),padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
                child:Column(children:[for(var i=0;i<group.$3.length;i++)...[
                  if(i>0)const Divider(height:1,color:Color(0xFF353A3D)),
                  Material(color:Colors.transparent,child:InkWell(borderRadius:BorderRadius.circular(10),
                    onTap:()=>open(context,group.$3[i]),child:Padding(padding:const EdgeInsets.symmetric(vertical:5),
                      child:Row(children:[badge(group.$3[i].$3,group.$3[i].$4),const SizedBox(width:13),
                        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                          Text(group.$3[i].$1,style:const TextStyle(color:Color(0xFFE9EAEB),fontSize:11,fontWeight:FontWeight.w500)),
                          const SizedBox(height:3),Text(group.$3[i].$2,style:const TextStyle(color:Color(0xFF90999E),fontSize:9)),
                        ])),const SizedBox(width:4),const Icon(Icons.chevron_right,color:Color(0xFFBDC3C5),size:19),
                      ])))),
                ]])))),
          ]));
        })),
      if(showNavigation)Padding(padding:const EdgeInsets.fromLTRB(8,4,8,3),
        child:_MillDock(index:4,onChanged:(i)=>navigate(context,i))),
    ]))]));
}
class _MorePlaceholder extends StatelessWidget {
  final (String,String,IconData,Color) item;
  const _MorePlaceholder({required this.item});
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFF080E12),
    body:Stack(children:[_CinematicMore.backdrop(),SafeArea(child:Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:Row(children:[
        IconButton(tooltip:'Назад',onPressed:()=>Navigator.pop(context),
          icon:const Icon(Icons.arrow_back,color:_CinematicMore.gold)),
        const SizedBox(width:8),Expanded(child:Text(item.$1,
          style:const TextStyle(color:Color(0xFFEEECE6),fontSize:20))),
      ])),
      Padding(padding:const EdgeInsets.all(22),child:Container(width:double.infinity,
        padding:const EdgeInsets.all(24),decoration:_CinematicMore.panel(),child:Column(children:[
          _CinematicMore.badge(item.$3,item.$4),const SizedBox(height:16),
          Text(item.$2,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFD3D7D9),fontSize:15)),
          const SizedBox(height:12),const Text('Раздел в разработке',style:TextStyle(color:Color(0xFF929FA6),fontSize:12)),
        ]))),
    ]))]));
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

class _OpenShiftDashboard extends StatefulWidget {
  final TextEditingController controller;
  const _OpenShiftDashboard({required this.controller});
  @override State<_OpenShiftDashboard> createState()=>_OpenShiftDashboardState();
}
class _OpenShiftDashboardState extends State<_OpenShiftDashboard> {
  static const gold=Color(0xFFE8BD7B),white=Color(0xFFE6E9E9);
  bool busy=false;
  String? error;
  Future<void> edit()async{
    if(busy)return;
    final draft=TextEditingController(text:widget.controller.text);
    draft.selection=TextSelection(baseOffset:0,extentOffset:draft.text.length);
    String? validation;
    final route=showModalBottomSheet<String>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF111A20),
      sheetAnimationStyle:const AnimationStyle(duration:Duration(milliseconds:180),reverseDuration:Duration(milliseconds:140)),
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))),builder:(sheet)=>
        StatefulBuilder(builder:(sheet,update){
          void accept(){if(int.tryParse(draft.text)==null){update(()=>validation='Введите показание одометра');return;}Navigator.pop(sheet,draft.text);}
          return Padding(padding:EdgeInsets.fromLTRB(22,22,22,MediaQuery.viewInsetsOf(sheet).bottom+20),child:SafeArea(top:false,
            child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Показание одометра',style:TextStyle(color:white,fontSize:20)),const SizedBox(height:16),
              TextField(controller:draft,autofocus:true,keyboardType:TextInputType.number,textInputAction:TextInputAction.done,
                inputFormatters:[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(9)],
                style:const TextStyle(color:gold,fontSize:32,letterSpacing:3),cursorColor:gold,
                decoration:InputDecoration(suffixText:'км',hintText:'Введите показание',hintStyle:const TextStyle(fontSize:18,color:Colors.white38),
                  errorText:validation,filled:true,fillColor:const Color(0xFF080F14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
                onSubmitted:(_)=>accept()),const SizedBox(height:16),SizedBox(width:double.infinity,child:OutlinedButton(
                  style:OutlinedButton.styleFrom(foregroundColor:gold,side:const BorderSide(color:gold),padding:const EdgeInsets.all(14)),onPressed:accept,child:const Text('Готово')))
            ])));}));
    final value=await route;
    if(mounted&&value!=null)setState((){widget.controller.text=value;error=null;});
    // The closing sheet may still render its TextField during its transition.
    Future<void>.delayed(const Duration(seconds:1),draft.dispose);
  }
  Future<void> submit()async{
    if(busy)return;
    final km=int.tryParse(widget.controller.text);
    if(km==null){setState(()=>error='Нажмите на одометр и введите показание');await edit();return;}
    setState((){busy=true;error=null;});
    try{await TestStore.open(km);if(mounted)Navigator.pop(context);}
    catch(e){if(mounted)setState((){busy=false;error=_testError(e);});}
  }
  Widget drum(String value){
    final digits=value.isEmpty?'------':value.padLeft(6,'0');
    return Semantics(button:true,label:value.isEmpty?'Ввести показание одометра':'Показание одометра $value километров. Нажмите для изменения',
      child:GestureDetector(behavior:HitTestBehavior.opaque,onTap:busy?null:edit,child:Row(children:[
        for(var i=0;i<digits.length;i++)Expanded(child:Container(margin:const EdgeInsets.symmetric(horizontal:3),
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(13),border:Border.all(color:const Color(0xFF37414A),width:1.5),
            gradient:const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
              colors:[Color(0xFF03080B),Color(0xFF38424A),Color(0xFF101316),Color(0xFF24211B),Color(0xFF020507)],stops:[0,.2,.49,.72,1])),
          child:Center(child:FittedBox(fit:BoxFit.scaleDown,child:Text(digits[i],style:const TextStyle(fontFamily:'monospace',fontSize:75,color:gold,fontWeight:FontWeight.w600))))))
      ])));
  }
  @override Widget build(BuildContext context)=>AnnotatedRegion<SystemUiOverlayStyle>(value:const SystemUiOverlayStyle(
    statusBarColor:Colors.transparent,statusBarIconBrightness:Brightness.light,systemNavigationBarColor:Colors.transparent,systemNavigationBarIconBrightness:Brightness.light),
    child:PopScope(canPop:!busy,child:Scaffold(resizeToAvoidBottomInset:false,backgroundColor:const Color(0xFF050B10),body:LayoutBuilder(builder:(context,box){
      final scale=box.maxWidth/864,safe=MediaQuery.viewPaddingOf(context).top;
      Widget at(double x,double y,double w,double h,Widget child)=>Positioned(left:x,top:y,width:w,height:h,child:child);
      final scene=SizedBox(width:864,height:1536,child:Stack(children:[
        at(46,72,88,88,_GasTap(label:'Назад',onTap:(){if(!busy)Navigator.pop(context);},child:Container(decoration:BoxDecoration(shape:BoxShape.circle,
          color:const Color(0xB8091117),border:Border.all(color:gold,width:1.5)),child:const Icon(Icons.arrow_back,color:gold,size:45)))),
        at(171,88,580,63,Row(children:[const Icon(Icons.speed,color:gold,size:60),const SizedBox(width:24),
          const Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text('Открыть смену',style:TextStyle(color:white,fontSize:44))))])),
        at(173,157,372,2,Container(color:gold.withValues(alpha:.65))),
        at(182,757,510,40,const Center(child:FittedBox(fit:BoxFit.scaleDown,child:Text('Текущее показание одометра',style:TextStyle(color:white,fontSize:29))))),
        at(183,851,485,131,ValueListenableBuilder<TextEditingValue>(valueListenable:widget.controller,builder:(_,v,__)=>drum(v.text))),
        at(697,911,52,42,const Text('км',style:TextStyle(color:gold,fontSize:32))),
        at(134,1047,604,102,_GasTap(label:'Открыть смену',onTap:submit,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          if(busy)const SizedBox(width:35,height:35,child:CircularProgressIndicator(color:gold,strokeWidth:3))else const Icon(Icons.play_arrow_rounded,color:gold,size:59),
          const SizedBox(width:22),Text(busy?'Сохранение…':'Открыть смену',style:const TextStyle(color:gold,fontSize:39,fontWeight:FontWeight.w500))]))),
        if(error!=null)at(135,1190,607,108,Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xEC10171C),borderRadius:BorderRadius.circular(14)),
          child:Center(child:Text(error!,textAlign:TextAlign.center,style:const TextStyle(color:gold,fontSize:23))))),
      ]));
      return SingleChildScrollView(child:SizedBox(width:box.maxWidth,height:math.max(box.maxHeight,1536*scale+safe+MediaQuery.viewPaddingOf(context).bottom),child:Stack(children:[
        Positioned.fill(child:RepaintBoundary(child:_ExtendedArtwork(asset:'assets/images/scenes/open_shift.png',topInset:safe))),
        Positioned(top:safe,left:0,width:box.maxWidth,height:1536*scale,child:FittedBox(fit:BoxFit.contain,child:MediaQuery.withClampedTextScaling(minScaleFactor:1,maxScaleFactor:1,child:scene)))])));
    }))));
}

class _CloseShiftDashboard extends StatefulWidget {
  final TextEditingController controller;
  final Map<String,dynamic> shift;
  const _CloseShiftDashboard({required this.controller,required this.shift});
  @override State<_CloseShiftDashboard> createState()=>_CloseShiftDashboardState();
}
class _CloseShiftDashboardState extends State<_CloseShiftDashboard> {
  static const gold=Color(0xFFE8BD7B),white=Color(0xFFE6E9E9);
  bool busy=false;
  String? error;
  late int? workedMinutes=widget.shift['hoursWorked']==null?null:((widget.shift['hoursWorked'] as num)*60).round();
  Future<void> edit()async{
    if(busy)return;
    final draft=TextEditingController(text:widget.controller.text);
    draft.selection=TextSelection(baseOffset:0,extentOffset:draft.text.length);
    String? validation;
    final route=showModalBottomSheet<String>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF111A20),
      sheetAnimationStyle:const AnimationStyle(duration:Duration(milliseconds:180),reverseDuration:Duration(milliseconds:140)),
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))),builder:(sheet)=>
        StatefulBuilder(builder:(sheet,update){
          void accept(){if(int.tryParse(draft.text)==null){update(()=>validation='Введите показание одометра');return;}Navigator.pop(sheet,draft.text);}
          return Padding(padding:EdgeInsets.fromLTRB(22,22,22,MediaQuery.viewInsetsOf(sheet).bottom+20),child:SafeArea(top:false,
            child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Показание одометра',style:TextStyle(color:white,fontSize:20)),const SizedBox(height:16),
              TextField(controller:draft,autofocus:true,keyboardType:TextInputType.number,textInputAction:TextInputAction.done,
                inputFormatters:[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(9)],
                style:const TextStyle(color:gold,fontSize:32,letterSpacing:3),cursorColor:gold,
                decoration:InputDecoration(suffixText:'км',hintText:'Введите показание',hintStyle:const TextStyle(fontSize:18,color:Colors.white38),
                  errorText:validation,filled:true,fillColor:const Color(0xFF080F14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
                onSubmitted:(_)=>accept()),const SizedBox(height:16),SizedBox(width:double.infinity,child:OutlinedButton(
                  style:OutlinedButton.styleFrom(foregroundColor:gold,side:const BorderSide(color:gold),padding:const EdgeInsets.all(14)),onPressed:accept,child:const Text('Готово')))
            ])));}));
    final value=await route;
    if(mounted&&value!=null)setState((){widget.controller.text=value;error=null;});
    // The closing sheet may still render its TextField during its transition.
    Future<void>.delayed(const Duration(seconds:1),draft.dispose);
  }
  Future<void> editHours()async{
    if(busy)return;
    final hour=TextEditingController(text:workedMinutes==null?'':'${workedMinutes!~/60}');
    final minute=TextEditingController(text:workedMinutes==null?'00':'${workedMinutes!%60}'.padLeft(2,'0'));
    String? validation;
    final result=await showModalBottomSheet<int>(context:context,isScrollControlled:true,
      backgroundColor:const Color(0xFF111A20),
      sheetAnimationStyle:const AnimationStyle(duration:Duration(milliseconds:180),reverseDuration:Duration(milliseconds:140)),
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(22))),
      builder:(sheet)=>StatefulBuilder(builder:(sheet,update){
        void accept(){final h=int.tryParse(hour.text),m=int.tryParse(minute.text);
          if(h==null||m==null||m>59){update(()=>validation='Введите часы и минуты от 00 до 59');return;}
          Navigator.pop(sheet,h*60+m);
        }
        Widget field(TextEditingController c,String label,bool focus)=>Expanded(child:TextField(controller:c,
          autofocus:focus,keyboardType:TextInputType.number,textInputAction:focus?TextInputAction.next:TextInputAction.done,
          inputFormatters:[FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(focus?3:2)],
          style:const TextStyle(color:gold,fontSize:32),cursorColor:gold,
          decoration:InputDecoration(labelText:label,filled:true,fillColor:const Color(0xFF080F14),border:const OutlineInputBorder()),
          onSubmitted:focus?null:(_)=>accept()));
        return Padding(padding:EdgeInsets.fromLTRB(22,22,22,MediaQuery.viewInsetsOf(sheet).bottom+20),child:SafeArea(top:false,
          child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Отработанные часы',style:TextStyle(color:white,fontSize:20)),const SizedBox(height:16),
            Row(children:[field(hour,'Часы',true),const SizedBox(width:16),field(minute,'Минуты',false)]),
            if(validation!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(validation!,style:const TextStyle(color:gold))),
            const SizedBox(height:16),SizedBox(width:double.infinity,child:OutlinedButton(onPressed:accept,
              style:OutlinedButton.styleFrom(foregroundColor:gold,side:const BorderSide(color:gold),padding:const EdgeInsets.all(14)),child:const Text('Готово')))
          ])));
      }));
    if(mounted&&result!=null)setState((){workedMinutes=result;error=null;});
    Future<void>.delayed(const Duration(seconds:1),(){hour.dispose();minute.dispose();});
  }
  Future<void> submit()async{
    if(busy)return;
    final km=int.tryParse(widget.controller.text);
    if(km==null){setState(()=>error='Введите показание одометра');await edit();return;}
    if(km<(widget.shift['startKm'] as num)){setState(()=>error='Показание не может быть меньше одометра начала смены');return;}
    if(workedMinutes==null){setState(()=>error='Укажите отработанные часы');await editHours();return;}
    setState((){busy=true;error=null;});
    try{
      final hours='${workedMinutes!~/60} ч ${workedMinutes!%60} мин';
      final confirmed=await _testConfirm(context,'Завершить смену? Одометр: $km км. Отработано: $hours.');
      if(!mounted)return;
      if(!confirmed){setState(()=>busy=false);return;}
      await TestStore.odometer(widget.shift['id'] as String,km,close:true,hours:workedMinutes!/60);
      if(mounted)Navigator.pop(context);
    }catch(e){if(mounted)setState((){busy=false;error=_testError(e);});}
  }
  Widget digits(String value)=>Row(children:[for(final char in value.split(''))Expanded(child:Center(
    child:FittedBox(fit:BoxFit.scaleDown,child:Text(char,style:const TextStyle(fontFamily:'monospace',fontSize:74,color:gold,fontWeight:FontWeight.w600)))))]);
  Widget drum(String value)=>Semantics(button:true,label:'Изменить показание одометра',child:GestureDetector(
    behavior:HitTestBehavior.opaque,onTap:busy?null:edit,child:digits(value.isEmpty?'------':value.padLeft(6,'0'))));
  Widget hoursDrum()=>Semantics(button:true,label:'Изменить отработанные часы',child:GestureDetector(
    behavior:HitTestBehavior.opaque,onTap:busy?null:editHours,child:Row(children:[
      Expanded(child:digits(workedMinutes==null?'--':'${workedMinutes!~/60}'.padLeft(2,'0'))),
      const SizedBox(width:43,child:Center(child:Text(':',style:TextStyle(fontSize:66,color:gold)))),
      Expanded(child:digits(workedMinutes==null?'--':'${workedMinutes!%60}'.padLeft(2,'0'))),
    ])));
  @override Widget build(BuildContext context)=>AnnotatedRegion<SystemUiOverlayStyle>(value:const SystemUiOverlayStyle(
    statusBarColor:Colors.transparent,statusBarIconBrightness:Brightness.light,systemNavigationBarColor:Colors.transparent,systemNavigationBarIconBrightness:Brightness.light),
    child:PopScope(canPop:!busy,child:Scaffold(resizeToAvoidBottomInset:false,backgroundColor:const Color(0xFF050B10),body:LayoutBuilder(builder:(context,box){
      final scale=box.maxWidth/864,safe=MediaQuery.viewPaddingOf(context).top;
      Widget at(double x,double y,double w,double h,Widget child)=>Positioned(left:x,top:y,width:w,height:h,child:child);
      final scene=SizedBox(width:864,height:1536,child:Stack(children:[
        at(46,72,88,88,_GasTap(label:'Назад',onTap:(){if(!busy)Navigator.pop(context);},child:Container(decoration:BoxDecoration(shape:BoxShape.circle,
          color:const Color(0xB8091117),border:Border.all(color:gold,width:1.5)),child:const Icon(Icons.arrow_back,color:gold,size:45)))),
        at(173,88,580,63,const Align(alignment:Alignment.centerLeft,child:FittedBox(fit:BoxFit.scaleDown,child:Text('Завершить смену',style:TextStyle(color:white,fontSize:44))))),
        at(173,157,372,2,Container(color:gold.withValues(alpha:.65))),
        at(182,699,510,40,const Center(child:FittedBox(fit:BoxFit.scaleDown,child:Text('Текущее показание одометра',style:TextStyle(color:white,fontSize:29))))),
        at(211,790,449,108,ValueListenableBuilder<TextEditingValue>(valueListenable:widget.controller,builder:(_,v,__)=>drum(v.text))),
        at(689,839,52,42,const Text('км',style:TextStyle(color:gold,fontSize:32))),
        at(225,960,440,40,const Center(child:Text('Отработанные часы',style:TextStyle(color:white,fontSize:29)))),
        at(253,1038,355,101,hoursDrum()),
        at(641,1070,42,42,const Text('ч',style:TextStyle(color:gold,fontSize:32))),
        at(140,1190,610,86,_GasTap(label:'Завершить смену',onTap:submit,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          if(busy)const SizedBox(width:35,height:35,child:CircularProgressIndicator(color:gold,strokeWidth:3))else const Icon(Icons.play_arrow_rounded,color:gold,size:59),
          const SizedBox(width:22),Text(busy?'Сохранение…':'Завершить смену',style:const TextStyle(color:gold,fontSize:36,fontWeight:FontWeight.w500))]))),
        if(error!=null)at(135,1310,607,108,Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xEC10171C),borderRadius:BorderRadius.circular(14)),
          child:Center(child:Text(error!,textAlign:TextAlign.center,style:const TextStyle(color:gold,fontSize:23))))),
      ]));
      return SingleChildScrollView(child:SizedBox(width:box.maxWidth,height:math.max(box.maxHeight,1536*scale+safe+MediaQuery.viewPaddingOf(context).bottom),child:Stack(children:[
        Positioned.fill(child:RepaintBoundary(child:_ExtendedArtwork(asset:'assets/images/scenes/close_shift.png',topInset:safe))),
        Positioned(top:safe,left:0,width:box.maxWidth,height:1536*scale,child:FittedBox(fit:BoxFit.contain,child:MediaQuery.withClampedTextScaling(minScaleFactor:1,maxScaleFactor:1,child:scene)))])));
    }))));
}
