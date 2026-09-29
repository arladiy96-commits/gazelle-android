part of 'app_shell.dart';

// Approved composition, bound to the isolated miniapp-compatible shift journal.
class _WorkViewData {
  final int mileage, startOdometer, currentOdometer, trips;
  final double cityTonnage, regionTonnage;
  final String elapsed, started;
  final bool open,paused;
  const _WorkViewData({this.mileage=0,this.startOdometer=0,this.currentOdometer=0,this.trips=0,this.cityTonnage=0,this.regionTonnage=0,this.elapsed='00:00:00',this.started='—',this.open=false,this.paused=false});
}

class WorkPage extends StatelessWidget {
  final AppSession session;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onQuickAdd;
  final bool showNavigation;
  const WorkPage({super.key,required this.session,this.onNavigate,this.onQuickAdd,
    this.showNavigation=true});

  @override Widget build(BuildContext context)=>_MillWorkScreen(
    session:session,onNavigate:onNavigate,onQuickAdd:onQuickAdd,
    showNavigation:showNavigation);
}

class _WorkPanel extends StatelessWidget {
  final Widget child;
  const _WorkPanel({required this.child});
  @override
  Widget build(BuildContext context)=>Container(decoration:BoxDecoration(
    borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0x99778C98)),
    gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[Color(0xCF0B1C25),Color(0xA6040D14)])),
    child:ClipRRect(borderRadius:BorderRadius.circular(22),child:child));
}

class _WorkStatus extends StatelessWidget {
  final _WorkViewData data;final VoidCallback onPause;
  const _WorkStatus({required this.data,required this.onPause});
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.only(left:20,right:2),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(36),
      color:const Color(0xC000151E),border:Border.all(color:_ice,width:1.5),
      boxShadow:const[BoxShadow(color:Color(0x221AE4F2),blurRadius:18)]),
    child:Row(children:[Container(width:19,height:19,decoration:const BoxDecoration(
      color:Color(0xFF00E69C),shape:BoxShape.circle,boxShadow:[BoxShadow(color:Color(0x4400E69C),blurRadius:18)])),
      const SizedBox(width:20),_garageText(!data.open?'Смена закрыта':data.paused?'GPS на паузе':'Смена открыта',26,color:_ice,weight:FontWeight.w600),
      const Spacer(),_divider(),const Spacer(),_garageText(data.elapsed,29,color:_ice,weight:FontWeight.w600),
      const Spacer(),_divider(),const Spacer(),_garageText('Начало ',24,color:_ice),_garageText(data.started,25),
      const Spacer(),_GarageTap(label:'Пауза смены',onTap:onPause,child:Container(width:68,height:68,
        decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xFF04141E),
          border:Border.all(color:_ice,width:2.5),boxShadow:const[BoxShadow(color:Color(0x6615DDE8),blurRadius:15)]),
        child:Icon(data.paused||!data.open?Icons.play_arrow_rounded:Icons.pause_rounded,color:_ice,size:42)))]));
  Widget _divider()=>Container(width:1,height:28,color:const Color(0xAA39CDD4));
}

class _WorkMetric extends StatelessWidget {
  final String kind,title,value;final Color color;
  const _WorkMetric({required this.kind,required this.title,required this.value,required this.color});
  @override
  Widget build(BuildContext context)=>_WorkPanel(child:Padding(padding:const EdgeInsets.all(12),
    child:Row(children:[Container(width:87,height:87,decoration:BoxDecoration(shape:BoxShape.circle,
      color:const Color(0x66060E14),border:Border.all(color:color.withValues(alpha:.4),width:1.4)),
      child:Center(child:_GarageIcon(kind,color:color,size:48))),const SizedBox(width:16),
      Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,
        children:[_garageText(title,23,color:const Color(0xFFCAD1DA)),const SizedBox(height:5),
          FittedBox(fit:BoxFit.scaleDown,child:_garageText(value,34,weight:FontWeight.w600))]))])));
}

