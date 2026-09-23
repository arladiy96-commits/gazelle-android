part of 'app_shell.dart';

class _ServiceHoodTarget extends StatefulWidget {
  final AppSession session;
  const _ServiceHoodTarget({required this.session});
  @override
  State<_ServiceHoodTarget> createState()=>_ServiceHoodTargetState();
}
class _ServiceHoodTargetState extends State<_ServiceHoodTarget> {
  bool _opening=false;
  Future<void> _open() async {
    if(_opening)return;
    setState(()=>_opening=true);
    try { await _openMaintenance(context,widget.session); }
    finally { if(mounted)setState(()=>_opening=false); }
  }
  @override
  Widget build(BuildContext context)=>Tooltip(message:'ТО и обслуживание',child:_GarageTap(
    label:'Открыть капот: ТО и обслуживание',onTap:_open,
    child:Center(child:Container(width:78,height:39,decoration:BoxDecoration(
      color:const Color(0x9909161C),borderRadius:BorderRadius.circular(22),
      border:Border.all(color:_amber.withValues(alpha:.8)),
      boxShadow:const[BoxShadow(color:Color(0x44FFA221),blurRadius:12)]),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        _opening?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:_amber)):
          const _GarageIcon('oil',color:_amber,size:24),const SizedBox(width:7),_garageText('ТО',19,color:_amber)])))));
}

Future<void> _openMaintenance(BuildContext context,AppSession session,{String? initialItem}) async {
  try {
    await Future.wait([
      precacheImage(const AssetImage('assets/images/service_closed.png'),context),
      precacheImage(const AssetImage('assets/images/service_open.png'),context),
    ]);
    if(!context.mounted)return;
    final reduced=MediaQuery.disableAnimationsOf(context);
    await Navigator.of(context).push<void>(PageRouteBuilder<void>(
      opaque:false,barrierColor:Colors.transparent,
      transitionDuration:Duration(milliseconds:reduced?0:1150),
      reverseTransitionDuration:Duration(milliseconds:reduced?0:850),
      pageBuilder:(context,animation,secondary)=>_MaintenancePage(session:session,
        animation:animation,initialItem:initialItem),
      transitionsBuilder:(context,animation,secondary,child)=>child));
    _homeDataRevision.value++;
  } catch(e) {
    if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content:Text('Не удалось открыть ТО. Проверьте файлы service_open.png и service_closed.png.')));
  }
}

double _servicePhase(double t,double start,double end)=>((t-start)/(end-start)).clamp(0.0,1.0).toDouble();
String _serviceDate(DateTime date)=>'${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}';
String _serviceKm(int? value)=>value==null?'—':'${_fmtInt(value.toDouble())} км';
int _serviceDays(DateTime date){final now=DateTime.now();return date.difference(DateTime(now.year,now.month,now.day)).inDays;}

typedef _ServicePlace=Widget Function(double x,double y,double w,double h,Widget child);

