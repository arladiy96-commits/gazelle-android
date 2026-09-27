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
      if(mounted&&id==_loadId)setState((){_total=total;_book=book;_prefs=prefs;_error=null;});
    }catch(_){if(mounted&&id==_loadId)setState(()=>_error='Не удалось прочитать данные. Повторите попытку.');}
  }
  void _monthTo(int delta){setState((){_month=DateTime(_month.year,_month.month+delta);_book=null;_total=null;_direction=null;_salaryDaysExpanded=false;});if(_scroll.hasClients)_scroll.jumpTo(0);_load();}
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
