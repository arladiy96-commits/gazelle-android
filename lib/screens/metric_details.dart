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



// Барабанный механический одометр. Фото даёт металлическую окантовку,
// Painter рисует только сменяющиеся колёса внутри окна.
class _MileageDrumPainter extends CustomPainter {
  final String reading;
  const _MileageDrumPainter(this.reading);
  TextPainter _glyph(String text, double size, Color color, {bool bold = true}) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color,
            shadows: const [Shadow(color: Color(0xAF000000), blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 190, size.height / 74);
    final window = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 3, 188, 68), const Radius.circular(8));
    canvas.drawRRect(window, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF060403), Color(0xFF3A1B0C), Color(0xFF170A05)],
      ).createShader(const Rect.fromLTWH(0, 0, 190, 74)));
    canvas.save();
    canvas.clipRRect(window);

    final clean = reading.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = clean.isEmpty ? '------' :
        (clean.length > 6 ? clean.substring(clean.length - 6) : clean.padLeft(6, '0'));

    const left = 7.0;
    const slotWidth = 29.4;
    for (var i = 0; i < 6; i++) {
      final x = left + i * slotWidth;
      final isLast = i == 5;
      canvas.drawRect(Rect.fromLTWH(x, 4, slotWidth - 1.2, 66), Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: isLast
              ? const [Color(0xFF4B1606), Color(0xFF7C3010), Color(0xFF240A04)]
              : const [Color(0xFF201009), Color(0xFF663414), Color(0xFF281105)],
        ).createShader(Rect.fromLTWH(x, 0, slotWidth, 74)));
      canvas.drawLine(Offset(x + slotWidth - 1.4, 5),
          Offset(x + slotWidth - 1.4, 69),
          Paint()..color = const Color(0xAF050402)..strokeWidth = 1.7);
      final current = digits[i];
      if (current == '-') {
        final dash = _glyph('–', 32, const Color(0xFFFFC97B));
        dash.paint(canvas, Offset(x + (slotWidth - dash.width)/2, 17));
      } else {
        final n = int.parse(current);
        for (final pair in [
          (((n + 9) % 10).toString(), -25.0, const Color(0x668C683E)),
          (current, 13.0, const Color(0xFFFFD79A)),
          (((n + 1) % 10).toString(), 52.0, const Color(0x886C4622)),
        ]) {
          final glyph = _glyph(pair.$1, 38, pair.$3);
          glyph.paint(canvas, Offset(x + (slotWidth - glyph.width)/2, pair.$2));
        }
      }
    }

    canvas.drawRect(const Rect.fromLTWH(0, 0, 190, 74), Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        stops: [0, .16, .35, .73, .95, 1],
        colors: [
          Color(0xE5000000), Color(0x44000000), Color(0x00000000),
          Color(0x00000000), Color(0x66000000), Color(0xD9000000),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 190, 74)));
    canvas.drawLine(const Offset(4, 11), const Offset(185, 11),
        Paint()..color=const Color(0x55FFD18C)..strokeWidth=1.1);
    canvas.restore();
    canvas.drawRRect(window, Paint()
      ..style=PaintingStyle.stroke..strokeWidth=2
      ..color=const Color(0xAA49290E));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MileageDrumPainter old) => old.reading != reading;
}

