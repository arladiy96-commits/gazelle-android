part of 'app_shell.dart';

class _MillStatistics extends StatefulWidget {
  final AppSession session;
  final VoidCallback? onHome;
  const _MillStatistics({required this.session,this.onHome});
  @override State<_MillStatistics> createState()=>_MillStatisticsState();
}
class _StatsDay {
  final DateTime date; final double city,region,km,salary; final int trips;
  const _StatsDay(this.date,this.city,this.region,this.km,this.salary,this.trips);
  double get kg=>city+region;
  bool get active=>kg!=0||km!=0||salary!=0||trips!=0;
  double value(int i)=>switch(i){0=>kg,1=>trips.toDouble(),2=>km,3=>salary,_=>km>0?kg/km:0};
}
class _MillStatisticsState extends State<_MillStatistics> {
  DateTime month=DateTime(DateTime.now().year,DateTime.now().month);
  int period=0,metric=0; bool onlyActive=false; DateTimeRange? custom;
  static const gold=Color(0xFFE4AB50);
  static const names=['Тоннаж','Рейсы','Пробег','Зарплата','Эффективность'];
  static const units=['кг','рейсов','км','₸','кг/км'];
  DateTimeRange get range=>period==2&&custom!=null?custom!:DateTimeRange(
    start:DateTime(month.year,month.month-(period==1?2:0)),end:DateTime(month.year,month.month+1,0));
  String date(DateTime d)=>'${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}';
  String get periodLabel=>period==0?'${_garageMonths[month.month-1]} ${month.year} г.':'${date(range.start)}.${range.start.year} — ${date(range.end)}.${range.end.year}';
  List<_StatsDay> data(TestState b,DateTimeRange r){
    final out=<_StatsDay>[];final factors=<String,double>{};
    for(var d=r.start;!d.isAfter(r.end);d=DateTime(d.year,d.month,d.day+1)){
      final key='${d.year}-${d.month}';
      final factor=factors.putIfAbsent(key,(){
        var sum=0.0;for(var i=1;i<=DateTime(d.year,d.month+1,0).day;i++)sum+=b.statistics(d,day:DateTime(d.year,d.month,i))['base_salary']??0;
        return sum==0?1:(b.statistics(d)['base_salary']??0)/sum;
      });
      final s=b.statistics(d,day:d);
      final trips=b.records.where((e)=>e['kind']=='trip'&&TestState.dayKey(b.recordDay(e))==TestState.dayKey(d)).length;
      out.add(_StatsDay(d,s['city_kg']??0,s['region_kg']??0,s['mileage']??0,
        (s['salary']??0)-(s['base_salary']??0)*(1-factor),trips));
    }return out;
  }
  double total(List<_StatsDay> rows,int i){
    if(i==4){final km=rows.fold<double>(0,(s,d)=>s+d.km);return km==0?0:rows.fold<double>(0,(s,d)=>s+d.kg)/km;}
    return rows.fold<double>(0,(s,d)=>s+d.value(i));
  }
  Future<void> pickMonth() async {
    var year=month.year;
    final selected=await showModalBottomSheet<DateTime>(context:context,backgroundColor:const Color(0xFF111A20),
      builder:(sheet)=>StatefulBuilder(builder:(context,update)=>SafeArea(child:SizedBox(height:300,child:Column(children:[
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:()=>update(()=>year--),icon:const Icon(Icons.chevron_left,color:gold)),
          Text('$year',style:const TextStyle(color:Colors.white,fontSize:19)),IconButton(onPressed:()=>update(()=>year++),icon:const Icon(Icons.chevron_right,color:gold))]),
        Expanded(child:GridView.count(crossAxisCount:3,childAspectRatio:2.5,children:[for(var m=1;m<=12;m++)TextButton(
          onPressed:()=>Navigator.pop(sheet,DateTime(year,m)),child:Text(_garageMonths[m-1],style:const TextStyle(color:gold)))])),
      ])))));
    if(selected!=null&&mounted)setState((){month=selected;if(period==2)period=0;});
  }
  Future<void> setPeriod(int i) async {
    if(i!=2){setState(()=>period=i);return;}
    final r=await showDateRangePicker(context:context,firstDate:DateTime(2000),lastDate:DateTime(2100),
      initialDateRange:range,helpText:'Выберите период',saveText:'Готово');
    if(r!=null&&mounted)setState((){custom=r;period=2;});
  }
  void openDay(TestState b,_StatsDay d)=>showModalBottomSheet<void>(context:context,isScrollControlled:true,
    backgroundColor:const Color(0xFF10191F),builder:(sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),
      child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text('${date(d.date)}.${d.date.year}',style:const TextStyle(color:Colors.white,fontSize:20))),
          IconButton(onPressed:()=>Navigator.pop(sheet),icon:const Icon(Icons.close,color:gold))]),
        Text('Город: ${_fmt1(d.city)} кг   Район: ${_fmt1(d.region)} кг\nРейсы: ${d.trips}   Пробег: ${_fmt1(d.km)} км\nЗаработано: ${_fmt1(d.salary)} ₸',
          style:const TextStyle(color:Colors.white,height:1.8)),
        if(!d.active)const Text('За этот день данных нет',style:TextStyle(color:Colors.grey)),
        ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.sizeOf(sheet).height*.45),child:ListView(shrinkWrap:true,children:[
          for(final s in b.shifts.where((s)=>TestState.dayKey(DateTime.parse(s['start'] as String))==TestState.dayKey(d.date)))
            ListTile(contentPadding:EdgeInsets.zero,title:Text('Смена · ${_detailTime(DateTime.parse(s['start'] as String))}',style:const TextStyle(color:gold)),
              trailing:const Icon(Icons.chevron_right,color:gold),onTap:(){Navigator.pop(sheet);_testOpen(context,shiftId:s['id'] as String);}),
        ])),
      ]))));
  Widget panel(Widget child,{bool light=false})=>Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFF86603C),width:.8),
      gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:light?
        const [Color(0xEB10171C),Color(0xA010171C)]:const [Color(0xF21A2024),Color(0xF0080F14)])),child:child);
  Widget chip(String label,bool selected,VoidCallback tap)=>Padding(padding:const EdgeInsets.only(right:5),child:Material(color:Colors.transparent,
    child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(24),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),color:selected?const Color(0xAA5D3B12):const Color(0xCC10171C),
        border:Border.all(color:selected?gold:const Color(0xFF694829))),
      child:Text(label,style:TextStyle(color:selected?gold:const Color(0xFFB4BABE),fontSize:11))))));
  @override Widget build(BuildContext context)=>Stack(children:[

    _TestLive(builder:(b){
      final rows=data(b,range);final shown=rows.where((d)=>!onlyActive||d.active).toList();
      final previous=period==2?DateTimeRange(start:DateTime(range.start.year,range.start.month,range.start.day-rows.length),end:DateTime(range.start.year,range.start.month,range.start.day-1)):
        DateTimeRange(start:DateTime(range.start.year,range.start.month-(period==1?3:1)),end:DateTime(range.start.year,range.start.month,0));
      final before=data(b,previous);final hasBefore=before.any((d)=>d.active);
      return ListView(padding:const EdgeInsets.fromLTRB(14,8,14,14),children:[
        Row(children:[IconButton(onPressed:widget.onHome??()=>Navigator.maybePop(context),icon:const Icon(Icons.arrow_back,color:gold)),
          const Expanded(child:Text('Статистика',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.w600))),
          TextButton(onPressed:pickMonth,child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.calendar_month_outlined,color:gold,size:17),
            const SizedBox(width:5),Text('${_garageMonths[month.month-1]} ${month.year}',style:const TextStyle(color:Colors.white,fontSize:10)),
            const Icon(Icons.expand_more,color:gold,size:16)])),
        ]),
        panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('ПЕРИОД',style:TextStyle(color:Color(0xFFB5B5AE),fontSize:10,letterSpacing:1)),const SizedBox(height:5),
          Text(periodLabel,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w600)),const SizedBox(height:12),
          Row(children:[for(var i=0;i<3;i++)chip(const ['Месяц','3 месяца','Свой'][i],period==i,()=>setPeriod(i))]),
        ]),light:true),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(var i=0;i<5;i++)chip(names[i],metric==i,()=>setState(()=>metric=i))])),
        const SizedBox(height:8),
        panel(Column(children:[Row(children:[Expanded(child:Text('${names[metric]}, ${units[metric]}',style:const TextStyle(color:Colors.white,fontSize:13))),
          Text('${_fmt1(total(rows,metric))} ${units[metric]}',style:const TextStyle(color:gold,fontSize:16,fontWeight:FontWeight.w600))]),
          const SizedBox(height:8),SizedBox(height:145,width:double.infinity,child:LayoutBuilder(builder:(context,box)=>GestureDetector(
            onTapUp:(tap){final i=((tap.localPosition.dx-35)/(box.maxWidth-45)*(rows.length-1)).round().clamp(0,rows.length-1);openDay(b,rows[i]);},
            child:CustomPaint(painter:_StatsLine(rows.map((d)=>d.value(metric)).toList(),rows.map((d)=>date(d.date)).toList()))))),
          if(metric==4)const Text('Эффективность — перевезённые кг на 1 км',style:TextStyle(color:Colors.grey,fontSize:10)),
        ])),
        panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Сравнение с предыдущим периодом',style:TextStyle(color:Colors.white,fontSize:13)),
          const SizedBox(height:10),if(!hasBefore)const Text('За предыдущий период данных нет',style:TextStyle(color:Colors.grey,fontSize:11))
          else Row(children:[for(var i=0;i<3;i++)Expanded(child:Builder(builder:(context){final prev=total(before,i),now=total(rows,i);final delta=now-prev;
            return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(names[i],style:const TextStyle(color:Colors.grey,fontSize:10)),
              Text(prev==0?'—':'${delta>=0?'+':''}${_fmt1(delta/prev*100)}%',style:TextStyle(color:delta>=0?const Color(0xFF7CCF91):const Color(0xFF57ADD2),fontSize:19)),
              Text('${delta>=0?'+':''}${_fmt1(delta)} ${units[i]}',style:const TextStyle(color:Colors.grey,fontSize:10))]);
          }))]),
        ]),light:true),
        const Padding(padding:EdgeInsets.only(bottom:8),child:Text('Ключевые итоги',style:TextStyle(color:Colors.white,fontSize:17))),
        Row(children:[for(var i=0;i<4;i++)Expanded(child:Padding(padding:EdgeInsets.only(right:i==3?0:5),child:panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(const [Icons.scale_outlined,Icons.local_shipping_outlined,Icons.route_outlined,Icons.payments_outlined][i],color:gold,size:20),
          const SizedBox(height:5),Text(names[i],style:const TextStyle(color:Colors.grey,fontSize:9)),const SizedBox(height:4),
          FittedBox(fit:BoxFit.scaleDown,child:Text(_fmt1(total(rows,i)),style:const TextStyle(color:Colors.white,fontSize:15))),
          Text(units[i],style:const TextStyle(color:Colors.grey,fontSize:9)),
        ]))))]),
        panel(Column(children:[Row(children:[const Icon(Icons.calendar_month_outlined,color:gold,size:19),const SizedBox(width:7),
          const Expanded(child:Text('Детализация по дням',style:TextStyle(color:Colors.white,fontSize:13))),
          PopupMenuButton<bool>(initialValue:onlyActive,onSelected:(v)=>setState(()=>onlyActive=v),
            itemBuilder:(_)=>const [PopupMenuItem(value:false,child:Text('Все дни')),PopupMenuItem(value:true,child:Text('С записями'))],
            child:Row(children:[Text(onlyActive?'С записями':'Все дни',style:const TextStyle(color:Colors.white,fontSize:10)),const Icon(Icons.expand_more,color:gold,size:17)]))]),
          const SizedBox(height:10),tableRow(['Дата','Город, кг','Район, кг','Км','₸'],header:true),
          if(shown.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('Записей за период нет',style:TextStyle(color:Colors.grey))),
          for(final d in shown)InkWell(onTap:()=>openDay(b,d),child:tableRow([date(d.date),_fmt1(d.city),_fmt1(d.region),_fmt1(d.km),_fmt1(d.salary)],weekend:d.date.weekday>=6)),
        ])),
      ]);
    }),
  ]);
  Widget tableRow(List<String> cells,{bool header=false,bool weekend=false})=>Container(
    padding:const EdgeInsets.symmetric(vertical:7,horizontal:2),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:Color(0xFF293238),width:.5))),
    child:Row(children:[for(var i=0;i<cells.length;i++)Expanded(child:Text(cells[i],textAlign:i==0?TextAlign.left:TextAlign.right,
      style:TextStyle(color:header?Colors.grey:i==0&&weekend?const Color(0xFFD78576):const Color(0xFFD5D9DB),fontSize:header?9:10))),
      SizedBox(width:12,child:header?null:const Icon(Icons.chevron_right,size:12,color:gold))]));
}
class _StatsLine extends CustomPainter {
  final List<double> values;final List<String> labels;
  const _StatsLine(this.values,this.labels);
  @override void paint(Canvas canvas,Size size){
    const gold=Color(0xFFE9AC50);final rect=Rect.fromLTWH(35,8,math.max(1,size.width-45),size.height-29);
    final maximum=math.max(1.0,values.fold<double>(0,math.max)*1.15);
    void label(String t,Offset p){final painter=TextPainter(text:TextSpan(text:t,style:const TextStyle(color:Color(0xFF92999D),fontSize:8)),textDirection:TextDirection.ltr)..layout();painter.paint(canvas,p);}
    for(var i=0;i<5;i++){final y=rect.bottom-rect.height*i/4;canvas.drawLine(Offset(rect.left,y),Offset(rect.right,y),Paint()..color=const Color(0xFF263037)..strokeWidth=.5);label(_fmt1(maximum*i/4),Offset(0,y-4));}
    if(values.isEmpty)return;final path=Path();final points=<Offset>[];
    for(var i=0;i<values.length;i++){final p=Offset(rect.left+rect.width*i/math.max(1,values.length-1),rect.bottom-rect.height*values[i]/maximum);points.add(p);if(i==0){path.moveTo(p.dx,p.dy);}else{path.lineTo(p.dx,p.dy);}}
    final fill=Path.from(path)..lineTo(points.last.dx,rect.bottom)..lineTo(rect.left,rect.bottom)..close();
    canvas.drawPath(fill,Paint()..shader=const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0x665F401A),Color(0x035F401A)]).createShader(rect));
    canvas.drawPath(path,Paint()..color=gold.withOpacity(.35)..style=PaintingStyle.stroke..strokeWidth=5..maskFilter=const MaskFilter.blur(BlurStyle.normal,3));
    canvas.drawPath(path,Paint()..color=gold..style=PaintingStyle.stroke..strokeWidth=1.6);
    final step=math.max(1,(values.length/7).ceil());for(var i=0;i<points.length;i++){if(values.length<=31||i%step==0){canvas.drawCircle(points[i],2.3,Paint()..color=gold);canvas.drawCircle(points[i],1.2,Paint()..color=const Color(0xFF10171C));}
      if(i%step==0)label(labels[i],Offset(points[i].dx-8,rect.bottom+7));}
  }
  @override bool shouldRepaint(covariant _StatsLine old)=>old.values!=values||old.labels!=labels;
}

