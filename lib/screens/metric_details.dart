part of 'app_shell.dart';

Future<void> _openMetricDetails(BuildContext context,String metric,DateTime month) async {
  await Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>_MetricDetails(metric:metric,month:month)));
}
String _detailDate(DateTime d)=>'${d.day} ${const ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'][d.month-1]}';
String _detailTime(DateTime d)=>'${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
Text _dt(String s,{double size=14,Color color=_paper,FontWeight weight=FontWeight.w400})=>Text(s,
  style:TextStyle(fontSize:size,color:color,fontWeight:weight,height:1.25));
class _DetailGlass extends StatelessWidget {
  final Widget child;final bool accent;final EdgeInsets padding;
  const _DetailGlass({required this.child,this.accent=false,this.padding=const EdgeInsets.all(14)});
  @override
  Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:12),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:accent?const Color(0xBFFFBE5C):const Color(0x66768F98)),
      gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xC0182329),Color(0xD0061016)]),
      boxShadow:accent?const[BoxShadow(color:Color(0x14FFB23C),blurRadius:10)]:null),
    child:ClipRRect(borderRadius:BorderRadius.circular(16),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:2,sigmaY:2),
      child:Padding(padding:padding,child:child))));
}
class _DetailFrame extends StatelessWidget {
  final String title;final List<Widget> children;final ScrollController? controller;
  const _DetailFrame({required this.title,required this.children,this.controller});
  @override
  Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFF030B10),body:Stack(children:[
    Positioned.fill(child:Image.asset('assets/images/work_approved.png',fit:BoxFit.cover)),
    Positioned.fill(child:ColoredBox(color:Colors.black.withValues(alpha:.12))),
    SafeArea(child:Column(children:[Padding(padding:const EdgeInsets.fromLTRB(8,4,8,4),child:Row(children:[
      IconButton(tooltip:'Назад',onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.chevron_left,color:_amber,size:26)),
      Expanded(child:Text(title,textAlign:TextAlign.center,style:const TextStyle(color:_paper,fontSize:18,fontWeight:FontWeight.w500))),
      IconButton(tooltip:'Закрыть карточки',onPressed:()=>Navigator.of(context).popUntil((route)=>route.isFirst),icon:const Icon(Icons.close,color:_paper))])),
      Expanded(child:ListView(controller:controller,padding:const EdgeInsets.fromLTRB(16,0,16,24),children:children))]))]));
}
Widget _detailButton(String label,VoidCallback action,{IconData icon=Icons.chevron_right})=>Padding(padding:const EdgeInsets.only(bottom:12),
  child:OutlinedButton.icon(onPressed:action,icon:Icon(icon,size:18),label:Text(label,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w500)),
    style:OutlinedButton.styleFrom(foregroundColor:_amber,backgroundColor:const Color(0xC0081319),
      side:const BorderSide(color:Color(0xBFFFBE5C)),minimumSize:const Size.fromHeight(46),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))));
Widget _detailRow(String label,String value,{VoidCallback? onTap,String? subtitle,Color? color})=>InkWell(onTap:onTap,
  borderRadius:BorderRadius.circular(12),child:Container(constraints:const BoxConstraints(minHeight:48),padding:const EdgeInsets.symmetric(vertical:11,horizontal:2),child:Row(children:[
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(label,color:color??_paper),
      if(subtitle!=null)...[const SizedBox(height:4),_dt(subtitle,size:13,color:const Color(0xFFADC0CC))]])),
    const SizedBox(width:12),_dt(value,weight:FontWeight.w500),if(onTap!=null)...[const SizedBox(width:8),const Icon(Icons.chevron_right,color:_paper,size:18)]])));
List<Widget> _separated(List<Widget> rows)=>[for(var i=0;i<rows.length;i++)...[if(i>0)const Divider(height:1,color:Color(0x803E505B)),rows[i]]];

