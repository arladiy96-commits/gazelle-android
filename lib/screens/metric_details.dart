part of 'app_shell.dart';

Future<void> _openMetricDetails(BuildContext context,String metric,DateTime month) async {
  await Navigator.of(context).push<void>(_SceneRoute(builder:(_)=>_MetricDetails(metric:metric,month:month)));
}
String _detailDate(DateTime d)=>'${d.day} ${const ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'][d.month-1]}';
String _detailTime(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
Text _dt(String s,{double size=13,Color color=_paper,FontWeight weight=FontWeight.w400})=>Text(s,
  style:TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.25));
class _DetailGlass extends StatelessWidget {
  final Widget child;final bool accent;final EdgeInsets padding;
  const _DetailGlass({required this.child,this.accent=false,this.padding=const EdgeInsets.symmetric(horizontal:14,vertical:10)});
  @override
  Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:accent?const Color(0xBFFFBE5C):const Color(0xB57899A9)),
      gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xB316252D),Color(0xC7071219)]),
      boxShadow:accent?const[BoxShadow(color:Color(0x14FFB23C),blurRadius:10)]:null),
    child:ClipRRect(borderRadius:BorderRadius.circular(16),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:2,sigmaY:2),
      child:Padding(padding:padding,child:child))));
}
class _DetailFrame extends StatelessWidget {
  final String title;final List<Widget> children;final ScrollController? controller;
  final _Scene? scene;final bool embedded,showHero;final Widget? action;
  const _DetailFrame({required this.title,required this.children,this.controller,this.scene,this.embedded=false,this.showHero=true,this.action});
  @override Widget build(BuildContext context){final resolved=scene??_sceneFor(title);
    final body=Stack(children:[Positioned.fill(child:_SceneBackdrop(scene:resolved)),
      SafeArea(top:!embedded,bottom:!embedded,child:Column(children:[
        Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:Row(children:[
          SizedBox(width:48,child:embedded?null:IconButton(tooltip:'Назад',onPressed:()=>Navigator.maybePop(context),icon:const Icon(Icons.chevron_left,color:_amber))),
          Expanded(child:Text(title,textAlign:TextAlign.center,style:const TextStyle(color:_paper,fontSize:16,fontWeight:FontWeight.w400))),
          SizedBox(width:48,child:action??(embedded?null:IconButton(tooltip:'На главную',onPressed:()=>Navigator.of(context).popUntil((r)=>r.isFirst),icon:const Icon(Icons.close,color:_paper,size:21))))])),
        Expanded(child:_SceneReveal(child:ListView(key:PageStorageKey('scene-$title'),controller:controller,
          keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.onDrag,padding:const EdgeInsets.fromLTRB(16,4,16,24),children:[
            if(showHero)_SceneSpace(scene:resolved),...children])))]))]);
    return embedded?body:Scaffold(backgroundColor:const Color(0xFF030B10),body:body);
  }
}
Widget _detailButton(String label,VoidCallback action,{IconData icon=Icons.chevron_right})=>Padding(padding:const EdgeInsets.only(bottom:12),
  child:OutlinedButton.icon(onPressed:action,icon:Icon(icon,size:18),label:Text(label,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w500)),
    style:OutlinedButton.styleFrom(foregroundColor:_amber,backgroundColor:const Color(0xC0081319),
      side:const BorderSide(color:Color(0xBFFFBE5C)),minimumSize:const Size.fromHeight(44),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))));
Widget _detailRow(String label,String value,{VoidCallback? onTap,String? subtitle,Color? color})=>InkWell(onTap:onTap,
  borderRadius:BorderRadius.circular(12),child:Container(constraints:const BoxConstraints(minHeight:44),padding:const EdgeInsets.symmetric(vertical:9,horizontal:2),child:Row(children:[
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(label,color:color??_paper),
      if(subtitle!=null)...[const SizedBox(height:4),_dt(subtitle,size:12,color:const Color(0xFFADC0CC))]])),
    const SizedBox(width:12),_dt(value,weight:FontWeight.w500),if(onTap!=null)...[const SizedBox(width:8),const Icon(Icons.chevron_right,color:_paper,size:18)]])));
List<Widget> _separated(List<Widget> rows)=>[for(var i=0;i<rows.length;i++)...[if(i>0)const Divider(height:1,color:Color(0x803E505B)),rows[i]]];


// Project each live value onto the four corners of its photographic display.
// A 3D rotation cannot reproduce this trapezoid: it needs a homography.
Matrix4 _mileagePhotoPlane(
  double flatWidth,double flatHeight,
  Offset topLeft,Offset topRight,Offset bottomRight,Offset bottomLeft,
){
  final dx1=topRight.dx-bottomRight.dx;
  final dx2=bottomLeft.dx-bottomRight.dx;
  final dx3=topLeft.dx-topRight.dx+bottomRight.dx-bottomLeft.dx;
  final dy1=topRight.dy-bottomRight.dy;
  final dy2=bottomLeft.dy-bottomRight.dy;
  final dy3=topLeft.dy-topRight.dy+bottomRight.dy-bottomLeft.dy;
  final determinant=dx1*dy2-dx2*dy1;
  if(determinant.abs()<0.000001)return Matrix4.identity();
  final g=(dx3*dy2-dx2*dy3)/determinant;
  final h=(dx1*dy3-dx3*dy1)/determinant;
  final a=topRight.dx-topLeft.dx+g*topRight.dx;
  final b=bottomLeft.dx-topLeft.dx+h*bottomLeft.dx;
  final d=topRight.dy-topLeft.dy+g*topRight.dy;
  final e=bottomLeft.dy-topLeft.dy+h*bottomLeft.dy;
  return Matrix4.identity()
    ..setEntry(0,0,a/flatWidth)
    ..setEntry(0,1,b/flatHeight)
    ..setEntry(0,3,topLeft.dx)
    ..setEntry(1,0,d/flatWidth)
    ..setEntry(1,1,e/flatHeight)
    ..setEntry(1,3,topLeft.dy)
    ..setEntry(3,0,g/flatWidth)
    ..setEntry(3,1,h/flatHeight);
}

class _MileageGlassReadoutPainter extends CustomPainter {
  final String value;
  const _MileageGlassReadoutPainter({required this.value});

  TextPainter _text(String text,TextStyle style)=>TextPainter(
    text:TextSpan(text:text,style:style),
    textDirection:TextDirection.ltr,
    maxLines:1,
  )..layout();