class _WorkMap extends StatelessWidget {
  final VoidCallback onNavigate;const _WorkMap({required this.onNavigate});
  @override
  Widget build(BuildContext context)=>_WorkPanel(child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(20,15,20,13),child:Row(children:[
      _garageText('Маршрут смены',26,weight:FontWeight.w600),const Spacer(),
      const Icon(Icons.gps_fixed,color:_ice,size:25),const SizedBox(width:8),
      _garageText('GPS · демо',23,color:_ice)])),
    Expanded(child:Stack(children:[
      const Positioned.fill(child:CustomPaint(painter:_WorkMapPainter())),
      Positioned(left:15,right:15,bottom:9,child:Container(height:93,
        padding:const EdgeInsets.symmetric(horizontal:18),decoration:BoxDecoration(
          color:const Color(0xEE05141E),borderRadius:BorderRadius.circular(20),
          border:Border.all(color:const Color(0x66577987))),
        child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
          mainAxisAlignment:MainAxisAlignment.center,children:[
            _garageText('Схема маршрута · демо',27,weight:FontWeight.w600),const SizedBox(height:8),
            _garageText('Управление пробегом и сменой',23,color:const Color(0xFFB5CDD9))])),
          _GarageTap(label:'Навигация по маршруту смены',onTap:onNavigate,
            child:Container(width:72,height:72,decoration:BoxDecoration(shape:BoxShape.circle,
              color:const Color(0xCC061117),border:Border.all(color:_amber,width:2),
              boxShadow:const[BoxShadow(color:Color(0x44FFAD2B),blurRadius:14)]),
              child:const Center(child:_GarageIcon('navigationOutline',color:_amber,size:39))))]))),
    ]))]));
}