class _MetricDetails extends StatefulWidget {
  final String metric;final DateTime month;
  const _MetricDetails({required this.metric,required this.month});
  @override
  State<_MetricDetails> createState()=>_MetricDetailsState();
}
class _MetricDetailsState extends State<_MetricDetails> {
  late DateTime _month;
  _HomeMonthData? _total;ActivityBook? _book;TestPreferences? _prefs;
  final _scroll=ScrollController();
  String? _error,_direction;bool _trips=false,_hideEmpty=false;int _loadId=0;
  bool get _weight=>['Город','Район'].contains(widget.metric);
  bool get _fuel=>['Газ','Бензин'].contains(widget.metric);
  @override
  void initState(){super.initState();_month=widget.month;_homeDataRevision.addListener(_load);_load();}
  @override
  void dispose(){_loadId++;_homeDataRevision.removeListener(_load);_scroll.dispose();super.dispose();}
  Future<void> _load() async {
    final id=++_loadId;
    try {final total=await _HomeMonthData.load(_month);final book=await ActivityRepository.load(_month);final prefs=await TestPreferences.getInstance();
      if(mounted&&id==_loadId)setState((){_total=total;_book=book;_prefs=prefs;_error=null;});
    }catch(_){if(mounted&&id==_loadId)setState(()=>_error='Не удалось прочитать данные. Повторите попытку.');}
  }
  void _monthTo(int delta){setState((){_month=DateTime(_month.year,_month.month+delta);_book=null;_total=null;_direction=null;});if(_scroll.hasClients)_scroll.jumpTo(0);_load();}
  Future<void> _pickDay() async {
    final now=DateTime.now();final first=DateTime(_month.year,_month.month);final last=DateTime(_month.year,_month.month+1,0);
    final d=await showDatePicker(context:context,initialDate:ActivityBook.sameDay(first,now)?now:first,firstDate:first,lastDate:last);
    if(d!=null&&mounted)_day(d);
  }
  void _day(DateTime d)=>Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>_DayDetails(date:d)));
  List<ActivityEntry> get _entries=>(_book?.entries??[]).where((e)=>(_fuel?e.kind=='fuel':e.kind=='trip')&&e.type==widget.metric&&(_direction==null||e.direction==_direction)).toList()
    ..sort((a,b)=>b.date.compareTo(a.date));
  double? _dayValue(DateTime d,String metric)=>(_prefs?.get('home_day_${d.year}_${d.month}_${d.day}_$metric') as num?)?.toDouble();
  Future<void> _filter() async {
    final options=(_book?.entries??[]).where((e)=>e.kind=='trip'&&e.type==widget.metric).map((e)=>e.direction).where((e)=>e.isNotEmpty).toSet().toList()..sort();
    final selected=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF0A1820),builder:(c)=>SafeArea(child:ListView(shrinkWrap:true,children:[
      ListTile(title:_dt('Все направления'),onTap:()=>Navigator.pop(c,'')),for(final x in options)ListTile(title:_dt(x),onTap:()=>Navigator.pop(c,x))])));
    if(selected!=null&&mounted)setState(()=>_direction=selected.isEmpty?null:selected);
  }
  @override
  Widget build(BuildContext context){
    if(widget.metric=='Район')return _districtScreen();
    if(widget.metric=='Пробег')return _mileageScreen();
    return _DetailFrame(title:widget.metric,controller:_scroll,children:[
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(tooltip:'Предыдущий месяц',onPressed:()=>_monthTo(-1),icon:const Icon(Icons.chevron_left,color:_amber)),
        Flexible(child:_dt('${_garageMonths[_month.month-1]} ${_month.year}',size:15)),
        IconButton(tooltip:'Следующий месяц',onPressed:()=>_monthTo(1),icon:const Icon(Icons.chevron_right,color:_amber))]),const SizedBox(height:12),
      if(_error!=null)...[_DetailGlass(child:_dt(_error!)),_detailButton('Повторить',_load)]
      else if(_total==null||_book==null)const Center(child:CircularProgressIndicator(color:_amber))
      else ..._content(),
    ]);
  }

  double? _mileageOdometer(){
    if(_prefs==null)return null;
    final last=DateTime(_month.year,_month.month+1,0).day;
    for(var day=last;day>=1;day--){
      final key='home_day_${_month.year}_${_month.month}_${day}_';
      final end=(_prefs!.get('${key}odometer_end') as num?)?.toDouble();
      if(end!=null)return end;
      final start=(_prefs!.get('${key}odometer_start') as num?)?.toDouble();
      if(start!=null)return start;
    }
    return null;
  }
  void _mileageRoutes(){
    final trips=(_book?.entries??[]).where((e)=>e.kind=='trip').toList()..sort((a,b)=>b.date.compareTo(a.date));
    showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF091116),shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(20,14,20,24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Center(child:Container(width:42,height:4,decoration:BoxDecoration(color:const Color(0xFF6F777C),borderRadius:BorderRadius.circular(4)))),const SizedBox(height:18),
      _dt('История маршрутов',size:20,weight:FontWeight.w600),const SizedBox(height:4),_dt('${_garageMonths[_month.month-1]} ${_month.year}',size:13,color:const Color(0xFF9CA9B0)),const SizedBox(height:14),
      if(trips.isEmpty)_dt('За выбранный месяц маршрутов пока нет.',color:const Color(0xFFB3C6D0)) else Flexible(child:ListView(shrinkWrap:true,children:_separated([for(final e in trips)_detailRow(_detailDate(e.date),e.direction.isEmpty?'Маршрут не указан':e.direction,subtitle:_detailTime(e.date),onTap:(){Navigator.pop(c);_day(e.date);})]))),
    ]))));
  }
  Widget _mileageScreen(){
    final ready=_total!=null&&_book!=null&&_prefs!=null&&_error==null;
    final now=DateTime.now();
    final current=_month.year==now.year&&_month.month==now.month;
    final last=current?now.day:DateTime(_month.year,_month.month+1,0).day;
    final dates=[for(var i=last;i>=1;i--)DateTime(_month.year,_month.month,i)];
    final odo=ready?_mileageOdometer():null;
    return Scaffold(backgroundColor:const Color(0xFF05090C),body:Stack(children:[
      Positioned.fill(child:Image.asset('assets/images/mileage_approved.png',fit:BoxFit.cover,alignment:Alignment.topCenter,errorBuilder:(c,e,s)=>Image.asset('assets/images/garage_scene.png',fit:BoxFit.cover,alignment:Alignment.topCenter))),
      Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,stops:const[0,.43,.67,1],colors:[Colors.black.withValues(alpha:.08),Colors.black.withValues(alpha:.10),const Color(0xB70A0D0F),const Color(0xFA05090C)])))),
      SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(12,4,12,0),child:Row(children:[IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_ios_new_rounded,color:_paper,size:22)),Expanded(child:Text('Пробег',textAlign:TextAlign.center,style:const TextStyle(color:_paper,fontSize:20,fontWeight:FontWeight.w600))),IconButton(onPressed:()=>Navigator.of(context).popUntil((r)=>r.isFirst),icon:const Icon(Icons.more_horiz,color:_paper,size:28))])),
        Container(margin:const EdgeInsets.only(top:6),padding:const EdgeInsets.symmetric(horizontal:8),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),color:const Color(0xB80B1115),border:Border.all(color:const Color(0x665E6B72))),child:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>_monthTo(-1),icon:const Icon(Icons.chevron_left_rounded,color:_paper,size:25)),_dt('${_garageMonths[_month.month-1]} ${_month.year}',size:15),IconButton(onPressed:()=>_monthTo(1),icon:const Icon(Icons.chevron_right_rounded,color:_paper,size:25))])),
        Expanded(flex:9,child:Stack(children:[
          if(ready)Positioned(right:28,bottom:48,child:_MileageMonthTotal(value:'${_fmtInt(_total!.mileage)} км')),
          if(ready&&odo!=null)Positioned(left:0,right:0,bottom:24,child:IgnorePointer(child:Center(child:_MileageOdo(value:_fmtInt(odo))))),
          if(_error!=null)Center(child:Padding(padding:const EdgeInsets.all(24),child:_DetailGlass(child:Column(mainAxisSize:MainAxisSize.min,children:[_dt(_error!),const SizedBox(height:10),_detailButton('Повторить',_load)])))),
          if(_error==null&&!ready)const Center(child:CircularProgressIndicator(color:_amber)),
        ])),
        Expanded(flex:10,child:Container(margin:const EdgeInsets.fromLTRB(18,0,18,10),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xAFFFAD42)),gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xE11A1B1B),Color(0xE2081014)]),boxShadow:const[BoxShadow(color:Color(0x22FF9D2E),blurRadius:18)]),child:ClipRRect(borderRadius:BorderRadius.circular(22),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:8,sigmaY:8),child:Column(children:[
          Padding(padding:const EdgeInsets.fromLTRB(18,15,8,8),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Пробег по дням',size:17,weight:FontWeight.w600),const SizedBox(height:4),_dt(ready?'Всего за месяц: ${_fmtInt(_total!.mileage)} км':'Загрузка данных…',size:12,color:const Color(0xFF9DA7AD))])),IconButton(tooltip:'Выбрать дату',onPressed:_pickDay,icon:const Icon(Icons.calendar_month_outlined,color:Color(0xFFB8C2C8),size:22))])),
          const Divider(height:1,indent:18,endIndent:18,color:Color(0x554F5C62)),
          Expanded(child:ready?ListView(controller:_scroll,padding:const EdgeInsets.symmetric(horizontal:18),children:_separated([for(final d in dates)_MileageDayRow(date:_detailDate(d),value:_dailyText(d),weekend:d.weekday>=6,onTap:()=>_day(d))])):const SizedBox()),
        ]))))),
        Padding(padding:const EdgeInsets.fromLTRB(18,0,18,8),child:OutlinedButton(onPressed:ready?_mileageRoutes:null,style:OutlinedButton.styleFrom(foregroundColor:const Color(0xFF66E8FF),side:const BorderSide(color:Color(0x8866E8FF)),backgroundColor:const Color(0xC4081419),minimumSize:const Size.fromHeight(52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17))),child:const Row(children:[Icon(Icons.route_rounded,size:24),SizedBox(width:12),Expanded(child:Text('Открыть историю маршрутов',style:TextStyle(fontSize:15,fontWeight:FontWeight.w500))),Icon(Icons.chevron_right_rounded)]))),
        Padding(padding:const EdgeInsets.fromLTRB(22,0,22,10),child:Row(children:[const Icon(Icons.info_outline,color:Color(0xFF8D9498),size:18),const SizedBox(width:8),_dt('Реальные данные',size:12,color:const Color(0xFF8D9498)),const Spacer(),TextButton(onPressed:()=>Navigator.pop(context),child:const Text('К показателям  ›',style:TextStyle(color:_amber,fontSize:13)))])),
      ])),
    ]));
  }

  Widget _districtScreen(){
    final ready=_total!=null&&_book!=null&&_error==null;
    final entries=ready?_entries:<ActivityEntry>[];
    final total=ready?_total!.region:0.0;
    final grouped=<DateTime,List<ActivityEntry>>{};
    for(final e in entries){
      final d=DateTime(e.date.year,e.date.month,e.date.day);
      grouped.putIfAbsent(d,()=>[]).add(e);
    }
    final days=grouped.keys.toList()..sort((a,b)=>b.compareTo(a));
    return Scaffold(backgroundColor:const Color(0xFF05090C),body:Stack(children:[
      Positioned.fill(child:Image.asset('assets/images/district_approved.png',fit:BoxFit.cover,alignment:Alignment.topCenter)),
      Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,stops:const[0,.46,.72,1],colors:[Colors.black.withValues(alpha:.10),Colors.black.withValues(alpha:.03),const Color(0xB20A0D0F),const Color(0xF205090C)])))),
      SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(12,4,12,0),child:Row(children:[
          IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_ios_new_rounded,color:_paper,size:22)),
          Expanded(child:Text('Район',textAlign:TextAlign.center,style:const TextStyle(color:_paper,fontSize:20,fontWeight:FontWeight.w600))),
          IconButton(onPressed:()=>Navigator.of(context).popUntil((r)=>r.isFirst),icon:const Icon(Icons.more_horiz,color:_paper,size:28)),
        ])),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          IconButton(onPressed:()=>_monthTo(-1),icon:const Icon(Icons.chevron_left_rounded,color:_amber,size:27)),
          _dt('${_garageMonths[_month.month-1]} ${_month.year}',size:15,color:const Color(0xFFE8E8E8)),
          IconButton(onPressed:()=>_monthTo(1),icon:const Icon(Icons.chevron_right_rounded,color:_amber,size:27)),
        ]),
        Expanded(flex:10,child:Stack(children:[
          if(ready)Positioned(right:24,bottom:22,child:_DistrictTotal(value:'${_fmt1(total)} т')),
          if(_error!=null)Center(child:Padding(padding:const EdgeInsets.all(24),child:_DetailGlass(child:Column(mainAxisSize:MainAxisSize.min,children:[_dt(_error!),const SizedBox(height:10),_detailButton('Повторить',_load)])))),
          if(_error==null&&!ready)const Center(child:CircularProgressIndicator(color:_amber)),
        ])),
        Padding(padding:const EdgeInsets.fromLTRB(18,0,18,10),child:_DistrictTabs(trips:_trips,direction:_direction,onDays:()=>setState(()=>_trips=false),onTrips:()=>setState(()=>_trips=true),onFilter:_filter)),
        Expanded(flex:8,child:Container(margin:const EdgeInsets.fromLTRB(18,0,18,8),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xAFFFAD42),width:1),gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xD526211C),Color(0xD50A1014)]),boxShadow:const[BoxShadow(color:Color(0x22FF9D2E),blurRadius:18)]),child:ClipRRect(borderRadius:BorderRadius.circular(22),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:8,sigmaY:8),child:Column(children:[
          Padding(padding:const EdgeInsets.fromLTRB(18,16,8,8),child:Row(children:[Expanded(child:_dt(_trips?'Рейсы по району':'Перевозки по району',size:17,weight:FontWeight.w600)),IconButton(tooltip:_hideEmpty?'Показывать пустые дни':'Скрывать пустые дни',onPressed:()=>setState(()=>_hideEmpty=!_hideEmpty),icon:Icon(_hideEmpty?Icons.visibility_off_outlined:Icons.visibility_outlined,color:_amber,size:20))])),
          const Divider(height:1,indent:18,endIndent:18,color:Color(0x554F5C62)),
          Expanded(child:ready?_districtRows(entries,days):const SizedBox()),
        ]))))),
        Padding(padding:const EdgeInsets.fromLTRB(22,4,22,10),child:Row(children:[const Icon(Icons.info_outline,color:Color(0xFF8D9498),size:18),const SizedBox(width:8),_dt('Реальные данные',size:12,color:const Color(0xFF8D9498)),const Spacer(),TextButton(onPressed:()=>Navigator.pop(context),child:const Text('К показателям  ›',style:TextStyle(color:_amber,fontSize:13)))])),
      ])),
    ]));
  }

  Widget _districtRows(List<ActivityEntry> entries,List<DateTime> days){
    if(_trips){
      if(entries.isEmpty)return Center(child:_dt('За этот месяц рейсов пока нет.',color:const Color(0xFFB3C6D0)));
      return ListView(controller:_scroll,padding:const EdgeInsets.symmetric(horizontal:18),children:_separated([for(final e in entries)_DistrictRow(date:_detailDate(e.date),direction:e.direction.isEmpty?'Направление не указано':e.direction,value:'${_fmtInt(e.amount*1000)} кг',onTap:()=>_day(e.date))]));
    }
    final now=DateTime.now();final current=_month.year==now.year&&_month.month==now.month;
    final last=current?now.day:DateTime(_month.year,_month.month+1,0).day;
    final visible=_hideEmpty?days:[for(var i=last;i>=1;i--)DateTime(_month.year,_month.month,i)];
    if(visible.isEmpty)return Center(child:_dt('За этот месяц перевозок пока нет.',color:const Color(0xFFB3C6D0)));
    return ListView(controller:_scroll,padding:const EdgeInsets.symmetric(horizontal:18),children:_separated([for(final d in visible)
      Builder(builder:(context){final rows=entries.where((e)=>ActivityBook.sameDay(e.date,d)).toList();final kg=rows.fold<double>(0,(s,e)=>s+e.amount)*1000;final dirs=rows.map((e)=>e.direction).where((x)=>x.isNotEmpty).toSet().join(', ');return _DistrictRow(date:_detailDate(d),direction:dirs.isEmpty?'Нет перевозок':dirs,value:rows.isEmpty?'—':'${_fmtInt(kg)} кг',weekend:d.weekday>=6,onTap:()=>_day(d));})]));
  }
  List<Widget> _content(){
    final total=_total!;final entries=_entries;final metric=widget.metric;
    final value=switch(metric){'Город'=>'${_fmt1(total.city)} т','Район'=>'${_fmt1(total.region)} т','Газ'=>'${_fmt1(total.gas)} л',
      'Бензин'=>'${_fmt1(total.petrol)} л','Пробег'=>'${_fmtInt(total.mileage)} км',_=>'${_fmtInt(total.salary)} ₸'};
    final now=DateTime.now();final isCurrent=_month.year==now.year&&_month.month==now.month;
    final days=DateTime(_month.year,_month.month+1,0).day;
    final count=isCurrent?now.day:days;
    final dates=[for(var i=count;i>=1;i--)DateTime(_month.year,_month.month,i)];
    return [
      _DetailGlass(accent:true,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(value,size:27,weight:FontWeight.w500),const SizedBox(height:7),
        _dt(_fuel?'Получено за месяц':_weight?'Перевезено за месяц':metric=='Зарплата'?'Начислено за месяц':'За выбранный месяц',color:const Color(0xFFB2C4CF)),
        if(_fuel)...[const SizedBox(height:14),_dt('Записей в журнале: ${entries.length}',size:14)]])),
      if(metric=='Зарплата')...[
        _DetailGlass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Состав зарплаты',size:16,weight:FontWeight.w500),const SizedBox(height:8),
          ..._separated([for(final row in const {'base_salary':'Основной оклад','weekend_pay':'Выходные','holiday_pay':'Праздники',
            'paid_routes_pay':'Платные рейсы','city_pay':'Городской вес','region_pay':'Районный вес'}.entries)
            _detailRow(row.value,_salaryPart(row.key))]),
          const SizedBox(height:12),_dt('«—» — расшифровка начислений ещё не получена.',size:13,color:const Color(0xFFB3C6D0))])),
        _DetailGlass(child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Отработано',size:14),
          const SizedBox(height:8),_dt(_salaryPart('hours',unit:'ч'),size:20)])),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Норма',size:14),const SizedBox(height:8),_dt(_salaryPart('norm_hours',unit:'ч'),size:20)]))])),
      ],
      if(_weight)...[
        Row(children:[Expanded(child:_detailButton('По дням',()=>setState(()=>_trips=false),icon:_trips?Icons.calendar_today:Icons.check)),const SizedBox(width:10),
          Expanded(child:_detailButton('По рейсам',()=>setState(()=>_trips=true),icon:_trips?Icons.check:Icons.route))]),
        _detailButton(_direction??'Все направления',_filter,icon:Icons.filter_alt_outlined),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:_dt('Скрыть дни без записей',size:14),value:_hideEmpty,activeThumbColor:_amber,onChanged:(v)=>setState(()=>_hideEmpty=v)),
      ],
      if(_fuel||(_weight&&_trips))...[
        if(entries.isEmpty)_DetailGlass(child:_dt('За этот месяц записей пока нет.',color:const Color(0xFFB3C6D0)))
        else _DetailGlass(child:Column(children:_separated([for(final e in entries)_detailRow(_fuel?_detailDate(e.date):e.direction.isEmpty?'Направление не указано':e.direction,
          _fuel?'${_fmt1(e.amount)} л':'${_fmtInt(e.amount*1000)} кг',subtitle:_fuel?_detailTime(e.date):'${_detailDate(e.date)} · ${_detailTime(e.date)}',onTap:()=>_day(e.date))]))),
      ]else ...[
        Row(children:[Expanded(child:_dt('По дням',size:16,weight:FontWeight.w500)),IconButton(tooltip:'Выбрать дату',onPressed:_pickDay,icon:const Icon(Icons.calendar_month,color:_amber))]),
        _DetailGlass(child:Column(children:_separated([for(final d in dates)
          if(!_hideEmpty||entries.any((e)=>ActivityBook.sameDay(e.date,d)))
            _detailRow(_detailDate(d),_weight?_weightDay(entries,d):_dailyText(d),onTap:()=>_day(d),
              color:d.weekday>=6?const Color(0xFFFFAA91):null)]))),
      ],
      _dt('Подробные записи доступны не за все дни. «—» — нет записи.',size:13,color:const Color(0xFFBAC8D1)),
      const SizedBox(height:18),
      if(_fuel)_detailButton('Добавить заправку',()=>_openFuelEntry(context),icon:Icons.add),
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