  @override
  void paint(Canvas canvas,Size size){
    canvas.save();
    // These measurements refer to the clean photograph's 711x1536 pixels,
    // with this painter placed at image (430,452), size 230x140.
    canvas.scale(size.width/115.0,size.height/70.0);
    canvas.transform(_mileagePhotoPlane(
      100,34,
      const Offset(19.5,21.0),
      const Offset(98.0,28.0),
      const Offset(96.5,48.0),
      const Offset(19.5,41.5),
    ).storage);

    // The bezel/glass are part of the photograph. Draw no added tile,
    // border or background: only softly illuminated live glyphs.
    const fontSize=23.0;
    final number=_text(value,TextStyle(
      fontSize:fontSize,
      fontWeight:FontWeight.w600,
      letterSpacing:-.40,
      foreground:Paint()..shader=const LinearGradient(
        begin:Alignment.topCenter,end:Alignment.bottomCenter,
        colors:[
          Color(0xF2EAE7DB),
          Color(0xE9E8DCCA),
          Color(0xD1BAAA91),
        ],
      ).createShader(const Rect.fromLTWH(0,0,110,30)),
    ));
    final unit=_text(' км',const TextStyle(
      color:Color(0xD6A5C7D1),
      fontSize:11.0,
      fontWeight:FontWeight.w500,
    ));
    final combined=number.width+unit.width+0.7;
    final fit=math.min(1.0,94.0/math.max(1.0,combined));
    final start=(100.0-combined*fit)/2.0;
    canvas.translate(start,(34-fontSize*fit)/2.0);
    canvas.scale(fit);

    // Local shadow/glow use the same perspective as the characters.
    final shadow=_text(value,const TextStyle(
      color:Color(0x78000000),
      fontSize:fontSize,fontWeight:FontWeight.w600,letterSpacing:-.40,
    ));
    shadow.paint(canvas,const Offset(.45,.8));
    final warmGlow=_text(value,const TextStyle(
      color:Color(0x1CFFE3AF),
      fontSize:fontSize,fontWeight:FontWeight.w600,letterSpacing:-.40,
    ));
    canvas.saveLayer(const Rect.fromLTWH(-5,-5,135,45),
      Paint()..maskFilter=const MaskFilter.blur(BlurStyle.normal,1.7));
    warmGlow.paint(canvas,Offset.zero);
    canvas.restore();
    number.paint(canvas,Offset.zero);
    unit.paint(canvas,Offset(number.width+.7,9.5));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MileageGlassReadoutPainter oldDelegate)=>
    oldDelegate.value!=value;
}

class _MileageOdometerPainter extends CustomPainter {
  final String reading;
  const _MileageOdometerPainter({required this.reading});

  static const _patterns=<String,List<int>>{
    '0':[0,1,2,4,5,6], '1':[2,5], '2':[0,2,3,4,6],
    '3':[0,2,3,5,6], '4':[1,2,3,5],
    '5':[0,1,3,5,6], '6':[0,1,3,4,5,6],
    '7':[0,2,5], '8':[0,1,2,3,4,5,6],
    '9':[0,1,2,3,5,6], '-':[3],
  };

  Path _horizontal(double x,double y,double w,double t){
    final bevel=t*.56;
    return Path()
      ..moveTo(x+bevel,y)
      ..lineTo(x+w-bevel,y)
      ..lineTo(x+w,y+t/2)
      ..lineTo(x+w-bevel,y+t)
      ..lineTo(x+bevel,y+t)
      ..lineTo(x,y+t/2)
      ..close();
  }

  Path _vertical(double x,double y,double h,double t){
    final bevel=t*.53;
    return Path()
      ..moveTo(x+t/2,y)
      ..lineTo(x+t,y+bevel)
      ..lineTo(x+t,y+h-bevel)
      ..lineTo(x+t/2,y+h)
      ..lineTo(x,y+h-bevel)
      ..lineTo(x,y+bevel)
      ..close();
  }

  void _digit(Canvas canvas,String digit,double x,double y,double w,double h){
    final t=math.max(.90,w*.16);
    final half=h/2;
    final verticalLength=half-t*1.50;
    final paths=<Path>[
      _horizontal(x+t*.65,y,w-t*1.30,t),
      _vertical(x,y+t*.85,verticalLength,t),
      _vertical(x+w-t,y+t*.85,verticalLength,t),
      _horizontal(x+t*.65,y+half-t/2,w-t*1.30,t),
      _vertical(x,y+half+t*.35,verticalLength,t),
      _vertical(x+w-t,y+half+t*.35,verticalLength,t),
      _horizontal(x+t*.65,y+h-t,w-t*1.30,t),
    ];
    final active=_patterns[digit]??const <int>[];
    for(var i=0;i<7;i++){
      if(!active.contains(i)){
        canvas.drawPath(paths[i],Paint()..color=const Color(0x183E291A));
        continue;
      }
      canvas.drawPath(paths[i],Paint()
        ..color=const Color(0x48EF9D46)
        ..maskFilter=const MaskFilter.blur(BlurStyle.normal,1.30));
      canvas.drawPath(paths[i],Paint()..shader=const LinearGradient(
        begin:Alignment.topCenter,end:Alignment.bottomCenter,
        colors:[
          Color(0xF4FFE0A0),Color(0xE3F5B65C),Color(0xBFC76D29),
        ],
      ).createShader(Rect.fromLTWH(x,y,w,h)));
    }
  }

  @override
  void paint(Canvas canvas,Size size){
    canvas.save();
    // Photograph origin (214,592), bounds 124x50; corners follow the LCD
    // window, not a separate rectangle laid on top of the dashboard.
    canvas.scale(size.width/62.0,size.height/25.0);
    // Fine-tuned to the photographed odometer window so the digits follow
    // the plane of the LCD more naturally.
    canvas.transform(_mileagePhotoPlane(
      100,24,
      const Offset(5.0,8.3),
      const Offset(58.6,6.2),
      const Offset(57.8,21.2),
      const Offset(4.1,22.7),
    ).storage);

    final onlyDigits=reading.replaceAll(RegExp(r'[^0-9]'),'');
    final shown=onlyDigits.isEmpty?'------':onlyDigits.padLeft(6,'0');
    final n=shown.length;
    const leftMargin=4.0;
    const spacing=.9;
    final groupGap=n>=5?1.8:0.0;
    final digitWidth=(92.0-spacing*(n-1)-groupGap)/n;
    var x=leftMargin;
    for(var i=0;i<n;i++){
      if(i==n-3&&groupGap>0)x+=groupGap;
      _digit(canvas,shown[i],x,1.9,digitWidth,18.7);
      x+=digitWidth+spacing;
    }
    // The original background supplies the smoked LCD, bezel and highlights.
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MileageOdometerPainter oldDelegate)=>
    oldDelegate.reading!=reading;
}

