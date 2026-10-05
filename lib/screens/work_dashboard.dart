part of 'app_shell.dart';

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

class _MillWorkScreen extends StatelessWidget {
  final AppSession session;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onQuickAdd;
  final bool showNavigation;
  const _MillWorkScreen({required this.session,this.onNavigate,this.onQuickAdd,this.showNavigation=true});
  static const gold=Color(0xFFE3B66F),cyan=Color(0xFF24B6DB);
  void go(BuildContext c,int i){if(onNavigate!=null){onNavigate!(i);}else{_CinematicMore(session:session).navigate(c,i);}}
  Widget label(String value,double size,{Color color=Colors.white,FontWeight weight=FontWeight.w400,int lines=1})=>Text(value,maxLines:lines,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.18));
  Widget card({required String title,required String value,required IconData icon,required String foot,required String detail,required VoidCallback tap,double? progress,bool gauge=false})=>_GarageTap(label:title.replaceAll('\n',' '),onTap:tap,child:Padding(padding:const EdgeInsets.fromLTRB(17,16,17,12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:40,color:gold),const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[label(title,17,color:const Color(0xFFBFCBD2),lines:2),const SizedBox(height:7),FittedBox(fit:BoxFit.scaleDown,child:label(value,27,weight:FontWeight.w600))]))]),
    const Spacer(),
    if(gauge)Row(children:[const Icon(Icons.speed,size:39,color:cyan),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[label(foot,13,color:Colors.white60),label(detail,15)]))])
    else ...[
      if(progress!=null)ClipRRect(borderRadius:BorderRadius.circular(5),child:LinearProgressIndicator(value:progress.clamp(0.0,1.0),minHeight:7,color:cyan,backgroundColor:const Color(0xFF283943)))
      else Container(height:1,color:const Color(0xFF34414A)),
      const SizedBox(height:10),Row(children:[Expanded(child:label(foot,13,color:Colors.white60)),label(detail,14)]),
    ],
  ])));
  Widget event(BuildContext context,Map<String,dynamic> r,int index){
    final kind=r['kind']?.toString()??'other';
    final fuel=r['type']?.toString()??'Топливо';
    final time=DateTime.tryParse(r['date']?.toString()??'');
    final amount=_fmt1((r['amount'] as num?)?.toDouble()??0);
    final title=switch(kind){'trip'=>r['direction']?.toString()??'Рейс','fuel'=>fuel,'invoice'=>'Накладная № ${r['number']??'—'}',_=>r['note']?.toString()??'Запись'};
    final subtitle=switch(kind){'trip'=>'Рейс · ${r['type']??''}','fuel'=>'Заправка','invoice'=>r['status']=='closed'?'Закрыта':'Черновик',_=>'Примечание'};
    final value=switch(kind){'trip'=>'$amount кг','fuel'=>'$amount л',_=>''};
    final icon=switch(kind){'trip'=>Icons.scale_outlined,'fuel'=>fuel=='Газ'?Icons.local_fire_department:Icons.local_gas_station_outlined,'invoice'=>Icons.receipt_long_outlined,_=>Icons.edit_note};
    return SizedBox(height:64,child:Row(children:[
      Container(width:33,height:33,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:const Color(0xFF467A8E)),gradient:const RadialGradient(colors:[Color(0xFF246479),Color(0xFF071C29)])),child:label('${index+1}',16)),
      const SizedBox(width:14),Container(width:1,color:const Color(0xFF53616A)),const SizedBox(width:13),
      Expanded(child:Material(color:Colors.transparent,child:InkWell(onTap:()=>_testEditor(context,kind,entry:r),child:Container(decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFF3E4A50),width:.6))),child:Row(children:[
        SizedBox(width:66,child:label(time==null?'—':_detailTime(time),18,color:Colors.white60)),Icon(icon,size:38,color:gold),const SizedBox(width:17),
        Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[label(title,16),const SizedBox(height:5),label(subtitle,13,color:Colors.white60)])),
        const SizedBox(width:8),label(value,23,weight:FontWeight.w600),const SizedBox(width:8),const Icon(Icons.more_vert,color:Colors.white60,size:23),
      ]))))),
    ]));
  }
  @override Widget build(BuildContext context)=>_TestLive(builder:(b){
    final shift=b.active;
    final rows=shift==null?<Map<String,dynamic>>[]:[...b.forShift(shift['id'] as String)]..sort((a,b)=>(a['date']?.toString()??'').compareTo(b['date']?.toString()??''));
    double sum(String kind,[String? type])=>rows.where((r)=>r['kind']==kind&&(type==null||r['type']==type)).fold<double>(0,(s,r)=>s+((r['amount'] as num?)?.toDouble()??0));
    final trips=rows.where((r)=>r['kind']=='trip').length;
    final elapsed=shift==null?0:math.max(0,(b.elapsed(shift)*3600).round());
    final clock='${(elapsed~/3600).toString().padLeft(2,'0')}:${(elapsed~/60%60).toString().padLeft(2,'0')}:${(elapsed%60).toString().padLeft(2,'0')}';
    final start=DateTime.tryParse(shift?['start']?.toString()??'');
    final km=shift==null?0.0:shift['odometerSet']==true?b.mileage(shift):(shift['gpsKm'] as num?)?.toDouble()??0.0;
    final gas=sum('fuel','Газ'),petrol=sum('fuel','Бензин');
    final totalFuel=gas+petrol;
    return LayoutBuilder(builder:(context,box){
      final scale=box.maxWidth/709;
      final top=MediaQuery.viewPaddingOf(context).top;
      final bottom=MediaQuery.viewPaddingOf(context).bottom;
      final dock=showNavigation?87.0+bottom:bottom;
      final height=math.max(1310*scale+top,box.maxHeight-dock);
      Widget at(double x,double y,double w,double h,Widget child)=>Positioned(left:x,top:y,width:w,height:h,child:child);
      final scene=SizedBox(width:709,height:1310,child:Stack(children:[
        at(31,27,76,76,_GarageTap(label:'Главная',onTap:()=>go(context,0),child:Container(decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xE609131B),border:Border.all(color:gold,width:1.5)),child:const Icon(Icons.arrow_back,size:37,color:gold)))),
        at(198,31,290,49,Row(children:[const Icon(Icons.local_shipping_outlined,color:gold,size:52),const SizedBox(width:22),label('Работа',41,weight:FontWeight.w600)])),
        at(238,82,255,26,label('Сводка за текущую смену',18,color:Colors.white70)),
        at(503,31,179,71,Container(padding:const EdgeInsets.symmetric(horizontal:15),decoration:BoxDecoration(color:const Color(0xE60A151D),borderRadius:BorderRadius.circular(23),border:Border.all(color:gold.withValues(alpha:.7))),child:Row(children:[Container(width:14,height:14,decoration:BoxDecoration(shape:BoxShape.circle,color:shift==null?Colors.grey:const Color(0xFF09C46B))),const SizedBox(width:13),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[label(shift==null?'Смена закрыта':'Смена открыта',13,color:Colors.white60),const SizedBox(height:4),label(clock,22)]))]))),
        at(29,132,649,372,_WorkMapFrame(child:RepaintBoundary(child:ShiftRouteMap(key:ValueKey(shift?['id']),shiftId:shift?['id'] as String?,paused:shift?['gpsStatus']=='paused',unit:1.8,satellite:false)))),
        at(27,536,214,155,card(title:'Тоннаж\nза смену',value:'${_fmt1(sum('trip'))} кг',icon:Icons.scale_outlined,foot:'Цель (день)',detail:'—',tap:()=>_testOpen(context,page:'Рейсы',shiftId:shift?['id'] as String?))),
        at(258,536,201,155,card(title:'Пробег\nза смену',value:'${_fmt1(km)} км',icon:Icons.add_road,foot:'Средний за смену',detail:elapsed>0?'${_fmt1(km*3600/elapsed)} км/ч':'—',gauge:true,tap:()=>_openMetricDetails(context,'Пробег',DateTime.now()))),
        at(475,536,205,155,card(title:'Рейсы\nза смену',value:'$trips',icon:Icons.local_shipping_outlined,foot:'План (день)',detail:'—',tap:()=>_testOpen(context,page:'Рейсы',shiftId:shift?['id'] as String?))),
        at(27,709,214,157,card(title:'Газ\nза смену',value:'${_fmt1(gas)} л',icon:Icons.local_fire_department,foot:'Выдано',detail:'${_fmt1(gas)} л',progress:totalFuel>0?gas/totalFuel:0,tap:()=>_testEditor(context,'fuel',initialType:'Газ'))),
        at(258,709,201,157,card(title:'Бензин\nза смену',value:'${_fmt1(petrol)} л',icon:Icons.local_gas_station_outlined,foot:'Выдано',detail:'${_fmt1(petrol)} л',progress:totalFuel>0?petrol/totalFuel:0,tap:()=>_testEditor(context,'fuel',initialType:'Бензин'))),
        at(475,709,205,157,card(title:'Время смены',value:clock,icon:Icons.access_time,foot:'Начало',detail:start==null?'—':_detailTime(start),tap:()=>_testOpen(context,shiftId:shift?['id'] as String?))),
        at(45,905,617,46,Row(children:[const Icon(Icons.history,color:gold,size:40),const SizedBox(width:20),Expanded(child:label('Действия в текущей смене',23,weight:FontWeight.w600))])),
        at(40,960,633,317,rows.isEmpty?Center(child:label(shift==null?'Откройте смену, чтобы начать работу':'Действий пока нет',20,color:Colors.white60)):ListView.builder(key:ValueKey('events-${shift?['id']}'),padding:EdgeInsets.zero,itemExtent:64,itemCount:rows.length,itemBuilder:(c,i)=>event(context,rows[i],i))),
      ]));
      return Stack(children:[
        Positioned.fill(child:_ExtendedArtwork(asset:'assets/images/scenes/work_shift_scene.png',topInset:top)),
        Positioned(left:0,right:0,top:0,bottom:dock,child:SingleChildScrollView(child:SizedBox(height:height,child:Stack(children:[
          Positioned.fill(child:_ExtendedArtwork(asset:'assets/images/scenes/work_shift_scene.png',topInset:top)),
          Positioned(top:top,left:0,right:0,height:1310*scale,child:FittedBox(fit:BoxFit.contain,alignment:Alignment.topCenter,child:MediaQuery.withClampedTextScaling(minScaleFactor:1,maxScaleFactor:1,child:scene))),
        ])))),
        if(showNavigation)Positioned(left:8,right:8,bottom:bottom+3,child:_MillDock(index:1,onChanged:(i){if(i==1)return;if(i==2){(onQuickAdd??()=>_showQuickAddMenu(context,session))();}else if(i==4){_openHomeMenu(context,session);}else{go(context,i);}})),
      ]);
    });
  });
}


class _WorkMapFrame extends StatelessWidget {
  final Widget child;
  const _WorkMapFrame({required this.child});
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(5),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),
      border:Border.all(color:const Color(0xFFE0AE63),width:1.6),
      gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:[Color(0xFF839AA3),Color(0xFF182A35),Color(0xFFB57C3D),Color(0xFF14252D)]),
      boxShadow:const[BoxShadow(color:Color(0x66000000),blurRadius:8,offset:Offset(0,4))]),
    child:Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(19),
      border:Border.all(color:const Color(0xFF071018),width:2)),padding:const EdgeInsets.all(2),
      child:ClipRRect(borderRadius:BorderRadius.circular(16),child:child)));
}