class _MileageMonthTotal extends StatelessWidget{
  final String value;const _MileageMonthTotal({required this.value});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.fromLTRB(18,12,18,11),decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0x556BE8F6)),gradient:const LinearGradient(colors:[Color(0xDD172126),Color(0xE80A1115)]),boxShadow:const[BoxShadow(color:Color(0x1A52E8FF),blurRadius:16)]),child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Row(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[_dt(value,size:27,weight:FontWeight.w500)]),const SizedBox(height:2),_dt('За месяц',size:12,color:const Color(0xFFB5BEC3))]));
}
class _MileageOdo extends StatelessWidget{
  final String value;const _MileageOdo({required this.value});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),decoration:BoxDecoration(borderRadius:BorderRadius.circular(4),color:const Color(0xE3271604),border:Border.all(color:const Color(0x777A4A16))),child:Text(value.replaceAll(' ',''),style:const TextStyle(color:Color(0xFFFFB43C),fontSize:15,fontWeight:FontWeight.w600,letterSpacing:1.8,fontFeatures:[FontFeature.tabularFigures()],shadows:[Shadow(color:Color(0xAAFF8A00),blurRadius:5)])));
}
class _MileageDayRow extends StatelessWidget{
  final String date,value;final bool weekend;final VoidCallback onTap;
  const _MileageDayRow({required this.date,required this.value,required this.onTap,this.weekend=false});
  @override Widget build(BuildContext context)=>InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(vertical:14),child:Row(children:[Expanded(child:_dt(date,size:14,color:weekend?const Color(0xFFFFAA91):_paper)),_dt(value,size:15,weight:FontWeight.w500),const SizedBox(width:8),const Icon(Icons.chevron_right_rounded,color:_paper,size:20)])));
}