class _MetricDetails extends StatefulWidget {
  final String metric;final DateTime month;
  const _MetricDetails({required this.metric,required this.month});
  @override
  State<_MetricDetails> createState()=>_MetricDetailsState();
}
class _MetricDetailsState extends State<_MetricDetails> {
  late DateTime _month;
  _HomeMonthData? _total;ActivityBook? _book;TestPreferences? _prefs;double? _mileageOdometer;
  final _scroll=ScrollController();
  String? _error,_direction;bool _trips=false,_hideEmpty=true,_salaryDaysExpanded=false;int _loadId=0;
  bool get _weight=>['Город','Район'].contains(widget.metric);
  bool get _fuel=>['Газ','Бензин'].contains(widget.metric);
  @override
  void initState(){super.initState();_month=widget.month;_homeDataRevision.addListener(_load);_load();}
  @override
  void dispose(){_loadId++;_homeDataRevision.removeListener(_load);_scroll.dispose();super.dispose();}
  Future<void> _load() async {
    final id=++_loadId;
    try {final total=await _HomeMonthData.load(_month);final book=await ActivityRepository.load(_month);final prefs=await TestPreferences.getInstance();
      final odometer=widget.metric=='Пробег'?_mileageMonthOdometer(await TestStore.load(),_month):null;
      if(mounted&&id==_loadId)setState((){_total=total;_book=book;_prefs=prefs;_mileageOdometer=odometer;_error=null;});
    }catch(_){if(mounted&&id==_loadId)setState(()=>_error='Не удалось прочитать данные. Повторите попытку.');}
  }
  void _monthTo(int delta){setState((){_month=DateTime(_month.year,_month.month+delta);_book=null;_total=null;_mileageOdometer=null;_direction=null;_salaryDaysExpanded=false;});if(_scroll.hasClients)_scroll.jumpTo(0);_load();}
  Future<void> _pickDay() async {
    final now=DateTime.now();final first=DateTime(_month.year,_month.month);final last=DateTime(_month.year,_month.month+1,0);
    final d=await showDatePicker(context:context,initialDate:ActivityBook.sameDay(first,now)?now:first,firstDate:first,lastDate:last);
    if(d!=null&&mounted)_day(d);
  }
  void _day(DateTime d)=>Navigator.of(context).push<void>(_SceneRoute(builder:(_)=>_DayDetails(date:d)));
  List<ActivityEntry> get _entries=>(_book?.entries??[]).where((e)=>(_fuel?e.kind=='fuel':e.kind=='trip')&&e.type==widget.metric&&(_direction==null||e.direction==_direction)).toList()
    ..sort((a,b)=>b.date.compareTo(a.date));
  double? _dayValue(DateTime d,String metric)=>(_prefs?.get('home_day_${d.year}_${d.month}_${d.day}_$metric') as num?)?.toDouble();
  Future<void> _filter() async {
    final options=(_book?.entries??[]).where((e)=>e.kind=='trip'&&e.type==widget.metric).map((e)=>e.direction).where((e)=>e.isNotEmpty).toSet().toList()..sort();
    final selected=await _pickQuickValue(context,'Направление',['Все направления',...options]);
    if(selected!=null&&mounted)setState(()=>_direction=selected=='Все направления'?null:selected);
  }
  @override
  Widget build(BuildContext context)=>widget.metric=='Зарплата'
      ? _salaryScreen()
      : widget.metric=='Пробег'
      ? _mileageScreen()
      : _DetailFrame(title:widget.metric,controller:_scroll,showHero:false,children:[
          Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            IconButton(tooltip:'Предыдущий месяц',onPressed:()=>_monthTo(-1),icon:const Icon(Icons.chevron_left,color:_amber)),
            Flexible(child:_dt('${_garageMonths[_month.month-1]} ${_month.year}',size:15)),
            IconButton(tooltip:'Следующий месяц',onPressed:()=>_monthTo(1),icon:const Icon(Icons.chevron_right,color:_amber)),
          ]),const SizedBox(height:12),
          if(_error!=null)...[_DetailGlass(child:_dt(_error!)),_detailButton('Повторить',_load)]
          else if(_total==null||_book==null)const Center(child:CircularProgressIndicator(color:_amber))
          else ..._content(),
        ]);


  double? _mileageMonthOdometer(TestState book,DateTime month){
    final shifts=book.shifts.where((shift){
      final date=DateTime.tryParse((shift['start'] as String?)??'');
      return date!=null&&date.year==month.year&&date.month==month.month;
    }).toList()
      ..sort((a,b)=>((a['start'] as String?)??'')
          .compareTo((b['start'] as String?)??''));
    if(shifts.isEmpty)return null;
    return (shifts.last['currentKm'] as num?)?.toDouble();
  }

  Future<void> _mileagePickDay() async {
    final now=DateTime.now();
    final first=DateTime(_month.year,_month.month);
    final last=DateTime(_month.year,_month.month+1,0);
    final inMonth=now.year==_month.year&&now.month==_month.month;
    final selected=await showDatePicker(
      context:context,
      initialDate:inMonth?now:first,
      firstDate:first,
      lastDate:last,
      builder:(context,child)=>Theme(
        data:Theme.of(context).copyWith(
          colorScheme:const ColorScheme.dark(
            primary:Color(0xFFFFC477),
            surface:Color(0xFF162129),
          ),
        ),
        child:child!,
      ),
    );
    if(selected!=null&&mounted)_day(selected);
  }

  Future<void> _mileageRouteHistory() async {
    final month=_month;
    try {
      final state=await TestStore.load();
      if(!mounted)return;
      final days=<DateTime,double>{};
      for(final shift in state.shifts){
        final date=DateTime.tryParse((shift['start'] as String?)??'');
        final gps=(shift['gpsKm'] as num?)?.toDouble()??0;
        if(date!=null&&date.year==month.year&&date.month==month.month&&gps>0){
          final day=DateTime(date.year,date.month,date.day);
          days.update(day,(previous)=>previous+gps,ifAbsent:()=>gps);
        }
      }
      final dates=days.keys.toList()..sort((a,b)=>b.compareTo(a));
      Navigator.of(context).push<void>(_SceneRoute(builder:(routeContext)=>
        _DetailFrame(
          title:'История маршрутов',
          scene:_Scene.cab,
          showHero:false,
          children:[
            const SizedBox(height:14),
            const _DetailGlass(child:Text(
              'GPS здесь работает в демонстрационном режиме. '
              'Расстояния из журнала доступны по дням; '
              'реальный GPS-трек не записывается.',
              style:TextStyle(color:Color(0xFFBCCBD2),fontSize:13),
            )),
            const SizedBox(height:12),
            if(dates.isEmpty)
              const _DetailGlass(child:Text(
                'За выбранный месяц GPS-маршрутов пока нет.',
                style:TextStyle(color:Color(0xFFE8EEF1),fontSize:14),
              ))
            else
              _DetailGlass(child:Column(children:_separated([
                for(final day in dates)
                  _detailRow(
                    _detailDate(day),
                    '${_fmt1(days[day]??0)} км',
                    onTap:()=>Navigator.of(routeContext).push<void>(
                      _SceneRoute(builder:(_)=>_DayGps(day:day))),
                  ),
              ]))),
          ],
        ),
      ));
    }catch(_){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Не удалось загрузить историю GPS.')),
      );
    }
  }

  Widget _mileageScreen()=>Scaffold(
    backgroundColor:const Color(0xFF080D11),
    body:LayoutBuilder(builder:(context,box){
      // Layout follows the supplied 709px-wide mockup at a 2x density.
      // One clean photo is used: the mileage-specific source artwork.
      final u=box.maxWidth/354.5;
      final photoScale=math.max(box.maxWidth/711.0,box.maxHeight/1536.0);
      final photoCropX=(711*photoScale-box.maxWidth)/2.0;
      final safe=MediaQuery.paddingOf(context);
      final available=math.max(0.0,box.maxHeight-safe.top-safe.bottom);
      final heroSpace=math.max(200*u,390*u-safe.top-86*u);
      return Stack(children:[
        Positioned.fill(child:ColoredBox(color:const Color(0xFF080D11))),
        const Positioned.fill(
          child:Image(
            image:AssetImage('assets/images/scenes/mileage.png'),
            fit:BoxFit.cover,
            alignment:Alignment.topCenter,
            filterQuality:FilterQuality.high,
          ),
        ),
        const Positioned.fill(child:IgnorePointer(child:DecoratedBox(
          decoration:BoxDecoration(
            gradient:LinearGradient(
              begin:Alignment.topCenter,
              end:Alignment.bottomCenter,
              stops:[0,.30,.49,.65,1],
              colors:[
                Color(0x25000000),Color(0x00000000),
                Color(0x24070A0E),Color(0x7406090C),Color(0xE4080D11),
              ],
            ),
          ),
        ))),
        // Match BoxFit.cover's photograph coordinates, including side crop.
        // Painting by screen-width alone makes the digits slip on tall devices.
        Positioned(
          left:430*photoScale-photoCropX,
          top:452*photoScale,
          width:230*photoScale,height:140*photoScale,
          child:IgnorePointer(child:CustomPaint(
            painter:_MileageGlassReadoutPainter(
              value:_total==null?'—':_fmtInt(_total!.mileage),
            ),
          )),
        ),
        Positioned(
          left:212*photoScale-photoCropX,
          top:594*photoScale,
          width:128*photoScale,height:52*photoScale,
          child:IgnorePointer(child:CustomPaint(
            painter:_MileageOdometerPainter(
              reading:_mileageOdometer==null?'':_mileageOdometer!.round().toString(),
            ),
          )),
        ),
        SafeArea(child:SingleChildScrollView(
          key:const PageStorageKey('mileage-screen'),
          controller:_scroll,
          child:ConstrainedBox(
            constraints:BoxConstraints(minHeight:available),
            child:Column(children:[
              _mileageHeader(u),
              SizedBox(height:8*u),
              _mileageMonthSelector(u),
              SizedBox(height:heroSpace),
              if(_error!=null)
                Padding(
                  padding:EdgeInsets.symmetric(horizontal:15*u),
                  child:Column(children:[
                    _DetailGlass(child:_dt(_error!)),
                    _detailButton('Повторить',_load),
                  ]),
                )
              else
                _mileageDaysPanel(u),
              SizedBox(height:12*u),
              _mileageHistoryButton(u),
              SizedBox(height:16*u),
              Row(
                mainAxisAlignment:MainAxisAlignment.center,
                children:[
                  Icon(Icons.info_outline,
                    size:15*u,color:const Color(0xFF959EA6)),
                  SizedBox(width:9*u),
                  Text('Данные из журнала',
                    style:TextStyle(
                      fontSize:11*u,color:const Color(0xFF959EA6))),
                ],
              ),
              SizedBox(height:23*u),
              Align(
                alignment:Alignment.centerLeft,
                child:TextButton.icon(
                  onPressed:()=>_openGarageSection(
                    context,'Статистика',''),
                  icon:Icon(Icons.chevron_left,
                    size:19*u,color:const Color(0xFFABB7C1)),
                  label:Text('К показателям',
                    style:TextStyle(
                      fontSize:13*u,color:const Color(0xFFABB7C1))),
                  style:TextButton.styleFrom(
                    padding:EdgeInsets.symmetric(
                      horizontal:15*u,vertical:6*u),
                  ),
                ),
              ),
              SizedBox(height:11*u),
            ]),
          ),
        )),
      ]);
    }),
  );

  Widget _mileageHeader(double u)=>SizedBox(
    height:44*u,
    child:Padding(
      padding:EdgeInsets.symmetric(horizontal:15*u),
      child:Row(children:[
        SizedBox(
          width:26*u,
          child:IconButton(
            onPressed:()=>Navigator.maybePop(context),
            padding:EdgeInsets.zero,
            tooltip:'Назад',
            icon:Icon(Icons.arrow_back_ios_new,
              color:Colors.white,size:20*u),
          ),
        ),
        SizedBox(width:9*u),
        Text('Пробег',style:TextStyle(
          fontSize:17*u,color:Colors.white,
          fontWeight:FontWeight.w400,
        )),
        const Spacer(),
        PopupMenuButton<String>(
          tooltip:'Действия',
          color:const Color(0xFF1C2327),
          icon:Icon(Icons.more_horiz,
            size:24*u,color:Colors.white),
          onSelected:(value){
            if(value=='day')_mileagePickDay();
            if(value=='history')_mileageRouteHistory();
            if(value=='stats')_openGarageSection(
              context,'Статистика','');
          },
          itemBuilder:(context)=>const[
            PopupMenuItem(
              value:'day',
              child:Text('Выбрать дату',
                style:TextStyle(color:Colors.white))),
            PopupMenuItem(
              value:'history',
              child:Text('История маршрутов',
                style:TextStyle(color:Colors.white))),
            PopupMenuItem(
              value:'stats',
              child:Text('Показатели',
                style:TextStyle(color:Colors.white))),
          ],
        ),
      ]),
    ),
  );

  Widget _mileageMonthSelector(double u)=>Container(
    width:160*u,height:34*u,
    decoration:BoxDecoration(
      color:const Color(0xE7192228),
      border:Border.all(
        color:const Color(0xB8818D93),width:.7*u),
      borderRadius:BorderRadius.circular(22*u),
    ),
    child:Row(children:[
      SizedBox(
        width:33*u,
        child:IconButton(
          tooltip:'Предыдущий месяц',
          padding:EdgeInsets.zero,
          onPressed:()=>_monthTo(-1),
          icon:Icon(Icons.chevron_left,
            color:Colors.white,size:21*u),
        ),
      ),
      Expanded(
        child:FittedBox(
          fit:BoxFit.scaleDown,
          child:Text(
            '${_garageMonths[_month.month-1]} ${_month.year}',
            maxLines:1,
            style:TextStyle(
              color:Colors.white,fontSize:13.5*u),
          ),
        ),
      ),
      SizedBox(
        width:33*u,
        child:IconButton(
          tooltip:'Следующий месяц',
          padding:EdgeInsets.zero,
          onPressed:()=>_monthTo(1),
          icon:Icon(Icons.chevron_right,
            color:Colors.white,size:21*u),
        ),
      ),
    ]),
  );

  Widget _mileageDaysPanel(double u){
    final now=DateTime.now();
    final last=DateTime(_month.year,_month.month+1,0).day;
    final count=now.year==_month.year&&now.month==_month.month?
      now.day:last;
    final dates=<DateTime>[
      for(var day=count;day>=1;day--)
        DateTime(_month.year,_month.month,day),
    ].where((day)=>_dayValue(day,'mileage')!=null).take(4).toList();

    const line=Color(0x6650575A);
    return Container(
      width:double.infinity,
      constraints:BoxConstraints(minHeight:213*u),
      margin:EdgeInsets.symmetric(horizontal:15*u),
      padding:EdgeInsets.fromLTRB(14*u,12*u,14*u,9*u),
      decoration:BoxDecoration(
        color:const Color(0xE51C1D1D),
        border:Border.all(
          color:const Color(0xC39E783F),width:.7*u),
        borderRadius:BorderRadius.circular(12*u),
        boxShadow:const [
          BoxShadow(color:Color(0x99000000),
            blurRadius:18,offset:Offset(0,8)),
        ],
      ),
      child:Material(
        color:Colors.transparent,
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Row(children:[
              Expanded(
                child:Text('Пробег по дням',
                  style:TextStyle(
                    fontSize:16*u,color:Colors.white,
                    fontWeight:FontWeight.w500,
                  )),
              ),
              IconButton(
                tooltip:'Выбрать дату',
                visualDensity:VisualDensity.compact,
                padding:EdgeInsets.zero,
                constraints:BoxConstraints(
                  minWidth:30*u,minHeight:28*u),
                onPressed:_mileagePickDay,
                icon:Icon(Icons.calendar_month_outlined,
                  size:19*u,
                  color:const Color(0xFFC9D4D8)),
              ),
            ]),
            SizedBox(height:2*u),
            Text(
              'Последние записи (всего за месяц: '
              '${_total==null?'—':_fmtInt(_total!.mileage)} км)',
              style:TextStyle(
                fontSize:11.5*u,
                color:const Color(0xFFA1A6A9),
              ),
            ),
            SizedBox(height:11*u),
            const Divider(height:1,thickness:.7,color:line),
            if(_total==null||_book==null)
              Padding(
                padding:EdgeInsets.symmetric(vertical:37*u),
                child:Center(
                  child:SizedBox(
                    width:22*u,height:22*u,
                    child:CircularProgressIndicator(
                      strokeWidth:2*u,
                      color:const Color(0xFFFFBF66),
                    ),
                  ),
                ),
              )
            else if(dates.isEmpty)
              Padding(
                padding:EdgeInsets.symmetric(vertical:31*u),
                child:Text(
                  'За этот месяц записей пробега пока нет.',
                  style:TextStyle(
                    fontSize:12*u,
                    color:const Color(0xFFBDC5CB),
                  ),
                ),
              )
            else
              for(var i=0;i<dates.length;i++)...[
                InkWell(
                  onTap:()=>_day(dates[i]),
                  child:SizedBox(
                    height:36*u,
                    child:Row(children:[
                      Expanded(
                        child:Text(
                          _detailDate(dates[i]),
                          style:TextStyle(
                            color:const Color(0xFFF2F3F5),
                            fontSize:13*u,
                          ),
                        ),
                      ),
                      Text(
                        '${_fmtInt(_dayValue(dates[i],'mileage')??0)} км',
                        style:TextStyle(
                          color:const Color(0xFFF2F3F5),
                          fontSize:13*u,
                        ),
                      ),
                      SizedBox(width:8*u),
                      Icon(Icons.chevron_right,
                        color:const Color(0xFFCCD4D8),
                        size:20*u),
                    ]),
                  ),
                ),
                if(i!=dates.length-1)
                  const Divider(height:1,thickness:.7,color:line),
              ],
          ],
        ),
      ),
    );
  }

  Widget _mileageHistoryButton(double u)=>Container(
    margin:EdgeInsets.symmetric(horizontal:15*u),
    decoration:BoxDecoration(
      border:Border.all(
        color:const Color(0xB16A919E),width:.7*u),
      borderRadius:BorderRadius.circular(12*u),
      color:const Color(0xC7102027),
      boxShadow:const [
        BoxShadow(color:Color(0x44000000),
          blurRadius:12,offset:Offset(0,4)),
      ],
    ),
    child:Material(
      color:Colors.transparent,
      child:InkWell(
        onTap:_mileageRouteHistory,
        borderRadius:BorderRadius.circular(12*u),
        child:SizedBox(
          height:45*u,
          child:Padding(
            padding:EdgeInsets.symmetric(horizontal:13*u),
            child:Row(children:[
              Icon(Icons.route_outlined,
                color:const Color(0xFF82DDF3),
                size:27*u),
              SizedBox(width:13*u),
              Expanded(
                child:Text('Открыть историю маршрутов',
                  style:TextStyle(
                    color:Colors.white,fontSize:12.5*u))),
              Icon(Icons.chevron_right,
                color:Colors.white,size:20*u),
            ]),
          ),
        ),
      ),
    ),
  );

  // Salary uses its own image and overlay; every other metric keeps the
  // existing backdrop and its original navigation.
  Widget _salaryScreen()=>Scaffold(
    backgroundColor:const Color(0xFF0A0E10),
    body:LayoutBuilder(builder:(context,box){
      // These are coordinates in the 747x1536 salary backdrop.
      // Match BoxFit.cover, including the horizontal crop on narrower phones.
      final scale=math.max(box.maxWidth/747.0,box.maxHeight/1536.0);
      final offsetX=(747*scale-box.maxWidth)/2;
      final safe=MediaQuery.paddingOf(context);
      final availableHeight=math.max(0.0,box.maxHeight-safe.top-safe.bottom);
      return Stack(children:[
        const Positioned.fill(child:Image(
          image:AssetImage('assets/images/salary_cab.png'),
          fit:BoxFit.cover,alignment:Alignment.topCenter,
        )),
        const Positioned.fill(child:IgnorePointer(child:DecoratedBox(
          decoration:BoxDecoration(gradient:LinearGradient(
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
            stops:[0,.12,.33,.53,1],
            colors:[Color(0x6504080A),Color(0x0804080A),
              Color(0x0004080A),Color(0x0504080A),Color(0x3504080A)],
          )),
        ))),
        SafeArea(child:SingleChildScrollView(
          key:const PageStorageKey('salary-screen'),
          controller:_scroll,
          child:ConstrainedBox(
            constraints:BoxConstraints(minHeight:availableHeight),
            child:IntrinsicHeight(child:Column(children:[
              _salaryHeader(),
              const SizedBox(height:63),
              const Expanded(child:SizedBox(height:165)),
              if(_error!=null)
                Padding(padding:const EdgeInsets.all(16),child:Column(children:[
                  _DetailGlass(child:_dt(_error!)),
                  _detailButton('Повторить',_load),
                ]))
              else if(_total==null||_book==null)
                const Padding(padding:EdgeInsets.all(40),
                  child:CircularProgressIndicator(color:_amber))
              else
                _salaryPanel(),
            ])),
          ),
        )),
        // The photographic month selector remains crisp; this foreground
        // supplies the current month and hit targets for the photo chevrons.
        Positioned(
          left:230*scale-offsetX,top:126*scale,
          width:294*scale,height:57*scale,
          child:_salaryMonthOverlay(),
        ),
        // The tablet is already in the photo: draw only its current amount.
        Positioned(
          left:545*scale-offsetX,top:349*scale,
          width:141*scale,height:39*scale,
          child:IgnorePointer(
            child:Transform(
              alignment:Alignment.centerLeft,
              transform:Matrix4.identity()
                ..setEntry(3,2,0.001)
                ..rotateZ(0.02)
                ..rotateY(-0.09),
              child:Align(
                alignment:Alignment.centerLeft,
                child:FittedBox(
                  fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
                  child:Text(_total==null?'—':'${_fmtInt(_total!.salary)} ₸',
                    maxLines:1,
                    style:TextStyle(
                      color:const Color(0xF0D4A35D),
                      fontSize:20*scale,fontWeight:FontWeight.w500,
                      letterSpacing:0.1,
                      shadows:const [
                        Shadow(color:Color(0x70000000),blurRadius:2,
                          offset:Offset(0,1)),
                      ],
                    )),
                ),
              ),
            ),
          ),
        ),
      ]);
    }),
  );

  Widget _salaryHeader()=>Padding(
    padding:const EdgeInsets.fromLTRB(9,4,9,0),
    child:Row(children:[
      SizedBox(width:48,child:IconButton(
        tooltip:'Назад',onPressed:()=>Navigator.maybePop(context),
        icon:const Icon(Icons.arrow_back_ios_new,color:_paper,size:20))),
      const Expanded(child:Text('Зарплата',textAlign:TextAlign.center,
        style:TextStyle(color:_paper,fontSize:16,fontWeight:FontWeight.w500))),
      SizedBox(width:48,child:PopupMenuButton<String>(
        tooltip:'Дополнительные действия',
        color:const Color(0xFF1C2226),
        icon:const Icon(Icons.more_horiz,color:_paper,size:21),
        onSelected:(value){
          if(value=='day')_pickDay();
          if(value=='stats')_salaryStatistics();
          if(value=='home')Navigator.of(context).popUntil((route)=>route.isFirst);
        },
        itemBuilder:(context)=>const [
          PopupMenuItem(value:'day',child:Text('Выбрать дату',style:TextStyle(color:_paper))),
          PopupMenuItem(value:'stats',child:Text('Показатели',style:TextStyle(color:_paper))),
          PopupMenuItem(value:'home',child:Text('На главную',style:TextStyle(color:_paper))),
        ],
      )),
    ]),
  );

  Widget _salaryMonthOverlay()=>Row(children:[
    Expanded(child:Semantics(
      button:true,label:'Предыдущий месяц',
      child:GestureDetector(behavior:HitTestBehavior.opaque,
        onTap:()=>_monthTo(-1),child:const SizedBox.expand()),
    )),
    Expanded(flex:4,child:Container(
      alignment:Alignment.center,
      // This hides the placeholder text printed in the reference image.
      decoration:BoxDecoration(
        color:const Color(0xFF1C1D1E),
        borderRadius:BorderRadius.circular(3),
      ),
      child:Text('${_garageMonths[_month.month-1]} ${_month.year}',
        maxLines:1,overflow:TextOverflow.ellipsis,
        textAlign:TextAlign.center,
        style:TextStyle(color:_paper,fontSize:25*math.min(
          MediaQuery.sizeOf(context).width/747.0,
          MediaQuery.sizeOf(context).height/1536.0,
        ),fontWeight:FontWeight.w400)),
    )),
    Expanded(child:Semantics(
      button:true,label:'Следующий месяц',
      child:GestureDetector(behavior:HitTestBehavior.opaque,
        onTap:()=>_monthTo(1),child:const SizedBox.expand()),
    )),
  ]);

  Widget _salaryPanel(){
    const line=Color(0x554F5557);
    const gold=Color(0xFFBA873C);
    final parts=const <(String,String)>[
      ('base_salary','Основной оклад'),
      ('weekend_pay','Выходные'),
      ('holiday_pay','Праздники'),
      ('paid_routes_pay','Платные рейсы'),
      ('city_pay','Городской вес'),
      ('region_pay','Районный вес'),
    ];
    final now=DateTime.now();
    final last=DateTime(_month.year,_month.month+1,0).day;
    final count=_month.year==now.year&&_month.month==now.month?now.day:last;
    final dates=[for(var day=count;day>=1;day--)
      DateTime(_month.year,_month.month,day)]
      .where((date)=>!_hideEmpty||_dayValue(date,'salary')!=null).toList();
    return Container(
      width:double.infinity,
      margin:const EdgeInsets.fromLTRB(8,0,8,4),
      padding:const EdgeInsets.fromLTRB(16,19,16,14),
      decoration:BoxDecoration(
        color:const Color(0xF21B1E20),
        border:Border.all(color:gold,width:1),
        borderRadius:BorderRadius.circular(16),
        boxShadow:const [BoxShadow(color:Color(0x70000000),blurRadius:26,offset:Offset(0,9))],
      ),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Состав зарплаты',style:TextStyle(
          color:_paper,fontSize:16,fontWeight:FontWeight.w500)),
        const SizedBox(height:9),
        for(final part in parts)...[
          Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[
            Expanded(child:Text(part.$2,style:const TextStyle(color:_paper,fontSize:12))),
            const SizedBox(width:12),
            Text(_salaryPart(part.$1),textAlign:TextAlign.right,
              style:const TextStyle(color:_paper,fontSize:12,fontWeight:FontWeight.w500)),
          ])),
          Divider(height:1,thickness:.6,color:part.$1=='region_pay'?gold:line),
        ],
        const SizedBox(height:14),
        IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Отработано',style:TextStyle(fontSize:11,color:Color(0xFFB4B6B8))),
            const SizedBox(height:4),
            Text(_salaryPart('hours',unit:'ч'),
              style:const TextStyle(color:_paper,fontSize:18)),
          ])),
          const VerticalDivider(thickness:1,color:Color(0x776B512F),width:26),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Норма',style:TextStyle(fontSize:11,color:Color(0xFFB4B6B8))),
            const SizedBox(height:4),
            Text(_salaryPart('norm_hours',unit:'ч'),
              style:const TextStyle(color:_paper,fontSize:18)),
          ])),
        ])),
        const SizedBox(height:20),
        Material(color:Colors.transparent,child:InkWell(
          key:const ValueKey('salary-show-days'),
          onTap:()=>setState(()=>_salaryDaysExpanded=!_salaryDaysExpanded),
          borderRadius:BorderRadius.circular(10),
          child:Ink(
            decoration:BoxDecoration(
              color:const Color(0x52101619),
              border:Border.all(color:gold),
              borderRadius:BorderRadius.circular(10)),
            child:Padding(padding:const EdgeInsets.symmetric(horizontal:13,vertical:12),
              child:Row(children:[
                Expanded(child:Text(_salaryDaysExpanded?'Скрыть дни':'Посмотреть по дням',
                  style:const TextStyle(color:_paper,fontSize:12))),
                Icon(_salaryDaysExpanded?Icons.keyboard_arrow_up:Icons.chevron_right,
                  color:_paper,size:19),
              ])),
          ),
        )),
        if(_salaryDaysExpanded)...[
          const SizedBox(height:16),
          Row(children:[
            const Expanded(child:Text('По дням',style:TextStyle(color:_paper,fontSize:16))),
            IconButton(tooltip:'Выбрать дату',onPressed:_pickDay,
              icon:const Icon(Icons.calendar_month_outlined,color:_amber)),
          ]),
          if(dates.isEmpty)
            const Padding(padding:EdgeInsets.symmetric(vertical:12),
              child:Text('За этот месяц записей пока нет.',
                style:TextStyle(color:Color(0xFFAFB8BE),fontSize:13)))
          else for(final date in dates)...[
            const Divider(height:1,thickness:.6,color:line),
            InkWell(onTap:()=>_day(date),child:Padding(
              padding:const EdgeInsets.symmetric(vertical:14),
              child:Row(children:[
                Expanded(child:Text(_detailDate(date),
                  style:TextStyle(fontSize:14,
                    color:date.weekday>=6?const Color(0xFFFFAA91):_paper))),
                Text(_dailyText(date),style:const TextStyle(color:_paper,fontSize:14)),
                const SizedBox(width:4),
                const Icon(Icons.chevron_right,color:_paper,size:19),
              ]),
            )),
          ],
        ],
        const SizedBox(height:10),
        Row(children:[
          Expanded(child:TextButton.icon(
            onPressed:_salaryExplain,
            style:TextButton.styleFrom(
              padding:EdgeInsets.zero,alignment:Alignment.centerLeft,
              foregroundColor:const Color(0xFFB7B9BC)),
            icon:const Icon(Icons.info_outline,size:19),
            label:const Text('Пример расчёта',style:TextStyle(fontSize:11)),
          )),
          TextButton(
            onPressed:_salaryStatistics,
            style:TextButton.styleFrom(
              foregroundColor:_amber,padding:EdgeInsets.zero),
            child:const Row(mainAxisSize:MainAxisSize.min,children:[
              Text('К показателям',style:TextStyle(fontSize:11)),
              SizedBox(width:3),Icon(Icons.chevron_right,size:20),
            ]),
          ),
        ]),
      ]),
    );
  }

  void _salaryStatistics()=>_openGarageSection(context,'Статистика','');

  void _salaryExplain()=>showDialog<void>(
    context:context,
    builder:(dialogContext)=>AlertDialog(
      backgroundColor:const Color(0xFF1C2226),
      title:const Text('О расчёте',style:TextStyle(color:_paper)),
      content:const Text(
        'Сумма складывается из основного оклада, выплат за выходные и праздники, '
        'платных рейсов и начислений за городской и районный вес. '
        'На экране показаны данные выбранного месяца.',
        style:TextStyle(color:_paper)),
      actions:[TextButton(
        onPressed:()=>Navigator.pop(dialogContext),
        child:const Text('Понятно',style:TextStyle(color:_amber)))],
    ),
  );

  List<Widget> _content(){
    final total=_total!;final entries=_entries;final metric=widget.metric;
    final value=switch(metric){'Город'=>'${_fmt1(total.city)} т','Район'=>'${_fmt1(total.region)} т','Газ'=>'${_fmt1(total.gas)} л',
      'Бензин'=>'${_fmt1(total.petrol)} л','Пробег'=>'${_fmtInt(total.mileage)} км',_=>'${_fmtInt(total.salary)} ₸'};
    final now=DateTime.now();final isCurrent=_month.year==now.year&&_month.month==now.month;
    final days=DateTime(_month.year,_month.month+1,0).day;
    final count=isCurrent?now.day:days;
    final dates=[for(var i=count;i>=1;i--)DateTime(_month.year,_month.month,i)];
    return [
      _SceneSpace(scene:_sceneFor(metric),controlsHeight:120),
      _SceneSummary(value:value,label:_fuel?'Получено за месяц':_weight?'Перевезено за месяц':metric=='Пробег'?'За выбранный месяц':'Начислено за месяц'),
      if(_weight)...[
        _QuickSegment(values:const ['По дням','По рейсам'],selected:_trips?'По рейсам':'По дням',onChanged:(v)=>setState(()=>_trips=v=='По рейсам')),
        Row(children:[Expanded(child:TextButton.icon(onPressed:_filter,icon:const Icon(Icons.filter_alt_outlined,size:17,color:_amber),
          label:Text(_direction??'Все направления',overflow:TextOverflow.ellipsis,style:const TextStyle(color:_amber,fontSize:13)))),
          IconButton(tooltip:_hideEmpty?'Показать пустые дни':'Скрыть пустые дни',onPressed:()=>setState(()=>_hideEmpty=!_hideEmpty),icon:Icon(_hideEmpty?Icons.visibility_off_outlined:Icons.visibility_outlined,size:20,color:_ice))]),
      ],
      if(_fuel||(_weight&&_trips))...[
        if(entries.isEmpty)_DetailGlass(child:_dt('За этот месяц записей пока нет.',color:const Color(0xFFB3C6D0)))
        else _DetailGlass(child:Column(children:_separated([for(final e in entries)_detailRow(_fuel?_detailDate(e.date):e.direction.isEmpty?'Направление не указано':e.direction,
          _fuel?'${_fmt1(e.amount)} л':'${_fmtInt(e.amount*1000)} кг',subtitle:_fuel?_detailTime(e.date):'${_detailDate(e.date)} · ${_detailTime(e.date)}',onTap:()=>_day(e.date))]))),
      ]else ...[
        Row(children:[Expanded(child:_dt('По дням',size:16,weight:FontWeight.w500)),IconButton(tooltip:'Выбрать дату',onPressed:_pickDay,icon:const Icon(Icons.calendar_month,color:_amber))]),
        _DetailGlass(child:Column(children:_separated([for(final d in dates)
          if(!_hideEmpty||(_weight?entries.any((e)=>ActivityBook.sameDay(e.date,d)):_dayValue(d,metric=='Зарплата'?'salary':'mileage')!=null))
            _detailRow(_detailDate(d),_weight?_weightDay(entries,d):_dailyText(d),onTap:()=>_day(d),
              color:d.weekday>=6?const Color(0xFFFFAA91):null)]))),
      ],
      const SizedBox(height:8),
      if(_fuel)_detailButton('Добавить заправку',()=>_testEditor(context,'fuel',initialType:metric),icon:Icons.add),
    ];
  }
  String _salaryPart(String key,{String unit='₸'}) {
    final value=(_prefs?.get('home_${_month.year}_${_month.month}_$key') as num?)?.toDouble();
    return value==null?'—':'${_fmtInt(value)} $unit';
  }
  String _weightDay(List<ActivityEntry> entries,DateTime d){final rows=entries.where((e)=>ActivityBook.sameDay(e.date,d));
    return rows.isEmpty?'—':'${_fmtInt(rows.fold<double>(0,(s,e)=>s+e.amount)*1000)} кг';}
  String _dailyText(DateTime d){final value=_dayValue(d,widget.metric=='Зарплата'?'salary':'mileage');
    return value==null?'—':'${_fmtInt(value)} ${widget.metric=='Зарплата'?'₸':'км'}';}
}

