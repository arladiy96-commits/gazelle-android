part of 'app_shell.dart';

// Presentation snapshot for the approved design. No monthly totals are used.
// The shift service and real GPS provider will supply this view data later.
class _WorkViewData {
  final int mileage, startOdometer, currentOdometer, trips;
  final double cityTonnage, regionTonnage;
  final String elapsed, started;
  const _WorkViewData({this.mileage=124,this.startOdometer=128540,
    this.currentOdometer=128664,this.trips=5,this.cityTonnage=8.4,
    this.regionTonnage=12.6,this.elapsed='04:26:18',this.started='07:10'});
}

class WorkPage extends StatelessWidget {
  final AppSession session;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onQuickAdd;
  const WorkPage({super.key,required this.session,this.onNavigate,this.onQuickAdd});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder:(context,c){
    const data=_WorkViewData();
    final bottom=MediaQuery.paddingOf(context).bottom;
    final scale=c.maxWidth/840;
    final h=math.max(1500.0,(c.maxHeight-bottom)/scale);
    final sy=h/1870;
    void navigate(int index){onNavigate?.call(index);}
    void quickAdd(){if(onQuickAdd!=null){onQuickAdd!();}else{_showQuickAddMenu(context,session);}}
    void later(String title){_garageInfo(context,title,'Подключим на следующем этапе',
      'Сейчас здесь утверждённый макет текущей смены. Учёт смены и GPS пока не подключены.');}
    Widget p(double x,double y,double w,double height,Widget child)=>Positioned(
      left:x,top:y*sy,width:w,height:height*sy,
      child:FittedBox(fit:BoxFit.contain,child:SizedBox(width:w,height:height,child:child)));
    final canvas=SizedBox(width:840,height:h,child:Stack(children:[
      Positioned.fill(child:Image.asset('assets/images/work_approved.png',fit:BoxFit.fill,filterQuality:FilterQuality.high)),
      const Positioned.fill(child:IgnorePointer(child:DecoratedBox(decoration:BoxDecoration(
        gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,
          colors:[Color(0x22020B12),Color(0x44020B12),Color(0x55020B12)]))))),
      p(25,13,70,80,_GarageTap(label:'Вернуться на главную',onTap:()=>navigate(0),
        child:const Icon(Icons.arrow_back_ios_new_rounded,color:_paper,size:43))),
      p(220,15,400,78,Column(children:[_garageText('Работа',38,weight:FontWeight.w600),
        const SizedBox(height:5),_garageText('Текущая смена',25,color:const Color(0xFFB7CBD6))])),
      p(751,13,68,80,_GarageTap(label:'Уведомления',onTap:()=>later('Уведомления'),
        child:const Center(child:_GarageIcon('bellOutline',size:40)))),
      p(42,110,757,70,_WorkStatus(data:data,onPause:()=>later('Пауза смены'))),
      p(58,238,334,168,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        _garageText('Пробег за смену',29),const SizedBox(height:12),
        Expanded(child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,
          child:_garageText('${data.mileage} км',106,color:_amber,weight:FontWeight.w600)))])),
      p(418,239,3,156,Container(color:_ice)),
      p(532,237,271,170,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        _garageText('Начало смены',24),const SizedBox(height:7),
        _garageText('${_fmtInt(data.startOdometer.toDouble())} км',32,weight:FontWeight.w600),
        const SizedBox(height:24),_garageText('Текущий одометр',24),const SizedBox(height:7),
        _garageText('${_fmtInt(data.currentOdometer.toDouble())} км',32,weight:FontWeight.w600)])),
      p(37,474,242,109,_WorkMetric(kind:'city',title:'Город',value:'${_fmt1(data.cityTonnage)} т',color:_amber)),
      p(296,474,262,109,_WorkMetric(kind:'district',title:'Район',value:'${_fmt1(data.regionTonnage)} т',color:const Color(0xFFD58BE8))),
      p(575,474,232,109,_WorkMetric(kind:'truck',title:'Рейсы',value:'${data.trips}',color:_ice)),
      p(210,593,420,41,Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        _garageText('Всего перевезено',23),const SizedBox(width:18),
        _garageText('${(data.cityTonnage+data.regionTonnage).toStringAsFixed(1).replaceAll('.',',')} т',31,color:_amber,weight:FontWeight.w600)])),
      p(28,646,786,428,_WorkMap(onNavigate:()=>later('Навигация'))),
      p(29,1090,785,228,_WorkFuel(onAdd:()=>_openFuelEntry(context))),
      p(29,1331,785,213,const _WorkEvents()),
      p(49,1588,301,85,_GarageTap(label:'Добавить рейс',onTap:()=>_openTripEntry(context),
        child:Container(decoration:BoxDecoration(color:const Color(0xD8061016),
          borderRadius:BorderRadius.circular(22),border:Border.all(color:_amber,width:1.6)),
          child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            const _GarageIcon('truck',color:_amber,size:47),const SizedBox(width:18),
            _garageText('Добавить рейс',23,color:_amber)])))),
      p(584,1490,215,208,_GarageTap(label:'Завершить смену',onTap:()=>later('Завершение смены'),
        child:const _GarageEndShift())),
      p(0,1697,840,151,_WorkNavigation(onHome:()=>navigate(0),onAdd:quickAdd,
        onInvoices:()=>navigate(3),onMore:()=>_openHomeMenu(context,session))),
    ]));
    return ColoredBox(color:const Color(0xFF02090E),child:SingleChildScrollView(
      physics:const ClampingScrollPhysics(),child:Padding(padding:EdgeInsets.only(bottom:bottom),
        child:SizedBox(width:c.maxWidth,height:h*scale,child:FittedBox(fit:BoxFit.fill,
          alignment:Alignment.topCenter,child:MediaQuery.withClampedTextScaling(
            minScaleFactor:1,maxScaleFactor:1,child:canvas))))));
  });
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
      const SizedBox(width:20),_garageText('Смена открыта',26,color:_ice,weight:FontWeight.w600),
      const Spacer(),_divider(),const Spacer(),_garageText(data.elapsed,29,color:_ice,weight:FontWeight.w600),
      const Spacer(),_divider(),const Spacer(),_garageText('Начало ',24,color:_ice),_garageText(data.started,25),
      const Spacer(),_GarageTap(label:'Пауза смены',onTap:onPause,child:Container(width:68,height:68,
        decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xFF04141E),
          border:Border.all(color:_ice,width:2.5),boxShadow:const[BoxShadow(color:Color(0x6615DDE8),blurRadius:15)]),
        child:const Icon(Icons.pause_rounded,color:_ice,size:42)))]));
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
            _garageText('Склад → Бишкуль',27,weight:FontWeight.w600),const SizedBox(height:8),
            _garageText('В пути · 18 км до точки',23,color:const Color(0xFFB5CDD9))])),
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
  final VoidCallback onAdd;const _WorkFuel({required this.onAdd});
  @override
  Widget build(BuildContext context)=>_WorkPanel(child:Padding(padding:const EdgeInsets.fromLTRB(17,13,17,12),
    child:Column(children:[Row(children:[_garageText('Заправки за смену',27,weight:FontWeight.w600),
      const Spacer(),_GarageTap(label:'Добавить заправку',onTap:onAdd,child:Row(children:[
        const Icon(Icons.add_circle_outline,color:_ice,size:37),const SizedBox(width:12),_garageText('Добавить',24,color:_ice)]))]),
      const SizedBox(height:11),_row('flame','Газ','+40 л','09:35','4 800 ₸',_ice),
      _row('fuel','Бензин','+15 л','11:20','3 150 ₸',const Color(0xFFFF6653)),
      const Spacer(),Row(mainAxisAlignment:MainAxisAlignment.end,children:[_garageText('Всего ',22),
        _garageText('7 950 ₸',27,color:_amber,weight:FontWeight.w600)])])));
  Widget _row(String icon,String title,String litres,String time,String cost,Color color)=>Container(
    height:61,padding:const EdgeInsets.symmetric(horizontal:14),decoration:BoxDecoration(
      color:const Color(0x88040C11),borderRadius:BorderRadius.circular(17),border:Border.all(color:const Color(0x775A6F77))),
    child:Row(children:[Container(width:54,height:54,decoration:BoxDecoration(shape:BoxShape.circle,
      border:Border.all(color:color.withValues(alpha:.22))),child:Center(child:_GarageIcon(icon,color:color,size:39))),
      const SizedBox(width:23),SizedBox(width:168,child:_garageText(title,23)),
      _garageText(litres,24,weight:FontWeight.w600),const Spacer(),_garageText('$time  ·  $cost',22,color:const Color(0xFFCDD5DE))]));
}