class _MaintenancePage extends StatefulWidget {
  final AppSession session;final Animation<double> animation;final String? initialItem;
  const _MaintenancePage({required this.session,required this.animation,this.initialItem});
  @override
  State<_MaintenancePage> createState()=>_MaintenancePageState();
}
class _MaintenancePageState extends State<_MaintenancePage> {
  late final MaintenanceRepository _repository;
  MaintenanceBook? _book;
  String? _selected;
  String _category='Двигатель';
  String? _error;
  @override
  void initState(){super.initState();_repository=MaintenanceRepository(widget.session.login);
    _selected=widget.initialItem;_load();}
  Future<void> _load() async {
    try {final book=await _repository.load();if(mounted)setState((){_book=book;_error=null;});}
    catch(e){if(mounted)setState(()=>_error='Не удалось прочитать историю ТО. Данные не перезаписаны.');}
  }
  void _back(){if(_selected!=null){setState(()=>_selected=null);}else{Navigator.of(context).maybePop();}}
  void _select(String id)=>setState(()=>_selected=id);
  Future<void> _record(MaintenanceItem item) async {
    final book=_book;if(book==null)return;
    final updated=await showModalBottomSheet<MaintenanceBook>(context:context,isScrollControlled:true,
      backgroundColor:Colors.transparent,builder:(_)=>_MaintenanceEntryForm(item:item,book:book,repository:_repository));
    if(updated!=null&&mounted)setState(()=>_book=updated);
  }
  Future<void> _note(MaintenanceItem item) async {
    final result=await showDialog<String>(context:context,builder:(_)=>_ServiceNoteDialog(
      initial:_book?.notes[item.id]??''));
    if(result==null)return;
    try {final updated=await _repository.setNote(item.id,result);if(mounted)setState(()=>_book=updated);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Примечание не сохранено. Повторите попытку.')));}
  }
  void _history(MaintenanceItem item){
    final entries=_book!.history(item.id);
    showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF07141D),
      builder:(_)=>SafeArea(child:Padding(padding:const EdgeInsets.all(22),child:SizedBox(
        height:MediaQuery.sizeOf(context).height*.62,
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(item.title,style:const TextStyle(fontSize:23,color:_amber)),const SizedBox(height:16),
          Expanded(child:entries.isEmpty?const Center(child:Text('Записей пока нет')):ListView.separated(
            itemCount:entries.length,separatorBuilder:(_,i)=>const Divider(color:Color(0xFF29414E)),
            itemBuilder:(_,i){final entry=entries[i];return ListTile(contentPadding:EdgeInsets.zero,
              title:Text('${_serviceDate(entry.date)} · ${_serviceKm(entry.odometer)}',style:const TextStyle(color:_paper)),
              subtitle:Text([if(entry.example)'Пример записи',if(entry.note.isNotEmpty)entry.note,
                if(entry.nextKm!=null)'Следующая замена: ${_serviceKm(entry.nextKm)}',
                if(entry.nextDate!=null)'Срок: ${_serviceDate(entry.nextDate!)}',
                if(entry.cost!=null)'Стоимость: ${_fmt1(entry.cost!)} ₸'].join('\n'),
                style:const TextStyle(color:Color(0xFFB6CDD9),height:1.4)));})),
        ])))));
  }
  @override
  Widget build(BuildContext context)=>PopScope(canPop:_selected==null,
    onPopInvokedWithResult:(didPop,result){if(!didPop&&_selected!=null)setState(()=>_selected=null);},
    child:Scaffold(backgroundColor:Colors.transparent,body:AnimatedBuilder(animation:widget.animation,
      builder:(context,_){
        final t=MediaQuery.disableAnimationsOf(context)?1.0:widget.animation.value;
        final zoom=Curves.easeInOutCubic.transform(_servicePhase(t,0,.55));
        final front=Curves.easeInOut.transform(_servicePhase(t,.2,.57));
        final opened=Curves.easeInOut.transform(_servicePhase(t,.56,.88));
        final controls=_servicePhase(t,.78,1);
        return Opacity(opacity:_servicePhase(t,0,.12),child:Stack(children:[
          Positioned.fill(child:ClipRect(child:Transform.scale(scale:1+1.05*zoom,
            alignment:const Alignment(.28,-.12),child:Image.asset('assets/images/garage_approved.png',fit:BoxFit.fill)))),
          Positioned.fill(child:Opacity(opacity:front,child:Image.asset('assets/images/service_closed.png',fit:BoxFit.fill))),
          Positioned.fill(child:Opacity(opacity:opened,child:Image.asset('assets/images/service_open.png',fit:BoxFit.fill))),
          Positioned.fill(child:SafeArea(bottom:true,child:LayoutBuilder(builder:(context,c){
            final scale=c.maxWidth/840;final h=math.max(1570.0,c.maxHeight/scale);final sy=h/1870;
            Widget p(double x,double y,double w,double height,Widget child)=>Positioned(
              left:x,top:y*sy,width:w,height:height*sy,child:FittedBox(fit:BoxFit.contain,
                child:SizedBox(width:w,height:height,child:child)));
            final book=_book;
            return IgnorePointer(ignoring:t<.98,child:Opacity(opacity:controls,
              child:SingleChildScrollView(child:SizedBox(width:c.maxWidth,height:h*scale,
                child:FittedBox(fit:BoxFit.fill,child:MediaQuery.withClampedTextScaling(
                  minScaleFactor:1,maxScaleFactor:1,child:SizedBox(width:840,height:h,child:Stack(children:[
                    if(_error!=null)p(70,1100,700,250,_ServiceGlass(child:Column(mainAxisAlignment:MainAxisAlignment.center,
                      children:[_garageText(_error!,24,align:TextAlign.center),TextButton(onPressed:_load,child:const Text('Повторить'))]))),
                    if(book==null&&_error==null)p(370,1100,100,100,const Center(child:CircularProgressIndicator(color:_amber))),
                    if(book!=null)Positioned.fill(child:AnimatedSwitcher(duration:const Duration(milliseconds:230),
                      child:SizedBox(key:ValueKey(_selected??_category),width:840,height:h,
                        child:Stack(children:_selected==null?_overview(book,p):_details(book,MaintenanceCatalog.byId(_selected!),p))))),
                    p(18,17,80,75,_GarageTap(label:_selected==null?'Вернуться к машине':'Назад к узлам',onTap:_back,
                      child:const Icon(Icons.arrow_back_ios_new_rounded,color:_paper,size:38))),
                    p(118,19,605,58,Center(child:_garageText(_selected==null?'Состояние Газели':'Обслуживание',37))),
                    if(book?.example==true)p(335,80,170,28,Center(child:_garageText('Пример данных',16,color:const Color(0xFFB3C6D0)))),
                  ]))))))));
          }))),
        ]));
      })));

  List<Widget> _overview(MaintenanceBook book,_ServicePlace p){
    final category=MaintenanceCatalog.items.where((item)=>item.category==_category).toList();
    final oil=book.latest('oil');
    return [
      p(170,110,500,55,Center(child:_garageText(_category=='Двигатель'?'Под капотом':_category,31))),
      if(_category=='Двигатель')...[
        p(0,0,840,760,const IgnorePointer(child:CustomPaint(painter:_ServiceLeaders()))),
        p(100,350,265,80,_hotspot('oil','Масло',oil?.nextKm==null?'Добавить запись':_serviceKm(oil!.nextKm!-book.odometer),_amber)),
        p(555,391,224,80,_hotspot('air_filter','Фильтры',null,_ice)),
        p(57,644,248,80,_hotspot('coolant','Антифриз',null,_ice)),
        p(555,644,250,80,_hotspot('battery','Аккумулятор',null,_paper)),
      ],
      p(35,1034,770,210,_ServiceGlass(accent:_amber,child:Padding(padding:const EdgeInsets.all(26),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[const _GarageIcon('oil',color:_amber,size:32),const SizedBox(width:17),_garageText('Контроль обслуживания',23)]),
          const SizedBox(height:18),_garageText('Моторное масло',34,weight:FontWeight.w600),
          const SizedBox(height:8),Row(children:[Expanded(child:_garageText(oil?.nextKm==null?'Укажите срок замены':
            'До замены ${_serviceKm(oil!.nextKm!-book.odometer)}',28,color:_amber)),
            _ServiceButton(label:'Подробнее',onTap:()=>_select('oil'),compact:true)])])))),
      p(35,1265,770,94,Row(children:[for(final c in MaintenanceCatalog.categories)Expanded(child:Padding(
        padding:const EdgeInsets.symmetric(horizontal:5),child:_GarageTap(label:c,onTap:()=>setState(()=>_category=c),
          child:_ServiceGlass(accent:c==_category?_amber:null,child:Center(child:_garageText(c,25,color:c==_category?_amber:_paper))))))])),
      p(35,1385,770,335,_ServiceGlass(child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:20,vertical:8),
        itemCount:category.length,separatorBuilder:(_,i)=>const Divider(color:Color(0xFF405462),height:1),
        itemBuilder:(_,i){final item=category[i];final entry=book.latest(item.id);
          return SizedBox(height:82,child:_GarageTap(label:item.title,onTap:()=>_select(item.id),
            child:Row(children:[_ServiceIcon(item.icon,color:_amber,size:34),const SizedBox(width:17),
              Expanded(child:_garageText(item.title,24)),_garageText(entry==null?'Нет записи':item.usesDate?
                (entry.nextDate==null?'—':_serviceDate(entry.nextDate!)):(entry.nextKm==null?'—':_serviceKm(entry.nextKm!-book.odometer)),19,
                color:const Color(0xFFB8CDD8)),const Icon(Icons.chevron_right,color:_paper,size:29)])));}))),
      p(175,1770,490,66,_GarageTap(label:'Вернуться к машине',onTap:()=>Navigator.of(context).pop(),
        child:Center(child:_garageText('←  Вернуться к машине',24,color:const Color(0xFFCFD8DF))))),
    ];
  }
  Widget _hotspot(String id,String title,String? value,Color color)=>_GarageTap(label:title,onTap:()=>_select(id),
    child:_ServiceGlass(accent:color,child:Padding(padding:const EdgeInsets.symmetric(horizontal:17),
      child:Row(children:[_ServiceIcon(MaintenanceCatalog.byId(id).icon,color:color,size:37),const SizedBox(width:14),
        Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,
          children:[_garageText(title,23),if(value!=null)_garageText(value,23,color:color,weight:FontWeight.w600)]))]))));

  List<Widget> _details(MaintenanceBook book,MaintenanceItem item,_ServicePlace p){
    final entry=book.latest(item.id);final next=entry?.nextKm;
    final remaining=next==null?null:next-book.odometer;
    final total=next==null||entry==null?null:next-entry.odometer;
    final ratio=total==null||total<=0?null:((book.odometer-entry!.odometer)/total).clamp(0.0,1.0).toDouble();
    final dueDays=entry?.nextDate==null?null:_serviceDays(entry!.nextDate!);
    final status=item.usesDate?(dueDays==null?'Срок не задан':dueDays<0?'Срок истёк':'До окончания'):
      (remaining==null?'Нет записи':remaining<0?'Замена просрочена':'До замены');
    final large=item.usesDate?(dueDays==null?'—':'${dueDays.abs()} дн.'):
      (remaining==null?'—':_serviceKm(remaining.abs()));
    return [
      p(90,107,660,66,Center(child:FittedBox(fit:BoxFit.scaleDown,child:_garageText(item.title,47,weight:FontWeight.w600)))),
      p(737,21,65,65,Center(child:_ServiceIcon(item.icon,color:_amber,size:50))),
      if(item.id=='oil')...[
        p(0,0,840,650,const IgnorePointer(child:CustomPaint(painter:_ServiceLeaders(oilOnly:true)))),
        p(158,353,321,66,_ServiceGlass(accent:_amber,child:Row(mainAxisAlignment:MainAxisAlignment.center,
          children:[const _GarageIcon('oil',color:_amber,size:40),const SizedBox(width:16),_garageText(item.title,26)]))),
      ],
      p(38,764,765,150,_ServiceGlass(accent:_amber,child:Padding(padding:const EdgeInsets.all(20),
        child:Row(children:[SizedBox(width:103,height:103,child:CustomPaint(painter:_ServiceArc(ratio??0),
          child:Center(child:_ServiceIcon(item.icon,color:_amber,size:49)))),const SizedBox(width:15),
          SizedBox(width:216,child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,
            children:[_garageText(ratio==null?'Обслуживание':'${(ratio*100).toStringAsFixed(1).replaceAll('.',',')}%',29,weight:FontWeight.w600),
              const SizedBox(height:5),_garageText(ratio==null?'Запишите выполненную работу':'интервала пройдено',20),
              if(total!=null)_garageText('из ${_serviceKm(total)}',19,color:const Color(0xFFB9CDD8))])),
          Container(width:1,height:100,color:const Color(0xFF798685)),const SizedBox(width:28),
          Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,
            children:[_garageText(status,23),const SizedBox(height:10),FittedBox(fit:BoxFit.scaleDown,
              child:_garageText(large,47,color:(remaining??dueDays??0)<0?const Color(0xFFFF8A6F):_amber,weight:FontWeight.w600))]))])))),
      p(35,965,770,235,_ServiceGlass(child:Padding(padding:const EdgeInsets.symmetric(horizontal:30),
        child:Column(children:[
          _detailRow(Icons.calendar_month_outlined,'Последняя замена',entry==null?'—':item.usesDate?_serviceDate(entry.date):_serviceKm(entry.odometer)),
          const Divider(height:1,color:Color(0xFF537583)),
          _detailRow(Icons.speed_outlined,'Текущий пробег',_serviceKm(book.odometer)),
          const Divider(height:1,color:Color(0xFF537583)),
          _detailRow(Icons.route_outlined,item.usesDate?'Срок действия':'Следующая замена',item.usesDate?
            (entry?.nextDate==null?'—':_serviceDate(entry!.nextDate!)):_serviceKm(next)),
        ])))),
      p(45,1230,715,49,_garageText('История обслуживания',31)),
      p(35,1284,770,112,_GarageTap(label:'История обслуживания',onTap:()=>_history(item),
        child:_ServiceGlass(child:Padding(padding:const EdgeInsets.symmetric(horizontal:25),
          child:Row(children:[const Icon(Icons.build_outlined,color:_paper,size:46),const SizedBox(width:27),
            Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,
              children:[_garageText(entry==null?'Записей пока нет':_serviceDate(entry.date),24,color:const Color(0xFFB7CEDD)),
                const SizedBox(height:8),_garageText(entry==null?'Добавьте первую работу':entry.note.isEmpty?'Обслуживание выполнено':entry.note,21)])),
            if(entry!=null)_garageText(_serviceKm(entry.odometer),24),const SizedBox(width:15),
            const Icon(Icons.chevron_right,color:_paper,size:34)]))))),
      p(45,1420,700,43,_garageText('Примечание',29)),
      p(35,1469,770,82,_GarageTap(label:'Примечание',onTap:()=>_note(item),child:_ServiceGlass(
        child:Padding(padding:const EdgeInsets.symmetric(horizontal:27),child:Row(children:[
          const Icon(Icons.edit_note,color:_paper,size:42),const SizedBox(width:25),
          Expanded(child:_garageText((_book!.notes[item.id]??'').isEmpty?'Добавить':_book!.notes[item.id]!,23,color:const Color(0xFFB9CFDC))),
          const Icon(Icons.chevron_right,color:_paper,size:30)]))))),
      p(38,1584,765,96,_ServiceButton(label:item.usesDate?'Записать продление':'Записать замену',onTap:()=>_record(item))),
      p(35,1705,770,96,_GarageTap(label:'Все работы по разделу',onTap:()=>setState((){_category=item.category;_selected=null;}),
        child:_ServiceGlass(child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          const Icon(Icons.format_list_bulleted,color:_paper,size:35),const SizedBox(width:20),
          _garageText(item.category=='Двигатель'?'Все работы по двигателю':'Все работы · ${item.category}',26),
          const SizedBox(width:20),const Icon(Icons.chevron_right,color:_paper,size:34)])))),
    ];
  }
  Widget _detailRow(IconData icon,String label,String value)=>Expanded(child:Row(children:[
    Icon(icon,color:_ice,size:39),const SizedBox(width:27),Expanded(child:_garageText(label,27,color:_ice)),
    _garageText(value,27,weight:FontWeight.w600)]));
}