// Геометрия строится только из сохранённых координат. Фоновая сетка
// декоративная, она НЕ является картой дорог или навигацией.
class _MileageRecordedTrackPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;
  const _MileageRecordedTrackPainter(this.points);

  @override
  void paint(Canvas canvas, Size s) {
    final grid = Paint()
      ..color = const Color(0x2D63808B)..strokeWidth = .7;
    for (var x = 0.0; x < s.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), grid);
    }
    for (var y = 0.0; y < s.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), grid);
    }
    final rows = points.where((p)=>p['lat'] is num && p['lng'] is num).toList();
    if (rows.isEmpty) return;
    final cosLat = math.max(.05, math.cos((rows.first['lat'] as num).toDouble() *
        math.pi / 180));
    final xs = [for (final p in rows) (p['lng'] as num).toDouble() * cosLat];
    final ys = [for (final p in rows) (p['lat'] as num).toDouble()];
    final minX=xs.reduce(math.min), maxX=xs.reduce(math.max);
    final minY=ys.reduce(math.min), maxY=ys.reduce(math.max);
    final dx=math.max(maxX-minX, .00012);
    final dy=math.max(maxY-minY, .00012);
    final scale=math.min((s.width-55)/dx,(s.height-48)/dy);
    Offset at(int i)=>Offset(
      s.width/2+((xs[i]-minX)-(maxX-minX)/2)*scale,
      s.height/2-((ys[i]-minY)-(maxY-minY)/2)*scale,
    );
    Path? path;
    final segments=<Path>[];
    for (var i=0; i<rows.length; i++) {
      if (path==null || rows[i]['segmentStart']==true) {
        if (path!=null) segments.add(path);
        path=Path()..moveTo(at(i).dx, at(i).dy);
      } else {
        path.lineTo(at(i).dx, at(i).dy);
      }
    }
    if (path!=null) segments.add(path);
    for (final p in segments) {
      canvas.drawPath(p, Paint()
        ..color=const Color(0x80FF8E25)
        ..style=PaintingStyle.stroke..strokeWidth=11
        ..strokeCap=StrokeCap.round
        ..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
      canvas.drawPath(p, Paint()
        ..color=const Color(0xFFFFAA49)
        ..style=PaintingStyle.stroke..strokeWidth=2.7
        ..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round);
    }
    final origin=at(0), end=at(rows.length-1);
    canvas.drawCircle(origin,7,Paint()..color=const Color(0xFF65D7F5));
    canvas.drawCircle(origin,3,Paint()..color=Colors.white);
    canvas.drawCircle(end,10,Paint()
      ..color=const Color(0x66FF9B21)
      ..maskFilter=const MaskFilter.blur(BlurStyle.normal,6));
    canvas.drawCircle(end,5,Paint()..color=const Color(0xFFFFBA60));
    canvas.drawCircle(end,2,Paint()..color=Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MileageRecordedTrackPainter old) =>
      old.points != points;
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
  List<Map<String,dynamic>> _gpsRoutes = <Map<String,dynamic>>[];
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
      final routes = <Map<String,dynamic>>[];
      double? odometer;
      if (widget.metric == 'Пробег') {
        final journal = await TestStore.load();
        odometer = _mileageMonthOdometer(journal, _month);
        for (final shift in journal.shifts) {
          final started = DateTime.tryParse(shift['start']?.toString() ?? '');
          if (started == null || started.year != _month.year ||
              started.month != _month.month) continue;
          final shiftId = shift['id']?.toString();
          if (shiftId == null) continue;
          final route = await GpsRouteStore.loadShift(shiftId);
          final points = <Map<String,dynamic>>[
            for (final p in (route['points'] as List? ?? const []))
              Map<String,dynamic>.from(p as Map)
          ];
          if (points.isNotEmpty) routes.add({
            'shiftId': shiftId, 'started': started, 'points': points,
            'km': (route['distanceKm'] as num?)?.toDouble() ?? 0.0
          });
        }
        routes.sort((a,b)=>
          (b['started'] as DateTime).compareTo(a['started'] as DateTime));
      }
      if(mounted&&id==_loadId)setState((){
        _total=total;_book=book;_prefs=prefs;
        _mileageOdometer=odometer;_gpsRoutes=routes;_error=null;
      });
    }catch(_){if(mounted&&id==_loadId)setState(()=>_error='Не удалось прочитать данные. Повторите попытку.');}
  }
  void _monthTo(int delta){setState((){_month=DateTime(_month.year,_month.month+delta);_book=null;_total=null;_mileageOdometer=null;_gpsRoutes=[];_direction=null;_salaryDaysExpanded=false;});if(_scroll.hasClients)_scroll.jumpTo(0);_load();}
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


  double? _mileageDayValue(DateTime day) {
    final manual = _dayValue(day, 'mileage');
    if (manual != null && manual > 0) return manual;
    final gps = _gpsRoutes.where((r)=>
      ActivityBook.sameDay(r['started'] as DateTime,day))
      .fold<double>(0.0,(sum,r)=>sum+(r['km'] as double));
    return gps > 0 ? gps : manual;
  }

  double get _mileageMonthValue {
    final manual = _total?.mileage ?? 0.0;
    final gpsOnly = _gpsRoutes.where((r) {
      final day = r['started'] as DateTime;
      return (_dayValue(day,'mileage') ?? 0.0) <= 0;
    }).fold<double>(0.0,(sum,r)=>sum+(r['km'] as double));
    return manual + gpsOnly;
  }

  void _mileageOpenRoute(Map<String,dynamic> route) {
    final points = route['points'] as List<Map<String,dynamic>>;
    final started = route['started'] as DateTime;
    final km = (route['km'] as double);
    Navigator.of(context).push<void>(_SceneRoute(builder: (_) => _DetailFrame(
      title:'GPS · ${_detailDate(started)}',
      scene:_Scene.cab,
      showHero:false,
      children:[
        const SizedBox(height:14),
        Container(height:215,
          decoration:BoxDecoration(
            color:const Color(0xE5102027),
            borderRadius:BorderRadius.circular(18),
            border:Border.all(color:const Color(0x885E929E)),
          ),
          child:ClipRRect(
            borderRadius:BorderRadius.circular(18),
            child:CustomPaint(
              painter:_MileageRecordedTrackPainter(points),
              child:const SizedBox.expand(),
            ),
          ),
        ),
        _DetailGlass(accent:true,child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            _dt('${_fmt1(km)} км • ${points.length} GPS-точек',
              color:_amber,size:17),
            const SizedBox(height:8),
            _dt('Начало записи: ${_detailTime(DateTime.tryParse(
              points.first['time']?.toString() ?? '') ?? started)}',size:13),
            _dt('Последняя точка: ${_detailTime(DateTime.tryParse(
              points.last['time']?.toString() ?? '') ?? started)}',size:13),
          ],
        )),
        const _DetailGlass(child:Text(
          'Линия построена из записанных координат. '
          'Сетка декоративная, это не карта дорог. '
          'При выключенном GPS или свёрнутом приложении '
          'часть маршрута может отсутствовать.',
          style:TextStyle(color:Color(0xFFBDC9CE),fontSize:13),
        )),
      ],
    )));
  }

  Future<void> _mileageRouteHistory() async {
    if (_gpsRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text(
          'GPS-маршрутов за выбранный месяц пока нет.',
        )),
      );
      return;
    }
    await Navigator.of(context).push<void>(_SceneRoute(builder: (_) =>
      _DetailFrame(
        title:'История маршрутов',
        scene:_Scene.cab,
        showHero:false,
        children:[
          const SizedBox(height:12),
          _DetailGlass(child:Column(children:_separated([
            for (final route in _gpsRoutes)
              _detailRow(
                '${_detailDate(route['started'] as DateTime)} · '
                '${_detailTime(route['started'] as DateTime)}',
                '${_fmt1(route['km'] as double)} км',
                subtitle:'${(route['points'] as List).length} GPS-точек',
                onTap:()=>_mileageOpenRoute(route),
              ),
          ]))),
        ],
      ),
    ));
  }

  Widget _mileageRouteMap(double u) {
    final latest=_gpsRoutes.isEmpty ? null : _gpsRoutes.first;
    final points= latest==null ? <Map<String,dynamic>>[] :
      latest['points'] as List<Map<String,dynamic>>;
    final started=latest?['started'] as DateTime?;
    final length=latest?['km'] as double? ?? 0.0;
    return Container(
      height:165*u,
      margin:EdgeInsets.fromLTRB(13*u,9*u,13*u,0),
      decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(17*u),
        border:Border.all(color:const Color(0x86618D9D),width:.75*u),
        color:const Color(0xC90A1921),
        boxShadow:const [
          BoxShadow(color:Color(0x99000000),blurRadius:14),
        ],
      ),
      child:ClipRRect(
        borderRadius:BorderRadius.circular(17*u),
        child:Stack(children:[
          Positioned.fill(child:CustomPaint(
            painter:_MileageRecordedTrackPainter(points))),
          Positioned(top:10*u,left:12*u,right:12*u,child:Row(children:[
            Icon(Icons.route,color:const Color(0xFFFFB45B),size:18*u),
            SizedBox(width:7*u),
            Expanded(child:Text('Маршрут смены',
              style:TextStyle(color:Colors.white,fontSize:15*u,
                fontWeight:FontWeight.w600))),
            Icon(Icons.gps_fixed,color:points.isNotEmpty?
              const Color(0xFF69D7F2):const Color(0xFF8797A0),size:13*u),
            SizedBox(width:5*u),
            Text(points.isNotEmpty?'GPS · запись':'GPS · ожидание',
              style:TextStyle(color:const Color(0xFFB9D5E0),fontSize:10*u)),
          ])),
          if(points.isEmpty)
            Center(child:Padding(
              padding:EdgeInsets.symmetric(horizontal:20*u),
              child:Text('Нет записанных GPS-точек.\n'
                'Открой смену и разреши доступ к геолокации.',
                textAlign:TextAlign.center,
                style:TextStyle(fontSize:12*u,height:1.4,
                  color:const Color(0xFFD3DFE2)),
              ),
            )),
          Positioned(left:10*u,right:10*u,bottom:9*u,child:Material(
            color:const Color(0xD809151B),
            borderRadius:BorderRadius.circular(11*u),
            child:InkWell(
              onTap:_mileageRouteHistory,
              borderRadius:BorderRadius.circular(11*u),
              child:Padding(
                padding:EdgeInsets.symmetric(horizontal:12*u,vertical:8*u),
                child:Row(children:[
                  Expanded(child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children:[
                      Text(started==null?'История маршрутов':
                        '${_detailDate(started)} · ${_fmt1(length)} км',
                        style:TextStyle(color:Colors.white,
                          fontSize:12*u,fontWeight:FontWeight.w600)),
                      Text('Реальные координаты · схема без карты дорог',
                        style:TextStyle(color:const Color(0xFF9AB8C5),
                          fontSize:9*u)),
                    ],
                  )),
                  Icon(Icons.chevron_right,color:const Color(0xFFFFC57A),
                    size:19*u),
                ]),
              ),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _mileagePhoto(double u) => LayoutBuilder(builder:(context,box) {
    final r=box.maxWidth/864.0;
    final current=_mileageOdometer==null?'':_mileageOdometer!.round().toString();
    return SizedBox(
      width:box.maxWidth,
      height:554*r,
      child:Stack(children:[
        Positioned.fill(child:Image.asset(
          'assets/images/scenes/mileage_reference_instruments.png',
          fit:BoxFit.fill,filterQuality:FilterQuality.high,
        )),
        // Только внутреннее окно барабанов; металл и циферблаты из фото.
        Positioned(
          left:294*r, top:364*r, width:188*r,height:73*r,
          child:IgnorePointer(child:CustomPaint(
            painter:_MileageDrumPainter(current))),
        ),
        // Фото содержит старое число: перекрываем ТОЛЬКО область цифр.
        Positioned(
          left:625*r,top:244*r,width:171*r,height:65*r,
          child:IgnorePointer(child:ClipRRect(
            borderRadius:BorderRadius.circular(6*r),
            child:Container(
              decoration:const BoxDecoration(
                gradient:LinearGradient(
                  begin:Alignment.topLeft,end:Alignment.bottomRight,
                  colors:[Color(0xFF251F19),Color(0xFF121D21),
                    Color(0xFF132229)],
                ),
              ),
              child:Center(child:FittedBox(fit:BoxFit.scaleDown,
                child:Row(mainAxisSize:MainAxisSize.min,
                  crossAxisAlignment:CrossAxisAlignment.end,children:[
                  Text(_total==null?'—':_fmtInt(_mileageMonthValue),
                    style:TextStyle(
                      fontSize:50*r,color:const Color(0xFFF5E9D6),
                      fontWeight:FontWeight.w700,
                      shadows:const [
                        Shadow(color:Color(0xFF000000),
                          blurRadius:3,offset:Offset(1,2))
                      ])),
                  SizedBox(width:4*r),
                  Padding(
                    padding:EdgeInsets.only(bottom:8*r),
                    child:Text('км',style:TextStyle(
                      fontSize:18*r,color:const Color(0xFFBDD1D7),
                      fontWeight:FontWeight.w500))),
                ]))),
              ),
            ),
          )),
      ]),
    );
  });


  Widget _mileageScreen()=>Scaffold(
    backgroundColor:const Color(0xFF080D11),
    body:LayoutBuilder(builder:(context,box) {
      final u=box.maxWidth/354.5;
      return Stack(children:[
        const Positioned.fill(child:Image(
          image:AssetImage('assets/images/scenes/mileage.png'),
          fit:BoxFit.cover,alignment:Alignment.topCenter,
          filterQuality:FilterQuality.high,
        )),
        const Positioned.fill(child:IgnorePointer(child:DecoratedBox(
          decoration:BoxDecoration(gradient:LinearGradient(
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
            colors:[Color(0x33000000),Color(0x22000000),
              Color(0xC80A0E12),Color(0xEA080D11)],
            stops:[0,.29,.82,1],
          )),
        ))),
        SafeArea(child:ListView(
          key:const PageStorageKey('mileage-with-real-gps'),
          controller:_scroll,
          physics:const ClampingScrollPhysics(),
          padding:EdgeInsets.only(bottom:20*u),
          children:[
            _mileageHeader(u),
            SizedBox(height:7*u),
            Center(child:_mileageMonthSelector(u)),
            _mileageRouteMap(u),
            SizedBox(height:5*u),
            _mileagePhoto(u),
            SizedBox(height:8*u),
            if(_error!=null)
              Padding(padding:EdgeInsets.symmetric(horizontal:15*u),
                child:Column(children:[
                  _DetailGlass(child:_dt(_error!)),
                  _detailButton('Повторить',_load),
                ]))
            else
              _mileageDaysPanel(u),
            SizedBox(height:9*u),
            _mileageHistoryButton(u),
            SizedBox(height:12*u),
            Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              Icon(Icons.info_outline,size:14*u,
                color:const Color(0xFFA6B1B8)),
              SizedBox(width:8*u),
              Text('Данные из журнала и GPS',
                style:TextStyle(color:const Color(0xFFA6B1B8),
                  fontSize:11*u)),
            ]),
            SizedBox(height:16*u),
            Align(alignment:Alignment.centerLeft,child:TextButton.icon(
              onPressed:()=>_openGarageSection(context,'Статистика',''),
              icon:Icon(Icons.chevron_left,
                color:const Color(0xFFABB7C1),size:19*u),
              label:Text('К показателям',style:TextStyle(
                color:const Color(0xFFABB7C1),fontSize:13*u)),
            )),
          ],
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
    ].where((day)=>_mileageDayValue(day)!=null).take(4).toList();

    const line=Color(0x6650575A);
    return Container(
      width:double.infinity,
      constraints:BoxConstraints(minHeight:184*u),
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
              '${_total==null?'—':_fmtInt(_mileageMonthValue)} км)',
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
                        '${_fmtInt(_mileageDayValue(dates[i])??0)} км',
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