class _MillStatisticsRoute extends StatelessWidget {
  final AppSession session;
  const _MillStatisticsRoute({required this.session});
  @override Widget build(BuildContext context)=>Scaffold(
    body:Stack(children:[
      Positioned.fill(child:_ExtendedArtwork(asset:'assets/images/scenes/statistics_dashboard.png',topInset:MediaQuery.paddingOf(context).top,fit:BoxFit.cover)),
      SafeArea(child:_MillStatistics(session:session))]),
    bottomNavigationBar:_BottomNavigation(index:3,items:const [
      _NavItem(label:'Главная',icon:Icons.home_outlined,activeIcon:Icons.home_rounded),
      _NavItem(label:'Работа',icon:Icons.local_shipping_outlined,activeIcon:Icons.local_shipping_rounded),
      _NavItem(label:'Добавить',icon:Icons.add,activeIcon:Icons.add),
      _NavItem(label:'Статистика',icon:Icons.bar_chart_outlined,activeIcon:Icons.bar_chart_rounded),
      _NavItem(label:'Ещё',icon:Icons.grid_view_outlined,activeIcon:Icons.grid_view_rounded),
    ],onChanged:(i){if(i==3)return;if(i==4){_openHomeMenu(context,session);return;}
      _CinematicMore(session:session).navigate(context,i);},onLongPressLogo:(){}));
}