class _ServiceGlass extends StatelessWidget {
  final Widget child;final Color? accent;
  const _ServiceGlass({required this.child,this.accent});
  @override
  Widget build(BuildContext context)=>Container(decoration:BoxDecoration(
    borderRadius:BorderRadius.circular(23),border:Border.all(color:accent??const Color(0xB57899A9),width:accent==null?1:1.5),
    gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
      colors:[Color(0xC316252D),Color(0xDF071219),Color(0xB0132029)]),
    boxShadow:accent==null?null:[BoxShadow(color:accent!.withValues(alpha:.2),blurRadius:17)]),
    child:ClipRRect(borderRadius:BorderRadius.circular(23),child:child));
}
class _ServiceButton extends StatelessWidget {
  final String label;final VoidCallback onTap;final bool compact;
  const _ServiceButton({required this.label,required this.onTap,this.compact=false});
  @override
  Widget build(BuildContext context)=>_GarageTap(label:label,onTap:onTap,child:Container(
    padding:EdgeInsets.symmetric(horizontal:compact?22:24,vertical:compact?13:0),
    decoration:BoxDecoration(color:const Color(0xD007131B),borderRadius:BorderRadius.circular(compact?15:24),
      border:Border.all(color:_amber,width:1.7),boxShadow:[BoxShadow(color:_amber.withValues(alpha:compact ? 0.1 : 0.32),blurRadius:18)]),
    child:Row(mainAxisSize:compact?MainAxisSize.min:MainAxisSize.max,mainAxisAlignment:MainAxisAlignment.center,
      children:[if(!compact)...[const _GarageIcon('plus',color:_amber,size:46),const SizedBox(width:24)],
        _garageText(label,compact?23:34,color:_amber,weight:FontWeight.w500),
        if(compact)const Icon(Icons.chevron_right,color:_amber,size:24)])));
}
class _ServiceIcon extends StatelessWidget {
  final String kind;final Color color;final double size;
  const _ServiceIcon(this.kind,{this.color=_paper,this.size=34});
  @override
  Widget build(BuildContext context){
    if(kind=='oil')return _GarageIcon('oil',color:color,size:size);
    final icon=switch(kind){'filter'=>Icons.filter_alt_outlined,'coolant'=>Icons.water_drop_outlined,
      'battery'=>Icons.battery_std,'belt'=>Icons.settings_outlined,'brakes'=>Icons.album_outlined,
      'tyre'=>Icons.trip_origin,'document'=>Icons.description_outlined,_=>Icons.build_outlined};
    return Icon(icon,color:color,size:size);
  }
}
class _ServiceArc extends CustomPainter {
  final double ratio;const _ServiceArc(this.ratio);
  @override
  void paint(Canvas c,Size s){final rect=Rect.fromLTWH(5,5,s.width-10,s.height-10);
    for(var i=0;i<20;i++)c.drawArc(rect,math.pi*.8+i*math.pi*1.4/20,.16,false,
      Paint()..color=i<ratio*20?_amber:const Color(0xFF65717A)..style=PaintingStyle.stroke..strokeWidth=8);}
  @override
  bool shouldRepaint(_ServiceArc old)=>old.ratio!=ratio;
}
class _ServiceLeaders extends CustomPainter {
  final bool oilOnly;const _ServiceLeaders({this.oilOnly=false});
  @override
  void paint(Canvas c,Size size){
    c.save();c.scale(size.width/840,size.height/(oilOnly?650:760));
    void line(Color color,Offset a,Offset b){c.drawLine(a,b,Paint()..color=color..strokeWidth=2);
      c.drawCircle(b,20,Paint()..color=color.withValues(alpha:.55)..maskFilter=const MaskFilter.blur(BlurStyle.normal,12));
      c.drawCircle(b,13,Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=2);
      c.drawCircle(b,5,Paint()..color=color);}
    line(_amber,const Offset(274,421),const Offset(315,524));
    if(!oilOnly){line(_ice,const Offset(619,471),const Offset(591,541));
      line(_ice,const Offset(181,644),const Offset(183,593));line(_paper,const Offset(680,644),const Offset(666,601));}
    c.restore();
  }
  @override
  bool shouldRepaint(_ServiceLeaders old)=>old.oilOnly!=oilOnly;
}