class _DistrictTotal extends StatelessWidget{
  final String value;const _DistrictTotal({required this.value});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.fromLTRB(16,10,18,10),decoration:BoxDecoration(borderRadius:BorderRadius.circular(13),border:Border.all(color:const Color(0x55FFB24A)),gradient:const LinearGradient(colors:[Color(0xD8343535),Color(0xE91B1D1F)]),boxShadow:const[BoxShadow(color:Color(0x33000000),blurRadius:14,offset:Offset(0,5))]),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.inventory_2_outlined,color:_amber,size:21),const SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(value,size:24,weight:FontWeight.w500),_dt('За месяц',size:12,color:const Color(0xFFC1C1C1))]) ]));
}
class _DistrictTabs extends StatelessWidget{
  final bool trips;final String? direction;final VoidCallback onDays,onTrips,onFilter;
  const _DistrictTabs({required this.trips,required this.direction,required this.onDays,required this.onTrips,required this.onFilter});
  @override Widget build(BuildContext context)=>Container(height:48,decoration:BoxDecoration(borderRadius:BorderRadius.circular(15),color:const Color(0xC61B1D1E),border:Border.all(color:const Color(0x556F7478))),child:Row(children:[
    Expanded(child:_tab('По дням',!trips,onDays)),Expanded(child:_tab('По рейсам',trips,onTrips)),
    Expanded(child:InkWell(onTap:onFilter,borderRadius:BorderRadius.circular(14),child:Padding(padding:const EdgeInsets.symmetric(horizontal:10),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Flexible(child:Text(direction??'Все направления',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_paper,fontSize:13))),const SizedBox(width:4),const Icon(Icons.keyboard_arrow_down_rounded,color:_paper,size:19)]))))
  ]));
  Widget _tab(String label,bool active,VoidCallback tap)=>InkWell(onTap:tap,borderRadius:BorderRadius.circular(14),child:Container(alignment:Alignment.center,decoration:active?BoxDecoration(borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xCCFFAA3B)),gradient:const LinearGradient(colors:[Color(0x55FF9D20),Color(0x161B1D1E)])):null,child:Text(label,style:TextStyle(color:active?_paper:const Color(0xFFB7B7B7),fontSize:13,fontWeight:active?FontWeight.w600:FontWeight.w400))));
}
class _DistrictRow extends StatelessWidget{
  final String date,direction,value;final bool weekend;final VoidCallback onTap;
  const _DistrictRow({required this.date,required this.direction,required this.value,required this.onTap,this.weekend=false});
  @override Widget build(BuildContext context)=>InkWell(onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(vertical:13),child:Row(children:[const Icon(Icons.calendar_today_outlined,color:_paper,size:19),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(date,size:14,color:weekend?const Color(0xFFFFAA91):_paper),const SizedBox(height:3),_dt(direction,size:12,color:const Color(0xFFA8A8A8))])),_dt(value,size:15,weight:FontWeight.w500),const SizedBox(width:8),const Icon(Icons.chevron_right_rounded,color:_paper,size:20)])));
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
  Widget build(BuildContext context)=>_DetailFrame(title:'${_detailDate(widget.date)} ${widget.date.year}',children:[
    if(_error!=null)...[_DetailGlass(child:_dt(_error!)),_detailButton('Повторить',_load)]
    else if(_book==null)const Center(child:CircularProgressIndicator(color:_amber))
    else ..._content(),
  ]);
  List<Widget> _content(){
    final rows=_book!.onDay(widget.date);final trips=rows.where((e)=>e.kind=='trip').toList();final fuel=rows.where((e)=>e.kind=='fuel').toList();
    final status=_prefs?.getString('${_key}status');final hours=_number('hours'),mileage=_number('mileage'),start=_number('odometer_start'),end=_number('odometer_end');
    return [
      _detailButton('Изменить / удалить смену',()=>_testOpen(context,page:'История смен')),
      Center(child:_dt(switch(status){'completed'=>'Смена завершена','open'=>'Смена открыта',_=>'Статус смены не записан'},color:_amber,size:14)),const SizedBox(height:20),
      _DetailGlass(accent:true,child:Column(children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        _dt(hours==null?'—':'${_fmt1(hours)} ч',size:24),const SizedBox(height:6),_dt('Отработано',size:14)])),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(mileage==null?'—':'${_fmtInt(mileage)} км',size:24),const SizedBox(height:6),_dt('Пробег за день',size:14)]))]),
        const Divider(height:30,color:Color(0xFF53616A)),_dt(start==null||end==null?'Одометр не записан':'Одометр  ${_fmtInt(start)} → ${_fmtInt(end)} км',size:15)])),
      _dt('Рейсы · ${trips.length}',size:17),const SizedBox(height:12),
      _DetailGlass(child:trips.isEmpty?_dt('Рейсы за этот день не записаны.',color:const Color(0xFFB3C6D0)):Column(children:_separated([
        for(var i=0;i<trips.length;i++)_detailRow('${(i+1).toString().padLeft(2,'0')}  ${trips[i].direction.isEmpty?'Без направления':trips[i].direction}',
          '${_fmtInt(trips[i].amount*1000)} кг',subtitle:trips[i].type,onTap:()=>_trip(trips[i]))]))),
      _DetailGlass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Топливо',size:17),const SizedBox(height:10),
        if(fuel.isEmpty)_dt('Заправки за этот день не записаны.',color:const Color(0xFFB3C6D0))
        else ..._separated([for(final e in fuel)_detailRow(e.type,'${_fmt1(e.amount)} л',subtitle:_detailTime(e.date),onTap:()=>_editActivity(context,e))])])),
      _detailButton('GPS за день',()=>Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>_DetailFrame(title:'GPS · ${_detailDate(widget.date)}',children:[
        _DetailGlass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Маршрут · скорость · стоянки',size:20),const SizedBox(height:12),
          _dt('GPS-история этого дня пока не подключена. После подключения здесь появятся маршрут и остановки.',color:const Color(0xFFB3C6D0))]))]))),icon:Icons.route),
    ];
  }
}