// Offline illustrative map, explicitly labelled demo. This is not a GPS route
// or a geographical source. The map surface can later host the real map widget.
class _WorkMapPainter extends CustomPainter {
  const _WorkMapPainter();
  @override
  void paint(Canvas c,Size size){
    c.save();c.clipRect(Offset.zero&size);c.scale(size.width/786,size.height/371);
    c.drawRect(const Rect.fromLTWH(0,0,786,371),Paint()..color=const Color(0xFF102734));
    final random=math.Random(19);
    for(var i=0;i<115;i++){
      final x=random.nextDouble()*800;final y=random.nextDouble()*390;
      final radius=12+random.nextDouble()*56;
      final path=Path();
      for(var j=0;j<11;j++){
        final a=j*math.pi*2/11;final r=radius*(.45+random.nextDouble()*.55);
        final p=Offset(x+math.cos(a)*r,y+math.sin(a)*r);
        if(j==0){path.moveTo(p.dx,p.dy);}else{path.lineTo(p.dx,p.dy);}
      }
      path.close();c.drawPath(path,Paint()..color=[const Color(0xFF183B3B),
        const Color(0xFF1C3D38),const Color(0xFF234440),const Color(0xFF173039)][i%4]);
    }
    final river=Path()..moveTo(470,-30)..cubicTo(380,25,468,54,423,87)
      ..cubicTo(360,134,484,165,452,206)..cubicTo(423,259,569,284,605,410);
    c.drawPath(river,Paint()..color=const Color(0xFF204D6D)..style=PaintingStyle.stroke..strokeWidth=52);
    void road(Path path,{double width=1.2,Color color=const Color(0xFF8B743A)}){
      c.drawPath(path,Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=width);
    }
    road(Path()..moveTo(-20,132)..lineTo(115,53)..lineTo(236,-10),width:3);
    road(Path()..moveTo(50,-10)..lineTo(111,56)..lineTo(170,127)..lineTo(229,204)
      ..lineTo(284,228)..lineTo(290,318)..lineTo(345,390),width:2.6);
    road(Path()..moveTo(326,-10)..lineTo(357,59)..lineTo(345,120)..lineTo(319,175)..lineTo(294,215),width:2);
    road(Path()..moveTo(608,-10)..lineTo(639,43)..lineTo(624,69)..lineTo(672,107)..lineTo(733,78)..lineTo(800,94),width:2);
    for(var i=0;i<35;i++){
      final x=40+random.nextDouble()*730;final y=random.nextDouble()*320;
      road(Path()..moveTo(x-95,y-25)..lineTo(x-25,y)..lineTo(x,y+38)..lineTo(x+65,y+52),
        width:.7,color:const Color(0xFF5E6040));
    }
    // Small street grid surrounding the illustrative city marker.
    for(var i=0;i<9;i++){
      road(Path()..moveTo(56+i*13.0,16)..lineTo(78+i*13.0,117),width:.9,color:const Color(0xFF657B7E));
      road(Path()..moveTo(41,28+i*9.0)..lineTo(172,36+i*9.0),width:.8,color:const Color(0xFF657B7E));
    }
    final route=Path()..moveTo(146,151)..lineTo(170,168)..lineTo(214,181)
      ..quadraticBezierTo(230,164,244,174)..lineTo(284,184)..lineTo(310,186)
      ..cubicTo(335,188,315,225,352,218)..cubicTo(412,209,386,163,432,175)
      ..lineTo(479,158)..lineTo(525,160)..quadraticBezierTo(563,165,562,135)
      ..cubicTo(558,90,607,102,637,96)..lineTo(674,77);
    c.drawPath(route,Paint()..color=const Color(0x8822DFF6)..style=PaintingStyle.stroke
      ..strokeWidth=10..maskFilter=const MaskFilter.blur(BlurStyle.normal,7));
    c.drawPath(route,Paint()..color=_ice..style=PaintingStyle.stroke..strokeWidth=4..strokeJoin=StrokeJoin.round);
    c.drawCircle(const Offset(146,151),25,Paint()..color=const Color(0x7752BEFF)..maskFilter=const MaskFilter.blur(BlurStyle.normal,9));
    c.drawCircle(const Offset(146,151),19,Paint()..color=const Color(0xFF118FF2));
    c.drawCircle(const Offset(146,151),19,Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);
    c.drawPath(Path()..moveTo(146,139)..lineTo(137,161)..lineTo(146,155)..lineTo(155,161)..close(),Paint()..color=Colors.white);
    c.drawCircle(const Offset(562,120),6,Paint()..color=Colors.white);
    c.drawCircle(const Offset(674,72),22,Paint()..color=const Color(0x99FF9700)..maskFilter=const MaskFilter.blur(BlurStyle.normal,12));
    final pin=Path()..moveTo(674,92)..cubicTo(653,70,659,57,674,57)
      ..cubicTo(689,57,695,70,674,92)..close();
    c.drawPath(pin,Paint()..color=_amber);c.drawPath(pin,Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);
    c.drawCircle(const Offset(674,70),5,Paint()..color=Colors.white);
    void label(String text,double x,double y,{double font=22,Color color=_paper}){
      final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(fontFamily:'Roboto',fontSize:font,color:color,
        shadows:const[Shadow(color:Colors.black,blurRadius:4)])),textDirection:TextDirection.ltr)..layout();
      tp.paint(c,Offset(x,y));
    }
    label('Петропавловск',65,97);label('Бишкуль',651,108);
    void highway(double x,double y){c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,37,23),const Radius.circular(3)),
      Paint()..color=const Color(0xFF2B5B9D));label('А-1',x+6,y+2,font:16);}
    highway(239,25);highway(353,239);
    c.restore();
  }
  @override
  bool shouldRepaint(_WorkMapPainter old)=>false;
}