class _MaintenanceEntryForm extends StatefulWidget {
  final MaintenanceItem item;
  final MaintenanceBook book;
  final MaintenanceRepository repository;
  const _MaintenanceEntryForm({required this.item,required this.book,required this.repository});
  @override
  State<_MaintenanceEntryForm> createState()=>_MaintenanceEntryFormState();
}
class _MaintenanceEntryFormState extends State<_MaintenanceEntryForm> {
  final _form=GlobalKey<FormState>();
  late final TextEditingController _at,_current;
  final _next=TextEditingController(),_cost=TextEditingController(),_note=TextEditingController();
  DateTime _date=DateUtils.dateOnly(DateTime.now());
  DateTime? _nextDate;
  bool _saving=false;
  String? _error;
  @override
  void initState(){super.initState();_at=TextEditingController(text:'${widget.book.odometer}');_current=TextEditingController(text:'${widget.book.odometer}');}
  @override
  void dispose(){for(final c in [_at,_current,_next,_cost,_note]){c.dispose();}super.dispose();}
  Future<void> _pick(bool next) async {
    final now=DateUtils.dateOnly(DateTime.now());
    final value=await showDatePicker(context:context,initialDate:next?(_nextDate??_date.add(const Duration(days:365))):_date,
      firstDate:next?_date.add(const Duration(days:1)):DateTime(2000),lastDate:next?DateTime(now.year+20):now);
    if(value!=null&&mounted)setState((){if(next){_nextDate=value;}else{_date=value;if(_nextDate!=null&&!_nextDate!.isAfter(value))_nextDate=null;}});
  }
  Future<void> _save() async {
    if(_saving||!_form.currentState!.validate())return;
    if(widget.item.usesDate&&_nextDate==null){setState(()=>_error='Укажите срок действия');return;}
    setState((){_saving=true;_error=null;});
    try {
      final book=await widget.repository.record(itemId:widget.item.id,date:_date,
        atKm:int.parse(_at.text),currentKm:int.parse(_current.text),nextKm:int.tryParse(_next.text),
        nextDate:_nextDate,cost:double.tryParse(_cost.text.replaceAll(',','.')),note:_note.text);
      if(mounted)Navigator.of(context).pop(book);
    }catch(e){if(mounted)setState(()=>_error=e is ArgumentError?'${e.message}':'Не удалось сохранить. Повторите попытку.');}
    finally{if(mounted)setState(()=>_saving=false);}
  }
  Widget _number(TextEditingController c,String label,{bool optional=false,bool money=false})=>Padding(
    padding:const EdgeInsets.only(bottom:14),child:TextFormField(controller:c,
      keyboardType:TextInputType.numberWithOptions(decimal:money),
      inputFormatters:money?[FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]:[FilteringTextInputFormatter.digitsOnly],
      style:const TextStyle(color:_paper),decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
      validator:(value){if(optional&&(value??'').isEmpty)return null;
        final n=double.tryParse((value??'').replaceAll(',','.'));
        return n==null||!n.isFinite||n<0?'Введите корректное число':null;}));
  @override
  Widget build(BuildContext context)=>PopScope(canPop:!_saving,child:SafeArea(child:Container(
    padding:EdgeInsets.fromLTRB(22,24,22,22+MediaQuery.viewInsetsOf(context).bottom),
    decoration:BoxDecoration(color:const Color(0xFF09151D),borderRadius:const BorderRadius.vertical(top:Radius.circular(26)),border:Border.all(color:_amber.withValues(alpha:.6))),
    child:SingleChildScrollView(child:AbsorbPointer(absorbing:_saving,child:Form(key:_form,child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(widget.item.title,style:const TextStyle(color:_amber,fontSize:24)),const SizedBox(height:8),
      const Text('Запись обслуживания',style:TextStyle(color:_paper)),const SizedBox(height:18),
      TextButton.icon(onPressed:()=>_pick(false),icon:const Icon(Icons.calendar_month),label:Text('Дата: ${_serviceDate(_date)}')),
      _number(_at,'Пробег при обслуживании, км'),_number(_current,'Текущий пробег, км'),
      if(widget.item.usesDate)TextButton.icon(onPressed:()=>_pick(true),icon:const Icon(Icons.event),label:Text(_nextDate==null?'Указать срок действия':'До ${_serviceDate(_nextDate!)}'))
      else _number(_next,'Следующая замена на пробеге, км (необязательно)',optional:true),
      _number(_cost,'Стоимость, ₸ (необязательно)',optional:true,money:true),
      TextFormField(controller:_note,maxLines:3,style:const TextStyle(color:_paper),decoration:const InputDecoration(labelText:'Что сделано',border:OutlineInputBorder())),
      if(_error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,style:const TextStyle(color:Colors.redAccent))),
      const SizedBox(height:20),OutlinedButton(onPressed:_saving?null:_save,style:OutlinedButton.styleFrom(foregroundColor:_amber,side:const BorderSide(color:_amber),padding:const EdgeInsets.all(18)),child:Text(_saving?'Сохранение…':'Сохранить обслуживание')),
    ])))))));
}
class _ServiceNoteDialog extends StatefulWidget {
  final String initial;const _ServiceNoteDialog({required this.initial});
  @override
  State<_ServiceNoteDialog> createState()=>_ServiceNoteDialogState();
}
class _ServiceNoteDialogState extends State<_ServiceNoteDialog> {
  late final TextEditingController _text=TextEditingController(text:widget.initial);
  @override
  void dispose(){_text.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>AlertDialog(backgroundColor:const Color(0xFF09151D),
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:BorderSide(color:_amber.withValues(alpha:.5))),
    title:const Text('Примечание',style:TextStyle(color:_amber)),
    content:TextField(controller:_text,maxLines:4,style:const TextStyle(color:_paper)),
    actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Отмена')),
      TextButton(onPressed:()=>Navigator.pop(context,_text.text),child:const Text('Сохранить',style:TextStyle(color:_amber)))]);
}