class _DayDetails extends StatefulWidget {
  final DateTime date;const _DayDetails({required this.date});
  @override
  State<_DayDetails> createState()=>_DayDetailsState();
}
class _DayDetailsState extends State<_DayDetails> {
  ActivityBook? _book;TestPreferences? _prefs;String? _error;
  @override
  void initState(){super.initState();_homeDataRevision.addListener(_load);_load();}
  @override
  void dispose(){_homeDataRevision.removeListener(_load);super.dispose();}
  Future<void> _load() async {
    try{final b=await ActivityRepository.load(widget.date);final p=await TestPreferences.getInstance();
      if(mounted)setState((){_book=b;_prefs=p;_error=null;});}
    catch(_){if(mounted)setState(()=>_error='Не удалось прочитать отчёт');}
  }
  String get _key=>'home_day_${widget.date.year}_${widget.date.month}_${widget.date.day}_';
  double? _number(String name)=>(_prefs?.get('$_key$name') as num?)?.toDouble();
  void _trip(ActivityEntry e)=>_editActivity(context,e);
  @override
  Widget build(BuildContext context)=>_DetailFrame(title:'${_detailDate(widget.date)} ${widget.date.year}',scene:_Scene.cab,action:IconButton(tooltip:'Действия со сменой',icon:const Icon(Icons.more_horiz,color:_amber),onPressed:()=>_dayActions(context,widget.date)),children:[
    if(_error!=null)...[_DetailGlass(child:_dt(_error!)),_detailButton('Повторить',_load)]
    else if(_book==null)const Center(child:CircularProgressIndicator(color:_amber))
    else ..._content(),
  ]);
  List<Widget> _content(){
    final rows=_book!.onDay(widget.date);final trips=rows.where((e)=>e.kind=='trip').toList();final fuel=rows.where((e)=>e.kind=='fuel').toList();
    final status=_prefs?.getString('${_key}status');final hours=_number('hours'),mileage=_number('mileage'),start=_number('odometer_start'),end=_number('odometer_end');
    return [
      Center(child:_dt(switch(status){'completed'=>'Смена завершена','open'=>'Смена открыта',_=>'Статус смены не записан'},color:_amber,size:14)),const SizedBox(height:10),
      _DetailGlass(accent:true,child:Column(children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        _dt(hours==null?'—':'${_fmt1(hours)} ч',size:20),const SizedBox(height:6),_dt('Отработано',size:14)])),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(mileage==null?'—':'${_fmtInt(mileage)} км',size:20),const SizedBox(height:6),_dt('Пробег за день',size:14)]))]),
        const Divider(height:18,color:Color(0xFF53616A)),_dt(start==null||end==null?'Одометр не записан':'Одометр  ${_fmtInt(start)} → ${_fmtInt(end)} км',size:15)])),
      _dt('Рейсы · ${trips.length}',size:15),const SizedBox(height:12),
      _DetailGlass(child:trips.isEmpty?_dt('Рейсы за этот день не записаны.',color:const Color(0xFFB3C6D0)):Column(children:_separated([
        for(var i=0;i<trips.length;i++)_detailRow('${(i+1).toString().padLeft(2,'0')}  ${trips[i].direction.isEmpty?'Без направления':trips[i].direction}',
          '${_fmtInt(trips[i].amount*1000)} кг',subtitle:trips[i].type,onTap:()=>_trip(trips[i]))]))),
      _DetailGlass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Топливо',size:15),const SizedBox(height:10),
        if(fuel.isEmpty)_dt('Заправок нет',size:13,color:const Color(0xFFB3C6D0))
        else ..._separated([for(final e in fuel)_detailRow(e.type,'${_fmt1(e.amount)} л',subtitle:_detailTime(e.date),onTap:()=>_editActivity(context,e))])])),
      _detailButton('GPS за день',()=>Navigator.push(context,_SceneRoute<void>(builder:(_)=>_DayGps(day:widget.date))),icon:Icons.route),
    ];
  }
}