class _WorkFuel extends StatelessWidget {
  final VoidCallback onAdd;final List<Map<String,dynamic>> rows;
  const _WorkFuel({required this.onAdd,required this.rows});
  @override Widget build(BuildContext context){double litres(String type)=>rows.where((e)=>e['kind']=='fuel'&&e['type']==type).fold<double>(0,(v,e)=>v+(e['amount'] as num).toDouble());
    return _WorkPanel(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[_garageText('Заправки за смену',27),const Spacer(),_GarageTap(label:'Добавить топливо',onTap:onAdd,child:const Icon(Icons.add_circle_outline,color:_ice,size:38))]),
      const SizedBox(height:20),_garageText('Газ     ${_fmt1(litres('Газ'))} л',30,color:_ice),const SizedBox(height:16),_garageText('Бензин     ${_fmt1(litres('Бензин'))} л',30,color:_amber)])));}
}
class _WorkEvents extends StatelessWidget {
  final List<Map<String,dynamic>> rows;final VoidCallback onOpen;
  const _WorkEvents({required this.rows,required this.onOpen});
  @override Widget build(BuildContext context)=>_GarageTap(label:'Записи смены: изменить или удалить',onTap:onOpen,child:_WorkPanel(child:Padding(padding:const EdgeInsets.all(18),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_garageText('Записи смены · подробнее ›',27),const SizedBox(height:14),
      if(rows.isEmpty)_garageText('Записей пока нет',24),
      for(final e in rows.reversed.take(3))Padding(padding:const EdgeInsets.only(bottom:9),child:_garageText('${_detailTime(DateTime.parse(e['date'] as String))}   ${_testKind(e['kind'] as String)} · ${e['direction']??e['type']??''}',23))]))));
}

class _WorkNavigation extends StatelessWidget {
  final VoidCallback onHome,onAdd,onInvoices,onMore;
  const _WorkNavigation({required this.onHome,required this.onAdd,required this.onInvoices,required this.onMore});
  @override
  Widget build(BuildContext context){
    final items=[('homeOutline','Главная',onHome),('truck','Работа',(){}),('plus','Добавить',onAdd),
      ('chart','Статистика',onInvoices),('gridOutline','Ещё',onMore)];
    return Stack(clipBehavior:Clip.none,children:[
      Positioned(left:0,right:0,top:20,bottom:0,child:Container(decoration:const BoxDecoration(
        color:Color(0xD3030A0F),border:Border(top:BorderSide(color:Color(0x99788B95)))),
        child:Row(children:[for(var i=0;i<5;i++)Expanded(child:_GarageTap(label:items[i].$2,onTap:items[i].$3,
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            SizedBox(height:50,child:i==2?null:_GarageIcon(items[i].$1,color:i==1?_amber:_paper,size:45)),
            const SizedBox(height:14),_garageText(items[i].$2,22,color:i==1?_amber:_paper)])))]))),
      Positioned(left:372,top:0,width:96,height:96,child:_GarageTap(label:'Добавить',onTap:onAdd,
        child:Container(decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xFF040D14),
          border:Border.all(color:_amber,width:2),boxShadow:const[BoxShadow(color:Color(0x66FFB33F),blurRadius:18)]),
          child:const Center(child:_GarageIcon('plus',size:43))))),
      Positioned(left:214,bottom:7,width:74,height:2,child:Container(decoration:const BoxDecoration(color:_amber,
        boxShadow:[BoxShadow(color:Color(0xFFFFA32E),blurRadius:9,spreadRadius:2)])))
    ]);
  }
}

