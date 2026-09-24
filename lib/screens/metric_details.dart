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
  _HomeMonthData? _total;ActivityBook? _book;SharedPreferences? _prefs;
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
    try {final total=await _HomeMonthData.load(_month);final book=await ActivityRepository.load(_month);final prefs=await SharedPreferences.getInstance();
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
  Widget build(BuildContext context)=>_DetailFrame(title:widget.metric,controller:_scroll,children:[
    Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(tooltip:'Предыдущий месяц',onPressed:()=>_monthTo(-1),icon:const Icon(Icons.chevron_left,color:_amber)),
      Flexible(child:_dt('${_garageMonths[_month.month-1]} ${_month.year}',size:15)),
      IconButton(tooltip:'Следующий месяц',onPressed:()=>_monthTo(1),icon:const Icon(Icons.chevron_right,color:_amber))]),const SizedBox(height:12),
    if(_error!=null)...[_DetailGlass(child:_dt(_error!)),_detailButton('Повторить',_load)]
    else if(_total==null||_book==null)const Center(child:CircularProgressIndicator(color:_amber))
    else ..._content(),
  ]);
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

class _DayDetails extends StatefulWidget {
  final DateTime date;const _DayDetails({required this.date});
  @override
  State<_DayDetails> createState()=>_DayDetailsState();
}
class _DayDetailsState extends State<_DayDetails> {
  ActivityBook? _book;SharedPreferences? _prefs;String? _error;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load() async {
    try{final b=await ActivityRepository.load(widget.date);final p=await SharedPreferences.getInstance();
      if(mounted)setState((){_book=b;_prefs=p;_error=null;});}
    catch(_){if(mounted)setState(()=>_error='Не удалось прочитать отчёт');}
  }
  String get _key=>'home_day_${widget.date.year}_${widget.date.month}_${widget.date.day}_';
  double? _number(String name)=>(_prefs?.get('$_key$name') as num?)?.toDouble();
  void _trip(ActivityEntry e)=>Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>_DetailFrame(title:'Рейс',children:[
    _DetailGlass(accent:true,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt(e.direction.isEmpty?'Направление не указано':e.direction,size:20),
      _detailRow('Тип',e.type),_detailRow('Вес','${_fmtInt(e.amount*1000)} кг'),_detailRow('Дата',_detailDate(e.date)),_detailRow('Время',_detailTime(e.date))]))])));
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
        else ..._separated([for(final e in fuel)_detailRow(e.type,'${_fmt1(e.amount)} л',subtitle:_detailTime(e.date))])])),
      _detailButton('GPS за день',()=>Navigator.of(context).push<void>(MaterialPageRoute(builder:(_)=>_DetailFrame(title:'GPS · ${_detailDate(widget.date)}',children:[
        _DetailGlass(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_dt('Маршрут · скорость · стоянки',size:20),const SizedBox(height:12),
          _dt('GPS-история этого дня пока не подключена. После подключения здесь появятся маршрут и остановки.',color:const Color(0xFFB3C6D0))]))]))),icon:Icons.route),
    ];
  }
}