class _WorkEvents extends StatelessWidget {
  const _WorkEvents();
  @override
  Widget build(BuildContext context)=>_WorkPanel(child:Padding(padding:const EdgeInsets.fromLTRB(19,15,19,12),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _garageText('События смены',27,weight:FontWeight.w600),const SizedBox(height:12),
      _event(null,'11:45','Рейс завершён · Район · 6,2 т',_paper),
      _event('fuel','11:20','Заправка · Бензин +15 л',const Color(0xFFFF6653)),
      _event('flame','09:35','Заправка · Газ +40 л',_ice),
    ])));
  Widget _event(String? icon,String time,String description,Color color)=>SizedBox(height:47,child:Row(children:[
    SizedBox(width:66,child:Center(child:icon==null?const Icon(Icons.flag_outlined,color:_paper,size:32):_GarageIcon(icon,color:color,size:32))),
    SizedBox(width:77,child:_garageText(time,22,color:const Color(0xFFBFD0DC))),
    SizedBox(width:25,child:Stack(alignment:Alignment.center,children:[Container(width:1,color:const Color(0xFF6D8E9D)),
      Container(width:4,height:4,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFFADCEDB)))])),
    const SizedBox(width:11),Expanded(child:_garageText(description,22)),
  ]));
}

class _WorkNavigation extends StatelessWidget {
  final VoidCallback onHome,onAdd,onInvoices,onMore;
  const _WorkNavigation({required this.onHome,required this.onAdd,required this.onInvoices,required this.onMore});
  @override
  Widget build(BuildContext context){
    final items=[('homeOutline','Главная',onHome),('truck','Работа',(){}),('plus','Добавить',onAdd),
      ('invoice','Накладные',onInvoices),('gridOutline','Ещё',onMore)];
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