class _MillWorkScreen extends StatelessWidget {
  final AppSession session;final ValueChanged<int>? onNavigate;final VoidCallback? onQuickAdd;final bool showNavigation;
  const _MillWorkScreen({required this.session,this.onNavigate,this.onQuickAdd,this.showNavigation=true});
  static const gold=Color(0xFFFFC46A),cyan=Color(0xFF53CDEB);
  void go(BuildContext c,int i){if(onNavigate!=null){onNavigate!(i);}else{_CinematicMore(session:session).navigate(c,i);}}
  Future<void> note(BuildContext c,Map<String,dynamic>? shift,List<Map<String,dynamic>> rows) async {
    if(shift==null){await _showShiftForm(c);return;}
    final existing=rows.where((r)=>r['workNote']==true).firstOrNull;
    final controller=TextEditingController(text:existing?['note']?.toString()??'');
    final text=await showDialog<String>(context:c,builder:(dialog)=>AlertDialog(backgroundColor:const Color(0xFF111B22),
      title:const Text('Примечание к смене',style:TextStyle(color:Colors.white)),
      content:TextField(controller:controller,maxLines:4,autofocus:true,style:const TextStyle(color:Colors.white)),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Отмена')),
        TextButton(onPressed:()=>Navigator.pop(dialog,controller.text.trim()),child:const Text('Сохранить'))]));
    controller.dispose();if(text==null||!c.mounted)return;
    await _testRun(c,()async{if(text.isEmpty){if(existing!=null)await TestStore.deleteRecord(existing['id'] as String);return;}
      await TestStore.saveRecord({...?existing,'kind':'other','shiftId':shift['id'],'amount':0.0,'workNote':true,'note':text,
        'date':existing?['date']??DateTime.now().toIso8601String()});});
  }
  void history(BuildContext c)=>Navigator.push(c,_SceneRoute<void>(builder:(_)=>Scaffold(backgroundColor:const Color(0xFF0B151D),
    appBar:AppBar(title:const Text('История маршрута'),backgroundColor:const Color(0xFF101D25)),body:_TestLive(builder:(b){
      final shifts=[...b.shifts]..sort((a,b)=>(b['start'] as String).compareTo(a['start'] as String));
      return ListView(children:[if(shifts.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('Маршрутов пока нет',style:TextStyle(color:Colors.white70))),
        for(final s in shifts)ListTile(title:Text(_detailDate(DateTime.parse(s['start'] as String)),style:const TextStyle(color:Colors.white)),
          subtitle:Text('GPS: ${_fmt1((s['gpsKm'] as num?)?.toDouble()??0)} км',style:const TextStyle(color:gold)),
          trailing:const Icon(Icons.chevron_right,color:gold),onTap:()=>Navigator.push(c,_SceneRoute<void>(builder:(_)=>Scaffold(
            appBar:AppBar(title:Text('Маршрут · ${_detailDate(DateTime.parse(s['start'] as String))}')),
            body:SafeArea(child:ShiftRouteMap(shiftId:s['id'] as String,paused:s['gpsStatus']=='paused')))))),
      ]);
    }))));
  Widget text(String value,double size,{Color color=Colors.white})=>Text(value,style:TextStyle(color:color,fontSize:size,height:1.16),maxLines:2,overflow:TextOverflow.ellipsis);
  @override Widget build(BuildContext context)=>_TestLive(builder:(b){
    final shift=b.active;final rows=shift==null?<Map<String,dynamic>>[]:b.forShift(shift['id'] as String);
    double sum(String kind,[String? type])=>rows.where((r)=>r['kind']==kind&&(type==null||r['type']==type)).fold<double>(0,(s,r)=>s+((r['amount'] as num?)?.toDouble()??0));
    final trips=rows.where((r)=>r['kind']=='trip').toList()..sort((a,b)=>(a['date'] as String).compareTo(b['date'] as String));
    final elapsed=shift==null?0:math.max(0,(b.elapsed(shift)*3600).round());
    final clock='${(elapsed~/3600).toString().padLeft(2,'0')}:${(elapsed~/60%60).toString().padLeft(2,'0')}:${(elapsed%60).toString().padLeft(2,'0')}';
    final noteRow=rows.where((r)=>r['workNote']==true).firstOrNull;
    final km=shift==null?0.0:shift['odometerSet']==true?b.mileage(shift):(shift['gpsKm'] as num?)?.toDouble()??0;
    final destination=trips.isEmpty?'':trips.last['direction']?.toString()??'';
    return LayoutBuilder(builder:(context,box){final scale=box.maxWidth/864;
      Widget at(double x,double y,double w,double h,Widget child)=>Positioned(left:x,top:y,width:w,height:h,child:child);
      final items=< (String,String,IconData,Color,List<double>,VoidCallback)>[
        ('Тоннаж\nза смену','${_fmt1(sum('trip'))} кг',Icons.grass,gold,trips.map((r)=>(r['amount'] as num).toDouble()).toList(),()=>_testOpen(context,page:'Рейсы',shiftId:shift?['id'] as String?)),
        ('Пробег\nза смену','${_fmt1(km)} км',Icons.speed_outlined,gold,[km],()=>_openMetricDetails(context,'Пробег',DateTime.now())),
        ('Рейсы\nза смену','${trips.length}',Icons.local_shipping_outlined,gold,List.filled(trips.length,1.0),()=>_testOpen(context,page:'Рейсы',shiftId:shift?['id'] as String?)),
        ('Газ\nза смену','${_fmt1(sum('fuel','Газ'))} л',Icons.local_fire_department,gold,rows.where((r)=>r['kind']=='fuel'&&r['type']=='Газ').map((r)=>(r['amount'] as num).toDouble()).toList(),()=>_testEditor(context,'fuel',initialType:'Газ')),
        ('Бензин\nза смену','${_fmt1(sum('fuel','Бензин'))} л',Icons.local_gas_station_outlined,gold,rows.where((r)=>r['kind']=='fuel'&&r['type']=='Бензин').map((r)=>(r['amount'] as num).toDouble()).toList(),()=>_testEditor(context,'fuel',initialType:'Бензин')),
        ('Время смены',clock,Icons.access_time_outlined,gold,const [],()=>_testOpen(context,shiftId:shift?['id'] as String?)),
      ];
      final scene=SizedBox(width:864,height:1330,child:Stack(children:[
        Positioned(top:0,left:0,right:0,child:Image.asset('assets/images/scenes/work_dashboard.png',fit:BoxFit.fitWidth)),
        at(40,35,75,75,IconButton(tooltip:'Главная',onPressed:()=>go(context,0),icon:const Icon(Icons.arrow_back,color:gold,size:43))),
        at(288,30,420,70,Row(children:[const Icon(Icons.local_shipping_outlined,color:gold,size:48),const SizedBox(width:30),text('Работа',45)])),
        at(287,99,460,38,text(shift==null?'Смена закрыта':'Сводка за текущую смену',25,color:const Color(0xFFCBD0D4))),
        at(73,182,721,302,ClipPath(clipper:_MillMapClip(),child:Transform(
          alignment:Alignment.center,transform:Matrix4.identity()..setEntry(3,1,.000045)..rotateX(-.04),
          child:ShiftRouteMap(key:ValueKey(shift?['id']),shiftId:shift?['id'] as String?,paused:shift?['gpsStatus']=='paused',unit:2)))),
        at(94,400,520,52,IgnorePointer(child:Align(alignment:Alignment.centerLeft,child:Container(
          padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),decoration:BoxDecoration(color:const Color(0xCF07151D),borderRadius:BorderRadius.circular(12)),
          child:text(destination.isEmpty?'GPS · пройденный маршрут':'Направление: $destination',19,color:gold))))),
        for(var i=0;i<6;i++)at(62+(i%3)*263,797+(i~/3)*171,218,133,
          _GarageTap(label:items[i].$1,onTap:items[i].$6,child:Column(children:[
            Expanded(child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(items[i].$3,color:items[i].$4,size:49),const SizedBox(width:13),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[text(items[i].$1,21,color:const Color(0xFFD1D6D8)),const SizedBox(height:7),
                FittedBox(fit:BoxFit.scaleDown,child:text(items[i].$2,i==5?29:32))]))])),
            SizedBox(height:27,width:double.infinity,child:CustomPaint(painter:_MillBars(items[i].$5,i==1||i==3?cyan:gold))),
          ]))),
        at(67,1138,728,63,_GarageTap(label:'Примечание к смене',onTap:()=>note(context,shift,rows),child:Row(children:[
          const Icon(Icons.edit_note,color:gold,size:49),const SizedBox(width:24),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
            text('Примечание',21,color:const Color(0xFFCBD0D4)),const SizedBox(height:5),text(noteRow?['note']?.toString()??'Добавить примечание',23)])),
          const Icon(Icons.edit_outlined,color:Colors.white70,size:32)]))),
        at(66,1240,730,55,_GarageTap(label:'История маршрута',onTap:()=>history(context),child:Row(children:[
          const Icon(Icons.map_outlined,color:gold,size:48),const SizedBox(width:28),Expanded(child:text('История маршрута',26)),const Icon(Icons.chevron_right,color:Colors.white,size:43)]))),
      ]));
      return Stack(children:[
        const Positioned.fill(child:ColoredBox(color:Color(0xFF071017))),
        Positioned(top:0,left:0,right:0,child:Image.asset('assets/images/scenes/work_dashboard.png',fit:BoxFit.fitWidth)),
        Column(children:[Expanded(child:SingleChildScrollView(child:SizedBox(width:box.maxWidth,height:1330*scale,
          child:FittedBox(alignment:Alignment.topCenter,fit:BoxFit.contain,child:MediaQuery.withClampedTextScaling(minScaleFactor:1,maxScaleFactor:1,child:scene))))),
          if(showNavigation)SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,5,12,7),child:Container(height:65,
            decoration:BoxDecoration(color:const Color(0xC5111920),border:Border.all(color:const Color(0x998F7A5B)),borderRadius:BorderRadius.circular(24)),
            child:Row(children:[for(var i=0;i<5;i++)Expanded(child:_GarageTap(label:const ['Главная','Работа','Добавить','Статистика','Ещё'][i],
              onTap:(){if(i==1)return;if(i==2){(onQuickAdd??()=>_showQuickAddMenu(context,session))();}else if(i==4){_openHomeMenu(context,session);}else{go(context,i);}},
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(const [Icons.home_outlined,Icons.local_shipping_outlined,Icons.add_circle_outline,Icons.bar_chart,Icons.grid_view_outlined][i],
                color:i==1||i==2?gold:Colors.white70,size:i==2?49:27),if(i!=2)...[const SizedBox(height:4),Text(const ['Главная','Работа','','Статистика','Ещё'][i],style:TextStyle(fontSize:10,color:i==1?gold:Colors.white70))]])))])))),
        ]),
      ]);
    });
  });
}
class _MillMapClip extends CustomClipper<Path>{
  @override Path getClip(Size s)=>Path()..moveTo(0,0)..quadraticBezierTo(s.width*.5,s.height*.055,s.width,0)..lineTo(s.width,s.height*.95)..quadraticBezierTo(s.width*.5,s.height,s.width*.03,s.height*.95)..close();
  @override bool shouldReclip(covariant _MillMapClip old)=>false;
}
class _MillBars extends CustomPainter {
  final List<double> values;final Color color;const _MillBars(this.values,this.color);
  @override void paint(Canvas c,Size s){final max=values.fold<double>(0,math.max);final count=math.max(10,values.length);final w=s.width/count;
    for(var i=0;i<count;i++){final v=i<values.length&&max>0?values[i]/max:0.0;final h=math.max(1.0,s.height*v);
      c.drawRect(Rect.fromLTWH(i*w,s.height-h,w*.65,h),Paint()..color=v>0?color:color.withOpacity(.12));}}
  @override bool shouldRepaint(covariant _MillBars old)=>old.values!=values||old.color!=color;
}
